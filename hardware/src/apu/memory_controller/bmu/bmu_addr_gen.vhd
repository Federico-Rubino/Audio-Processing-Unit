library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- addr sequencer: row cursor + ring wraparound. shared read/write. no data path.
entity bmu_addr_gen is
    generic (
        BUFFER_ADDR_WIDTH : integer := 10; -- row-address width, shared by all 4 BRAM blocks
        BUFFER_SIZE_BITS  : integer := 18; -- width of sample-count fields
        LANES             : integer := 4  -- samples moved per count_en pulse: 1 (serial), 4 (parallel4), 8 (parallel8)
    );
    Port (
        clk, rst : in std_logic; -- synchronous, active low
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

    constant ROW_SAMPLES : integer := 4; 
    constant ROW_SHIFT    : integer := 2; 

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
    signal ring_len_rows : unsigned(BUFFER_ADDR_WIDTH downto 0) := (others => '0'); 
    -- Pre-calculated physical boundary of the ring (start + len) to make comparison fast
    signal ring_end      : unsigned(BUFFER_ADDR_WIDTH downto 0) := (others => '0'); 
    
    signal op_length_lat : unsigned(BUFFER_SIZE_BITS-1 downto 0) := (others => '0');

    signal row_cursor   : unsigned(BUFFER_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal samples_done : unsigned(BUFFER_SIZE_BITS-1 downto 0) := (others => '0');
    signal lane_cnt     : unsigned(1 downto 0) := (others => '0');

    signal row_advance : std_logic; 

begin

    lane_sel <= std_logic_vector(lane_cnt);

    row_advance <= '1' when (LANES /= 1) else
                   '1' when (lane_cnt = "11") else
                   '0';

    process(clk)
        variable next_port1_row : unsigned(BUFFER_ADDR_WIDTH-1 downto 0);
        
        -- High-speed temporary variables for single-cycle comparisons
        variable temp_port1_row : unsigned(BUFFER_ADDR_WIDTH downto 0);
        variable temp_row_step  : unsigned(BUFFER_ADDR_WIDTH downto 0);
        
        -- Calculated during 'start'
        variable temp_ring_len  : unsigned(BUFFER_ADDR_WIDTH downto 0);
        variable temp_ring_start : unsigned(BUFFER_ADDR_WIDTH-1 downto 0);
    begin
        if rising_edge(clk) then
            done <= '0';

            bram0_port0_en <= '0'; bram1_port0_en <= '0';
            bram2_port0_en <= '0'; bram3_port0_en <= '0';
            bram0_port1_en <= '0'; bram1_port1_en <= '0';
            bram2_port1_en <= '0'; bram3_port1_en <= '0';

            if rst = '0' then
                row_cursor   <= (others => '0');
                samples_done <= (others => '0');
                lane_cnt     <= (others => '0');
                ring_end     <= (others => '0');

            elsif start = '1' then
                temp_ring_start := unsigned(buffer_start);
                temp_ring_len   := resize(shift_right(unsigned(buffer_length), ROW_SHIFT), BUFFER_ADDR_WIDTH+1);
                
                ring_start    <= temp_ring_start;
                ring_len_rows <= temp_ring_len;
                -- Pre-calculate the physical end of the buffer (takes 1 cycle, during 'start' routine)
                ring_end      <= resize(temp_ring_start, BUFFER_ADDR_WIDTH+1) + temp_ring_len;
                
                op_length_lat <= unsigned(operation_length);
                row_cursor    <= unsigned(operation_start);
                samples_done  <= (others => '0');
                lane_cnt      <= (others => '0');

            elsif count_en = '1' then
                -- port0 address: same row for all 4 BRAM blocks
                bram0_port0_addr <= std_logic_vector(row_cursor);
                bram1_port0_addr <= std_logic_vector(row_cursor);
                bram2_port0_addr <= std_logic_vector(row_cursor);
                bram3_port0_addr <= std_logic_vector(row_cursor);

                if LANES = 1 then
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
                        temp_port1_row := resize(row_cursor, BUFFER_ADDR_WIDTH+1) + 1;
                        
                        if temp_port1_row >= ring_end then
                            next_port1_row := resize(temp_port1_row - ring_len_rows, BUFFER_ADDR_WIDTH);
                        else
                            next_port1_row := resize(temp_port1_row, BUFFER_ADDR_WIDTH);
                        end if;
                        
                        bram0_port1_addr <= std_logic_vector(next_port1_row);
                        bram1_port1_addr <= std_logic_vector(next_port1_row);
                        bram2_port1_addr <= std_logic_vector(next_port1_row);
                        bram3_port1_addr <= std_logic_vector(next_port1_row);
                        bram0_port1_en <= '1'; bram1_port1_en <= '1';
                        bram2_port1_en <= '1'; bram3_port1_en <= '1';
                    end if;
                end if;

                if row_advance = '1' then
                    temp_row_step := resize(row_cursor, BUFFER_ADDR_WIDTH+1) + ROW_STEP;
                    
                    if temp_row_step >= ring_end then
                        row_cursor <= resize(temp_row_step - ring_len_rows, BUFFER_ADDR_WIDTH);
                    else
                        row_cursor <= resize(temp_row_step, BUFFER_ADDR_WIDTH);
                    end if;
                end if;

                samples_done <= samples_done + LANES;
                if samples_done + LANES = op_length_lat then
                    done <= '1';
                end if;
            end if;
        end if;
    end process;

end Behavioral;