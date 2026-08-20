library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- end-to-end test for the new grain-based AudioIO. audio_top isn't
-- instantiated -- new_sample/line_in_l/r are driven directly instead,
-- skipping real I2S timing. Also fakes the shared a-ram (4 dual-port
-- memories + a small inline arbiter standing in for the real top-level
-- APU arbiter) and the CU (enable audio_in_unit, wait, enable
-- audio_out_unit, wait).
--
-- line_in_l/r count up 0..255, so a correct round trip shows sample_out_l
-- counting 0..255 too. Each a-ram cell packs 2 samples, so a 256-sample
-- grain is 128 cells; buffer_length below is in cells, not samples.
entity tb_audioIO_grain is
end tb_audioIO_grain;

architecture sim of tb_audioIO_grain is

    constant ADDR_W     : integer := 6; -- 64 rows, plenty for one 128-cell grain (16 bmu rows)
    constant SIZE_W     : integer := 9;
    constant CLK_PERIOD : time := 10 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    -- fake ADAU
    signal new_sample : std_logic := '0';
    signal line_in_l, line_in_r : std_logic_vector(15 downto 0) := (others => '0');
    signal sample_out_l, sample_out_r : std_logic_vector(15 downto 0);

    -- audio_in <-> audio_in_unit. rows are 16 samples (2 samples/a-ram cell)
    signal grain_ready_l, grain_ready_r : std_logic;
    signal grain_ack_l, grain_ack_r : std_logic;
    signal row_addr_in_l, row_addr_in_r : std_logic_vector(3 downto 0);
    signal row_data_in_l_0,  row_data_in_l_1,  row_data_in_l_2,  row_data_in_l_3  : std_logic_vector(15 downto 0);
    signal row_data_in_l_4,  row_data_in_l_5,  row_data_in_l_6,  row_data_in_l_7  : std_logic_vector(15 downto 0);
    signal row_data_in_l_8,  row_data_in_l_9,  row_data_in_l_10, row_data_in_l_11 : std_logic_vector(15 downto 0);
    signal row_data_in_l_12, row_data_in_l_13, row_data_in_l_14, row_data_in_l_15 : std_logic_vector(15 downto 0);
    signal row_data_in_r_0,  row_data_in_r_1,  row_data_in_r_2,  row_data_in_r_3  : std_logic_vector(15 downto 0);
    signal row_data_in_r_4,  row_data_in_r_5,  row_data_in_r_6,  row_data_in_r_7  : std_logic_vector(15 downto 0);
    signal row_data_in_r_8,  row_data_in_r_9,  row_data_in_r_10, row_data_in_r_11 : std_logic_vector(15 downto 0);
    signal row_data_in_r_12, row_data_in_r_13, row_data_in_r_14, row_data_in_r_15 : std_logic_vector(15 downto 0);

    -- audio_out <-> audio_out_unit. rows are 16 samples (2 samples/a-ram cell)
    signal need_grain_l, need_grain_r : std_logic;
    signal fill_ack_l, fill_ack_r : std_logic;
    signal row_addr_out_l, row_addr_out_r : std_logic_vector(3 downto 0);
    signal row_we_out_l, row_we_out_r : std_logic;
    signal back_write_done_l, back_write_done_r : std_logic;
    signal row_data_out_l_0,  row_data_out_l_1,  row_data_out_l_2,  row_data_out_l_3  : std_logic_vector(15 downto 0);
    signal row_data_out_l_4,  row_data_out_l_5,  row_data_out_l_6,  row_data_out_l_7  : std_logic_vector(15 downto 0);
    signal row_data_out_l_8,  row_data_out_l_9,  row_data_out_l_10, row_data_out_l_11 : std_logic_vector(15 downto 0);
    signal row_data_out_l_12, row_data_out_l_13, row_data_out_l_14, row_data_out_l_15 : std_logic_vector(15 downto 0);
    signal row_data_out_r_0,  row_data_out_r_1,  row_data_out_r_2,  row_data_out_r_3  : std_logic_vector(15 downto 0);
    signal row_data_out_r_4,  row_data_out_r_5,  row_data_out_r_6,  row_data_out_r_7  : std_logic_vector(15 downto 0);
    signal row_data_out_r_8,  row_data_out_r_9,  row_data_out_r_10, row_data_out_r_11 : std_logic_vector(15 downto 0);
    signal row_data_out_r_12, row_data_out_r_13, row_data_out_r_14, row_data_out_r_15 : std_logic_vector(15 downto 0);

    -- fake CU
    signal audio_in_enable, audio_in_left_right : std_logic := '0';
    signal audio_in_buffer_start, audio_in_operation_start : std_logic_vector(ADDR_W-1 downto 0) := (others => '0');
    signal audio_in_buffer_length : std_logic_vector(SIZE_W-1 downto 0) := (others => '0');
    signal audio_in_finished : std_logic;

    signal audio_out_enable, audio_out_left_right : std_logic := '0';
    signal audio_out_buffer_start, audio_out_operation_start : std_logic_vector(ADDR_W-1 downto 0) := (others => '0');
    signal audio_out_buffer_length : std_logic_vector(SIZE_W-1 downto 0) := (others => '0');
    signal audio_out_finished : std_logic;

    -- audio_in_unit's raw a-ram ports
    signal ain_addr0, ain_addr1, ain_addr2, ain_addr3 : std_logic_vector(ADDR_W-1 downto 0);
    signal ain_addr0_p1, ain_addr1_p1, ain_addr2_p1, ain_addr3_p1 : std_logic_vector(ADDR_W-1 downto 0);
    signal ain_we0, ain_we1, ain_we2, ain_we3 : std_logic;
    signal ain_we0_p1, ain_we1_p1, ain_we2_p1, ain_we3_p1 : std_logic;
    signal ain_en0, ain_en1, ain_en2, ain_en3 : std_logic;
    signal ain_en0_p1, ain_en1_p1, ain_en2_p1, ain_en3_p1 : std_logic;
    signal ain_din0, ain_din1, ain_din2, ain_din3 : std_logic_vector(31 downto 0);
    signal ain_din0_p1, ain_din1_p1, ain_din2_p1, ain_din3_p1 : std_logic_vector(31 downto 0);
    signal ain_dout0, ain_dout1, ain_dout2, ain_dout3 : std_logic_vector(31 downto 0);
    signal ain_dout0_p1, ain_dout1_p1, ain_dout2_p1, ain_dout3_p1 : std_logic_vector(31 downto 0);

    -- audio_out_unit's raw a-ram ports
    signal aout_addr0, aout_addr1, aout_addr2, aout_addr3 : std_logic_vector(ADDR_W-1 downto 0);
    signal aout_addr0_p1, aout_addr1_p1, aout_addr2_p1, aout_addr3_p1 : std_logic_vector(ADDR_W-1 downto 0);
    signal aout_we0, aout_we1, aout_we2, aout_we3 : std_logic;
    signal aout_we0_p1, aout_we1_p1, aout_we2_p1, aout_we3_p1 : std_logic;
    signal aout_en0, aout_en1, aout_en2, aout_en3 : std_logic;
    signal aout_en0_p1, aout_en1_p1, aout_en2_p1, aout_en3_p1 : std_logic;
    signal aout_din0, aout_din1, aout_din2, aout_din3 : std_logic_vector(31 downto 0);
    signal aout_din0_p1, aout_din1_p1, aout_din2_p1, aout_din3_p1 : std_logic_vector(31 downto 0);
    signal aout_dout0, aout_dout1, aout_dout2, aout_dout3 : std_logic_vector(31 downto 0);
    signal aout_dout0_p1, aout_dout1_p1, aout_dout2_p1, aout_dout3_p1 : std_logic_vector(31 downto 0);

    -- fake a-ram: muxed (arbitrated) port signals actually driving the memories
    signal m0_addr0, m1_addr0, m2_addr0, m3_addr0 : std_logic_vector(ADDR_W-1 downto 0);
    signal m0_addr1, m1_addr1, m2_addr1, m3_addr1 : std_logic_vector(ADDR_W-1 downto 0);
    signal m0_en0, m1_en0, m2_en0, m3_en0 : std_logic;
    signal m0_en1, m1_en1, m2_en1, m3_en1 : std_logic;
    signal m0_we0, m1_we0, m2_we0, m3_we0 : std_logic;
    signal m0_we1, m1_we1, m2_we1, m3_we1 : std_logic;
    signal m0_din0, m1_din0, m2_din0, m3_din0 : std_logic_vector(31 downto 0);
    signal m0_din1, m1_din1, m2_din1, m3_din1 : std_logic_vector(31 downto 0);
    signal m0_dout0, m1_dout0, m2_dout0, m3_dout0 : std_logic_vector(31 downto 0);
    signal m0_dout1, m1_dout1, m2_dout1, m3_dout1 : std_logic_vector(31 downto 0);

    type ram_array_t is array (0 to 63) of std_logic_vector(31 downto 0);
    signal m0_array, m1_array, m2_array, m3_array : ram_array_t := (others => (others => '0'));

    signal sample_ctr : unsigned(7 downto 0) := (others => '0');
    signal tick_div    : integer range 0 to 3 := 0;

