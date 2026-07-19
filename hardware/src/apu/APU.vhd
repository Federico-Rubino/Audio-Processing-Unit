library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.apu_opcode_pkg.all;
use work.apu_internal_pkg.all;

-- Top-level APU: AudioCU (instruction fetch/decode/execute) + AudioIO unit,
-- connected to the shared a-ram through aram_mux.
--
-- All memory lives inside APU, as named BRAM instances below -- create
-- matching Vivado Block Memory Generator IPs with these same names to back
-- them:
--   instr_bram          : dual-port, instructions + params + CPU<->CU comms
--   aram_bram0..aram_bram3 : dual-port, the 4 row-major a-ram lanes
--
-- instr_bram's port A is the only memory port exposed outside APU
-- (we/en/addr/data_in/data_out) -- an axi_bram_ctrl's BRAM-facing port
-- connects here, giving the CPU AXI access. Port B is AudioCU's own,
-- entirely internal.
--
-- FFT/Parallel-ALU units don't exist yet, so AudioCU's fft_*/vec_* control
-- outputs are left open and their *_end inputs tied low -- shaders using
-- those opcodes will stall forever until those units are built. Same for
-- aram_mux's vpu_*/fft_*/ps_* ports: tied to idle/open since only AudioIO
-- is wired up "for now" per the current scope.
entity APU is
    Generic (
        ARAM_WORD_SIZE    : integer := 32;    -- word size of aram and iram
        ARAM_ADDR_SIZE    : integer := 16;    -- width of the resolved (post param-lookup) buffer fields inside AudioCU
        INSTR_ADDR_SIZE   : integer := 11;    -- size needed to address a instruction RAM location
        UPARAM_SIZE       : integer := 9;     -- size of a uniform param address
        INSTR_SIZE        : integer := 128;   -- currently the max is 4*ARAM_WORD_SIZE
        COUNTER_SIZE      : integer := 16
    );
    Port (
        clk, rst : in std_logic;

        -- ADAU
        AC_ADR0  : out   std_logic;
        AC_ADR1  : out   std_logic;
        AC_GPIO0 : out   std_logic;
        AC_GPIO1 : in    std_logic;
        AC_GPIO2 : in    std_logic;
        AC_GPIO3 : in    std_logic;
        AC_MCLK  : out   std_logic;
        AC_SCK   : out   std_logic;
        AC_SDA   : inout std_logic;

        -- instr_bram port A: CPU/AXI side (axi_bram_ctrl connects here)
        we, en   : in  std_logic;
        addr     : in  std_logic_vector(INSTR_ADDR_SIZE-1 downto 0);
        data_in  : in  std_logic_vector(ARAM_WORD_SIZE-1 downto 0);
        data_out : out std_logic_vector(ARAM_WORD_SIZE-1 downto 0)
    );
end APU;

