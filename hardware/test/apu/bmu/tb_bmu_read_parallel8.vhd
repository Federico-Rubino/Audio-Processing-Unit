library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Waveform-focused testbench for bmu_read in parallel8 mode.
-- Drives a small (4-bit row address, 16 rows) ring so the wraparound is
-- visible within a handful of cycles, and backs the 4 BRAM ports with a
-- fake memory that stores the sample sequence 1, 2, 3, 4, ... in row-major
-- order (BRAM k, row r -> r*4 + k + 1), so data_out_0..7 should read off as
-- consecutive ascending numbers every pulse -- easy to eyeball, and any
-- gap/repeat/reorder is immediately visible as a break in the sequence.
entity tb_bmu_read_parallel8 is
end tb_bmu_read_parallel8;

architecture sim of tb_bmu_read_parallel8 is

    constant ADDR_W      : integer := 4;  -- 16 rows, small enough to read by eye
    constant SIZE_W       : integer := 8;  -- up to 255 samples
    constant CLK_PERIOD  : time := 10 ns;

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal start    : std_logic := '0';
    signal count_en : std_logic := '0';

    signal buffer_start     : std_logic_vector(ADDR_W-1 downto 0) := (others => '0');
    signal buffer_length    : std_logic_vector(SIZE_W-1 downto 0) := (others => '0');
    signal operation_start  : std_logic_vector(ADDR_W-1 downto 0) := (others => '0');
    signal operation_length : std_logic_vector(SIZE_W-1 downto 0) := (others => '0');

    signal bram0_port0_addr, bram1_port0_addr, bram2_port0_addr, bram3_port0_addr : std_logic_vector(ADDR_W-1 downto 0);
    signal bram0_port1_addr, bram1_port1_addr, bram2_port1_addr, bram3_port1_addr : std_logic_vector(ADDR_W-1 downto 0);

    signal bram0_port0_we, bram1_port0_we, bram2_port0_we, bram3_port0_we : std_logic;
    signal bram0_port1_we, bram1_port1_we, bram2_port1_we, bram3_port1_we : std_logic;

    signal bram0_port0_en, bram1_port0_en, bram2_port0_en, bram3_port0_en : std_logic;
    signal bram0_port1_en, bram1_port1_en, bram2_port1_en, bram3_port1_en : std_logic;

    signal bram0_port0_data_in, bram1_port0_data_in, bram2_port0_data_in, bram3_port0_data_in : std_logic_vector(31 downto 0);
    signal bram0_port1_data_in, bram1_port1_data_in, bram2_port1_data_in, bram3_port1_data_in : std_logic_vector(31 downto 0);

    signal bram0_port0_data_out, bram1_port0_data_out, bram2_port0_data_out, bram3_port0_data_out : std_logic_vector(31 downto 0) := (others => '0');
    signal bram0_port1_data_out, bram1_port1_data_out, bram2_port1_data_out, bram3_port1_data_out : std_logic_vector(31 downto 0) := (others => '0');

    signal data_out_0, data_out_1, data_out_2, data_out_3 : std_logic_vector(31 downto 0);
    signal data_out_4, data_out_5, data_out_6, data_out_7 : std_logic_vector(31 downto 0);

    signal done : std_logic;

    -- sample index (row-major: row r, lane k -> r*4 + k), 1-indexed so the
    -- very first sample read is 1, not 0
    function mem_value(bram_idx : integer; addr : std_logic_vector) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(to_integer(unsigned(addr)) * 4 + bram_idx + 1, 32));
    end function;

begin

    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.bmu_read
        generic map (
            BUFFER_ADDR_WIDTH => ADDR_W,
            BUFFER_SIZE_BITS  => SIZE_W,
            LANES             => 8
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

            data_out_0 => data_out_0, data_out_1 => data_out_1,
            data_out_2 => data_out_2, data_out_3 => data_out_3,
            data_out_4 => data_out_4, data_out_5 => data_out_5,
            data_out_6 => data_out_6, data_out_7 => data_out_7,

            done => done
        );

    -- fake dual-port memories: registered read (1-cycle latency, like a real
    -- BRAM), content = the ascending sample sequence via mem_value(), no
    -- actual storage array
    mem0 : process(clk)
    begin
        if rising_edge(clk) then
            if bram0_port0_en = '1' then
                bram0_port0_data_out <= mem_value(0, bram0_port0_addr);
            end if;
            if bram0_port1_en = '1' then
                bram0_port1_data_out <= mem_value(0, bram0_port1_addr);
            end if;
        end if;
    end process;

    mem1 : process(clk)
    begin
        if rising_edge(clk) then
            if bram1_port0_en = '1' then
                bram1_port0_data_out <= mem_value(1, bram1_port0_addr);
            end if;
            if bram1_port1_en = '1' then
                bram1_port1_data_out <= mem_value(1, bram1_port1_addr);
            end if;
        end if;
    end process;

    mem2 : process(clk)
    begin
        if rising_edge(clk) then
            if bram2_port0_en = '1' then
                bram2_port0_data_out <= mem_value(2, bram2_port0_addr);
            end if;
            if bram2_port1_en = '1' then
                bram2_port1_data_out <= mem_value(2, bram2_port1_addr);
            end if;
        end if;
    end process;

    mem3 : process(clk)
    begin
        if rising_edge(clk) then
            if bram3_port0_en = '1' then
                bram3_port0_data_out <= mem_value(3, bram3_port0_addr);
            end if;
            if bram3_port1_en = '1' then
                bram3_port1_data_out <= mem_value(3, bram3_port1_addr);
            end if;
        end if;
    end process;

    -- sanity check: a read BMU must never assert a write-enable
    check_we : process(clk)
    begin
        if rising_edge(clk) then
            assert (bram0_port0_we = '0' and bram1_port0_we = '0' and bram2_port0_we = '0' and bram3_port0_we = '0' and
                    bram0_port1_we = '0' and bram1_port1_we = '0' and bram2_port1_we = '0' and bram3_port1_we = '0')
                report "bmu_read must never assert a write-enable" severity error;
        end if;
    end process;

    stim : process
    begin
        rst      <= '1';
        start    <= '0';
        count_en <= '0';
        wait for CLK_PERIOD * 2;

        rst <= '0';
        wait for CLK_PERIOD;

        -- ring: 8 rows (32 samples) starting at row 0
        buffer_start  <= std_logic_vector(to_unsigned(0, ADDR_W));
        buffer_length <= std_logic_vector(to_unsigned(32, SIZE_W));

        -- operation starts mid-ring at row 4 and covers the full 32 samples
        -- (4 parallel8 pulses / 8 rows), so it wraps back around the ring
        -- partway through -- the interesting case to watch in the waveform
        operation_start  <= std_logic_vector(to_unsigned(4, ADDR_W));
        operation_length <= std_logic_vector(to_unsigned(32, SIZE_W));

        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';

        count_en <= '1';
        wait for CLK_PERIOD * 6;
        count_en <= '0';

        wait for CLK_PERIOD * 4;

        report "simulation finished";
        wait;
    end process;

end sim;
