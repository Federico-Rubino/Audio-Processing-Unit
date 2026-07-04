library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Shared address/wraparound sequencer used by both bmu_read and bmu_write.
-- Owns the row cursor into the 4-BRAM row-major layout (samples 0..3 in row 0,
-- one per BRAM block; samples 4..7 in row 1; ...) and the circular-buffer
-- wraparound arithmetic. Produces only address/enable/done; the data path
-- (we, data_in, data_out) is wired up by bmu_read/bmu_write themselves.
entity bmu_addr_gen is
    generic (
        BUFFER_ADDR_WIDTH : integer := 10; -- row-address width, shared by all 4 BRAM blocks
        BUFFER_SIZE_BITS  : integer := 18; -- width of sample-count fields
        LANES             : integer := 4  -- samples moved per count_en pulse: 1 (serial), 4 (parallel4), 8 (parallel8)
    );
    Port (
        clk, rst : in std_logic; -- synchronous, active high
        start    : in std_logic; -- pulse: load a new operation
        count_en : in std_logic; -- pulse: advance the operation by LANES samples

        buffer_start     : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0); -- ring start (row address)
        buffer_length    : in std_logic_vector(BUFFER_SIZE_BITS-1 downto 0);  -- ring length, in samples
        operation_start  : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0); -- this grain's start (row address)
        operation_length : in std_logic_vector(BUFFER_SIZE_BITS-1 downto 0);  -- this grain's length, in samples

        bram0_port0_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        bram1_port0_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        bram2_port0_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        bram3_port0_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);

        bram0_port1_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        bram1_port1_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        bram2_port1_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        bram3_port1_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);

        bram0_port0_en : out std_logic;
        bram1_port0_en : out std_logic;
        bram2_port0_en : out std_logic;
        bram3_port0_en : out std_logic;

        bram0_port1_en : out std_logic;
        bram1_port1_en : out std_logic;
        bram2_port1_en : out std_logic;
        bram3_port1_en : out std_logic;

        lane_sel : out std_logic_vector(1 downto 0); -- active BRAM index this cycle (serial mode only)
        done     : out std_logic -- 1-cycle pulse once operation_length samples have been moved
    );
end bmu_addr_gen;

architecture Behavioral of bmu_addr_gen is

    constant ROW_SAMPLES : integer := 4; -- one sample per BRAM block, per row
    constant ROW_SHIFT    : integer := 2; -- log2(ROW_SAMPLES): converts a sample count to a row count

    -- rows advanced per count_en pulse once row_advance is asserted.
    -- Serial mode (LANES=1) advances 1 row every 4th pulse (see row_advance below),
    -- so it shares the "1 row" step with parallel4; only parallel8 differs.
    function calc_row_step(l : integer) return integer is
    begin
        if l = 8 then
            return 2;
        else
            return 1;
        end if;
    end function;

    constant ROW_STEP : integer := calc_row_step(LANES);

    signal ring_start    : unsigned(BUFFER_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal ring_len_rows : unsigned(BUFFER_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal op_length_lat : unsigned(BUFFER_SIZE_BITS-1 downto 0) := (others => '0');

    signal row_cursor   : unsigned(BUFFER_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal samples_done : unsigned(BUFFER_SIZE_BITS-1 downto 0) := (others => '0');
    signal lane_cnt     : unsigned(1 downto 0) := (others => '0');

    signal row_advance : std_logic; -- '1' when this pulse should move row_cursor

begin

    lane_sel <= std_logic_vector(lane_cnt);

    row_advance <= '1' when (LANES /= 1) else
                   '1' when (lane_cnt = "11") else
                   '0';

    process(clk)
        variable next_port1_row : unsigned(BUFFER_ADDR_WIDTH-1 downto 0);
    begin
        if rising_edge(clk) then
            done <= '0';

            bram0_port0_en <= '0'; 
            bram1_port0_en <= '0';
            bram2_port0_en <= '0'; 
            bram3_port0_en <= '0';
            bram0_port1_en <= '0'; 
            bram1_port1_en <= '0';
            bram2_port1_en <= '0'; 
            bram3_port1_en <= '0';

            if rst = '1' then
                row_cursor   <= (others => '0');
                samples_done <= (others => '0');
                lane_cnt     <= (others => '0');

            elsif start = '1' then
                ring_start    <= unsigned(buffer_start);
                ring_len_rows <= resize(shift_right(unsigned(buffer_length), ROW_SHIFT), BUFFER_ADDR_WIDTH);
                op_length_lat <= unsigned(operation_length);
                row_cursor    <= unsigned(operation_start);
                samples_done  <= (others => '0');
                lane_cnt      <= (others => '0');

            elsif count_en = '1' then
                -- port0 address: same row for all 4 BRAM blocks (row-major layout)
                bram0_port0_addr <= std_logic_vector(row_cursor);
                bram1_port0_addr <= std_logic_vector(row_cursor);
                bram2_port0_addr <= std_logic_vector(row_cursor);
                bram3_port0_addr <= std_logic_vector(row_cursor);

                if LANES = 1 then
                    -- serial: exactly one BRAM enabled this cycle, picked by lane_cnt
                    case lane_cnt is
                        when "00"   => bram0_port0_en <= '1';
                        when "01"   => bram1_port0_en <= '1';
                        when "10"   => bram2_port0_en <= '1';
                        when others => bram3_port0_en <= '1';
                    end case;
                    lane_cnt <= lane_cnt + 1;
                else
                    bram0_port0_en <= '1'; bram1_port0_en <= '1';
                    bram2_port0_en <= '1'; bram3_port0_en <= '1';

                    if LANES = 8 then
                        -- second row (port1) is always "current row + 1", wrapped
                        next_port1_row := ring_start + ((row_cursor - ring_start + 1) mod ring_len_rows);
                        bram0_port1_addr <= std_logic_vector(next_port1_row);
                        bram1_port1_addr <= std_logic_vector(next_port1_row);
                        bram2_port1_addr <= std_logic_vector(next_port1_row);
                        bram3_port1_addr <= std_logic_vector(next_port1_row);
                        bram0_port1_en <= '1'; bram1_port1_en <= '1';
                        bram2_port1_en <= '1'; bram3_port1_en <= '1';
                    end if;
                end if;

                if row_advance = '1' then
                    row_cursor <= ring_start + ((row_cursor - ring_start + ROW_STEP) mod ring_len_rows);
                end if;

                samples_done <= samples_done + LANES;
                if samples_done + LANES = op_length_lat then
                    done <= '1';
                end if;
            end if;
        end if;
    end process;

end Behavioral;
