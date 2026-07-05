library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bmu_read is  -- buffer management unit: input buffer
    generic (
        BUFFER_ADDR_WIDTH : integer := 10; -- width of the address bus for the BRAM blocks
        BUFFER_SIZE_BITS  : integer := 18; -- width of the size bus for the buffers
        LANES             : integer := 4   -- samples moved per count_en pulse: 1 (serial), 4 (parallel4), 8 (parallel8)
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

        bram0_port0_we : out std_logic;
        bram1_port0_we : out std_logic;
        bram2_port0_we : out std_logic;
        bram3_port0_we : out std_logic;

        bram0_port1_we : out std_logic;
        bram1_port1_we : out std_logic;
        bram2_port1_we : out std_logic;
        bram3_port1_we : out std_logic;

        bram0_port0_en : out std_logic;
        bram1_port0_en : out std_logic;
        bram2_port0_en : out std_logic;
        bram3_port0_en : out std_logic;

        bram0_port1_en : out std_logic;
        bram1_port1_en : out std_logic;
        bram2_port1_en : out std_logic;
        bram3_port1_en : out std_logic;

        bram0_port0_data_in : out std_logic_vector(31 downto 0);
        bram1_port0_data_in : out std_logic_vector(31 downto 0);
        bram2_port0_data_in : out std_logic_vector(31 downto 0);
        bram3_port0_data_in : out std_logic_vector(31 downto 0);

        bram0_port1_data_in : out std_logic_vector(31 downto 0);
        bram1_port1_data_in : out std_logic_vector(31 downto 0);
        bram2_port1_data_in : out std_logic_vector(31 downto 0);
        bram3_port1_data_in : out std_logic_vector(31 downto 0);

        bram0_port0_data_out : in std_logic_vector(31 downto 0);
        bram1_port0_data_out : in std_logic_vector(31 downto 0);
        bram2_port0_data_out : in std_logic_vector(31 downto 0);
        bram3_port0_data_out : in std_logic_vector(31 downto 0);

        bram0_port1_data_out : in std_logic_vector(31 downto 0);
        bram1_port1_data_out : in std_logic_vector(31 downto 0);
        bram2_port1_data_out : in std_logic_vector(31 downto 0);
        bram3_port1_data_out : in std_logic_vector(31 downto 0);

        data_out_0 : out std_logic_vector(31 downto 0);
        data_out_1 : out std_logic_vector(31 downto 0);
        data_out_2 : out std_logic_vector(31 downto 0);
        data_out_3 : out std_logic_vector(31 downto 0);
        data_out_4 : out std_logic_vector(31 downto 0);
        data_out_5 : out std_logic_vector(31 downto 0);
        data_out_6 : out std_logic_vector(31 downto 0);
        data_out_7 : out std_logic_vector(31 downto 0);

        done : out std_logic
    );
end bmu_read;

architecture Behavioral of bmu_read is

    signal lane_sel   : std_logic_vector(1 downto 0);
    signal lane_sel_d : std_logic_vector(1 downto 0) := (others => '0'); -- data_out lags addr/en by 1 cycle (sync BRAM read latency)

begin

    addr_gen : entity work.bmu_addr_gen
        generic map (
            BUFFER_ADDR_WIDTH => BUFFER_ADDR_WIDTH,
            BUFFER_SIZE_BITS  => BUFFER_SIZE_BITS,
            LANES             => LANES
        )
        port map (
            clk => clk, rst => rst, start => start, count_en => count_en,

            buffer_start     => buffer_start,
            buffer_length    => buffer_length,
            operation_start  => operation_start,
            operation_length => operation_length,

            bram0_port0_addr => bram0_port0_addr, bram1_port0_addr => bram1_port0_addr,
            bram2_port0_addr => bram2_port0_addr, bram3_port0_addr => bram3_port0_addr,
            bram0_port1_addr => bram0_port1_addr, bram1_port1_addr => bram1_port1_addr,
            bram2_port1_addr => bram2_port1_addr, bram3_port1_addr => bram3_port1_addr,

            bram0_port0_en => bram0_port0_en, bram1_port0_en => bram1_port0_en,
            bram2_port0_en => bram2_port0_en, bram3_port0_en => bram3_port0_en,
            bram0_port1_en => bram0_port1_en, bram1_port1_en => bram1_port1_en,
            bram2_port1_en => bram2_port1_en, bram3_port1_en => bram3_port1_en,

            lane_sel => lane_sel,
            done     => done
        );

    -- read-only: never writes
    bram0_port0_we <= '0'; bram1_port0_we <= '0'; bram2_port0_we <= '0'; bram3_port0_we <= '0';
    bram0_port1_we <= '0'; bram1_port1_we <= '0'; bram2_port1_we <= '0'; bram3_port1_we <= '0';

    bram0_port0_data_in <= (others => '0'); bram1_port0_data_in <= (others => '0');
    bram2_port0_data_in <= (others => '0'); bram3_port0_data_in <= (others => '0');
    bram0_port1_data_in <= (others => '0'); bram1_port1_data_in <= (others => '0');
    bram2_port1_data_in <= (others => '0'); bram3_port1_data_in <= (others => '0');

    process(clk)
    begin
        if rising_edge(clk) then
            lane_sel_d <= lane_sel;
        end if;
    end process;

    parallel_out : if LANES /= 1 generate
        data_out_0 <= bram0_port0_data_out;
        data_out_1 <= bram1_port0_data_out;
        data_out_2 <= bram2_port0_data_out;
        data_out_3 <= bram3_port0_data_out;
        data_out_4 <= bram0_port1_data_out;
        data_out_5 <= bram1_port1_data_out;
        data_out_6 <= bram2_port1_data_out;
        data_out_7 <= bram3_port1_data_out;
    end generate;

    serial_out : if LANES = 1 generate
        -- lane_sel_d: which BRAM's data_out is valid now
        data_out_0 <= bram0_port0_data_out when lane_sel_d = "00" else
                      bram1_port0_data_out when lane_sel_d = "01" else
                      bram2_port0_data_out when lane_sel_d = "10" else
                      bram3_port0_data_out;
        data_out_1 <= (others => '0');
        data_out_2 <= (others => '0');
        data_out_3 <= (others => '0');
        data_out_4 <= (others => '0');
        data_out_5 <= (others => '0');
        data_out_6 <= (others => '0');
        data_out_7 <= (others => '0');
    end generate;

end Behavioral;