architecture Behavioral of APU is

    -- AudioCU <-> aram_mux
    signal unit_select_sig : apu_unit_t;

    -- AudioCU <-> instr_bram port B (fully internal)
    signal iwe_sig, ien_sig     : std_logic;
    signal iaddr_sig            : std_logic_vector(INSTR_ADDR_SIZE-1 downto 0);
    signal idata_in_sig         : std_logic_vector(ARAM_WORD_SIZE-1 downto 0);
    signal idata_out_sig        : std_logic_vector(ARAM_WORD_SIZE-1 downto 0);

    -- AudioCU <-> audioIO (CU control side)
    signal aio_new_grain_sig, aio_in_end_sig, aio_out_end_sig : std_logic;
    signal aio_in_en_sig, aio_in_lr_sig   : std_logic;
    signal aio_in_bs_sig, aio_in_bl_sig, aio_in_os_sig, aio_in_ol_sig : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal aio_out_en_sig, aio_out_lr_sig : std_logic;
    signal aio_out_bs_sig, aio_out_bl_sig, aio_out_os_sig, aio_out_ol_sig : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal grain_ready_l_sig, grain_ready_r_sig : std_logic;

    -- AudioCU <-> store
    signal st_en : std_logic;
    signal st_bs : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal st_bl : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal st_os : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal st_ol : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal st_data : std_logic_vector(ARAM_WORD_SIZE-1 downto 0);
    signal st_end : std_logic;

    -- audioIO <-> aram_mux (audio in unit's raw a-ram bus)
    signal ain_bram0_port0_addr_sig, ain_bram1_port0_addr_sig, ain_bram2_port0_addr_sig, ain_bram3_port0_addr_sig : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal ain_bram0_port1_addr_sig, ain_bram1_port1_addr_sig, ain_bram2_port1_addr_sig, ain_bram3_port1_addr_sig : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal ain_bram0_port0_we_sig, ain_bram1_port0_we_sig, ain_bram2_port0_we_sig, ain_bram3_port0_we_sig : std_logic;
    signal ain_bram0_port1_we_sig, ain_bram1_port1_we_sig, ain_bram2_port1_we_sig, ain_bram3_port1_we_sig : std_logic;
    signal ain_bram0_port0_en_sig, ain_bram1_port0_en_sig, ain_bram2_port0_en_sig, ain_bram3_port0_en_sig : std_logic;
    signal ain_bram0_port1_en_sig, ain_bram1_port1_en_sig, ain_bram2_port1_en_sig, ain_bram3_port1_en_sig : std_logic;
    signal ain_bram0_port0_data_in_sig, ain_bram1_port0_data_in_sig, ain_bram2_port0_data_in_sig, ain_bram3_port0_data_in_sig : std_logic_vector(31 downto 0);
    signal ain_bram0_port1_data_in_sig, ain_bram1_port1_data_in_sig, ain_bram2_port1_data_in_sig, ain_bram3_port1_data_in_sig : std_logic_vector(31 downto 0);
    signal ain_bram0_port0_data_out_sig, ain_bram1_port0_data_out_sig, ain_bram2_port0_data_out_sig, ain_bram3_port0_data_out_sig : std_logic_vector(31 downto 0);
    signal ain_bram0_port1_data_out_sig, ain_bram1_port1_data_out_sig, ain_bram2_port1_data_out_sig, ain_bram3_port1_data_out_sig : std_logic_vector(31 downto 0);

    -- audioIO <-> aram_mux (audio out unit's raw a-ram bus)
    signal aout_bram0_port0_addr_sig, aout_bram1_port0_addr_sig, aout_bram2_port0_addr_sig, aout_bram3_port0_addr_sig : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal aout_bram0_port1_addr_sig, aout_bram1_port1_addr_sig, aout_bram2_port1_addr_sig, aout_bram3_port1_addr_sig : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal aout_bram0_port0_we_sig, aout_bram1_port0_we_sig, aout_bram2_port0_we_sig, aout_bram3_port0_we_sig : std_logic;
    signal aout_bram0_port1_we_sig, aout_bram1_port1_we_sig, aout_bram2_port1_we_sig, aout_bram3_port1_we_sig : std_logic;
    signal aout_bram0_port0_en_sig, aout_bram1_port0_en_sig, aout_bram2_port0_en_sig, aout_bram3_port0_en_sig : std_logic;
    signal aout_bram0_port1_en_sig, aout_bram1_port1_en_sig, aout_bram2_port1_en_sig, aout_bram3_port1_en_sig : std_logic;
    signal aout_bram0_port0_data_in_sig, aout_bram1_port0_data_in_sig, aout_bram2_port0_data_in_sig, aout_bram3_port0_data_in_sig : std_logic_vector(31 downto 0);
    signal aout_bram0_port1_data_in_sig, aout_bram1_port1_data_in_sig, aout_bram2_port1_data_in_sig, aout_bram3_port1_data_in_sig : std_logic_vector(31 downto 0);
    signal aout_bram0_port0_data_out_sig, aout_bram1_port0_data_out_sig, aout_bram2_port0_data_out_sig, aout_bram3_port0_data_out_sig : std_logic_vector(31 downto 0);
    signal aout_bram0_port1_data_out_sig, aout_bram1_port1_data_out_sig, aout_bram2_port1_data_out_sig, aout_bram3_port1_data_out_sig : std_logic_vector(31 downto 0);

    -- store <-> aram_mux (store unit's raw a-ram bus)
    signal st_bram0_port0_addr_sig, st_bram1_port0_addr_sig, st_bram2_port0_addr_sig, st_bram3_port0_addr_sig : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal st_bram0_port1_addr_sig, st_bram1_port1_addr_sig, st_bram2_port1_addr_sig, st_bram3_port1_addr_sig : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal st_bram0_port0_we_sig, st_bram1_port0_we_sig, st_bram2_port0_we_sig, st_bram3_port0_we_sig : std_logic;
    signal st_bram0_port1_we_sig, st_bram1_port1_we_sig, st_bram2_port1_we_sig, st_bram3_port1_we_sig : std_logic;
    signal st_bram0_port0_en_sig, st_bram1_port0_en_sig, st_bram2_port0_en_sig, st_bram3_port0_en_sig : std_logic;
    signal st_bram0_port1_en_sig, st_bram1_port1_en_sig, st_bram2_port1_en_sig, st_bram3_port1_en_sig : std_logic;
    signal st_bram0_port0_data_in_sig, st_bram1_port0_data_in_sig, st_bram2_port0_data_in_sig, st_bram3_port0_data_in_sig : std_logic_vector(31 downto 0);
    signal st_bram0_port1_data_in_sig, st_bram1_port1_data_in_sig, st_bram2_port1_data_in_sig, st_bram3_port1_data_in_sig : std_logic_vector(31 downto 0);
    signal st_bram0_port0_data_out_sig, st_bram1_port0_data_out_sig, st_bram2_port0_data_out_sig, st_bram3_port0_data_out_sig : std_logic_vector(31 downto 0);
    signal st_bram0_port1_data_out_sig, st_bram1_port1_data_out_sig, st_bram2_port1_data_out_sig, st_bram3_port1_data_out_sig : std_logic_vector(31 downto 0);

    -- aram_mux <-> the 4 internal a-ram blocks (real, physical side)
    signal bram0_port0_addr_sig, bram1_port0_addr_sig, bram2_port0_addr_sig, bram3_port0_addr_sig : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal bram0_port1_addr_sig, bram1_port1_addr_sig, bram2_port1_addr_sig, bram3_port1_addr_sig : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal bram0_port0_we_sig, bram1_port0_we_sig, bram2_port0_we_sig, bram3_port0_we_sig : std_logic;
    signal bram0_port1_we_sig, bram1_port1_we_sig, bram2_port1_we_sig, bram3_port1_we_sig : std_logic;
    signal bram0_port0_en_sig, bram1_port0_en_sig, bram2_port0_en_sig, bram3_port0_en_sig : std_logic;
    signal bram0_port1_en_sig, bram1_port1_en_sig, bram2_port1_en_sig, bram3_port1_en_sig : std_logic;
    signal bram0_port0_data_in_sig, bram1_port0_data_in_sig, bram2_port0_data_in_sig, bram3_port0_data_in_sig : std_logic_vector(31 downto 0);
    signal bram0_port1_data_in_sig, bram1_port1_data_in_sig, bram2_port1_data_in_sig, bram3_port1_data_in_sig : std_logic_vector(31 downto 0);
    signal bram0_port0_data_out_sig, bram1_port0_data_out_sig, bram2_port0_data_out_sig, bram3_port0_data_out_sig : std_logic_vector(31 downto 0);
    signal bram0_port1_data_out_sig, bram1_port1_data_out_sig, bram2_port1_data_out_sig, bram3_port1_data_out_sig : std_logic_vector(31 downto 0);

begin

    -- new_grain: level while either channel's audio_in unit has a full grain waiting
    aio_new_grain_sig <= grain_ready_l_sig or grain_ready_r_sig;

    cu : entity work.AudioCU
        generic map (
            ARAM_WORD_SIZE  => ARAM_WORD_SIZE,
            ARAM_ADDR_SIZE  => ARAM_ADDR_SIZE,
            INSTR_ADDR_SIZE => INSTR_ADDR_SIZE,
            UPARAM_SIZE     => UPARAM_SIZE,
            INSTR_SIZE      => INSTR_SIZE,
            COUNTER_SIZE    => COUNTER_SIZE
        )
        port map (
            clk => clk, rst => rst,

            unit_select => unit_select_sig,

            iwe => iwe_sig, ien => ien_sig, iaddr => iaddr_sig,
            idata_in => idata_in_sig, idata_out => idata_out_sig,

            aio_new_grain => aio_new_grain_sig, aio_in_end => aio_in_end_sig, aio_out_end => aio_out_end_sig,
            aio_in_en => aio_in_en_sig, aio_in_lr => aio_in_lr_sig,
            aio_in_bs => aio_in_bs_sig, aio_in_bl => aio_in_bl_sig, aio_in_os => aio_in_os_sig, aio_in_ol => aio_in_ol_sig,
            aio_out_en => aio_out_en_sig, aio_out_lr => aio_out_lr_sig,
            aio_out_bs => aio_out_bs_sig, aio_out_bl => aio_out_bl_sig, aio_out_os => aio_out_os_sig, aio_out_ol => aio_out_ol_sig,

            -- no FFT unit yet: end tied low (would stall a shader using FFT/IFFT forever), outputs unused
            fft_end => '0',
            fft_en => open, fft_size => open, fwd_inv => open,
            fft_bsr => open, fft_blr => open, fft_osr => open, fft_olr => open,
            fft_bsw => open, fft_blw => open, fft_osw => open, fft_olw => open,

            -- no Parallel ALU / VPU unit yet: same treatment
            vec_end => '0',
            vec_en => open, vec_op => open, vec_scalar => open,
            vec_bsr1 => open, vec_blr1 => open, vec_osr1 => open, vec_olr1 => open,
            vec_bsr2 => open, vec_blr2 => open, vec_osr2 => open, vec_olr2 => open,
            vec_bsw => open, vec_blw => open, vec_osw => open, vec_olw => open

            st_en => st_en, st_end => st_end,
            st_bs => st_bs, st_bl => st_bl, st_os => st_os, st_ol => st_ol,
            st_data => st_data
        );

    aio : entity work.audioIO
        generic map (
            BUFFER_ADDR_WIDTH => ARAM_ADDR_SIZE,
            BUFFER_SIZE_BITS  => ARAM_WORD_SIZE
        )
        port map (
            clk => clk, rst => rst,

            AC_ADR0 => AC_ADR0, AC_ADR1 => AC_ADR1, AC_GPIO0 => AC_GPIO0,
            AC_GPIO1 => AC_GPIO1, AC_GPIO2 => AC_GPIO2, AC_GPIO3 => AC_GPIO3,
            AC_MCLK => AC_MCLK, AC_SCK => AC_SCK, AC_SDA => AC_SDA,

            -- audioIO's generics are set to ARAM_ADDR_SIZE/ARAM_WORD_SIZE above, so
            -- buffer_start/operation_start line up with AudioCU's own field width
            -- (ARAM_ADDR_SIZE) directly -- no truncation needed. buffer_length is
            -- widened from ARAM_ADDR_SIZE to ARAM_WORD_SIZE (zero-extended).
            -- audio_in_unit/audio_out_unit hardcode their own operation length to
            -- one grain (256 samples), so aio_in_ol/aio_out_ol have no destination
            -- here -- the shader's operation_length_reg field is a no-op today.
            audio_in_enable          => aio_in_en_sig,
            audio_in_left_right      => aio_in_lr_sig,
            audio_in_buffer_start    => aio_in_bs_sig,
            audio_in_buffer_length   => std_logic_vector(resize(unsigned(aio_in_bl_sig), ARAM_WORD_SIZE)),
            audio_in_operation_start => aio_in_os_sig,
            audio_in_finished        => aio_in_end_sig,
            grain_ready_l            => grain_ready_l_sig,
            grain_ready_r            => grain_ready_r_sig,

            audio_out_enable          => aio_out_en_sig,
            audio_out_left_right      => aio_out_lr_sig,
            audio_out_buffer_start    => aio_out_bs_sig,
            audio_out_buffer_length   => std_logic_vector(resize(unsigned(aio_out_bl_sig), ARAM_WORD_SIZE)),
            audio_out_operation_start => aio_out_os_sig,
            audio_out_finished        => aio_out_end_sig,
            need_grain_l              => open,
            need_grain_r              => open,

            ain_bram0_port0_addr => ain_bram0_port0_addr_sig, ain_bram1_port0_addr => ain_bram1_port0_addr_sig,
            ain_bram2_port0_addr => ain_bram2_port0_addr_sig, ain_bram3_port0_addr => ain_bram3_port0_addr_sig,
            ain_bram0_port1_addr => ain_bram0_port1_addr_sig, ain_bram1_port1_addr => ain_bram1_port1_addr_sig,
            ain_bram2_port1_addr => ain_bram2_port1_addr_sig, ain_bram3_port1_addr => ain_bram3_port1_addr_sig,

            ain_bram0_port0_we => ain_bram0_port0_we_sig, ain_bram1_port0_we => ain_bram1_port0_we_sig,
            ain_bram2_port0_we => ain_bram2_port0_we_sig, ain_bram3_port0_we => ain_bram3_port0_we_sig,
            ain_bram0_port1_we => ain_bram0_port1_we_sig, ain_bram1_port1_we => ain_bram1_port1_we_sig,
            ain_bram2_port1_we => ain_bram2_port1_we_sig, ain_bram3_port1_we => ain_bram3_port1_we_sig,

            ain_bram0_port0_en => ain_bram0_port0_en_sig, ain_bram1_port0_en => ain_bram1_port0_en_sig,
            ain_bram2_port0_en => ain_bram2_port0_en_sig, ain_bram3_port0_en => ain_bram3_port0_en_sig,
            ain_bram0_port1_en => ain_bram0_port1_en_sig, ain_bram1_port1_en => ain_bram1_port1_en_sig,
            ain_bram2_port1_en => ain_bram2_port1_en_sig, ain_bram3_port1_en => ain_bram3_port1_en_sig,

            ain_bram0_port0_data_in => ain_bram0_port0_data_in_sig, ain_bram1_port0_data_in => ain_bram1_port0_data_in_sig,
            ain_bram2_port0_data_in => ain_bram2_port0_data_in_sig, ain_bram3_port0_data_in => ain_bram3_port0_data_in_sig,
            ain_bram0_port1_data_in => ain_bram0_port1_data_in_sig, ain_bram1_port1_data_in => ain_bram1_port1_data_in_sig,
            ain_bram2_port1_data_in => ain_bram2_port1_data_in_sig, ain_bram3_port1_data_in => ain_bram3_port1_data_in_sig,

            ain_bram0_port0_data_out => ain_bram0_port0_data_out_sig, ain_bram1_port0_data_out => ain_bram1_port0_data_out_sig,
            ain_bram2_port0_data_out => ain_bram2_port0_data_out_sig, ain_bram3_port0_data_out => ain_bram3_port0_data_out_sig,
            ain_bram0_port1_data_out => ain_bram0_port1_data_out_sig, ain_bram1_port1_data_out => ain_bram1_port1_data_out_sig,
            ain_bram2_port1_data_out => ain_bram2_port1_data_out_sig, ain_bram3_port1_data_out => ain_bram3_port1_data_out_sig,

            aout_bram0_port0_addr => aout_bram0_port0_addr_sig, aout_bram1_port0_addr => aout_bram1_port0_addr_sig,
            aout_bram2_port0_addr => aout_bram2_port0_addr_sig, aout_bram3_port0_addr => aout_bram3_port0_addr_sig,
            aout_bram0_port1_addr => aout_bram0_port1_addr_sig, aout_bram1_port1_addr => aout_bram1_port1_addr_sig,
            aout_bram2_port1_addr => aout_bram2_port1_addr_sig, aout_bram3_port1_addr => aout_bram3_port1_addr_sig,

            aout_bram0_port0_we => aout_bram0_port0_we_sig, aout_bram1_port0_we => aout_bram1_port0_we_sig,
            aout_bram2_port0_we => aout_bram2_port0_we_sig, aout_bram3_port0_we => aout_bram3_port0_we_sig,
            aout_bram0_port1_we => aout_bram0_port1_we_sig, aout_bram1_port1_we => aout_bram1_port1_we_sig,
            aout_bram2_port1_we => aout_bram2_port1_we_sig, aout_bram3_port1_we => aout_bram3_port1_we_sig,

            aout_bram0_port0_en => aout_bram0_port0_en_sig, aout_bram1_port0_en => aout_bram1_port0_en_sig,
            aout_bram2_port0_en => aout_bram2_port0_en_sig, aout_bram3_port0_en => aout_bram3_port0_en_sig,
            aout_bram0_port1_en => aout_bram0_port1_en_sig, aout_bram1_port1_en => aout_bram1_port1_en_sig,
            aout_bram2_port1_en => aout_bram2_port1_en_sig, aout_bram3_port1_en => aout_bram3_port1_en_sig,

            aout_bram0_port0_data_in => aout_bram0_port0_data_in_sig, aout_bram1_port0_data_in => aout_bram1_port0_data_in_sig,
            aout_bram2_port0_data_in => aout_bram2_port0_data_in_sig, aout_bram3_port0_data_in => aout_bram3_port0_data_in_sig,
            aout_bram0_port1_data_in => aout_bram0_port1_data_in_sig, aout_bram1_port1_data_in => aout_bram1_port1_data_in_sig,
            aout_bram2_port1_data_in => aout_bram2_port1_data_in_sig, aout_bram3_port1_data_in => aout_bram3_port1_data_in_sig,

            aout_bram0_port0_data_out => aout_bram0_port0_data_out_sig, aout_bram1_port0_data_out => aout_bram1_port0_data_out_sig,
            aout_bram2_port0_data_out => aout_bram2_port0_data_out_sig, aout_bram3_port0_data_out => aout_bram3_port0_data_out_sig,
            aout_bram0_port1_data_out => aout_bram0_port1_data_out_sig, aout_bram1_port1_data_out => aout_bram1_port1_data_out_sig,
            aout_bram2_port1_data_out => aout_bram2_port1_data_out_sig, aout_bram3_port1_data_out => aout_bram3_port1_data_out_sig
        );

    st : entity work.store_unit
        generic map (
            BUFFER_ADDR_WIDTH => ARAM_ADDR_SIZE,
            BUFFER_SIZE_BITS  => ARAM_WORD_SIZE -- TODO use ARAM_ADDR_SIZE+3
        )
        port map (
            clk => clk, rst => rst,

            enable => st_en,
            buffer_start => st_bs,
            buffer_length => st_bl,
            operation_start => st_os,
            operation_length => st_ol,
            data => st_data,
            finished => st_end,

            bram0_port0_addr => st_bram0_port0_addr,
            bram1_port0_addr => st_bram1_port0_addr,
            bram2_port0_addr => st_bram2_port0_addr,
            bram3_port0_addr => st_bram3_port0_addr,

            bram0_port1_addr => st_bram0_port1_addr,
            bram1_port1_addr => st_bram1_port1_addr,
            bram2_port1_addr => st_bram2_port1_addr,
            bram3_port1_addr => st_bram3_port1_addr,

            bram0_port0_we => st_bram0_port0_we,
            bram1_port0_we => st_bram1_port0_we,
            bram2_port0_we => st_bram2_port0_we,
            bram3_port0_we => st_bram3_port0_we,

            bram0_port1_we => st_bram0_port1_we,
            bram1_port1_we => st_bram1_port1_we,
            bram2_port1_we => st_bram2_port1_we,
            bram3_port1_we => st_bram3_port1_we,

            bram0_port0_en => st_bram0_port0_en,
            bram1_port0_en => st_bram1_port0_en,
            bram2_port0_en => st_bram2_port0_en,
            bram3_port0_en => st_bram3_port0_en,

            bram0_port1_en => st_bram0_port1_en,
            bram1_port1_en => st_bram1_port1_en,
            bram2_port1_en => st_bram2_port1_en,
            bram3_port1_en => st_bram3_port1_en,

            bram0_port0_data_in => st_bram0_port0_data_in,
            bram1_port0_data_in => st_bram1_port0_data_in,
            bram2_port0_data_in => st_bram2_port0_data_in,
            bram3_port0_data_in => st_bram3_port0_data_in,

            bram0_port1_data_in => st_bram0_port1_data_in,
            bram1_port1_data_in => st_bram1_port1_data_in,
            bram2_port1_data_in => st_bram2_port1_data_in,
            bram3_port1_data_in => st_bram3_port1_data_in,

            bram0_port0_data_out => st_bram0_port0_data_out,
            bram1_port0_data_out => st_bram1_port0_data_out,
            bram2_port0_data_out => st_bram2_port0_data_out,
            bram3_port0_data_out => st_bram3_port0_data_out,

            bram0_port1_data_out => st_bram0_port1_data_out,
            bram1_port1_data_out => st_bram1_port1_data_out,
            bram2_port1_data_out => st_bram2_port1_data_out,
            bram3_port1_data_out => st_bram3_port1_data_out
        );

    mux : entity work.aram_mux
        generic map (
            BUFFER_ADDR_WIDTH => ARAM_ADDR_SIZE,
            BUFFER_SIZE_BITS  => ARAM_WORD_SIZE
        )
        port map (
            unit_select => unit_select_sig,

            ain_bram0_port0_addr => ain_bram0_port0_addr_sig, ain_bram1_port0_addr => ain_bram1_port0_addr_sig,
            ain_bram2_port0_addr => ain_bram2_port0_addr_sig, ain_bram3_port0_addr => ain_bram3_port0_addr_sig,
            ain_bram0_port1_addr => ain_bram0_port1_addr_sig, ain_bram1_port1_addr => ain_bram1_port1_addr_sig,
            ain_bram2_port1_addr => ain_bram2_port1_addr_sig, ain_bram3_port1_addr => ain_bram3_port1_addr_sig,
            ain_bram0_port0_we => ain_bram0_port0_we_sig, ain_bram1_port0_we => ain_bram1_port0_we_sig,
            ain_bram2_port0_we => ain_bram2_port0_we_sig, ain_bram3_port0_we => ain_bram3_port0_we_sig,
            ain_bram0_port1_we => ain_bram0_port1_we_sig, ain_bram1_port1_we => ain_bram1_port1_we_sig,
            ain_bram2_port1_we => ain_bram2_port1_we_sig, ain_bram3_port1_we => ain_bram3_port1_we_sig,
            ain_bram0_port0_en => ain_bram0_port0_en_sig, ain_bram1_port0_en => ain_bram1_port0_en_sig,
            ain_bram2_port0_en => ain_bram2_port0_en_sig, ain_bram3_port0_en => ain_bram3_port0_en_sig,
            ain_bram0_port1_en => ain_bram0_port1_en_sig, ain_bram1_port1_en => ain_bram1_port1_en_sig,
            ain_bram2_port1_en => ain_bram2_port1_en_sig, ain_bram3_port1_en => ain_bram3_port1_en_sig,
            ain_bram0_port0_data_in => ain_bram0_port0_data_in_sig, ain_bram1_port0_data_in => ain_bram1_port0_data_in_sig,
            ain_bram2_port0_data_in => ain_bram2_port0_data_in_sig, ain_bram3_port0_data_in => ain_bram3_port0_data_in_sig,
            ain_bram0_port1_data_in => ain_bram0_port1_data_in_sig, ain_bram1_port1_data_in => ain_bram1_port1_data_in_sig,
            ain_bram2_port1_data_in => ain_bram2_port1_data_in_sig, ain_bram3_port1_data_in => ain_bram3_port1_data_in_sig,
            ain_bram0_port0_data_out => ain_bram0_port0_data_out_sig, ain_bram1_port0_data_out => ain_bram1_port0_data_out_sig,
            ain_bram2_port0_data_out => ain_bram2_port0_data_out_sig, ain_bram3_port0_data_out => ain_bram3_port0_data_out_sig,
            ain_bram0_port1_data_out => ain_bram0_port1_data_out_sig, ain_bram1_port1_data_out => ain_bram1_port1_data_out_sig,
            ain_bram2_port1_data_out => ain_bram2_port1_data_out_sig, ain_bram3_port1_data_out => ain_bram3_port1_data_out_sig,

            aout_bram0_port0_addr => aout_bram0_port0_addr_sig, aout_bram1_port0_addr => aout_bram1_port0_addr_sig,
            aout_bram2_port0_addr => aout_bram2_port0_addr_sig, aout_bram3_port0_addr => aout_bram3_port0_addr_sig,
            aout_bram0_port1_addr => aout_bram0_port1_addr_sig, aout_bram1_port1_addr => aout_bram1_port1_addr_sig,
            aout_bram2_port1_addr => aout_bram2_port1_addr_sig, aout_bram3_port1_addr => aout_bram3_port1_addr_sig,
            aout_bram0_port0_we => aout_bram0_port0_we_sig, aout_bram1_port0_we => aout_bram1_port0_we_sig,
            aout_bram2_port0_we => aout_bram2_port0_we_sig, aout_bram3_port0_we => aout_bram3_port0_we_sig,
            aout_bram0_port1_we => aout_bram0_port1_we_sig, aout_bram1_port1_we => aout_bram1_port1_we_sig,
            aout_bram2_port1_we => aout_bram2_port1_we_sig, aout_bram3_port1_we => aout_bram3_port1_we_sig,
            aout_bram0_port0_en => aout_bram0_port0_en_sig, aout_bram1_port0_en => aout_bram1_port0_en_sig,
            aout_bram2_port0_en => aout_bram2_port0_en_sig, aout_bram3_port0_en => aout_bram3_port0_en_sig,
            aout_bram0_port1_en => aout_bram0_port1_en_sig, aout_bram1_port1_en => aout_bram1_port1_en_sig,
            aout_bram2_port1_en => aout_bram2_port1_en_sig, aout_bram3_port1_en => aout_bram3_port1_en_sig,
            aout_bram0_port0_data_in => aout_bram0_port0_data_in_sig, aout_bram1_port0_data_in => aout_bram1_port0_data_in_sig,
            aout_bram2_port0_data_in => aout_bram2_port0_data_in_sig, aout_bram3_port0_data_in => aout_bram3_port0_data_in_sig,
            aout_bram0_port1_data_in => aout_bram0_port1_data_in_sig, aout_bram1_port1_data_in => aout_bram1_port1_data_in_sig,
            aout_bram2_port1_data_in => aout_bram2_port1_data_in_sig, aout_bram3_port1_data_in => aout_bram3_port1_data_in_sig,
            aout_bram0_port0_data_out => aout_bram0_port0_data_out_sig, aout_bram1_port0_data_out => aout_bram1_port0_data_out_sig,
            aout_bram2_port0_data_out => aout_bram2_port0_data_out_sig, aout_bram3_port0_data_out => aout_bram3_port0_data_out_sig,
            aout_bram0_port1_data_out => aout_bram0_port1_data_out_sig, aout_bram1_port1_data_out => aout_bram1_port1_data_out_sig,
            aout_bram2_port1_data_out => aout_bram2_port1_data_out_sig, aout_bram3_port1_data_out => aout_bram3_port1_data_out_sig,

            -- no VPU unit yet: inputs tied idle, outputs unused
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

            -- no FFT unit yet: same treatment
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

            -- no Pitch Shift unit yet: same treatment
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

            -- real a-ram: feeds the 4 internal blocks instantiated below
            bram0_port0_addr => bram0_port0_addr_sig, bram1_port0_addr => bram1_port0_addr_sig,
            bram2_port0_addr => bram2_port0_addr_sig, bram3_port0_addr => bram3_port0_addr_sig,
            bram0_port1_addr => bram0_port1_addr_sig, bram1_port1_addr => bram1_port1_addr_sig,
            bram2_port1_addr => bram2_port1_addr_sig, bram3_port1_addr => bram3_port1_addr_sig,
            bram0_port0_we => bram0_port0_we_sig, bram1_port0_we => bram1_port0_we_sig,
            bram2_port0_we => bram2_port0_we_sig, bram3_port0_we => bram3_port0_we_sig,
            bram0_port1_we => bram0_port1_we_sig, bram1_port1_we => bram1_port1_we_sig,
            bram2_port1_we => bram2_port1_we_sig, bram3_port1_we => bram3_port1_we_sig,
            bram0_port0_en => bram0_port0_en_sig, bram1_port0_en => bram1_port0_en_sig,
            bram2_port0_en => bram2_port0_en_sig, bram3_port0_en => bram3_port0_en_sig,
            bram0_port1_en => bram0_port1_en_sig, bram1_port1_en => bram1_port1_en_sig,
            bram2_port1_en => bram2_port1_en_sig, bram3_port1_en => bram3_port1_en_sig,
            bram0_port0_data_in => bram0_port0_data_in_sig, bram1_port0_data_in => bram1_port0_data_in_sig,
            bram2_port0_data_in => bram2_port0_data_in_sig, bram3_port0_data_in => bram3_port0_data_in_sig,
            bram0_port1_data_in => bram0_port1_data_in_sig, bram1_port1_data_in => bram1_port1_data_in_sig,
            bram2_port1_data_in => bram2_port1_data_in_sig, bram3_port1_data_in => bram3_port1_data_in_sig,
            bram0_port0_data_out => bram0_port0_data_out_sig, bram1_port0_data_out => bram1_port0_data_out_sig,
            bram2_port0_data_out => bram2_port0_data_out_sig, bram3_port0_data_out => bram3_port0_data_out_sig,
            bram0_port1_data_out => bram0_port1_data_out_sig, bram1_port1_data_out => bram1_port1_data_out_sig,
            bram2_port1_data_out => bram2_port1_data_out_sig, bram3_port1_data_out => bram3_port1_data_out_sig
        );

    -- instruction/param memory: port A is the CPU/AXI side (APU's own
    -- external ports, straight through), port B is AudioCU's, internal only
    instr_bram_inst : entity work.instr_bram
        port map (
            clka  => clk, addra => addr, dina => data_in,
            wea(0) => we, ena => en, douta => data_out,
            clkb  => clk, addrb => iaddr_sig, dinb => idata_in_sig,
            web(0) => iwe_sig, enb => ien_sig, doutb => idata_out_sig
        );

    -- a-ram: 4 true-dual-port blocks, one per row-major lane. Entity names
    -- below (aram_bram0..aram_bram3) are what the matching Vivado Block
    -- Memory Generator IP customizations must be named as.
    aram_bram0_inst : entity work.aram_bram
        port map (
            clka  => clk, addra => bram0_port0_addr_sig, dina => bram0_port0_data_in_sig,
            wea(0) => bram0_port0_we_sig, ena => bram0_port0_en_sig, douta => bram0_port0_data_out_sig,
            clkb  => clk, addrb => bram0_port1_addr_sig, dinb => bram0_port1_data_in_sig,
            web(0) => bram0_port1_we_sig, enb => bram0_port1_en_sig, doutb => bram0_port1_data_out_sig
        );

    aram_bram1_inst : entity work.aram_bram
        port map (
            clka  => clk, addra => bram1_port0_addr_sig, dina => bram1_port0_data_in_sig,
            wea(0) => bram1_port0_we_sig, ena => bram1_port0_en_sig, douta => bram1_port0_data_out_sig,
            clkb  => clk, addrb => bram1_port1_addr_sig, dinb => bram1_port1_data_in_sig,
            web(0) => bram1_port1_we_sig, enb => bram1_port1_en_sig, doutb => bram1_port1_data_out_sig
        );

    aram_bram2_inst : entity work.aram_bram
        port map (
            clka  => clk, addra => bram2_port0_addr_sig, dina => bram2_port0_data_in_sig,
            wea(0) => bram2_port0_we_sig, ena => bram2_port0_en_sig, douta => bram2_port0_data_out_sig,
            clkb  => clk, addrb => bram2_port1_addr_sig, dinb => bram2_port1_data_in_sig,
            web(0) => bram2_port1_we_sig, enb => bram2_port1_en_sig, doutb => bram2_port1_data_out_sig
        );

    aram_bram3_inst : entity work.aram_bram
        port map (
            clka  => clk, addra => bram3_port0_addr_sig, dina => bram3_port0_data_in_sig,
            wea(0) => bram3_port0_we_sig, ena => bram3_port0_en_sig, douta => bram3_port0_data_out_sig,
            clkb  => clk, addrb => bram3_port1_addr_sig, dinb => bram3_port1_data_in_sig,
            web(0) => bram3_port1_we_sig, enb => bram3_port1_en_sig, doutb => bram3_port1_data_out_sig
        );

end Behavioral;
