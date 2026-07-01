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
    constant RAM_WORD_SIZE  : integer := 32;
    constant ARAM_ADDR_SIZE : integer := 10;
    constant INSTR_SIZE     : integer := 128;
    constant MEM_DEPTH      : integer := 256;

    -- --------------------------------------------------------
    -- Testbench Clock & Control Signals
    -- --------------------------------------------------------
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '0';
    signal en    : std_logic := '0';
    signal update: std_logic := '0';
    signal prog_addr_start : std_logic_vector(RAM_WORD_SIZE-1 downto 0) := (others => '0');

    -- ARAM Interfacing
    signal unit_select : apu_unit_t;
    
    -- RAM Interfacing
    signal ram_we, ram_en : std_logic;
    signal ram_addr, ram_din : std_logic_vector(RAM_WORD_SIZE-1 downto 0);
    signal ram_dout : std_logic_vector(RAM_WORD_SIZE-1 downto 0) := (others => '0');
    
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
    -- Mock Instruction Memory Type
    -- --------------------------------------------------------
    type ram_type is array (0 to MEM_DEPTH-1) of std_logic_vector(RAM_WORD_SIZE-1 downto 0);

    impure function init_mock_ram return ram_type is
        variable mem : ram_type := (others => (others => '0'));
        variable v_instr : std_logic_vector(127 downto 0);

        procedure load_instruction(base : integer; instr : std_logic_vector(127 downto 0)) is
        begin
            mem(base)   := instr(127 downto 96);
            mem(base+1) := instr(95 downto 64);
            mem(base+2) := instr(63 downto 32);
            mem(base+3) := instr(31 downto 0);
        end procedure;
    begin
         -- Address 0: APU_OP_AUDIO_IN (1100), bs=0x123, bl=0x05A, os=0x210, ol=0x0FF
        v_instr := (others => '0');
        v_instr(127 downto 124) := "1100"; 
        v_instr(123 downto 114) := "0100100011"; -- 0x123
        v_instr(113 downto 104) := "0001011010"; -- 0x05A
        v_instr(103 downto 94)  := "1000010000"; -- 0x210
        v_instr(93 downto 84)   := "0011111111"; -- 0x0FF
        load_instruction(0, v_instr);

        -- Address 4: APU_OP_FFT (0001), size=1, bsr=1, blr=2, osr=3, olr=4, bsw=5, blw=6, osw=7, olw=8
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
        load_instruction(4, v_instr);

        -- Address 8: APU_OP_ADD_VECTOR (0011), bsr1=0xAA, blr1=0xBB, osr1=0xCC, olr1=0xDD, bsr2=0x111...
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
        load_instruction(8, v_instr);

        -- Address 12: APU_OP_MUL_SCALAR (1000), bsr1=5, blr1=10, scalar=0xDEAD, bsw=0x300...
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
        load_instruction(12, v_instr);

        -- Address 16: APU_OP_STOP (1111)
        v_instr := (others => '0');
        v_instr(127 downto 124) := "1111";
        load_instruction(16, v_instr);

        return mem;
    end function;

    signal instruction_ram : ram_type := init_mock_ram;

    -- Clock Period Constant (100MHz System Clock)
    constant CLK_PERIOD : time := 10 ns;

