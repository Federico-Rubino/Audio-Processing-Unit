library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.apu_internal_pkg.all;
use work.vpu_internal_pkg.all;

entity vpu is
  generic (
    BUFFER_ADDR_WIDTH : integer := 10;
    BUFFER_SIZE_BITS  : integer := 18;
    FIXED_POINT_POSITION : integer := 8
  );
  Port (
    clk : in std_logic;
    rst : in std_logic;

    vec_end : out std_logic;
    vec_en : in std_logic;
    vec_op : in vec_op_t;
    vec_scalar : in std_logic_vector(15 downto 0);
    vec_bsr1, vec_blr1, vec_osr1, vec_olr1 : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
    vec_bsr2, vec_blr2, vec_osr2, vec_olr2 : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
    vec_bsw, vec_blw, vec_osw, vec_olw : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);

    --shared read bus <-> a-ram (bmu_read_1/bmu_read_2 muxed)
    bmu_read_bram0_port0_addr, bmu_read_bram1_port0_addr, bmu_read_bram2_port0_addr, bmu_read_bram3_port0_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
    bmu_read_bram0_port1_addr, bmu_read_bram1_port1_addr, bmu_read_bram2_port1_addr, bmu_read_bram3_port1_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
    bmu_read_bram0_port0_we, bmu_read_bram1_port0_we, bmu_read_bram2_port0_we, bmu_read_bram3_port0_we : out std_logic;
    bmu_read_bram0_port1_we, bmu_read_bram1_port1_we, bmu_read_bram2_port1_we, bmu_read_bram3_port1_we : out std_logic;
    bmu_read_bram0_port0_en, bmu_read_bram1_port0_en, bmu_read_bram2_port0_en, bmu_read_bram3_port0_en : out std_logic;
    bmu_read_bram0_port1_en, bmu_read_bram1_port1_en, bmu_read_bram2_port1_en, bmu_read_bram3_port1_en : out std_logic;
    bmu_read_bram0_port0_data_in, bmu_read_bram1_port0_data_in, bmu_read_bram2_port0_data_in, bmu_read_bram3_port0_data_in : out std_logic_vector(31 downto 0);
    bmu_read_bram0_port1_data_in, bmu_read_bram1_port1_data_in, bmu_read_bram2_port1_data_in, bmu_read_bram3_port1_data_in : out std_logic_vector(31 downto 0);
    bmu_read_bram0_port0_data_out, bmu_read_bram1_port0_data_out, bmu_read_bram2_port0_data_out, bmu_read_bram3_port0_data_out : in std_logic_vector(31 downto 0);
    bmu_read_bram0_port1_data_out, bmu_read_bram1_port1_data_out, bmu_read_bram2_port1_data_out, bmu_read_bram3_port1_data_out : in std_logic_vector(31 downto 0);

    --bmu_write <-> a-ram
    bmu_write_bram0_port0_addr, bmu_write_bram1_port0_addr, bmu_write_bram2_port0_addr, bmu_write_bram3_port0_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
    bmu_write_bram0_port1_addr, bmu_write_bram1_port1_addr, bmu_write_bram2_port1_addr, bmu_write_bram3_port1_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
    bmu_write_bram0_port0_we, bmu_write_bram1_port0_we, bmu_write_bram2_port0_we, bmu_write_bram3_port0_we : out std_logic;
    bmu_write_bram0_port1_we, bmu_write_bram1_port1_we, bmu_write_bram2_port1_we, bmu_write_bram3_port1_we : out std_logic;
    bmu_write_bram0_port0_en, bmu_write_bram1_port0_en, bmu_write_bram2_port0_en, bmu_write_bram3_port0_en : out std_logic;
    bmu_write_bram0_port1_en, bmu_write_bram1_port1_en, bmu_write_bram2_port1_en, bmu_write_bram3_port1_en : out std_logic;
    bmu_write_bram0_port0_data_in, bmu_write_bram1_port0_data_in, bmu_write_bram2_port0_data_in, bmu_write_bram3_port0_data_in : out std_logic_vector(31 downto 0);
    bmu_write_bram0_port1_data_in, bmu_write_bram1_port1_data_in, bmu_write_bram2_port1_data_in, bmu_write_bram3_port1_data_in : out std_logic_vector(31 downto 0);
    bmu_write_bram0_port0_data_out, bmu_write_bram1_port0_data_out, bmu_write_bram2_port0_data_out, bmu_write_bram3_port0_data_out : in std_logic_vector(31 downto 0);
    bmu_write_bram0_port1_data_out, bmu_write_bram1_port1_data_out, bmu_write_bram2_port1_data_out, bmu_write_bram3_port1_data_out : in std_logic_vector(31 downto 0)
   );
