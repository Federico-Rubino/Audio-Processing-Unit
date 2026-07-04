library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bmu_write is  -- buffer management unit: output buffer
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

        data_in_0 : in std_logic_vector(31 downto 0);
        data_in_1 : in std_logic_vector(31 downto 0);
        data_in_2 : in std_logic_vector(31 downto 0);
        data_in_3 : in std_logic_vector(31 downto 0);
        data_in_4 : in std_logic_vector(31 downto 0);
        data_in_5 : in std_logic_vector(31 downto 0);
        data_in_6 : in std_logic_vector(31 downto 0);
        data_in_7 : in std_logic_vector(31 downto 0);

        done : out std_logic
    );
end bmu_write;

architecture Behavioral of bmu_write is

    signal lane_sel : std_logic_vector(1 downto 0);

    -- intermediate copies of the port0/port1 enables from bmu_addr_gen:
    -- needed because 'we' is derived from 'en', and VHDL-93/2002 doesn't
    -- allow reading back the entity's own 'out' ports.
    signal en0_p0, en1_p0, en2_p0, en3_p0 : std_logic;
    signal en0_p1, en1_p1, en2_p1, en3_p1 : std_logic;

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

            bram0_port0_en => en0_p0, bram1_port0_en => en1_p0,
            bram2_port0_en => en2_p0, bram3_port0_en => en3_p0,
            bram0_port1_en => en0_p1, bram1_port1_en => en1_p1,
            bram2_port1_en => en2_p1, bram3_port1_en => en3_p1,

            lane_sel => lane_sel,
            done     => done
        );

    -- a write BMU only ever asserts 'en' on a lane it intends to write
    -- this cycle, so 'we' can just follow 'en' directly
    bram0_port0_en <= en0_p0; bram0_port0_we <= en0_p0;
    bram1_port0_en <= en1_p0; bram1_port0_we <= en1_p0;
    bram2_port0_en <= en2_p0; bram2_port0_we <= en2_p0;
    bram3_port0_en <= en3_p0; bram3_port0_we <= en3_p0;

    bram0_port1_en <= en0_p1; bram0_port1_we <= en0_p1;
    bram1_port1_en <= en1_p1; bram1_port1_we <= en1_p1;
    bram2_port1_en <= en2_p1; bram2_port1_we <= en2_p1;
    bram3_port1_en <= en3_p1; bram3_port1_we <= en3_p1;

    parallel_in : if LANES /= 1 generate
        bram0_port0_data_in <= data_in_0;
        bram1_port0_data_in <= data_in_1;
        bram2_port0_data_in <= data_in_2;
        bram3_port0_data_in <= data_in_3;
        bram0_port1_data_in <= data_in_4;
        bram1_port1_data_in <= data_in_5;
        bram2_port1_data_in <= data_in_6;
        bram3_port1_data_in <= data_in_7;
    end generate;

    serial_in : if LANES = 1 generate
        -- only the lane selected by en*_p0 actually gets written; the others
        -- see the same data but with 'we'/'en' low, so it's harmless to
        -- broadcast data_in_0 to all four
        bram0_port0_data_in <= data_in_0;
        bram1_port0_data_in <= data_in_0;
        bram2_port0_data_in <= data_in_0;
        bram3_port0_data_in <= data_in_0;
        bram0_port1_data_in <= (others => '0');
        bram1_port1_data_in <= (others => '0');
        bram2_port1_data_in <= (others => '0');
        bram3_port1_data_in <= (others => '0');
    end generate;

end Behavioral;