begin

    -- --------------------------------------------------------
    -- Device Under Test (DUT) Instantiation
    -- --------------------------------------------------------
    uut: entity work.AudioCU
        generic map (
            RAM_WORD_SIZE  => RAM_WORD_SIZE,
            ARAM_ADDR_SIZE => ARAM_ADDR_SIZE,
            INSTR_SIZE     => INSTR_SIZE
        )
        port map (
            clk             => clk,
            rst             => rst,
            en              => en,
            update          => update,
            prog_addr_start => prog_addr_start,
            unit_select     => unit_select,
            ram_we          => ram_we,
            ram_en          => ram_en,
            ram_addr        => ram_addr,
            ram_din         => ram_din,
            ram_dout        => ram_dout,
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
    -- Mock Instruction Memory (Synchronous Single-Cycle RAM)
    -- --------------------------------------------------------
    ram_process : process(clk)
        variable addr_idx : integer;
    begin
        if rising_edge(clk) then
            if ram_en = '1' then
                addr_idx := to_integer(unsigned(ram_addr(7 downto 0)));
                if ram_we = '1' then
                    instruction_ram(addr_idx) <= ram_din;
                else
                    ram_dout <= instruction_ram(addr_idx);
                end if;
            end if;
        end if;
    end process;

    -- --------------------------------------------------------
    -- Main Stimulus Process
    -- --------------------------------------------------------
    stim_proc: process
        variable v_instr : std_logic_vector(127 downto 0);

        -- Local procedure to parse and inject full 128-bit blocks into the RAM signal array
        procedure load_instruction(
            constant base_word_addr : in integer;
            constant full_instr     : in std_logic_vector(127 downto 0)
        ) is
        begin
            instruction_ram(base_word_addr)     <= full_instr(127 downto 96);
            instruction_ram(base_word_addr + 1) <= full_instr(95 downto 64);
            instruction_ram(base_word_addr + 2) <= full_instr(63 downto 32);
            instruction_ram(base_word_addr + 3) <= full_instr(31 downto 0);
        end procedure;

    begin		
        -- Initial State Holds
        rst             <= '0';
        en              <= '0';
        update          <= '0';
        prog_addr_start <= (others => '0');
        aio_new_grain   <= '0';
        aio_end         <= '0';
        fft_end         <= '0';
        vec_end         <= '0';
        wait for CLK_PERIOD * 2;

        -- Release System Reset
        wait until rising_edge(clk);
        rst <= '1';
        en  <= '1';
        wait for CLK_PERIOD * 2;

        report "--- STARTING AUDIO CONTROL UNIT VHDL TESTBENCH RUN ---";

        -- --------------------------------------------------------
        -- TEST CASE 1: AUDIO INPUT INSTRUCTION MAPPING
        -- --------------------------------------------------------
        report "[TEST] Launching Audio Input Core Validation...";
        prog_addr_start <= std_logic_vector(to_unsigned(0, RAM_WORD_SIZE));
        wait until rising_edge(clk);
        update <= '1';
        wait until rising_edge(clk);
        update <= '0';

        wait until aio_en = '1';
        wait for 1 ns; -- Step away from clock edge for safe combinatorial sampling

        assert (unit_select = APU_UNIT_AUDIO_IO) report "Wrong unit selection for Audio IO" severity failure;
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
        prog_addr_start <= std_logic_vector(to_unsigned(4, RAM_WORD_SIZE));
        wait until rising_edge(clk);
        update <= '1';
        wait until rising_edge(clk);
        update <= '0';

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


        -- --------------------------------------------------------
        -- TEST CASE 3: PARALLEL VECTOR UNIT EXECUTION
        -- --------------------------------------------------------
        report "[TEST] Launching Parallel SIMD Vector Instruction Mapping...";
        prog_addr_start <= std_logic_vector(to_unsigned(8, RAM_WORD_SIZE));
        wait until rising_edge(clk);
        update <= '1';
        wait until rising_edge(clk);
        update <= '0';

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
        prog_addr_start <= std_logic_vector(to_unsigned(12, RAM_WORD_SIZE));
        wait until rising_edge(clk);
        update <= '1';
        wait until rising_edge(clk);
        update <= '0';

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
        prog_addr_start <= std_logic_vector(to_unsigned(16, RAM_WORD_SIZE));
        
        -- System starts default tracking set to Left Channel (0)
        assert (aio_lr = '0') report "System failed default Left audio channel alignment assertion" severity failure;
        
        wait until rising_edge(clk);
        update <= '1';
        wait until rising_edge(clk);
        update <= '0';

        -- Await target parsing loop return jump inside the control engine
        wait for CLK_PERIOD * 6; 
        wait for 1 ns;

        -- Channel pointer must flip to Right channel ('1') and re-enter processing matrix loops
        assert (aio_lr = '1') report "Channel pointer failed to transition to Right channel track processing" severity failure;
        
        -- Let the second iteration run through FETCH and decode the same STOP instruction
        wait for CLK_PERIOD * 6;
        wait for 1 ns;

        -- System finishes second phase loop: returns safely to '0' tracking status inside IDLE block state
        assert (aio_lr = '0') report "Reset sequence to Left channel failed at frame exit path boundaries" severity failure;

        report "----------------------------------------------------";
        report "[PASSED] ALL AUDIO CONTROL UNIT TEST CASES CLEAR!";
        report "----------------------------------------------------";
        
        wait; -- Forever suspension ends simulation test bench
    end process;

end sim;