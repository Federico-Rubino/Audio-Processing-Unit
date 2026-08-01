library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity audioIO is
  generic (
    BUFFER_ADDR_WIDTH : integer := 10;
    BUFFER_SIZE_BITS  : integer := 18
  );
  Port (
    clk : in std_logic;
    rst : in std_logic;

    --ADAU
    AC_ADR0  : out   STD_LOGIC;
    AC_ADR1  : out   STD_LOGIC;
    AC_GPIO0 : out   STD_LOGIC;
    AC_GPIO1 : in    STD_LOGIC;
    AC_GPIO2 : in    STD_LOGIC;
    AC_GPIO3 : in    STD_LOGIC;
    AC_MCLK  : out   STD_LOGIC;
    AC_SCK   : out   STD_LOGIC;
    AC_SDA   : inout STD_LOGIC;

    -- audio in unit CU
    audio_in_enable          : in  std_logic;
    audio_in_left_right      : in  std_logic;
    audio_in_buffer_start    : in  std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
    audio_in_buffer_length   : in  std_logic_vector(BUFFER_SIZE_BITS-1 downto 0);
    audio_in_operation_start : in  std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
    audio_in_finished        : out std_logic;
    grain_ready_l            : out std_logic;
    grain_ready_r            : out std_logic;

    -- audio out unit CU
    audio_out_enable          : in  std_logic;
    audio_out_left_right      : in  std_logic;
    audio_out_buffer_start    : in  std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
    audio_out_buffer_length   : in  std_logic_vector(BUFFER_SIZE_BITS-1 downto 0);
    audio_out_operation_start : in  std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
    audio_out_finished        : out std_logic;
    need_grain_l              : out std_logic;
    need_grain_r              : out std_logic;

    -- audio In Unit to mem
    ain_bram0_port0_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
    ain_bram1_port0_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
    ain_bram2_port0_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
    ain_bram3_port0_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
    ain_bram0_port1_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
    ain_bram1_port1_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
    ain_bram2_port1_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
    ain_bram3_port1_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);

    ain_bram0_port0_we : out std_logic;
    ain_bram1_port0_we : out std_logic;
    ain_bram2_port0_we : out std_logic;
    ain_bram3_port0_we : out std_logic;
    ain_bram0_port1_we : out std_logic;
    ain_bram1_port1_we : out std_logic;
    ain_bram2_port1_we : out std_logic;
    ain_bram3_port1_we : out std_logic;

    ain_bram0_port0_en : out std_logic;
    ain_bram1_port0_en : out std_logic;
    ain_bram2_port0_en : out std_logic;
    ain_bram3_port0_en : out std_logic;
    ain_bram0_port1_en : out std_logic;
    ain_bram1_port1_en : out std_logic;
    ain_bram2_port1_en : out std_logic;
    ain_bram3_port1_en : out std_logic;

    ain_bram0_port0_data_in : out std_logic_vector(31 downto 0);
    ain_bram1_port0_data_in : out std_logic_vector(31 downto 0);
    ain_bram2_port0_data_in : out std_logic_vector(31 downto 0);
    ain_bram3_port0_data_in : out std_logic_vector(31 downto 0);
    ain_bram0_port1_data_in : out std_logic_vector(31 downto 0);
    ain_bram1_port1_data_in : out std_logic_vector(31 downto 0);
    ain_bram2_port1_data_in : out std_logic_vector(31 downto 0);
    ain_bram3_port1_data_in : out std_logic_vector(31 downto 0);

    ain_bram0_port0_data_out : in std_logic_vector(31 downto 0);
    ain_bram1_port0_data_out : in std_logic_vector(31 downto 0);
    ain_bram2_port0_data_out : in std_logic_vector(31 downto 0);
    ain_bram3_port0_data_out : in std_logic_vector(31 downto 0);
    ain_bram0_port1_data_out : in std_logic_vector(31 downto 0);
    ain_bram1_port1_data_out : in std_logic_vector(31 downto 0);
    ain_bram2_port1_data_out : in std_logic_vector(31 downto 0);
    ain_bram3_port1_data_out : in std_logic_vector(31 downto 0);

    -- audio out unit to mem
    aout_bram0_port0_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
    aout_bram1_port0_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
    aout_bram2_port0_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
    aout_bram3_port0_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
    aout_bram0_port1_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
    aout_bram1_port1_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
    aout_bram2_port1_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
    aout_bram3_port1_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);

    aout_bram0_port0_we : out std_logic;
    aout_bram1_port0_we : out std_logic;
    aout_bram2_port0_we : out std_logic;
    aout_bram3_port0_we : out std_logic;
    aout_bram0_port1_we : out std_logic;
    aout_bram1_port1_we : out std_logic;
    aout_bram2_port1_we : out std_logic;
    aout_bram3_port1_we : out std_logic;

    aout_bram0_port0_en : out std_logic;
    aout_bram1_port0_en : out std_logic;
    aout_bram2_port0_en : out std_logic;
    aout_bram3_port0_en : out std_logic;
    aout_bram0_port1_en : out std_logic;
    aout_bram1_port1_en : out std_logic;
    aout_bram2_port1_en : out std_logic;
    aout_bram3_port1_en : out std_logic;

    aout_bram0_port0_data_in : out std_logic_vector(31 downto 0);
    aout_bram1_port0_data_in : out std_logic_vector(31 downto 0);
    aout_bram2_port0_data_in : out std_logic_vector(31 downto 0);
    aout_bram3_port0_data_in : out std_logic_vector(31 downto 0);
    aout_bram0_port1_data_in : out std_logic_vector(31 downto 0);
    aout_bram1_port1_data_in : out std_logic_vector(31 downto 0);
    aout_bram2_port1_data_in : out std_logic_vector(31 downto 0);
    aout_bram3_port1_data_in : out std_logic_vector(31 downto 0);

    aout_bram0_port0_data_out : in std_logic_vector(31 downto 0);
    aout_bram1_port0_data_out : in std_logic_vector(31 downto 0);
    aout_bram2_port0_data_out : in std_logic_vector(31 downto 0);
    aout_bram3_port0_data_out : in std_logic_vector(31 downto 0);
    aout_bram0_port1_data_out : in std_logic_vector(31 downto 0);
    aout_bram1_port1_data_out : in std_logic_vector(31 downto 0);
    aout_bram2_port1_data_out : in std_logic_vector(31 downto 0);
    aout_bram3_port1_data_out : in std_logic_vector(31 downto 0)
   );
