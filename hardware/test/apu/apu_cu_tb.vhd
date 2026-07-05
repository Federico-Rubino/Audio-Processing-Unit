library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.apu_opcode_pkg.all;
use work.apu_internal_pkg.all;

entity AudioCU_tb is
-- Testbenches do not have ports
end AudioCU_tb;

architecture sim of AudioCU_tb is

    -- --------------------------------------------------------
    -- Geometry Parameters (Matching VHDL Generics)
    -- --------------------------------------------------------
    constant ARAM_WORD_SIZE : integer := 32;
    constant ARAM_ADDR_SIZE : integer := 16;
    constant INSTR_ADDR_SIZE: integer := 11;
    constant UPARAM_SIZE    : integer := 9;
    constant INSTR_SIZE     : integer := 128;
    constant COUNTER_SIZE   : integer := 16;
    constant MEM_DEPTH      : integer := 2048;

    -- --------------------------------------------------------
    -- Testbench Clock & Control Signals
    -- --------------------------------------------------------
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '0';

    -- ARAM Interfacing
    signal unit_select : apu_unit_t;

    -- Shared BRAM Interfacing
    signal iwe, ien  : std_logic;
    signal iaddr     : std_logic_vector(INSTR_ADDR_SIZE-1 downto 0);
    signal idata_in  : std_logic_vector(ARAM_WORD_SIZE-1 downto 0);
    signal idata_out : std_logic_vector(ARAM_WORD_SIZE-1 downto 0) := (others => '0');

    -- Outside CPU (Host) BRAM Interfacing
    signal host_we   : std_logic := '0';
    signal host_addr : integer := 0;
    signal host_data : std_logic_vector(31 downto 0) := (others => '0');
    
    -- Audio IO Interfacing
    signal aio_new_grain, aio_end : std_logic := '0';
    signal aio_en, aio_lr : std_logic;
    signal aio_bs, aio_bl, aio_os, aio_ol : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);

    -- FFT Unit Interfacing
    signal fft_end : std_logic := '0';
    signal fft_en, fft_size, fwd_inv : std_logic;
    signal fft_bsr, fft_blr, fft_osr, fft_olr : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal fft_bsw, fft_blw, fft_osw, fft_olw : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);

    -- Parallel ALU Interfacing
    signal vec_end : std_logic := '0';
    signal vec_en : std_logic;
    signal vec_op : vec_op_t;
    signal vec_scalar : std_logic_vector(15 downto 0);
    signal vec_bsr1, vec_blr1, vec_osr1, vec_olr1 : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal vec_bsr2, vec_blr2, vec_osr2, vec_olr2 : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal vec_bsw, vec_blw, vec_osw, vec_olw : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);

    -- --------------------------------------------------------
    -- Memory Storage Signal representing the unified 2048x32 BRAM
    -- --------------------------------------------------------
    type ram_type is array (0 to MEM_DEPTH-1) of std_logic_vector(ARAM_WORD_SIZE-1 downto 0);
    signal shared_bram : ram_type := (others => (others => '0'));

    -- Clock Period Constant (100MHz System Clock)
    constant CLK_PERIOD : time := 10 ns;

begin

    -- --------------------------------------------------------
    -- Device Under Test (DUT) Instantiation
    -- --------------------------------------------------------
    uut: entity work.AudioCU
        generic map (
            ARAM_WORD_SIZE => ARAM_WORD_SIZE,
            ARAM_ADDR_SIZE => ARAM_ADDR_SIZE,
            UPARAM_SIZE    => UPARAM_SIZE,
            INSTR_SIZE     => INSTR_SIZE,
            COUNTER_SIZE   => COUNTER_SIZE
        )
        port map (
            clk             => clk,
            rst             => rst,
            unit_select     => unit_select,
            iwe             => iwe,
            ien             => ien,
            iaddr           => iaddr,
            idata_in        => idata_in,
            idata_out       => idata_out,
            aio_new_grain   => aio_new_grain,
            aio_end         => aio_end,
            aio_en          => aio_en,
            aio_lr          => aio_lr,
            aio_bs          => aio_bs,
            aio_bl          => aio_bl,
            aio_os          => aio_os,
            aio_ol          => aio_ol,
            fft_end         => fft_end,
            fft_en          => fft_en,
            fft_size        => fft_size,
            fwd_inv         => fwd_inv,
            fft_bsr         => fft_bsr,
            fft_blr         => fft_blr,
            fft_osr         => fft_osr,
            fft_olr         => fft_olr,
            fft_bsw         => fft_bsw,
            fft_blw         => fft_blw,
            fft_osw         => fft_osw,
            fft_olw         => fft_olw,
            vec_end         => vec_end,
            vec_en          => vec_en,
            vec_op          => vec_op,
            vec_scalar      => vec_scalar,
            vec_bsr1        => vec_bsr1,
            vec_blr1        => vec_blr1,
            vec_osr1        => vec_osr1,
            vec_olr1        => vec_olr1,
            vec_bsr2        => vec_bsr2,
            vec_blr2        => vec_blr2,
            vec_osr2        => vec_osr2,
            vec_olr2        => vec_olr2,
            vec_bsw         => vec_bsw,
            vec_blw         => vec_blw,
            vec_osw         => vec_osw,
            vec_olw         => vec_olw
        );

    -- --------------------------------------------------------
    -- Clock Generator Process
    -- --------------------------------------------------------
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