begin

    clk <= not clk after CLK_PERIOD / 2;

    ------------------------------------------------------------------
    -- DUT: the four inner AudioIO blocks, wired like audioIO.vhd minus
    -- audio_top (replaced by the fake ADAU process below)
    ------------------------------------------------------------------
    audio_in_inst : entity work.audio_in
        port map (
            clk => clk, rst => rst,
            new_sample => new_sample,
            line_in_l => line_in_l, line_in_r => line_in_r,

            grain_ready_l => grain_ready_l, grain_ack_l => grain_ack_l,
            row_addr_l => row_addr_in_l,
            row_data_l_0 => row_data_in_l_0, row_data_l_1 => row_data_in_l_1,
            row_data_l_2 => row_data_in_l_2, row_data_l_3 => row_data_in_l_3,
            row_data_l_4 => row_data_in_l_4, row_data_l_5 => row_data_in_l_5,
            row_data_l_6 => row_data_in_l_6, row_data_l_7 => row_data_in_l_7,
            row_data_l_8 => row_data_in_l_8, row_data_l_9 => row_data_in_l_9,
            row_data_l_10 => row_data_in_l_10, row_data_l_11 => row_data_in_l_11,
            row_data_l_12 => row_data_in_l_12, row_data_l_13 => row_data_in_l_13,
            row_data_l_14 => row_data_in_l_14, row_data_l_15 => row_data_in_l_15,

            grain_ready_r => grain_ready_r, grain_ack_r => grain_ack_r,
            row_addr_r => row_addr_in_r,
            row_data_r_0 => row_data_in_r_0, row_data_r_1 => row_data_in_r_1,
            row_data_r_2 => row_data_in_r_2, row_data_r_3 => row_data_in_r_3,
            row_data_r_4 => row_data_in_r_4, row_data_r_5 => row_data_in_r_5,
            row_data_r_6 => row_data_in_r_6, row_data_r_7 => row_data_in_r_7,
            row_data_r_8 => row_data_in_r_8, row_data_r_9 => row_data_in_r_9,
            row_data_r_10 => row_data_in_r_10, row_data_r_11 => row_data_in_r_11,
            row_data_r_12 => row_data_in_r_12, row_data_r_13 => row_data_in_r_13,
            row_data_r_14 => row_data_in_r_14, row_data_r_15 => row_data_in_r_15
        );

    audio_in_unit_inst : entity work.audio_in_unit
        generic map (BUFFER_ADDR_WIDTH => ADDR_W, BUFFER_SIZE_BITS => SIZE_W)
        port map (
            clk => clk, rst => rst,

            enable => audio_in_enable, left_right => audio_in_left_right,
            buffer_start => audio_in_buffer_start, buffer_length => audio_in_buffer_length,
            operation_start => audio_in_operation_start, finished => audio_in_finished,

            row_addr_l => row_addr_in_l,
            row_data_l_0 => row_data_in_l_0, row_data_l_1 => row_data_in_l_1,
            row_data_l_2 => row_data_in_l_2, row_data_l_3 => row_data_in_l_3,
            row_data_l_4 => row_data_in_l_4, row_data_l_5 => row_data_in_l_5,
            row_data_l_6 => row_data_in_l_6, row_data_l_7 => row_data_in_l_7,
            row_data_l_8 => row_data_in_l_8, row_data_l_9 => row_data_in_l_9,
            row_data_l_10 => row_data_in_l_10, row_data_l_11 => row_data_in_l_11,
            row_data_l_12 => row_data_in_l_12, row_data_l_13 => row_data_in_l_13,
            row_data_l_14 => row_data_in_l_14, row_data_l_15 => row_data_in_l_15,
            grain_ack_l => grain_ack_l,

            row_addr_r => row_addr_in_r,
            row_data_r_0 => row_data_in_r_0, row_data_r_1 => row_data_in_r_1,
            row_data_r_2 => row_data_in_r_2, row_data_r_3 => row_data_in_r_3,
            row_data_r_4 => row_data_in_r_4, row_data_r_5 => row_data_in_r_5,
            row_data_r_6 => row_data_in_r_6, row_data_r_7 => row_data_in_r_7,
            row_data_r_8 => row_data_in_r_8, row_data_r_9 => row_data_in_r_9,
            row_data_r_10 => row_data_in_r_10, row_data_r_11 => row_data_in_r_11,
            row_data_r_12 => row_data_in_r_12, row_data_r_13 => row_data_in_r_13,
            row_data_r_14 => row_data_in_r_14, row_data_r_15 => row_data_in_r_15,
            grain_ack_r => grain_ack_r,

            bram0_port0_addr => ain_addr0, bram1_port0_addr => ain_addr1,
            bram2_port0_addr => ain_addr2, bram3_port0_addr => ain_addr3,
            bram0_port1_addr => ain_addr0_p1, bram1_port1_addr => ain_addr1_p1,
            bram2_port1_addr => ain_addr2_p1, bram3_port1_addr => ain_addr3_p1,

            bram0_port0_we => ain_we0, bram1_port0_we => ain_we1,
            bram2_port0_we => ain_we2, bram3_port0_we => ain_we3,
            bram0_port1_we => ain_we0_p1, bram1_port1_we => ain_we1_p1,
            bram2_port1_we => ain_we2_p1, bram3_port1_we => ain_we3_p1,

            bram0_port0_en => ain_en0, bram1_port0_en => ain_en1,
            bram2_port0_en => ain_en2, bram3_port0_en => ain_en3,
            bram0_port1_en => ain_en0_p1, bram1_port1_en => ain_en1_p1,
            bram2_port1_en => ain_en2_p1, bram3_port1_en => ain_en3_p1,

            bram0_port0_data_in => ain_din0, bram1_port0_data_in => ain_din1,
            bram2_port0_data_in => ain_din2, bram3_port0_data_in => ain_din3,
            bram0_port1_data_in => ain_din0_p1, bram1_port1_data_in => ain_din1_p1,
            bram2_port1_data_in => ain_din2_p1, bram3_port1_data_in => ain_din3_p1,

            bram0_port0_data_out => ain_dout0, bram1_port0_data_out => ain_dout1,
            bram2_port0_data_out => ain_dout2, bram3_port0_data_out => ain_dout3,
            bram0_port1_data_out => ain_dout0_p1, bram1_port1_data_out => ain_dout1_p1,
            bram2_port1_data_out => ain_dout2_p1, bram3_port1_data_out => ain_dout3_p1
        );

    audio_out_inst : entity work.audio_out
        port map (
            clk => clk, rst => rst,
            new_sample => new_sample,
            sample_out_l => sample_out_l, sample_out_r => sample_out_r,

            row_addr_l => row_addr_out_l, row_we_l => row_we_out_l,
            row_data_l_0 => row_data_out_l_0, row_data_l_1 => row_data_out_l_1,
            row_data_l_2 => row_data_out_l_2, row_data_l_3 => row_data_out_l_3,
            row_data_l_4 => row_data_out_l_4, row_data_l_5 => row_data_out_l_5,
            row_data_l_6 => row_data_out_l_6, row_data_l_7 => row_data_out_l_7,
            row_data_l_8 => row_data_out_l_8, row_data_l_9 => row_data_out_l_9,
            row_data_l_10 => row_data_out_l_10, row_data_l_11 => row_data_out_l_11,
            row_data_l_12 => row_data_out_l_12, row_data_l_13 => row_data_out_l_13,
            row_data_l_14 => row_data_out_l_14, row_data_l_15 => row_data_out_l_15,
            back_write_done_l => back_write_done_l, need_grain_l => need_grain_l, fill_ack_l => fill_ack_l,

            row_addr_r => row_addr_out_r, row_we_r => row_we_out_r,
            row_data_r_0 => row_data_out_r_0, row_data_r_1 => row_data_out_r_1,
            row_data_r_2 => row_data_out_r_2, row_data_r_3 => row_data_out_r_3,
            row_data_r_4 => row_data_out_r_4, row_data_r_5 => row_data_out_r_5,
            row_data_r_6 => row_data_out_r_6, row_data_r_7 => row_data_out_r_7,
            row_data_r_8 => row_data_out_r_8, row_data_r_9 => row_data_out_r_9,
            row_data_r_10 => row_data_out_r_10, row_data_r_11 => row_data_out_r_11,
            row_data_r_12 => row_data_out_r_12, row_data_r_13 => row_data_out_r_13,
            row_data_r_14 => row_data_out_r_14, row_data_r_15 => row_data_out_r_15,
            back_write_done_r => back_write_done_r, need_grain_r => need_grain_r, fill_ack_r => fill_ack_r
        );

    audio_out_unit_inst : entity work.audio_out_unit
        generic map (BUFFER_ADDR_WIDTH => ADDR_W, BUFFER_SIZE_BITS => SIZE_W)
        port map (
            clk => clk, rst => rst,

            enable => audio_out_enable, left_right => audio_out_left_right,
            buffer_start => audio_out_buffer_start, buffer_length => audio_out_buffer_length,
            operation_start => audio_out_operation_start, finished => audio_out_finished,

            row_addr_l => row_addr_out_l, row_we_l => row_we_out_l,
            row_data_l_0 => row_data_out_l_0, row_data_l_1 => row_data_out_l_1,
            row_data_l_2 => row_data_out_l_2, row_data_l_3 => row_data_out_l_3,
            row_data_l_4 => row_data_out_l_4, row_data_l_5 => row_data_out_l_5,
            row_data_l_6 => row_data_out_l_6, row_data_l_7 => row_data_out_l_7,
            row_data_l_8 => row_data_out_l_8, row_data_l_9 => row_data_out_l_9,
            row_data_l_10 => row_data_out_l_10, row_data_l_11 => row_data_out_l_11,
            row_data_l_12 => row_data_out_l_12, row_data_l_13 => row_data_out_l_13,
            row_data_l_14 => row_data_out_l_14, row_data_l_15 => row_data_out_l_15,
            back_write_done_l => back_write_done_l, fill_ack_l => fill_ack_l,

            row_addr_r => row_addr_out_r, row_we_r => row_we_out_r,
            row_data_r_0 => row_data_out_r_0, row_data_r_1 => row_data_out_r_1,
            row_data_r_2 => row_data_out_r_2, row_data_r_3 => row_data_out_r_3,
            row_data_r_4 => row_data_out_r_4, row_data_r_5 => row_data_out_r_5,
            row_data_r_6 => row_data_out_r_6, row_data_r_7 => row_data_out_r_7,
            row_data_r_8 => row_data_out_r_8, row_data_r_9 => row_data_out_r_9,
            row_data_r_10 => row_data_out_r_10, row_data_r_11 => row_data_out_r_11,
            row_data_r_12 => row_data_out_r_12, row_data_r_13 => row_data_out_r_13,
            row_data_r_14 => row_data_out_r_14, row_data_r_15 => row_data_out_r_15,
            back_write_done_r => back_write_done_r, fill_ack_r => fill_ack_r,

            bram0_port0_addr => aout_addr0, bram1_port0_addr => aout_addr1,
            bram2_port0_addr => aout_addr2, bram3_port0_addr => aout_addr3,
            bram0_port1_addr => aout_addr0_p1, bram1_port1_addr => aout_addr1_p1,
            bram2_port1_addr => aout_addr2_p1, bram3_port1_addr => aout_addr3_p1,

            bram0_port0_we => aout_we0, bram1_port0_we => aout_we1,
            bram2_port0_we => aout_we2, bram3_port0_we => aout_we3,
            bram0_port1_we => aout_we0_p1, bram1_port1_we => aout_we1_p1,
            bram2_port1_we => aout_we2_p1, bram3_port1_we => aout_we3_p1,

            bram0_port0_en => aout_en0, bram1_port0_en => aout_en1,
            bram2_port0_en => aout_en2, bram3_port0_en => aout_en3,
            bram0_port1_en => aout_en0_p1, bram1_port1_en => aout_en1_p1,
            bram2_port1_en => aout_en2_p1, bram3_port1_en => aout_en3_p1,

            bram0_port0_data_in => aout_din0, bram1_port0_data_in => aout_din1,
            bram2_port0_data_in => aout_din2, bram3_port0_data_in => aout_din3,
            bram0_port1_data_in => aout_din0_p1, bram1_port1_data_in => aout_din1_p1,
            bram2_port1_data_in => aout_din2_p1, bram3_port1_data_in => aout_din3_p1,

            bram0_port0_data_out => aout_dout0, bram1_port0_data_out => aout_dout1,
            bram2_port0_data_out => aout_dout2, bram3_port0_data_out => aout_dout3,
            bram0_port1_data_out => aout_dout0_p1, bram1_port1_data_out => aout_dout1_p1,
            bram2_port1_data_out => aout_dout2_p1, bram3_port1_data_out => aout_dout3_p1
        );

    ------------------------------------------------------------------
    -- fake a-ram: stands in for the real APU's arbiter + physical BRAM.
    -- only one Unit is ever enabled at a time, so a plain en-priority
    -- mux is enough
    ------------------------------------------------------------------
    m0_addr0 <= ain_addr0 when ain_en0 = '1' else aout_addr0;
    m1_addr0 <= ain_addr1 when ain_en1 = '1' else aout_addr1;
    m2_addr0 <= ain_addr2 when ain_en2 = '1' else aout_addr2;
    m3_addr0 <= ain_addr3 when ain_en3 = '1' else aout_addr3;

    m0_addr1 <= ain_addr0_p1 when ain_en0_p1 = '1' else aout_addr0_p1;
    m1_addr1 <= ain_addr1_p1 when ain_en1_p1 = '1' else aout_addr1_p1;
    m2_addr1 <= ain_addr2_p1 when ain_en2_p1 = '1' else aout_addr2_p1;
    m3_addr1 <= ain_addr3_p1 when ain_en3_p1 = '1' else aout_addr3_p1;

    m0_en0 <= ain_en0 or aout_en0; m1_en0 <= ain_en1 or aout_en1;
    m2_en0 <= ain_en2 or aout_en2; m3_en0 <= ain_en3 or aout_en3;
    m0_en1 <= ain_en0_p1 or aout_en0_p1; m1_en1 <= ain_en1_p1 or aout_en1_p1;
    m2_en1 <= ain_en2_p1 or aout_en2_p1; m3_en1 <= ain_en3_p1 or aout_en3_p1;

    m0_we0 <= ain_we0 or aout_we0; m1_we0 <= ain_we1 or aout_we1;
    m2_we0 <= ain_we2 or aout_we2; m3_we0 <= ain_we3 or aout_we3;
    m0_we1 <= ain_we0_p1 or aout_we0_p1; m1_we1 <= ain_we1_p1 or aout_we1_p1;
    m2_we1 <= ain_we2_p1 or aout_we2_p1; m3_we1 <= ain_we3_p1 or aout_we3_p1;

    m0_din0 <= ain_din0 when ain_en0 = '1' else aout_din0;
    m1_din0 <= ain_din1 when ain_en1 = '1' else aout_din1;
    m2_din0 <= ain_din2 when ain_en2 = '1' else aout_din2;
    m3_din0 <= ain_din3 when ain_en3 = '1' else aout_din3;
    m0_din1 <= ain_din0_p1 when ain_en0_p1 = '1' else aout_din0_p1;
    m1_din1 <= ain_din1_p1 when ain_en1_p1 = '1' else aout_din1_p1;
    m2_din1 <= ain_din2_p1 when ain_en2_p1 = '1' else aout_din2_p1;
    m3_din1 <= ain_din3_p1 when ain_en3_p1 = '1' else aout_din3_p1;

    -- read data fans out to both Units; only the one actually reading cares
    ain_dout0 <= m0_dout0; aout_dout0 <= m0_dout0;
    ain_dout1 <= m1_dout0; aout_dout1 <= m1_dout0;
    ain_dout2 <= m2_dout0; aout_dout2 <= m2_dout0;
    ain_dout3 <= m3_dout0; aout_dout3 <= m3_dout0;
    ain_dout0_p1 <= m0_dout1; aout_dout0_p1 <= m0_dout1;
    ain_dout1_p1 <= m1_dout1; aout_dout1_p1 <= m1_dout1;
    ain_dout2_p1 <= m2_dout1; aout_dout2_p1 <= m2_dout1;
    ain_dout3_p1 <= m3_dout1; aout_dout3_p1 <= m3_dout1;

    mem0 : process(clk)
    begin
        if rising_edge(clk) then
            if m0_en0 = '1' then
                if m0_we0 = '1' then
                    m0_array(to_integer(unsigned(m0_addr0))) <= m0_din0;
                end if;
                m0_dout0 <= m0_array(to_integer(unsigned(m0_addr0)));
            end if;
            if m0_en1 = '1' then
                if m0_we1 = '1' then
                    m0_array(to_integer(unsigned(m0_addr1))) <= m0_din1;
                end if;
                m0_dout1 <= m0_array(to_integer(unsigned(m0_addr1)));
            end if;
        end if;
    end process;

    mem1 : process(clk)
    begin
        if rising_edge(clk) then
            if m1_en0 = '1' then
                if m1_we0 = '1' then
                    m1_array(to_integer(unsigned(m1_addr0))) <= m1_din0;
                end if;
                m1_dout0 <= m1_array(to_integer(unsigned(m1_addr0)));
            end if;
            if m1_en1 = '1' then
                if m1_we1 = '1' then
                    m1_array(to_integer(unsigned(m1_addr1))) <= m1_din1;
                end if;
                m1_dout1 <= m1_array(to_integer(unsigned(m1_addr1)));
            end if;
        end if;
    end process;

    mem2 : process(clk)
    begin
        if rising_edge(clk) then
            if m2_en0 = '1' then
                if m2_we0 = '1' then
                    m2_array(to_integer(unsigned(m2_addr0))) <= m2_din0;
                end if;
                m2_dout0 <= m2_array(to_integer(unsigned(m2_addr0)));
            end if;
            if m2_en1 = '1' then
                if m2_we1 = '1' then
                    m2_array(to_integer(unsigned(m2_addr1))) <= m2_din1;
                end if;
                m2_dout1 <= m2_array(to_integer(unsigned(m2_addr1)));
            end if;
        end if;
    end process;

    mem3 : process(clk)
    begin
        if rising_edge(clk) then
            if m3_en0 = '1' then
                if m3_we0 = '1' then
                    m3_array(to_integer(unsigned(m3_addr0))) <= m3_din0;
                end if;
                m3_dout0 <= m3_array(to_integer(unsigned(m3_addr0)));
            end if;
            if m3_en1 = '1' then
                if m3_we1 = '1' then
                    m3_array(to_integer(unsigned(m3_addr1))) <= m3_din1;
                end if;
                m3_dout1 <= m3_array(to_integer(unsigned(m3_addr1)));
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- fake ADAU: free-running new_sample pulse (1 clock wide, every 4
    -- clocks), counting 0..255 into both channels -- runs the whole sim,
    -- same as a real codec would, independent of the CU sequencing below
    ------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '0' then
                tick_div   <= 0;
                new_sample <= '0';
                sample_ctr <= (others => '0');
            else
                new_sample <= '0';
                if tick_div = 3 then
                    tick_div   <= 0;
                    new_sample <= '1';
                    line_in_l  <= std_logic_vector(resize(sample_ctr, 16));
                    line_in_r  <= std_logic_vector(resize(sample_ctr, 16));
                    sample_ctr <= sample_ctr + 1;
                else
                    tick_div <= tick_div + 1;
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- fake CU: same a-ram location both ways. Loops several grains on
    -- BOTH channels back-to-back, continuously -- matching a real
    -- continuous-capture scenario, not just a single one-shot grain.
    ------------------------------------------------------------------
    stim : process
    begin
        rst <= '0';
        wait for CLK_PERIOD * 4;
        rst <= '1';

        audio_in_buffer_start    <= std_logic_vector(to_unsigned(0, ADDR_W));
        audio_in_buffer_length   <= std_logic_vector(to_unsigned(128, SIZE_W));
        audio_in_operation_start <= std_logic_vector(to_unsigned(0, ADDR_W));

        audio_out_buffer_start    <= std_logic_vector(to_unsigned(0, ADDR_W));
        audio_out_buffer_length   <= std_logic_vector(to_unsigned(128, SIZE_W));
        audio_out_operation_start <= std_logic_vector(to_unsigned(0, ADDR_W));

        for grain_num in 0 to 4 loop
            -- LEFT channel round trip
            audio_in_left_right  <= '0';
            audio_out_left_right <= '0';

            if grain_ready_l /= '1' then
                wait until grain_ready_l = '1';
            end if;
            report "grain " & integer'image(grain_num) & " L: grain_ready_l seen";
            audio_in_enable <= '1';
            wait for CLK_PERIOD;
            audio_in_enable <= '0';

            wait until audio_in_finished = '1';
            audio_out_enable <= '1';
            wait for CLK_PERIOD;
            audio_out_enable <= '0';

            wait until audio_out_finished = '1';
            report "grain " & integer'image(grain_num) & " L: done, streaming out";

            wait for CLK_PERIOD * 1050;

            -- RIGHT channel round trip
            audio_in_left_right  <= '1';
            audio_out_left_right <= '1';

            if grain_ready_r /= '1' then
                wait until grain_ready_r = '1';
            end if;
            report "grain " & integer'image(grain_num) & " R: grain_ready_r seen";
            audio_in_enable <= '1';
            wait for CLK_PERIOD;
            audio_in_enable <= '0';

            wait until audio_in_finished = '1';
            audio_out_enable <= '1';
            wait for CLK_PERIOD;
            audio_out_enable <= '0';

            wait until audio_out_finished = '1';
            report "grain " & integer'image(grain_num) & " R: done, streaming out";

            wait for CLK_PERIOD * 1050;
        end loop;

        report "simulation finished";
        wait;
    end process;

end sim;