end audioIO;

architecture Behavioral of audioIO is
    signal new_sample : std_logic := '0';
    signal line_in_l, line_in_r: std_logic_vector(15 downto 0) := (others => '0');
    signal line_in_l_24b, line_in_r_24b: std_logic_vector(23 downto 0):= (others => '0');
    signal line_out_l, line_out_r: std_logic_vector(15 downto 0) := (others => '0');
    signal line_out_l_24b, line_out_r_24b: std_logic_vector(23 downto 0) := (others => '0');
    signal sample_clk_48k : std_logic;

    -- audio_in <-> audio_in_unit. rows are 16 samples (2 samples/a-ram cell)
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

    signal hphone_valid : std_logic;
    
begin
    audio_in_inst: entity work.audio_in
        port map(
            clk => clk,
            rst => rst,
            new_sample => new_sample,
            line_in_l => line_in_l,
            line_in_r => line_in_r,

            grain_ready_l => grain_ready_l,
            grain_ack_l   => grain_ack_l,
            row_addr_l    => row_addr_in_l,
            row_data_l_0 => row_data_in_l_0, row_data_l_1 => row_data_in_l_1,
            row_data_l_2 => row_data_in_l_2, row_data_l_3 => row_data_in_l_3,
            row_data_l_4 => row_data_in_l_4, row_data_l_5 => row_data_in_l_5,
            row_data_l_6 => row_data_in_l_6, row_data_l_7 => row_data_in_l_7,
            row_data_l_8 => row_data_in_l_8, row_data_l_9 => row_data_in_l_9,
            row_data_l_10 => row_data_in_l_10, row_data_l_11 => row_data_in_l_11,
            row_data_l_12 => row_data_in_l_12, row_data_l_13 => row_data_in_l_13,
            row_data_l_14 => row_data_in_l_14, row_data_l_15 => row_data_in_l_15,

            grain_ready_r => grain_ready_r,
            grain_ack_r   => grain_ack_r,
            row_addr_r    => row_addr_in_r,
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
        generic map (
            BUFFER_ADDR_WIDTH => BUFFER_ADDR_WIDTH,
            BUFFER_SIZE_BITS  => BUFFER_SIZE_BITS
        )
        port map (
            clk => clk, rst => rst,

            enable          => audio_in_enable,
            left_right      => audio_in_left_right,
            buffer_start    => audio_in_buffer_start,
            buffer_length   => audio_in_buffer_length,
            operation_start => audio_in_operation_start,
            finished        => audio_in_finished,

            row_addr_l   => row_addr_in_l,
            row_data_l_0 => row_data_in_l_0, row_data_l_1 => row_data_in_l_1,
            row_data_l_2 => row_data_in_l_2, row_data_l_3 => row_data_in_l_3,
            row_data_l_4 => row_data_in_l_4, row_data_l_5 => row_data_in_l_5,
            row_data_l_6 => row_data_in_l_6, row_data_l_7 => row_data_in_l_7,
            row_data_l_8 => row_data_in_l_8, row_data_l_9 => row_data_in_l_9,
            row_data_l_10 => row_data_in_l_10, row_data_l_11 => row_data_in_l_11,
            row_data_l_12 => row_data_in_l_12, row_data_l_13 => row_data_in_l_13,
            row_data_l_14 => row_data_in_l_14, row_data_l_15 => row_data_in_l_15,
            grain_ack_l  => grain_ack_l,

            row_addr_r   => row_addr_in_r,
            row_data_r_0 => row_data_in_r_0, row_data_r_1 => row_data_in_r_1,
            row_data_r_2 => row_data_in_r_2, row_data_r_3 => row_data_in_r_3,
            row_data_r_4 => row_data_in_r_4, row_data_r_5 => row_data_in_r_5,
            row_data_r_6 => row_data_in_r_6, row_data_r_7 => row_data_in_r_7,
            row_data_r_8 => row_data_in_r_8, row_data_r_9 => row_data_in_r_9,
            row_data_r_10 => row_data_in_r_10, row_data_r_11 => row_data_in_r_11,
            row_data_r_12 => row_data_in_r_12, row_data_r_13 => row_data_in_r_13,
            row_data_r_14 => row_data_in_r_14, row_data_r_15 => row_data_in_r_15,
            grain_ack_r  => grain_ack_r,

            bram0_port0_addr => ain_bram0_port0_addr, bram1_port0_addr => ain_bram1_port0_addr,
            bram2_port0_addr => ain_bram2_port0_addr, bram3_port0_addr => ain_bram3_port0_addr,
            bram0_port1_addr => ain_bram0_port1_addr, bram1_port1_addr => ain_bram1_port1_addr,
            bram2_port1_addr => ain_bram2_port1_addr, bram3_port1_addr => ain_bram3_port1_addr,

            bram0_port0_we => ain_bram0_port0_we, bram1_port0_we => ain_bram1_port0_we,
            bram2_port0_we => ain_bram2_port0_we, bram3_port0_we => ain_bram3_port0_we,
            bram0_port1_we => ain_bram0_port1_we, bram1_port1_we => ain_bram1_port1_we,
            bram2_port1_we => ain_bram2_port1_we, bram3_port1_we => ain_bram3_port1_we,

            bram0_port0_en => ain_bram0_port0_en, bram1_port0_en => ain_bram1_port0_en,
            bram2_port0_en => ain_bram2_port0_en, bram3_port0_en => ain_bram3_port0_en,
            bram0_port1_en => ain_bram0_port1_en, bram1_port1_en => ain_bram1_port1_en,
            bram2_port1_en => ain_bram2_port1_en, bram3_port1_en => ain_bram3_port1_en,

            bram0_port0_data_in => ain_bram0_port0_data_in, bram1_port0_data_in => ain_bram1_port0_data_in,
            bram2_port0_data_in => ain_bram2_port0_data_in, bram3_port0_data_in => ain_bram3_port0_data_in,
            bram0_port1_data_in => ain_bram0_port1_data_in, bram1_port1_data_in => ain_bram1_port1_data_in,
            bram2_port1_data_in => ain_bram2_port1_data_in, bram3_port1_data_in => ain_bram3_port1_data_in,

            bram0_port0_data_out => ain_bram0_port0_data_out, bram1_port0_data_out => ain_bram1_port0_data_out,
            bram2_port0_data_out => ain_bram2_port0_data_out, bram3_port0_data_out => ain_bram3_port0_data_out,
            bram0_port1_data_out => ain_bram0_port1_data_out, bram1_port1_data_out => ain_bram1_port1_data_out,
            bram2_port1_data_out => ain_bram2_port1_data_out, bram3_port1_data_out => ain_bram3_port1_data_out
        );

    audio_out_inst : entity work.audio_out
        port map(
            clk => clk,
            rst => rst,

            new_sample   => new_sample,
            sample_out_l => line_out_l,
            sample_out_r => line_out_r,

            row_addr_l   => row_addr_out_l,
            row_we_l     => row_we_out_l,
            row_data_l_0 => row_data_out_l_0, row_data_l_1 => row_data_out_l_1,
            row_data_l_2 => row_data_out_l_2, row_data_l_3 => row_data_out_l_3,
            row_data_l_4 => row_data_out_l_4, row_data_l_5 => row_data_out_l_5,
            row_data_l_6 => row_data_out_l_6, row_data_l_7 => row_data_out_l_7,
            row_data_l_8 => row_data_out_l_8, row_data_l_9 => row_data_out_l_9,
            row_data_l_10 => row_data_out_l_10, row_data_l_11 => row_data_out_l_11,
            row_data_l_12 => row_data_out_l_12, row_data_l_13 => row_data_out_l_13,
            row_data_l_14 => row_data_out_l_14, row_data_l_15 => row_data_out_l_15,
            back_write_done_l => back_write_done_l,
            need_grain_l => need_grain_l,
            fill_ack_l   => fill_ack_l,

            row_addr_r   => row_addr_out_r,
            row_we_r     => row_we_out_r,
            row_data_r_0 => row_data_out_r_0, row_data_r_1 => row_data_out_r_1,
            row_data_r_2 => row_data_out_r_2, row_data_r_3 => row_data_out_r_3,
            row_data_r_4 => row_data_out_r_4, row_data_r_5 => row_data_out_r_5,
            row_data_r_6 => row_data_out_r_6, row_data_r_7 => row_data_out_r_7,
            row_data_r_8 => row_data_out_r_8, row_data_r_9 => row_data_out_r_9,
            row_data_r_10 => row_data_out_r_10, row_data_r_11 => row_data_out_r_11,
            row_data_r_12 => row_data_out_r_12, row_data_r_13 => row_data_out_r_13,
            row_data_r_14 => row_data_out_r_14, row_data_r_15 => row_data_out_r_15,
            back_write_done_r => back_write_done_r,
            need_grain_r => need_grain_r,
            fill_ack_r   => fill_ack_r
        );

    audio_out_unit_inst : entity work.audio_out_unit
        generic map (
            BUFFER_ADDR_WIDTH => BUFFER_ADDR_WIDTH,
            BUFFER_SIZE_BITS  => BUFFER_SIZE_BITS
        )
        port map (
            clk => clk, rst => rst,

            enable          => audio_out_enable,
            left_right      => audio_out_left_right,
            buffer_start    => audio_out_buffer_start,
            buffer_length   => audio_out_buffer_length,
            operation_start => audio_out_operation_start,
            finished        => audio_out_finished,

            row_addr_l   => row_addr_out_l,
            row_we_l     => row_we_out_l,
            row_data_l_0 => row_data_out_l_0, row_data_l_1 => row_data_out_l_1,
            row_data_l_2 => row_data_out_l_2, row_data_l_3 => row_data_out_l_3,
            row_data_l_4 => row_data_out_l_4, row_data_l_5 => row_data_out_l_5,
            row_data_l_6 => row_data_out_l_6, row_data_l_7 => row_data_out_l_7,
            row_data_l_8 => row_data_out_l_8, row_data_l_9 => row_data_out_l_9,
            row_data_l_10 => row_data_out_l_10, row_data_l_11 => row_data_out_l_11,
            row_data_l_12 => row_data_out_l_12, row_data_l_13 => row_data_out_l_13,
            row_data_l_14 => row_data_out_l_14, row_data_l_15 => row_data_out_l_15,
            back_write_done_l => back_write_done_l,
            fill_ack_l   => fill_ack_l,

            row_addr_r   => row_addr_out_r,
            row_we_r     => row_we_out_r,
            row_data_r_0 => row_data_out_r_0, row_data_r_1 => row_data_out_r_1,
            row_data_r_2 => row_data_out_r_2, row_data_r_3 => row_data_out_r_3,
            row_data_r_4 => row_data_out_r_4, row_data_r_5 => row_data_out_r_5,
            row_data_r_6 => row_data_out_r_6, row_data_r_7 => row_data_out_r_7,
            row_data_r_8 => row_data_out_r_8, row_data_r_9 => row_data_out_r_9,
            row_data_r_10 => row_data_out_r_10, row_data_r_11 => row_data_out_r_11,
            row_data_r_12 => row_data_out_r_12, row_data_r_13 => row_data_out_r_13,
            row_data_r_14 => row_data_out_r_14, row_data_r_15 => row_data_out_r_15,
            back_write_done_r => back_write_done_r,
            fill_ack_r   => fill_ack_r,

            bram0_port0_addr => aout_bram0_port0_addr, bram1_port0_addr => aout_bram1_port0_addr,
            bram2_port0_addr => aout_bram2_port0_addr, bram3_port0_addr => aout_bram3_port0_addr,
            bram0_port1_addr => aout_bram0_port1_addr, bram1_port1_addr => aout_bram1_port1_addr,
            bram2_port1_addr => aout_bram2_port1_addr, bram3_port1_addr => aout_bram3_port1_addr,

            bram0_port0_we => aout_bram0_port0_we, bram1_port0_we => aout_bram1_port0_we,
            bram2_port0_we => aout_bram2_port0_we, bram3_port0_we => aout_bram3_port0_we,
            bram0_port1_we => aout_bram0_port1_we, bram1_port1_we => aout_bram1_port1_we,
            bram2_port1_we => aout_bram2_port1_we, bram3_port1_we => aout_bram3_port1_we,

            bram0_port0_en => aout_bram0_port0_en, bram1_port0_en => aout_bram1_port0_en,
            bram2_port0_en => aout_bram2_port0_en, bram3_port0_en => aout_bram3_port0_en,
            bram0_port1_en => aout_bram0_port1_en, bram1_port1_en => aout_bram1_port1_en,
            bram2_port1_en => aout_bram2_port1_en, bram3_port1_en => aout_bram3_port1_en,

            bram0_port0_data_in => aout_bram0_port0_data_in, bram1_port0_data_in => aout_bram1_port0_data_in,
            bram2_port0_data_in => aout_bram2_port0_data_in, bram3_port0_data_in => aout_bram3_port0_data_in,
            bram0_port1_data_in => aout_bram0_port1_data_in, bram1_port1_data_in => aout_bram1_port1_data_in,
            bram2_port1_data_in => aout_bram2_port1_data_in, bram3_port1_data_in => aout_bram3_port1_data_in,

            bram0_port0_data_out => aout_bram0_port0_data_out, bram1_port0_data_out => aout_bram1_port0_data_out,
            bram2_port0_data_out => aout_bram2_port0_data_out, bram3_port0_data_out => aout_bram3_port0_data_out,
            bram0_port1_data_out => aout_bram0_port1_data_out, bram1_port1_data_out => aout_bram1_port1_data_out,
            bram2_port1_data_out => aout_bram2_port1_data_out, bram3_port1_data_out => aout_bram3_port1_data_out
        );

    audio_adau : entity work.audio_top
        port map(
            clk_100  => clk,
            AC_ADR0  => AC_ADR0,
            AC_ADR1  => AC_ADR1,
            AC_GPIO0 => AC_GPIO0,
            AC_GPIO1 => AC_GPIO1,
            AC_GPIO2 => AC_GPIO2,
            AC_GPIO3 => AC_GPIO3,
            AC_MCLK  => AC_MCLK,
            AC_SCK   => AC_SCK,
            AC_SDA   => AC_SDA,

            hphone_l  => line_out_l_24b,
            hphone_l_valid => hphone_valid,
            hphone_r  => line_out_r_24b,
            hphone_r_valid_dummy => hphone_valid,   --  this valid will be discarded later

            line_in_l => line_in_l_24b,
            line_in_r => line_in_r_24b,

            new_sample => new_sample,
            sample_clk_48k => sample_clk_48k
        );
        
    line_in_l <= line_in_l_24b(23 downto 8);
    line_in_r <= line_in_r_24b(23 downto 8);

    line_out_l_24b <= line_out_l & x"00";
    line_out_r_24b <= line_out_r & x"00";
    hphone_valid   <= new_sample;

end Behavioral;