-- --------------------------------------------------------
    -- Unified Synchronous Dual-Port BRAM Emulation Process
    -- --------------------------------------------------------
    bram_process : process(clk)
        variable addr_idx : integer;
    begin
        if rising_edge(clk) then
            -- Port A: Audio CU (Read/Write)
            if ien = '1' then
                addr_idx := to_integer(unsigned(iaddr));
                if iwe = '1' then
                    shared_bram(addr_idx) <= idata_in;
                else
                    idata_out <= shared_bram(addr_idx);
                end if;
            end if;
            
            -- Port B: Outside CPU / Testbench (Write-Only for stimulus)
            if host_we = '1' then
                shared_bram(host_addr) <= host_data;
            end if;
        end if;
    end process;

    -- --------------------------------------------------------
    -- Main Stimulus Process
    -- --------------------------------------------------------
    stim_proc: process
        variable v_instr : std_logic_vector(127 downto 0);

        -- Local procedure to load a 128-bit block using the Host CPU Port
        procedure load_instruction(
            constant base_word_addr : in integer;
            constant full_instr     : in std_logic_vector(127 downto 0)
        ) is
        begin
            wait until rising_edge(clk);
            host_we <= '1';
            
            host_addr <= base_word_addr;
            host_data <= full_instr(127 downto 96);
            wait until rising_edge(clk);
            
            host_addr <= base_word_addr + 1;
            host_data <= full_instr(95 downto 64);
            wait until rising_edge(clk);
            
            host_addr <= base_word_addr + 2;
            host_data <= full_instr(63 downto 32);
            wait until rising_edge(clk);
            
            host_addr <= base_word_addr + 3;
            host_data <= full_instr(31 downto 0);
            wait until rising_edge(clk);
            
            host_we <= '0';
        end procedure;

    begin		
        -- Initial Pipeline Holds
        rst             <= '0';
        aio_new_grain   <= '0';
        aio_end         <= '0';
        fft_end         <= '0';
        vec_end         <= '0';
        wait for CLK_PERIOD * 2;

        -- Pre-populate Shader space (Addresses 2-1023) inside the BRAM before execution
        -- Shader execution path begins at address 3

        -- Instruction 1 (Addr 3): APU_OP_AUDIO_IN (1100), bs=0x123, bl=0x05A, os=0x210, ol=0x0FF
        v_instr := (others => '0');
        v_instr(127 downto 124) := "1100"; 
        v_instr(123 downto 114) := "0100100011"; -- 0x123
        v_instr(113 downto 104) := "0001011010"; -- 0x05A
        v_instr(103 downto 94)  := "1000010000"; -- 0x210
        v_instr(93 downto 84)   := "0011111111"; -- 0x0FF
        load_instruction(3, v_instr);

        -- Instruction 2 (Addr 7): APU_OP_FFT (0001), size=1, bsr=1, blr=2, osr=3, olr=4, bsw=5, blw=6, osw=7, olw=8
        v_instr := (others => '0');
        v_instr(127 downto 124) := "0001";
        v_instr(123)            := '1';
        v_instr(122 downto 113) := std_logic_vector(to_unsigned(1, 10));
        v_instr(112 downto 103) := std_logic_vector(to_unsigned(2, 10));
        v_instr(102 downto 93)  := std_logic_vector(to_unsigned(3, 10));
        v_instr(92 downto 83)   := std_logic_vector(to_unsigned(4, 10));
        v_instr(82 downto 73)   := std_logic_vector(to_unsigned(5, 10));
        v_instr(72 downto 63)   := std_logic_vector(to_unsigned(6, 10));
        v_instr(62 downto 53)   := std_logic_vector(to_unsigned(7, 10));
        v_instr(52 downto 43)   := std_logic_vector(to_unsigned(8, 10));
        load_instruction(7, v_instr);

        -- Instruction 3 (Addr 11): APU_OP_ADD_VECTOR (0011), bsr1=0xAA, blr1=0xBB, osr1=0xCC, olr1=0xDD, bsr2=0x111...
        v_instr := (others => '0');
        v_instr(127 downto 124) := "0011";
        v_instr(123 downto 114) := "0010101010"; -- 0x0AA
        v_instr(113 downto 104) := "0010111011"; -- 0x0BB
        v_instr(103 downto 94)  := "0011001100"; -- 0x0CC
        v_instr(93 downto 84)   := "0011011101"; -- 0x0DD
        v_instr(83 downto 74)   := "0100010001"; -- 0x111
        v_instr(73 downto 64)   := "1000100010"; -- 0x222
        v_instr(63 downto 54)   := "1100110011"; -- 0x333
        v_instr(53 downto 44)   := "0101000100"; -- 0x444
        v_instr(43 downto 34)   := "0110100000"; -- 0x1A0
        v_instr(33 downto 24)   := "1010110000"; -- 0x2B0
        v_instr(23 downto 14)   := "1111000000"; -- 0x3C0
        v_instr(13 downto 4)    := "0100110000"; -- 0x4D0
        load_instruction(11, v_instr);

        -- Instruction 4 (Addr 15): APU_OP_MUL_SCALAR (1000), bsr1=5, blr1=10, scalar=0xDEAD, bsw=0x300...
        v_instr := (others => '0');
        v_instr(127 downto 124) := "1000";
        v_instr(123 downto 114) := std_logic_vector(to_unsigned(5, 10));
        v_instr(113 downto 104) := std_logic_vector(to_unsigned(10, 10));
        v_instr(103 downto 94)  := std_logic_vector(to_unsigned(15, 10));
        v_instr(93 downto 84)   := std_logic_vector(to_unsigned(20, 10));
        v_instr(83 downto 68)   := X"DEAD";       -- Immediate Scalar Value
        v_instr(43 downto 34)   := "1100000000"; -- 0x300
        v_instr(33 downto 24)   := "1100010000"; -- 0x310
        v_instr(23 downto 14)   := "1100100000"; -- 0x320
        v_instr(13 downto 4)    := "1100110000"; -- 0x330
        load_instruction(15, v_instr);

        -- Instruction 5 (Addr 19): APU_OP_STOP (1111)
        v_instr := (others => '0');
        v_instr(127 downto 124) := "1111";
        load_instruction(19, v_instr);

        -- Release System Reset
        wait until rising_edge(clk);
        rst <= '1';
        wait for CLK_PERIOD * 2;

        report "--- STARTING AUDIO CONTROL UNIT VHDL TESTBENCH RUN ---";

        -- Outside CPU initiates operations by writing start parameter configuration to Address 1
        -- Bit 0 = 1 (start active), Bits 10-1 value = 1 (Combined value = 3, mapping start_addr to 3)
        wait until rising_edge(clk);
        host_addr <= 1;
        host_data <= std_logic_vector(to_unsigned(3, ARAM_WORD_SIZE));
        host_we   <= '1';
        
        wait until rising_edge(clk);
        host_we   <= '0'; -- De-assert write enable

        -- --------------------------------------------------------
        -- TEST CASE 1: AUDIO INPUT INSTRUCTION MAPPING
        -- --------------------------------------------------------
        report "[TEST] Launching Audio Input Core Validation...";
        
        wait until aio_en = '1';
        wait for 1 ns; -- Safe margin away from clock edge for sampling

        assert (unit_select = APU_UNIT_AUDIO_IN) report "Wrong unit selection for Audio In" severity failure;
        assert (aio_bs = "0100100011") report "AIO Base Address structural extraction failed" severity failure;
        assert (aio_bl = "0001011010") report "AIO Block Length structural extraction failed" severity failure;
        
        wait until rising_edge(clk);
        aio_end <= '1';
        wait until rising_edge(clk);
        aio_end <= '0';

        -- --------------------------------------------------------
        -- TEST CASE 2: FFT UNIT PARAMETER GENERATOR
        -- --------------------------------------------------------
        report "[TEST] Launching FFT Co-Processor Parameter Routing...";

        wait until fft_en = '1';
        wait for 1 ns;

        assert (unit_select = APU_UNIT_FFT) report "Wrong unit selection for FFT" severity failure;
        assert (fwd_inv = '1')             report "Direction selection failed to configure to Forward mode" severity failure;
        assert (fft_size = '1')            report "Size matrix flag config failed" severity failure;
        assert (fft_olw = std_logic_vector(to_unsigned(8, 10))) report "FFT output offset vector length error" severity failure;

        wait until rising_edge(clk);
        fft_end <= '1';
        wait until rising_edge(clk);
        fft_end <= '0';

        -- Set 'start' back to 0
        host_addr <= 1;
        host_data <= std_logic_vector(to_unsigned(2, ARAM_WORD_SIZE));
        host_we   <= '1';

        -- --------------------------------------------------------
        -- TEST CASE 3: PARALLEL VECTOR UNIT EXECUTION
        -- --------------------------------------------------------
        report "[TEST] Launching Parallel SIMD Vector Instruction Mapping...";

        wait until vec_en = '1';
        wait for 1 ns;

        assert (unit_select = APU_UNIT_VEC) report "Wrong unit selection for Vector Unit" severity failure;
        assert (vec_op = VEC_OP_ADDV)        report "Opcode transformation lookup map broke for ADDV" severity failure;
        assert (vec_bsr1 = "0010101010")    report "Vector Operand Address Bus 1 mismatch" severity failure;
        assert (vec_bsr2 = "0100010001")    report "Vector Operand Address Bus 2 mismatch" severity failure;

        wait until rising_edge(clk);
        vec_end <= '1';
        wait until rising_edge(clk);
        vec_end <= '0';

        -- --------------------------------------------------------
        -- TEST CASE 4: IMMEDIATE SCALAR FIELD ISOLATION
        -- --------------------------------------------------------
        report "[TEST] Launching Scalar Immediate Value Routing & Bus Isolation Checks...";

        wait until vec_en = '1';
        wait for 1 ns;

        assert (vec_op = VEC_OP_MULS)      report "Opcode transformation lookup map broke for MULS" severity failure;
        assert (vec_scalar = X"DEAD")      report "Immediate Scalar value pipeline routing missed" severity failure;
        assert (vec_bsr2 = "0000000000")   report "Address Leakage! Buffer Read 2 must clear out during active scalar cycles" severity failure;
        
        wait until rising_edge(clk);
        vec_end <= '1';
        wait until rising_edge(clk);
        vec_end <= '0';

        -- --------------------------------------------------------
        -- TEST CASE 5: STEREO PING-PONG HANDSHAKE (STOP COMMAND)
        -- --------------------------------------------------------
        report "[TEST] Testing Stereo Interleaved Channel Sync (STOP Ping-Pong)...";
        
        -- System starts default tracking set to Left Channel (0)
        assert (aio_lr = '0') report "System failed default Left audio channel alignment assertion" severity failure;
        
        -- Wait for STOP command to flip channel pointer to Right Channel ('1')
        wait until aio_lr = '1';
        wait for 1 ns;
        assert (aio_lr = '1') report "Channel pointer failed to transition to Right channel track processing" severity failure;
        
        -- --- SECOND PASS (RIGHT CHANNEL): CLEAR PIPELINE INTERLEAVE ---

        -- 1. Trigger & Clear Audio IO
        wait until aio_en = '1';
        wait until rising_edge(clk); aio_end <= '1';
        wait until rising_edge(clk); aio_end <= '0';

        -- 2. Trigger & Clear FFT
        wait until fft_en = '1';
        wait until rising_edge(clk); fft_end <= '1';
        wait until rising_edge(clk); fft_end <= '0';

        -- 3. Trigger & Clear Vector ADD
        wait until vec_en = '1';
        wait until rising_edge(clk); vec_end <= '1';
        wait until rising_edge(clk); vec_end <= '0';

        -- 4. Trigger & Clear Vector MUL
        wait until vec_en = '1';
        wait until rising_edge(clk); vec_end <= '1';
        wait until rising_edge(clk); vec_end <= '0';
        
        -- Wait for system to safely return to Left channel tracking (and back into IDLE state)
        wait until aio_lr = '0';
        wait for 1 ns;

        -- System finishes channel pass 2 loops: clears back to zero status safely inside IDLE block state boundary
        assert (aio_lr = '0') report "Reset sequence to Left channel failed at frame exit path boundaries" severity failure;
        
        report "----------------------------------------------------";
        report "[PASSED] ALL AUDIO CONTROL UNIT TEST CASES CLEAR!";
        report "----------------------------------------------------";
        
        wait; -- Suspension ends simulation run
    end process;

end sim;