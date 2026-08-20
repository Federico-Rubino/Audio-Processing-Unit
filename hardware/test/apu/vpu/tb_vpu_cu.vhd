library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.apu_internal_pkg.all;
use work.vpu_internal_pkg.all;

entity tb_vpu_cu is
end tb_vpu_cu;

architecture sim of tb_vpu_cu is

    constant CLK_PERIOD : time := 10 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    signal en   : std_logic := '0';
    signal done : std_logic;
    signal vec_op : vec_op_t := VEC_OP_ADDV;

    signal bmu_read_1_start, bmu_read_2_start, bmu_write_start : std_logic;
    signal bmu_read_1_done, bmu_read_2_done, bmu_write_done : std_logic := '0';

    signal count_en : std_logic;
    signal exec1_en : std_logic := '0';

    signal dsp_op_sel : dsp_op_sel_array_t;
    signal sel_scal_in, sel_output_even, sel_output_odd : std_logic;

    signal count_en_pulses : integer := 0;

begin

    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.vpuCU
        port map (
            clk => clk, rst => rst,
            en => en, done => done,
            vec_op => vec_op,
            bmu_read_1_start => bmu_read_1_start,
            bmu_read_2_start => bmu_read_2_start,
            bmu_write_start  => bmu_write_start,
            bmu_read_1_done => bmu_read_1_done,
            bmu_read_2_done => bmu_read_2_done,
            bmu_write_done  => bmu_write_done,
            count_en => count_en,
            exec1_en => exec1_en,
            dsp_op_sel => dsp_op_sel,
            sel_scal_in => sel_scal_in,
            sel_output_even => sel_output_even,
            sel_output_odd => sel_output_odd
        );

    process(clk)
    begin
        if rising_edge(clk) and count_en = '1' then
            count_en_pulses <= count_en_pulses + 1;
        end if;
    end process;

    stim : process
    begin
        rst <= '0';
        wait for CLK_PERIOD * 2;
        rst <= '1';
        wait for CLK_PERIOD;

        en <= '1';
        wait for CLK_PERIOD;
        en <= '0';

        wait for CLK_PERIOD;
        assert bmu_read_1_start = '1' and bmu_read_2_start = '1' and bmu_write_start = '1'
            report "starts not asserted in SETUP" severity error;

        wait for CLK_PERIOD;
        assert count_en_pulses = 1 report "first count_en missing" severity error;

        -- two more read/execute loops, no done yet
        exec1_en <= '1';
        wait for CLK_PERIOD;
        exec1_en <= '0';
        wait for CLK_PERIOD * 2;
        assert count_en_pulses = 2 report "second count_en missing" severity error;

        exec1_en <= '1';
        wait for CLK_PERIOD;
        exec1_en <= '0';
        wait for CLK_PERIOD * 2;
        assert count_en_pulses = 3 report "third count_en missing" severity error;

        -- bmu_read_1_done pulses without waiting for exec1_en
        bmu_read_1_done <= '1';
        wait for CLK_PERIOD;
        bmu_read_1_done <= '0';
        wait for CLK_PERIOD;
        assert count_en_pulses = 3 report "count_en pulsed again after done" severity error;

        bmu_write_done <= '1';
        wait for CLK_PERIOD;
        bmu_write_done <= '0';
        wait for CLK_PERIOD;
        assert done = '1' report "done never pulsed" severity error;

        wait for CLK_PERIOD * 2;
        report "simulation finished";
        wait;
    end process;

end sim;