end vpu;

architecture Behavioral of vpu is

  --4x32 lane data, LANES=4
  type bmu_lane_data_t is array (0 to 3) of std_logic_vector(31 downto 0);

  -- count enable propagation registers
   signal s1a_en, next_s1a_en : std_logic;
   signal s1b_en, next_s1b_en : std_logic;
   signal s2a_en, next_s2a_en : std_logic;
   signal s2b_en, next_s2b_en : std_logic;
   signal s3a_en, next_s3a_en : std_logic;
   signal s3b_en, next_s3b_en : std_logic;
   signal s3c_en, next_s3c_en : std_logic;

  --buffer read 1 data propagation registers
  signal s1b_buf1_data, next_s1b_buf1_data : data_array_t;
  signal s2a_buf1_data, next_s2a_buf1_data : data_array_t;

  --buffer read 2
  signal buf2_data : data_array_t;

  --CU <-> BMUs
  signal bmu_read_1_start : std_logic;
  signal bmu_read_2_start : std_logic;
  signal bmu_write_start : std_logic;
  signal bmu_read_1_done : std_logic;
  signal bmu_read_2_done : std_logic;
  signal bmu_write_done : std_logic;
  signal bmu_count_en : std_logic; --shared by all 3 BMUs

  --CU <-> MUXs
  signal sel_scal_in : std_logic; -- 0 = vec in, 1 = scalar in
  signal sel_output_even : std_logic; -- even DSP; 0 = take DSP output, 1 = shift for fixed point alignement
  signal sel_output_odd : std_logic; -- odd DSP; 0 = take DSP output, 1 = shift for fixed point alignement
  signal sel_bmu_read : std_logic; -- 0 = bmu_read_1, 1 = bmu_read_2

  --bmu_read_1 pre-mux
  signal r1_bram0_port0_addr, r1_bram1_port0_addr, r1_bram2_port0_addr, r1_bram3_port0_addr : std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
  signal r1_bram0_port1_addr, r1_bram1_port1_addr, r1_bram2_port1_addr, r1_bram3_port1_addr : std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
  signal r1_bram0_port0_en, r1_bram1_port0_en, r1_bram2_port0_en, r1_bram3_port0_en : std_logic;
  signal r1_bram0_port1_en, r1_bram1_port1_en, r1_bram2_port1_en, r1_bram3_port1_en : std_logic;

  --bmu_read_2 pre-mux
  signal r2_bram0_port0_addr, r2_bram1_port0_addr, r2_bram2_port0_addr, r2_bram3_port0_addr : std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
  signal r2_bram0_port1_addr, r2_bram1_port1_addr, r2_bram2_port1_addr, r2_bram3_port1_addr : std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
  signal r2_bram0_port0_en, r2_bram1_port0_en, r2_bram2_port0_en, r2_bram3_port0_en : std_logic;
  signal r2_bram0_port1_en, r2_bram1_port1_en, r2_bram2_port1_en, r2_bram3_port1_en : std_logic;

  --bmu_read_1/bmu_read_2 lane data + muxed result
  signal bmu_read_1_data : bmu_lane_data_t;
  signal bmu_read_2_data : bmu_lane_data_t;
  signal bmu_read_sel_data : bmu_lane_data_t;

  --bmu_write lane data
  signal bmu_write_data : bmu_lane_data_t;

  --CU <-> DSPs
  signal dsp_op_sel : dsp_op_sel_array_t;

  --DSP data
  signal dsp_b_in : data_array_t;
  signal dsp_out : dsp_p_array_t; --P is 33 bits
  signal dsp_out_aligned : data_array_t; --post sel_output_even/odd, 16-bit/sample
