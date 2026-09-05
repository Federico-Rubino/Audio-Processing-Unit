library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.apu_opcode_pkg.all;
use work.apu_internal_pkg.all;

entity tb_audio_cu_load is
end tb_audio_cu_load;

architecture sim of tb_audio_cu_load is

    constant CLK_PERIOD : time := 10 ns;

    constant ARAM_WORD_SIZE  : integer := 32;
    constant ARAM_ADDR_SIZE  : integer := 16;
    constant INSTR_ADDR_SIZE : integer := 11;
    constant UPARAM_SIZE     : integer := 9;
    constant INSTR_SIZE      : integer := 128;
    constant COUNTER_SIZE    : integer := 16;

    constant DEST_ROW : integer := 10; -- a-ram destination row for this test

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    -- AudioCU <-> CU-facing memory (instr + both param tables)
    signal iwe, ien : std_logic;
    signal iaddr     : std_logic_vector(INSTR_ADDR_SIZE-1 downto 0);
    signal idata_in  : std_logic_vector(ARAM_WORD_SIZE-1 downto 0);
    signal idata_out : std_logic_vector(ARAM_WORD_SIZE-1 downto 0) := (others => '0');

    signal unit_select : apu_unit_t;

    -- unused unit interfaces
    signal aio_new_grain, aio_in_end, aio_out_end : std_logic := '0';
    signal aio_in_en, aio_in_lr : std_logic;
    signal aio_in_bs, aio_in_bl, aio_in_os, aio_in_ol : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal aio_out_en, aio_out_lr : std_logic;
    signal aio_out_bs, aio_out_bl, aio_out_os, aio_out_ol : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal fft_end : std_logic := '0';
    signal fft_en, fft_size, fwd_inv : std_logic;
    signal fft_bsr, fft_blr, fft_osr, fft_olr : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal fft_bsw, fft_blw, fft_osw, fft_olw : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal vec_end : std_logic := '0';
    signal vec_en : std_logic;
    signal vec_op : vec_op_t;
    signal vec_scalar : std_logic_vector(15 downto 0);
    signal vec_bsr1, vec_blr1, vec_osr1, vec_olr1 : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal vec_bsr2, vec_blr2, vec_osr2, vec_olr2 : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal vec_bsw, vec_blw, vec_osw, vec_olw : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);

    -- AudioCU <-> load unit
    signal load_en, load_count_en, load_end : std_logic;
    signal load_bs, load_bl, load_os, load_ol : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal load_data : std_logic_vector(ARAM_WORD_SIZE-1 downto 0);

    -- load unit's bmu_write <-> aram_mux
    signal l_addr0, l_addr1, l_addr2, l_addr3 : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal l_addr0_p1, l_addr1_p1, l_addr2_p1, l_addr3_p1 : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal l_we0, l_we1, l_we2, l_we3 : std_logic;
    signal l_we0_p1, l_we1_p1, l_we2_p1, l_we3_p1 : std_logic;
    signal l_en0, l_en1, l_en2, l_en3 : std_logic;
    signal l_en0_p1, l_en1_p1, l_en2_p1, l_en3_p1 : std_logic;
    signal l_din0, l_din1, l_din2, l_din3 : std_logic_vector(31 downto 0);
    signal l_din0_p1, l_din1_p1, l_din2_p1, l_din3_p1 : std_logic_vector(31 downto 0);
    signal l_dout0, l_dout1, l_dout2, l_dout3 : std_logic_vector(31 downto 0) := (others => '0');
    signal l_dout0_p1, l_dout1_p1, l_dout2_p1, l_dout3_p1 : std_logic_vector(31 downto 0) := (others => '0');

    -- aram_mux <-> real a-ram (this test only drives the LOAD unit's bus,
    -- so every other unit's ports are tied to idle/open)
    signal bram0_addr, bram1_addr, bram2_addr, bram3_addr : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal bram0_addr_p1, bram1_addr_p1, bram2_addr_p1, bram3_addr_p1 : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal bram0_we, bram1_we, bram2_we, bram3_we : std_logic;
    signal bram0_we_p1, bram1_we_p1, bram2_we_p1, bram3_we_p1 : std_logic;
    signal bram0_en, bram1_en, bram2_en, bram3_en : std_logic;
    signal bram0_en_p1, bram1_en_p1, bram2_en_p1, bram3_en_p1 : std_logic;
    signal bram0_din, bram1_din, bram2_din, bram3_din : std_logic_vector(31 downto 0);
    signal bram0_din_p1, bram1_din_p1, bram2_din_p1, bram3_din_p1 : std_logic_vector(31 downto 0);
    signal bram0_dout, bram1_dout, bram2_dout, bram3_dout : std_logic_vector(31 downto 0) := (others => '0');
    signal bram0_dout_p1, bram1_dout_p1, bram2_dout_p1, bram3_dout_p1 : std_logic_vector(31 downto 0) := (others => '0');

    -- behavioral a-ram: 64 rows/bram is plenty for this test
    type bram_mem_t is array (0 to 63) of std_logic_vector(31 downto 0);
    signal bram0_mem, bram1_mem, bram2_mem, bram3_mem : bram_mem_t := (others => (others => '0'));

    -- behavioral CU-facing memory: instr region (2048 words) + 2 param
    -- tables (512 words each)
    type instr_mem_t is array (0 to 2**INSTR_ADDR_SIZE-1) of std_logic_vector(31 downto 0);
    type param_mem_t is array (0 to 511) of std_logic_vector(31 downto 0);
    signal mem_instr : instr_mem_t := (others => (others => '0'));
    signal mem_param_left : param_mem_t := (others => (others => '0'));
    signal mem_param_right : param_mem_t := (others => (others => '0'));

begin

    clk <= not clk after CLK_PERIOD / 2;


    dut : entity work.AudioCU
        generic map (
            ARAM_WORD_SIZE  => ARAM_WORD_SIZE, ARAM_ADDR_SIZE => ARAM_ADDR_SIZE,
            INSTR_ADDR_SIZE => INSTR_ADDR_SIZE, UPARAM_SIZE => UPARAM_SIZE,
            INSTR_SIZE      => INSTR_SIZE, COUNTER_SIZE => COUNTER_SIZE
        )
        port map (
            clk => clk, rst => rst,
            unit_select => unit_select,
            iwe => iwe, ien => ien, iaddr => iaddr, idata_in => idata_in, idata_out => idata_out,

            aio_new_grain => aio_new_grain, aio_in_end => aio_in_end, aio_out_end => aio_out_end,
            aio_in_en => aio_in_en, aio_in_lr => aio_in_lr,
            aio_in_bs => aio_in_bs, aio_in_bl => aio_in_bl, aio_in_os => aio_in_os, aio_in_ol => aio_in_ol,
            aio_out_en => aio_out_en, aio_out_lr => aio_out_lr,
            aio_out_bs => aio_out_bs, aio_out_bl => aio_out_bl, aio_out_os => aio_out_os, aio_out_ol => aio_out_ol,

            fft_end => fft_end, fft_en => fft_en, fft_size => fft_size, fwd_inv => fwd_inv,
            fft_bsr => fft_bsr, fft_blr => fft_blr, fft_osr => fft_osr, fft_olr => fft_olr,
            fft_bsw => fft_bsw, fft_blw => fft_blw, fft_osw => fft_osw, fft_olw => fft_olw,

            vec_end => vec_end, vec_en => vec_en, vec_op => vec_op, vec_scalar => vec_scalar,
            vec_bsr1 => vec_bsr1, vec_blr1 => vec_blr1, vec_osr1 => vec_osr1, vec_olr1 => vec_olr1,
            vec_bsr2 => vec_bsr2, vec_blr2 => vec_blr2, vec_osr2 => vec_osr2, vec_olr2 => vec_olr2,
            vec_bsw => vec_bsw, vec_blw => vec_blw, vec_osw => vec_osw, vec_olw => vec_olw,

            load_end => load_end, load_en => load_en, load_count_en => load_count_en,
            load_bs => load_bs, load_bl => load_bl, load_os => load_os, load_ol => load_ol,
            load_data => load_data
        );

    load_bmu_write_inst : entity work.bmu_write
        generic map (
            BUFFER_ADDR_WIDTH => ARAM_ADDR_SIZE, BUFFER_SIZE_BITS => ARAM_WORD_SIZE, LANES => 1
        )
        port map (
            clk => clk, rst => rst, start => load_en, count_en => load_count_en,

            buffer_start     => load_bs,
            buffer_length    => std_logic_vector(resize(unsigned(load_bl), ARAM_WORD_SIZE)),
            operation_start  => load_os,
            operation_length => std_logic_vector(resize(unsigned(load_ol), ARAM_WORD_SIZE)),

            bram0_port0_addr => l_addr0, bram1_port0_addr => l_addr1,
            bram2_port0_addr => l_addr2, bram3_port0_addr => l_addr3,
            bram0_port1_addr => l_addr0_p1, bram1_port1_addr => l_addr1_p1,
            bram2_port1_addr => l_addr2_p1, bram3_port1_addr => l_addr3_p1,

            bram0_port0_we => l_we0, bram1_port0_we => l_we1,
            bram2_port0_we => l_we2, bram3_port0_we => l_we3,
            bram0_port1_we => l_we0_p1, bram1_port1_we => l_we1_p1,
            bram2_port1_we => l_we2_p1, bram3_port1_we => l_we3_p1,

            bram0_port0_en => l_en0, bram1_port0_en => l_en1,
            bram2_port0_en => l_en2, bram3_port0_en => l_en3,
            bram0_port1_en => l_en0_p1, bram1_port1_en => l_en1_p1,
            bram2_port1_en => l_en2_p1, bram3_port1_en => l_en3_p1,

            bram0_port0_data_in => l_din0, bram1_port0_data_in => l_din1,
            bram2_port0_data_in => l_din2, bram3_port0_data_in => l_din3,
            bram0_port1_data_in => l_din0_p1, bram1_port1_data_in => l_din1_p1,
            bram2_port1_data_in => l_din2_p1, bram3_port1_data_in => l_din3_p1,

            bram0_port0_data_out => l_dout0, bram1_port0_data_out => l_dout1,
            bram2_port0_data_out => l_dout2, bram3_port0_data_out => l_dout3,
            bram0_port1_data_out => l_dout0_p1, bram1_port1_data_out => l_dout1_p1,
            bram2_port1_data_out => l_dout2_p1, bram3_port1_data_out => l_dout3_p1,

            data_in_0 => load_data,
            data_in_1 => (others => '0'), data_in_2 => (others => '0'), data_in_3 => (others => '0'),
            data_in_4 => (others => '0'), data_in_5 => (others => '0'),
            data_in_6 => (others => '0'), data_in_7 => (others => '0'),

            done => load_end
        );

    ------------------------------------------------------------------
    -- aram_mux: only the LOAD unit's bus is driven; everything else idle
    ------------------------------------------------------------------
    mux : entity work.aram_mux
        generic map (
            BUFFER_ADDR_WIDTH => ARAM_ADDR_SIZE, BUFFER_SIZE_BITS => ARAM_WORD_SIZE
        )
        port map (
            unit_select => unit_select,

            ain_bram0_port0_addr => (others => '0'), ain_bram1_port0_addr => (others => '0'),
            ain_bram2_port0_addr => (others => '0'), ain_bram3_port0_addr => (others => '0'),
            ain_bram0_port1_addr => (others => '0'), ain_bram1_port1_addr => (others => '0'),
            ain_bram2_port1_addr => (others => '0'), ain_bram3_port1_addr => (others => '0'),
            ain_bram0_port0_we => '0', ain_bram1_port0_we => '0', ain_bram2_port0_we => '0', ain_bram3_port0_we => '0',
            ain_bram0_port1_we => '0', ain_bram1_port1_we => '0', ain_bram2_port1_we => '0', ain_bram3_port1_we => '0',
            ain_bram0_port0_en => '0', ain_bram1_port0_en => '0', ain_bram2_port0_en => '0', ain_bram3_port0_en => '0',
            ain_bram0_port1_en => '0', ain_bram1_port1_en => '0', ain_bram2_port1_en => '0', ain_bram3_port1_en => '0',
            ain_bram0_port0_data_in => (others => '0'), ain_bram1_port0_data_in => (others => '0'),
            ain_bram2_port0_data_in => (others => '0'), ain_bram3_port0_data_in => (others => '0'),
            ain_bram0_port1_data_in => (others => '0'), ain_bram1_port1_data_in => (others => '0'),
            ain_bram2_port1_data_in => (others => '0'), ain_bram3_port1_data_in => (others => '0'),
            ain_bram0_port0_data_out => open, ain_bram1_port0_data_out => open,
            ain_bram2_port0_data_out => open, ain_bram3_port0_data_out => open,
            ain_bram0_port1_data_out => open, ain_bram1_port1_data_out => open,
            ain_bram2_port1_data_out => open, ain_bram3_port1_data_out => open,

            aout_bram0_port0_addr => (others => '0'), aout_bram1_port0_addr => (others => '0'),
            aout_bram2_port0_addr => (others => '0'), aout_bram3_port0_addr => (others => '0'),
            aout_bram0_port1_addr => (others => '0'), aout_bram1_port1_addr => (others => '0'),
            aout_bram2_port1_addr => (others => '0'), aout_bram3_port1_addr => (others => '0'),
            aout_bram0_port0_we => '0', aout_bram1_port0_we => '0', aout_bram2_port0_we => '0', aout_bram3_port0_we => '0',
            aout_bram0_port1_we => '0', aout_bram1_port1_we => '0', aout_bram2_port1_we => '0', aout_bram3_port1_we => '0',
            aout_bram0_port0_en => '0', aout_bram1_port0_en => '0', aout_bram2_port0_en => '0', aout_bram3_port0_en => '0',
            aout_bram0_port1_en => '0', aout_bram1_port1_en => '0', aout_bram2_port1_en => '0', aout_bram3_port1_en => '0',
            aout_bram0_port0_data_in => (others => '0'), aout_bram1_port0_data_in => (others => '0'),
            aout_bram2_port0_data_in => (others => '0'), aout_bram3_port0_data_in => (others => '0'),
            aout_bram0_port1_data_in => (others => '0'), aout_bram1_port1_data_in => (others => '0'),
            aout_bram2_port1_data_in => (others => '0'), aout_bram3_port1_data_in => (others => '0'),
            aout_bram0_port0_data_out => open, aout_bram1_port0_data_out => open,
            aout_bram2_port0_data_out => open, aout_bram3_port0_data_out => open,
            aout_bram0_port1_data_out => open, aout_bram1_port1_data_out => open,
            aout_bram2_port1_data_out => open, aout_bram3_port1_data_out => open,

            vpu_bram0_port0_addr => (others => '0'), vpu_bram1_port0_addr => (others => '0'),
            vpu_bram2_port0_addr => (others => '0'), vpu_bram3_port0_addr => (others => '0'),
            vpu_bram0_port1_addr => (others => '0'), vpu_bram1_port1_addr => (others => '0'),
            vpu_bram2_port1_addr => (others => '0'), vpu_bram3_port1_addr => (others => '0'),
            vpu_bram0_port0_we => '0', vpu_bram1_port0_we => '0', vpu_bram2_port0_we => '0', vpu_bram3_port0_we => '0',
            vpu_bram0_port1_we => '0', vpu_bram1_port1_we => '0', vpu_bram2_port1_we => '0', vpu_bram3_port1_we => '0',
            vpu_bram0_port0_en => '0', vpu_bram1_port0_en => '0', vpu_bram2_port0_en => '0', vpu_bram3_port0_en => '0',
            vpu_bram0_port1_en => '0', vpu_bram1_port1_en => '0', vpu_bram2_port1_en => '0', vpu_bram3_port1_en => '0',
            vpu_bram0_port0_data_in => (others => '0'), vpu_bram1_port0_data_in => (others => '0'),
            vpu_bram2_port0_data_in => (others => '0'), vpu_bram3_port0_data_in => (others => '0'),
            vpu_bram0_port1_data_in => (others => '0'), vpu_bram1_port1_data_in => (others => '0'),
            vpu_bram2_port1_data_in => (others => '0'), vpu_bram3_port1_data_in => (others => '0'),
            vpu_bram0_port0_data_out => open, vpu_bram1_port0_data_out => open,
            vpu_bram2_port0_data_out => open, vpu_bram3_port0_data_out => open,
            vpu_bram0_port1_data_out => open, vpu_bram1_port1_data_out => open,
            vpu_bram2_port1_data_out => open, vpu_bram3_port1_data_out => open,

            fft_bram0_port0_addr => (others => '0'), fft_bram1_port0_addr => (others => '0'),
            fft_bram2_port0_addr => (others => '0'), fft_bram3_port0_addr => (others => '0'),
            fft_bram0_port1_addr => (others => '0'), fft_bram1_port1_addr => (others => '0'),
            fft_bram2_port1_addr => (others => '0'), fft_bram3_port1_addr => (others => '0'),
            fft_bram0_port0_we => '0', fft_bram1_port0_we => '0', fft_bram2_port0_we => '0', fft_bram3_port0_we => '0',
            fft_bram0_port1_we => '0', fft_bram1_port1_we => '0', fft_bram2_port1_we => '0', fft_bram3_port1_we => '0',
            fft_bram0_port0_en => '0', fft_bram1_port0_en => '0', fft_bram2_port0_en => '0', fft_bram3_port0_en => '0',
            fft_bram0_port1_en => '0', fft_bram1_port1_en => '0', fft_bram2_port1_en => '0', fft_bram3_port1_en => '0',
            fft_bram0_port0_data_in => (others => '0'), fft_bram1_port0_data_in => (others => '0'),
            fft_bram2_port0_data_in => (others => '0'), fft_bram3_port0_data_in => (others => '0'),
            fft_bram0_port1_data_in => (others => '0'), fft_bram1_port1_data_in => (others => '0'),
            fft_bram2_port1_data_in => (others => '0'), fft_bram3_port1_data_in => (others => '0'),
            fft_bram0_port0_data_out => open, fft_bram1_port0_data_out => open,
            fft_bram2_port0_data_out => open, fft_bram3_port0_data_out => open,
            fft_bram0_port1_data_out => open, fft_bram1_port1_data_out => open,
            fft_bram2_port1_data_out => open, fft_bram3_port1_data_out => open,

            ps_bram0_port0_addr => (others => '0'), ps_bram1_port0_addr => (others => '0'),
            ps_bram2_port0_addr => (others => '0'), ps_bram3_port0_addr => (others => '0'),
            ps_bram0_port1_addr => (others => '0'), ps_bram1_port1_addr => (others => '0'),
            ps_bram2_port1_addr => (others => '0'), ps_bram3_port1_addr => (others => '0'),
            ps_bram0_port0_we => '0', ps_bram1_port0_we => '0', ps_bram2_port0_we => '0', ps_bram3_port0_we => '0',
            ps_bram0_port1_we => '0', ps_bram1_port1_we => '0', ps_bram2_port1_we => '0', ps_bram3_port1_we => '0',
            ps_bram0_port0_en => '0', ps_bram1_port0_en => '0', ps_bram2_port0_en => '0', ps_bram3_port0_en => '0',
            ps_bram0_port1_en => '0', ps_bram1_port1_en => '0', ps_bram2_port1_en => '0', ps_bram3_port1_en => '0',
            ps_bram0_port0_data_in => (others => '0'), ps_bram1_port0_data_in => (others => '0'),
            ps_bram2_port0_data_in => (others => '0'), ps_bram3_port0_data_in => (others => '0'),
            ps_bram0_port1_data_in => (others => '0'), ps_bram1_port1_data_in => (others => '0'),
            ps_bram2_port1_data_in => (others => '0'), ps_bram3_port1_data_in => (others => '0'),
            ps_bram0_port0_data_out => open, ps_bram1_port0_data_out => open,
            ps_bram2_port0_data_out => open, ps_bram3_port0_data_out => open,
            ps_bram0_port1_data_out => open, ps_bram1_port1_data_out => open,
            ps_bram2_port1_data_out => open, ps_bram3_port1_data_out => open,

            load_bram0_port0_addr => l_addr0, load_bram1_port0_addr => l_addr1,
            load_bram2_port0_addr => l_addr2, load_bram3_port0_addr => l_addr3,
            load_bram0_port1_addr => l_addr0_p1, load_bram1_port1_addr => l_addr1_p1,
            load_bram2_port1_addr => l_addr2_p1, load_bram3_port1_addr => l_addr3_p1,
            load_bram0_port0_we => l_we0, load_bram1_port0_we => l_we1,
            load_bram2_port0_we => l_we2, load_bram3_port0_we => l_we3,
            load_bram0_port1_we => l_we0_p1, load_bram1_port1_we => l_we1_p1,
            load_bram2_port1_we => l_we2_p1, load_bram3_port1_we => l_we3_p1,
            load_bram0_port0_en => l_en0, load_bram1_port0_en => l_en1,
            load_bram2_port0_en => l_en2, load_bram3_port0_en => l_en3,
            load_bram0_port1_en => l_en0_p1, load_bram1_port1_en => l_en1_p1,
            load_bram2_port1_en => l_en2_p1, load_bram3_port1_en => l_en3_p1,
            load_bram0_port0_data_in => l_din0, load_bram1_port0_data_in => l_din1,
            load_bram2_port0_data_in => l_din2, load_bram3_port0_data_in => l_din3,
            load_bram0_port1_data_in => l_din0_p1, load_bram1_port1_data_in => l_din1_p1,
            load_bram2_port1_data_in => l_din2_p1, load_bram3_port1_data_in => l_din3_p1,
            load_bram0_port0_data_out => l_dout0, load_bram1_port0_data_out => l_dout1,
            load_bram2_port0_data_out => l_dout2, load_bram3_port0_data_out => l_dout3,
            load_bram0_port1_data_out => l_dout0_p1, load_bram1_port1_data_out => l_dout1_p1,
            load_bram2_port1_data_out => l_dout2_p1, load_bram3_port1_data_out => l_dout3_p1,

            bram0_port0_addr => bram0_addr, bram1_port0_addr => bram1_addr,
            bram2_port0_addr => bram2_addr, bram3_port0_addr => bram3_addr,
            bram0_port1_addr => bram0_addr_p1, bram1_port1_addr => bram1_addr_p1,
            bram2_port1_addr => bram2_addr_p1, bram3_port1_addr => bram3_addr_p1,
            bram0_port0_we => bram0_we, bram1_port0_we => bram1_we,
            bram2_port0_we => bram2_we, bram3_port0_we => bram3_we,
            bram0_port1_we => bram0_we_p1, bram1_port1_we => bram1_we_p1,
            bram2_port1_we => bram2_we_p1, bram3_port1_we => bram3_we_p1,
            bram0_port0_en => bram0_en, bram1_port0_en => bram1_en,
            bram2_port0_en => bram2_en, bram3_port0_en => bram3_en,
            bram0_port1_en => bram0_en_p1, bram1_port1_en => bram1_en_p1,
            bram2_port1_en => bram2_en_p1, bram3_port1_en => bram3_en_p1,
            bram0_port0_data_in => bram0_din, bram1_port0_data_in => bram1_din,
            bram2_port0_data_in => bram2_din, bram3_port0_data_in => bram3_din,
            bram0_port1_data_in => bram0_din_p1, bram1_port1_data_in => bram1_din_p1,
            bram2_port1_data_in => bram2_din_p1, bram3_port1_data_in => bram3_din_p1,
            bram0_port0_data_out => bram0_dout, bram1_port0_data_out => bram1_dout,
            bram2_port0_data_out => bram2_dout, bram3_port0_data_out => bram3_dout,
            bram0_port1_data_out => bram0_dout_p1, bram1_port1_data_out => bram1_dout_p1,
            bram2_port1_data_out => bram2_dout_p1, bram3_port1_data_out => bram3_dout_p1
        );


    aram_proc : process(clk)
    begin
        if rising_edge(clk) then
            if bram0_en = '1' then
                if bram0_we = '1' then bram0_mem(to_integer(unsigned(bram0_addr))) <= bram0_din; end if;
                bram0_dout <= bram0_mem(to_integer(unsigned(bram0_addr)));
            end if;
            if bram1_en = '1' then
                if bram1_we = '1' then bram1_mem(to_integer(unsigned(bram1_addr))) <= bram1_din; end if;
                bram1_dout <= bram1_mem(to_integer(unsigned(bram1_addr)));
            end if;
            if bram2_en = '1' then
                if bram2_we = '1' then bram2_mem(to_integer(unsigned(bram2_addr))) <= bram2_din; end if;
                bram2_dout <= bram2_mem(to_integer(unsigned(bram2_addr)));
            end if;
            if bram3_en = '1' then
                if bram3_we = '1' then bram3_mem(to_integer(unsigned(bram3_addr))) <= bram3_din; end if;
                bram3_dout <= bram3_mem(to_integer(unsigned(bram3_addr)));
            end if;
            -- port1 side is unused at LANES=1, modeled as read-only/no-op
        end if;
    end process;


    cu_mem_proc : process(clk, rst)
        variable addr9 : integer;
    begin
        -- seed instructions/params here (not in `stim`) -- this is the only
        -- process that ever drives mem_instr/mem_param_*, avoiding a
        -- multiple-driver 'X' conflict on a signal written from two places
        if rst = '0' then
            mem_instr(2) <= x"b0000000";
            mem_instr(3) <= x"00000000";
            mem_instr(4) <= x"00000004";
            mem_instr(5) <= x"02050483";
            mem_instr(6) <= x"f0000000";
            mem_instr(7) <= x"00000000";
            mem_instr(8) <= x"00000000";
            mem_instr(9) <= x"00000000";
            mem_instr(1) <= x"00000001";

            for k in 0 to 127 loop
                mem_param_left(k) <= std_logic_vector(to_unsigned(16#1000# + k, 32));
            end loop;
            -- bmu_addr_gen's row_cursor is initialized from operation_start
            -- directly (not buffer_start) -- operation_start_reg must hold
            -- the actual destination row, not just buffer_start_reg
            mem_param_left(128) <= std_logic_vector(to_unsigned(DEST_ROW, 32));
            mem_param_left(129) <= std_logic_vector(to_unsigned(128, 32));
            mem_param_left(130) <= std_logic_vector(to_unsigned(DEST_ROW, 32));
            mem_param_left(131) <= std_logic_vector(to_unsigned(128, 32));

        elsif rising_edge(clk) then
            if ien = '1' then
                if iaddr(UPARAM_SIZE+1) = '1' then
                    addr9 := to_integer(unsigned(iaddr(UPARAM_SIZE-1 downto 0)));
                    if iaddr(UPARAM_SIZE) = '0' then
                        idata_out <= mem_param_left(addr9);
                    else
                        idata_out <= mem_param_right(addr9);
                    end if;
                else
                    idata_out <= mem_instr(to_integer(unsigned(iaddr)));
                end if;
            end if;
            if iwe = '1' then
                if iaddr(UPARAM_SIZE+1) = '1' then
                    addr9 := to_integer(unsigned(iaddr(UPARAM_SIZE-1 downto 0)));
                    if iaddr(UPARAM_SIZE) = '0' then
                        mem_param_left(addr9) <= idata_in;
                    else
                        mem_param_right(addr9) <= idata_in;
                    end if;
                else
                    mem_instr(to_integer(unsigned(iaddr))) <= idata_in;
                end if;
            end if;
        end if;
    end process;

  
    stim : process
        variable errors : integer := 0;

        procedure check(actual, expected : std_logic_vector; msg : string) is
        begin
            if actual /= expected then
                report "FAIL: " & msg & " expected=" & integer'image(to_integer(unsigned(expected)))
                       & " actual=" & integer'image(to_integer(unsigned(actual))) severity error;
                errors := errors + 1;
            end if;
        end procedure;

    begin
        -- instr/param memory is seeded inside cu_mem_proc's.
        rst <= '0';
        wait for CLK_PERIOD * 3;
        rst <= '1';


        wait for CLK_PERIOD * 400;

        report "checking a-ram content written by LOAD...";

        -- k=0: bram0..3 @ row DEST_ROW should hold param[0..3]
        check(bram0_mem(DEST_ROW), std_logic_vector(to_unsigned(16#1000# + 0, 32)), "bram0 row10 (param0)");
        check(bram1_mem(DEST_ROW), std_logic_vector(to_unsigned(16#1000# + 1, 32)), "bram1 row10 (param1)");
        check(bram2_mem(DEST_ROW), std_logic_vector(to_unsigned(16#1000# + 2, 32)), "bram2 row10 (param2)");
        check(bram3_mem(DEST_ROW), std_logic_vector(to_unsigned(16#1000# + 3, 32)), "bram3 row10 (param3)");

        -- k=15 (mid-buffer): row = DEST_ROW+15, params 60..63
        check(bram0_mem(DEST_ROW+15), std_logic_vector(to_unsigned(16#1000# + 60, 32)), "bram0 row25 (param60)");
        check(bram1_mem(DEST_ROW+15), std_logic_vector(to_unsigned(16#1000# + 61, 32)), "bram1 row25 (param61)");
        check(bram2_mem(DEST_ROW+15), std_logic_vector(to_unsigned(16#1000# + 62, 32)), "bram2 row25 (param62)");
        check(bram3_mem(DEST_ROW+15), std_logic_vector(to_unsigned(16#1000# + 63, 32)), "bram3 row25 (param63)");

        -- k=31 (last group): row = DEST_ROW+31, params 124..127
        check(bram0_mem(DEST_ROW+31), std_logic_vector(to_unsigned(16#1000# + 124, 32)), "bram0 row41 (param124)");
        check(bram1_mem(DEST_ROW+31), std_logic_vector(to_unsigned(16#1000# + 125, 32)), "bram1 row41 (param125)");
        check(bram2_mem(DEST_ROW+31), std_logic_vector(to_unsigned(16#1000# + 126, 32)), "bram2 row41 (param126)");
        check(bram3_mem(DEST_ROW+31), std_logic_vector(to_unsigned(16#1000# + 127, 32)), "bram3 row41 (param127)");

        if errors = 0 then
            report "PASS: all checked rows match the expected pattern" severity note;
        else
            report "FAIL: " & integer'image(errors) & " mismatch(es)" severity error;
        end if;

        wait;
    end process;

end sim;
