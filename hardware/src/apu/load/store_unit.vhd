library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity store_unit is
    generic (
        BUFFER_ADDR_WIDTH : integer := 15,
        BUFFER_SIZE_BITS : integer := 17    -- TODO check generic values
    );
    Port (
        clk, rst : in std_logic;

        -- CU control
        enable           : in  std_logic;
        buffer_start     : in  std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        buffer_length    : in  std_logic_vector(BUFFER_SIZE_BITS-1 downto 0);
        operation_start  : in  std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        operation_length : in  std_logic_vector(BUFFER_SIZE_BITS-1 downto 0);
        data             : in  std_logic_vector(31 downto 0);
        finished         : out std_logic;

        -- a-ram side (bmu_write's full flat interface)
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
        bram3_port1_data_out : in std_logic_vector(31 downto 0)
    );
end store_unit;

architecture Behavioral of store_unit is
    signal last_enable : std_logic;
    signal done_sig    : std_logic;
    signal start_sig   : std_logic;
begin

    process(clk)
    begin
        if rst = '0' then
            last_enable <= '0';
        elsif rising_edge(clk) then
            last_enable <= enable;
        end if;
    end process;

    -- pulses for 1 cycle when 'enable' transitions from 0 to 1
    start_sig <= '1' when (enable = '1' and last_enable = '0') else '0';

    finished <= done_sig;

    bw : entity work.bmu_write
        generic map (
            BUFFER_ADDR_WIDTH => BUFFER_ADDR_WIDTH,
            BUFFER_SIZE_BITS  => BUFFER_SIZE_BITS,
            LANES             => 1
        )
        port map (
            clk => clk, 
            rst => rst, 
            
            start    => start_sig,
            count_en => enable and (not done_sig),  -- only count/write when enabled, but stop if we are done
            done     => done_sig,

            buffer_start     => buffer_start,
            buffer_length    => buffer_length,
            operation_start  => operation_start,
            operation_length => operation_length,

            bram0_port0_addr => bram0_port0_addr, bram1_port0_addr => bram1_port0_addr,
            bram2_port0_addr => bram2_port0_addr, bram3_port0_addr => bram3_port0_addr,
            bram0_port1_addr => bram0_port1_addr, bram1_port1_addr => bram1_port1_addr,
            bram2_port1_addr => bram2_port1_addr, bram3_port1_addr => bram3_port1_addr,

            bram0_port0_we => bram0_port0_we, bram1_port0_we => bram1_port0_we,
            bram2_port0_we => bram2_port0_we, bram3_port0_we => bram3_port0_we,
            bram0_port1_we => bram0_port1_we, bram1_port1_we => bram1_port1_we,
            bram2_port1_we => bram2_port1_we, bram3_port1_we => bram3_port1_we,

            bram0_port0_en => bram0_port0_en, bram1_port0_en => bram1_port0_en,
            bram2_port0_en => bram2_port0_en, bram3_port0_en => bram3_port0_en,
            bram0_port1_en => bram0_port1_en, bram1_port1_en => bram1_port1_en,
            bram2_port1_en => bram2_port1_en, bram3_port1_en => bram3_port1_en,

            bram0_port0_data_in => bram0_port0_data_in, bram1_port0_data_in => bram1_port0_data_in,
            bram2_port0_data_in => bram2_port0_data_in, bram3_port0_data_in => bram3_port0_data_in,
            bram0_port1_data_in => bram0_port1_data_in, bram1_port1_data_in => bram1_port1_data_in,
            bram2_port1_data_in => bram2_port1_data_in, bram3_port1_data_in => bram3_port1_data_in,

            bram0_port0_data_out => bram0_port0_data_out, bram1_port0_data_out => bram1_port0_data_out,
            bram2_port0_data_out => bram2_port0_data_out, bram3_port0_data_out => bram3_port0_data_out,
            bram0_port1_data_out => bram0_port1_data_out, bram1_port1_data_out => bram1_port1_data_out,
            bram2_port1_data_out => bram2_port1_data_out, bram3_port1_data_out => bram3_port1_data_out,

            -- Incoming streaming data
            data_in_0 => data, 
            data_in_1 => (others => '0'),
            data_in_2 => (others => '0'), 
            data_in_3 => (others => '0'),
            data_in_4 => (others => '0'), 
            data_in_5 => (others => '0'),
            data_in_6 => (others => '0'), 
            data_in_7 => (others => '0')
        );

end Behavioral;