begin

  cu : entity work.vpuCU
    port map (
      clk => clk, rst => rst,

      en   => vec_en,
      done => vec_end,

      vec_op => vec_op,

      bmu_read_1_start => bmu_read_1_start,
      bmu_read_2_start => bmu_read_2_start,
      bmu_write_start  => bmu_write_start,

      bmu_read_1_done => bmu_read_1_done,
      bmu_read_2_done => bmu_read_2_done,
      bmu_write_done  => bmu_write_done,

      count_en => bmu_count_en,
      exec1_en => s2b_en,

      dsp_op_sel => dsp_op_sel,

      sel_scal_in     => sel_scal_in,
      sel_output_even => sel_output_even,
      sel_output_odd  => sel_output_odd
    );

  bmu_read_1_inst : entity work.bmu_read
    generic map (
      BUFFER_ADDR_WIDTH => BUFFER_ADDR_WIDTH,
      BUFFER_SIZE_BITS  => BUFFER_SIZE_BITS,
      LANES             => 4
    )
    port map (
      clk => clk, 
      rst => rst, 
      start => bmu_read_1_start, 
      count_en => bmu_count_en,

      buffer_start     => vec_bsr1,
      buffer_length    => std_logic_vector(resize(unsigned(vec_blr1), BUFFER_SIZE_BITS)),
      operation_start  => vec_osr1,
      operation_length => std_logic_vector(resize(unsigned(vec_olr1), BUFFER_SIZE_BITS)),

      bram0_port0_addr => r1_bram0_port0_addr, bram1_port0_addr => r1_bram1_port0_addr,
      bram2_port0_addr => r1_bram2_port0_addr, bram3_port0_addr => r1_bram3_port0_addr,
      bram0_port1_addr => r1_bram0_port1_addr, bram1_port1_addr => r1_bram1_port1_addr,
      bram2_port1_addr => r1_bram2_port1_addr, bram3_port1_addr => r1_bram3_port1_addr,

      bram0_port0_we => open, bram1_port0_we => open, bram2_port0_we => open, bram3_port0_we => open,
      bram0_port1_we => open, bram1_port1_we => open, bram2_port1_we => open, bram3_port1_we => open,

      bram0_port0_en => r1_bram0_port0_en, bram1_port0_en => r1_bram1_port0_en,
      bram2_port0_en => r1_bram2_port0_en, bram3_port0_en => r1_bram3_port0_en,
      bram0_port1_en => r1_bram0_port1_en, bram1_port1_en => r1_bram1_port1_en,
      bram2_port1_en => r1_bram2_port1_en, bram3_port1_en => r1_bram3_port1_en,

      bram0_port0_data_in => open, bram1_port0_data_in => open, bram2_port0_data_in => open, bram3_port0_data_in => open,
      bram0_port1_data_in => open, bram1_port1_data_in => open, bram2_port1_data_in => open, bram3_port1_data_in => open,

      bram0_port0_data_out => bmu_read_bram0_port0_data_out, bram1_port0_data_out => bmu_read_bram1_port0_data_out,
      bram2_port0_data_out => bmu_read_bram2_port0_data_out, bram3_port0_data_out => bmu_read_bram3_port0_data_out,
      bram0_port1_data_out => bmu_read_bram0_port1_data_out, bram1_port1_data_out => bmu_read_bram1_port1_data_out,
      bram2_port1_data_out => bmu_read_bram2_port1_data_out, bram3_port1_data_out => bmu_read_bram3_port1_data_out,

      data_out_0 => bmu_read_1_data(0), data_out_1 => bmu_read_1_data(1),
      data_out_2 => bmu_read_1_data(2), data_out_3 => bmu_read_1_data(3),
      data_out_4 => open, data_out_5 => open, data_out_6 => open, data_out_7 => open,

      done => bmu_read_1_done
    );

  bmu_read_2_inst : entity work.bmu_read
    generic map (
      BUFFER_ADDR_WIDTH => BUFFER_ADDR_WIDTH,
      BUFFER_SIZE_BITS  => BUFFER_SIZE_BITS,
      LANES             => 4
    )
    port map (
      clk => clk, 
      rst => rst, 
      start => bmu_read_2_start, 
      count_en => s1b_en,

      buffer_start     => vec_bsr2,
      buffer_length    => std_logic_vector(resize(unsigned(vec_blr2), BUFFER_SIZE_BITS)),
      operation_start  => vec_osr2,
      operation_length => std_logic_vector(resize(unsigned(vec_olr2), BUFFER_SIZE_BITS)),

      bram0_port0_addr => r2_bram0_port0_addr, bram1_port0_addr => r2_bram1_port0_addr,
      bram2_port0_addr => r2_bram2_port0_addr, bram3_port0_addr => r2_bram3_port0_addr,
      bram0_port1_addr => r2_bram0_port1_addr, bram1_port1_addr => r2_bram1_port1_addr,
      bram2_port1_addr => r2_bram2_port1_addr, bram3_port1_addr => r2_bram3_port1_addr,

      bram0_port0_we => open, bram1_port0_we => open, bram2_port0_we => open, bram3_port0_we => open,
      bram0_port1_we => open, bram1_port1_we => open, bram2_port1_we => open, bram3_port1_we => open,

      bram0_port0_en => r2_bram0_port0_en, bram1_port0_en => r2_bram1_port0_en,
      bram2_port0_en => r2_bram2_port0_en, bram3_port0_en => r2_bram3_port0_en,
      bram0_port1_en => r2_bram0_port1_en, bram1_port1_en => r2_bram1_port1_en,
      bram2_port1_en => r2_bram2_port1_en, bram3_port1_en => r2_bram3_port1_en,

      bram0_port0_data_in => open, bram1_port0_data_in => open, bram2_port0_data_in => open, bram3_port0_data_in => open,
      bram0_port1_data_in => open, bram1_port1_data_in => open, bram2_port1_data_in => open, bram3_port1_data_in => open,

      bram0_port0_data_out => bmu_read_bram0_port0_data_out, bram1_port0_data_out => bmu_read_bram1_port0_data_out,
      bram2_port0_data_out => bmu_read_bram2_port0_data_out, bram3_port0_data_out => bmu_read_bram3_port0_data_out,
      bram0_port1_data_out => bmu_read_bram0_port1_data_out, bram1_port1_data_out => bmu_read_bram1_port1_data_out,
      bram2_port1_data_out => bmu_read_bram2_port1_data_out, bram3_port1_data_out => bmu_read_bram3_port1_data_out,

      data_out_0 => bmu_read_2_data(0), data_out_1 => bmu_read_2_data(1),
      data_out_2 => bmu_read_2_data(2), data_out_3 => bmu_read_2_data(3),
      data_out_4 => open, data_out_5 => open, data_out_6 => open, data_out_7 => open,

      done => bmu_read_2_done
    );

  --read mux
  bmu_read_bram0_port0_addr <= r1_bram0_port0_addr when sel_bmu_read = '0' else r2_bram0_port0_addr;
  bmu_read_bram1_port0_addr <= r1_bram1_port0_addr when sel_bmu_read = '0' else r2_bram1_port0_addr;
  bmu_read_bram2_port0_addr <= r1_bram2_port0_addr when sel_bmu_read = '0' else r2_bram2_port0_addr;
  bmu_read_bram3_port0_addr <= r1_bram3_port0_addr when sel_bmu_read = '0' else r2_bram3_port0_addr;
  bmu_read_bram0_port1_addr <= r1_bram0_port1_addr when sel_bmu_read = '0' else r2_bram0_port1_addr;
  bmu_read_bram1_port1_addr <= r1_bram1_port1_addr when sel_bmu_read = '0' else r2_bram1_port1_addr;
  bmu_read_bram2_port1_addr <= r1_bram2_port1_addr when sel_bmu_read = '0' else r2_bram2_port1_addr;
  bmu_read_bram3_port1_addr <= r1_bram3_port1_addr when sel_bmu_read = '0' else r2_bram3_port1_addr;

  bmu_read_bram0_port0_en <= r1_bram0_port0_en when sel_bmu_read = '0' else r2_bram0_port0_en;
  bmu_read_bram1_port0_en <= r1_bram1_port0_en when sel_bmu_read = '0' else r2_bram1_port0_en;
  bmu_read_bram2_port0_en <= r1_bram2_port0_en when sel_bmu_read = '0' else r2_bram2_port0_en;
  bmu_read_bram3_port0_en <= r1_bram3_port0_en when sel_bmu_read = '0' else r2_bram3_port0_en;
  bmu_read_bram0_port1_en <= r1_bram0_port1_en when sel_bmu_read = '0' else r2_bram0_port1_en;
  bmu_read_bram1_port1_en <= r1_bram1_port1_en when sel_bmu_read = '0' else r2_bram1_port1_en;
  bmu_read_bram2_port1_en <= r1_bram2_port1_en when sel_bmu_read = '0' else r2_bram2_port1_en;
  bmu_read_bram3_port1_en <= r1_bram3_port1_en when sel_bmu_read = '0' else r2_bram3_port1_en;

  bmu_read_bram0_port0_we <= '0'; bmu_read_bram1_port0_we <= '0'; bmu_read_bram2_port0_we <= '0'; bmu_read_bram3_port0_we <= '0';
  bmu_read_bram0_port1_we <= '0'; bmu_read_bram1_port1_we <= '0'; bmu_read_bram2_port1_we <= '0'; bmu_read_bram3_port1_we <= '0';

  bmu_read_bram0_port0_data_in <= (others => '0'); bmu_read_bram1_port0_data_in <= (others => '0');
  bmu_read_bram2_port0_data_in <= (others => '0'); bmu_read_bram3_port0_data_in <= (others => '0');
  bmu_read_bram0_port1_data_in <= (others => '0'); bmu_read_bram1_port1_data_in <= (others => '0');
  bmu_read_bram2_port1_data_in <= (others => '0'); bmu_read_bram3_port1_data_in <= (others => '0');

  bmu_read_sel_data <= bmu_read_1_data when sel_bmu_read = '0' else bmu_read_2_data;

  --s1a_en = bmu_read_1's addr/en valid on the bus; s2a_en = bmu_read_2's (one cycle after its count_en, s1b_en)
  sel_bmu_read <= '1' when s2a_en = '1' else '0';

  --align: split each 32-bit lane into 2x16-bit samples (15:0 even, 31:16 odd)
  next_s1b_buf1_data(0) <= bmu_read_1_data(0)(15 downto 0);
  next_s1b_buf1_data(1) <= bmu_read_1_data(0)(31 downto 16);
  next_s1b_buf1_data(2) <= bmu_read_1_data(1)(15 downto 0);
  next_s1b_buf1_data(3) <= bmu_read_1_data(1)(31 downto 16);
  next_s1b_buf1_data(4) <= bmu_read_1_data(2)(15 downto 0);
  next_s1b_buf1_data(5) <= bmu_read_1_data(2)(31 downto 16);
  next_s1b_buf1_data(6) <= bmu_read_1_data(3)(15 downto 0);
  next_s1b_buf1_data(7) <= bmu_read_1_data(3)(31 downto 16);

  buf2_data(0) <= bmu_read_2_data(0)(15 downto 0);
  buf2_data(1) <= bmu_read_2_data(0)(31 downto 16);
  buf2_data(2) <= bmu_read_2_data(1)(15 downto 0);
  buf2_data(3) <= bmu_read_2_data(1)(31 downto 16);
  buf2_data(4) <= bmu_read_2_data(2)(15 downto 0);
  buf2_data(5) <= bmu_read_2_data(2)(31 downto 16);
  buf2_data(6) <= bmu_read_2_data(3)(15 downto 0);
  buf2_data(7) <= bmu_read_2_data(3)(31 downto 16);

  bmu_write_inst : entity work.bmu_write
    generic map (
      BUFFER_ADDR_WIDTH => BUFFER_ADDR_WIDTH,
      BUFFER_SIZE_BITS  => BUFFER_SIZE_BITS,
      LANES             => 4
    )
    port map (
      clk => clk, 
      rst => rst, 
      start => bmu_write_start, 
      count_en => s3c_en,

      buffer_start     => vec_bsw,
      buffer_length    => std_logic_vector(resize(unsigned(vec_blw), BUFFER_SIZE_BITS)),
      operation_start  => vec_osw,
      operation_length => std_logic_vector(resize(unsigned(vec_olw), BUFFER_SIZE_BITS)),

      bram0_port0_addr => bmu_write_bram0_port0_addr, bram1_port0_addr => bmu_write_bram1_port0_addr,
      bram2_port0_addr => bmu_write_bram2_port0_addr, bram3_port0_addr => bmu_write_bram3_port0_addr,
      bram0_port1_addr => bmu_write_bram0_port1_addr, bram1_port1_addr => bmu_write_bram1_port1_addr,
      bram2_port1_addr => bmu_write_bram2_port1_addr, bram3_port1_addr => bmu_write_bram3_port1_addr,

      bram0_port0_we => bmu_write_bram0_port0_we, bram1_port0_we => bmu_write_bram1_port0_we,
      bram2_port0_we => bmu_write_bram2_port0_we, bram3_port0_we => bmu_write_bram3_port0_we,
      bram0_port1_we => bmu_write_bram0_port1_we, bram1_port1_we => bmu_write_bram1_port1_we,
      bram2_port1_we => bmu_write_bram2_port1_we, bram3_port1_we => bmu_write_bram3_port1_we,

      bram0_port0_en => bmu_write_bram0_port0_en, bram1_port0_en => bmu_write_bram1_port0_en,
      bram2_port0_en => bmu_write_bram2_port0_en, bram3_port0_en => bmu_write_bram3_port0_en,
      bram0_port1_en => bmu_write_bram0_port1_en, bram1_port1_en => bmu_write_bram1_port1_en,
      bram2_port1_en => bmu_write_bram2_port1_en, bram3_port1_en => bmu_write_bram3_port1_en,

      bram0_port0_data_in => bmu_write_bram0_port0_data_in, bram1_port0_data_in => bmu_write_bram1_port0_data_in,
      bram2_port0_data_in => bmu_write_bram2_port0_data_in, bram3_port0_data_in => bmu_write_bram3_port0_data_in,
      bram0_port1_data_in => bmu_write_bram0_port1_data_in, bram1_port1_data_in => bmu_write_bram1_port1_data_in,
      bram2_port1_data_in => bmu_write_bram2_port1_data_in, bram3_port1_data_in => bmu_write_bram3_port1_data_in,

      bram0_port0_data_out => bmu_write_bram0_port0_data_out, bram1_port0_data_out => bmu_write_bram1_port0_data_out,
      bram2_port0_data_out => bmu_write_bram2_port0_data_out, bram3_port0_data_out => bmu_write_bram3_port0_data_out,
      bram0_port1_data_out => bmu_write_bram0_port1_data_out, bram1_port1_data_out => bmu_write_bram1_port1_data_out,
      bram2_port1_data_out => bmu_write_bram2_port1_data_out, bram3_port1_data_out => bmu_write_bram3_port1_data_out,

      data_in_0 => bmu_write_data(0), data_in_1 => bmu_write_data(1),
      data_in_2 => bmu_write_data(2), data_in_3 => bmu_write_data(3),
      data_in_4 => (others => '0'), data_in_5 => (others => '0'),
      data_in_6 => (others => '0'), data_in_7 => (others => '0'),

      done => bmu_write_done
    );

    gen_dsp : for i in 0 to 7 generate

    dsp_i : entity work.vpu_dsp
        port map (
            clk => clk,
            a   => s2a_buf1_data(i),
            b   => dsp_b_in(i),
            c   => dsp_b_in(i),
            sel => dsp_op_sel(i),
            p   => dsp_out(i)
        );

    end generate gen_dsp;

  --dsp output alignment: sel_output_even/odd, 0 = raw, 1 = arithmetic shift for fixed point (P is signed)
  dsp_out_aligned(0) <= dsp_out(0)(15 downto 0) when sel_output_even = '0' else std_logic_vector(shift_right(signed(dsp_out(0)), FIXED_POINT_POSITION)(15 downto 0));
  dsp_out_aligned(1) <= dsp_out(1)(15 downto 0) when sel_output_odd  = '0' else std_logic_vector(shift_right(signed(dsp_out(1)), FIXED_POINT_POSITION)(15 downto 0));
  dsp_out_aligned(2) <= dsp_out(2)(15 downto 0) when sel_output_even = '0' else std_logic_vector(shift_right(signed(dsp_out(2)), FIXED_POINT_POSITION)(15 downto 0));
  dsp_out_aligned(3) <= dsp_out(3)(15 downto 0) when sel_output_odd  = '0' else std_logic_vector(shift_right(signed(dsp_out(3)), FIXED_POINT_POSITION)(15 downto 0));
  dsp_out_aligned(4) <= dsp_out(4)(15 downto 0) when sel_output_even = '0' else std_logic_vector(shift_right(signed(dsp_out(4)), FIXED_POINT_POSITION)(15 downto 0));
  dsp_out_aligned(5) <= dsp_out(5)(15 downto 0) when sel_output_odd  = '0' else std_logic_vector(shift_right(signed(dsp_out(5)), FIXED_POINT_POSITION)(15 downto 0));
  dsp_out_aligned(6) <= dsp_out(6)(15 downto 0) when sel_output_even = '0' else std_logic_vector(shift_right(signed(dsp_out(6)), FIXED_POINT_POSITION)(15 downto 0));
  dsp_out_aligned(7) <= dsp_out(7)(15 downto 0) when sel_output_odd  = '0' else std_logic_vector(shift_right(signed(dsp_out(7)), FIXED_POINT_POSITION)(15 downto 0));

  --pack: 2x16-bit samples per 32-bit bmu_write lane (even->15:0, odd->31:16)
  bmu_write_data(0) <= dsp_out_aligned(1) & dsp_out_aligned(0);
  bmu_write_data(1) <= dsp_out_aligned(3) & dsp_out_aligned(2);
  bmu_write_data(2) <= dsp_out_aligned(5) & dsp_out_aligned(4);
  bmu_write_data(3) <= dsp_out_aligned(7) & dsp_out_aligned(6);

  process(clk, rst)
    begin
      if rst = '0' then
            s1a_en <= '0';
            s1b_en <= '0';
            s2a_en <= '0';
            s2b_en <= '0';
            s3a_en <= '0';
            s3b_en <= '0';
            s3c_en <= '0';

            s1b_buf1_data <= (others => (others => '0'));
            s2a_buf1_data <= (others => (others => '0'));

        elsif rising_edge(clk) then
            s1a_en <= next_s1a_en;
            s1b_en <= next_s1b_en;
            s2a_en <= next_s2a_en;
            s2b_en <= next_s2b_en;
            s3a_en <= next_s3a_en;
            s3b_en <= next_s3b_en;
            s3c_en <= next_s3c_en;

            s1b_buf1_data <= next_s1b_buf1_data;
            s2a_buf1_data <= next_s2a_buf1_data;
        end if;
  end process;

  next_s1a_en <= bmu_count_en;
  next_s1b_en <= s1a_en;
  next_s2a_en <= s1b_en;
  next_s2b_en <= s2a_en;
  next_s3a_en <= s2b_en;
  next_s3b_en <= s3a_en;
  next_s3c_en <= s3b_en;

  next_s2a_buf1_data <= s1b_buf1_data;

  dsp_b_in <= buf2_data when sel_scal_in = '0' else (others => vec_scalar);

end Behavioral;
