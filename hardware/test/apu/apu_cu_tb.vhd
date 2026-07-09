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
    -- Geometry Parameters
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

    -- Shared BRAM Interfacing (CU Ports)
    signal iwe, ien  : std_logic;
    signal iaddr     : std_logic_vector(INSTR_ADDR_SIZE-1 downto 0);
    signal idata_in  : std_logic_vector(ARAM_WORD_SIZE-1 downto 0);
    signal idata_out : std_logic_vector(ARAM_WORD_SIZE-1 downto 0) := (others => '0');

    -- Outside CPU (Host) BRAM Interfacing
    signal host_we   : std_logic := '0';
    signal host_addr : integer := 0;
    signal host_data : std_logic_vector(ARAM_WORD_SIZE-1 downto 0) := (others => '0');
    
    -- Audio IO Interfacing
    signal aio_new_grain, aio_in_end, aio_out_end : std_logic := '0';
    signal aio_in_en, aio_in_lr, aio_out_en, aio_out_lr : std_logic;
    signal aio_in_bs, aio_in_bl, aio_in_os, aio_in_ol : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal aio_out_bs, aio_out_bl, aio_out_os, aio_out_ol : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);

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

    -- Memory Storage
    type ram_type is array (0 to MEM_DEPTH-1) of std_logic_vector(ARAM_WORD_SIZE-1 downto 0);
    signal shared_bram : ram_type := (others => (others => '0'));

    constant CLK_PERIOD : time := 10 ns;

begin

    uut: entity work.AudioCU
        generic map (
            ARAM_WORD_SIZE => ARAM_WORD_SIZE,
            ARAM_ADDR_SIZE => ARAM_ADDR_SIZE,
            INSTR_ADDR_SIZE=> INSTR_ADDR_SIZE,
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
            aio_in_end      => aio_in_end,
            aio_out_end     => aio_out_end,
            aio_in_en       => aio_in_en,
            aio_in_lr       => aio_in_lr,
            aio_in_bs       => aio_in_bs,
            aio_in_bl       => aio_in_bl,
            aio_in_os       => aio_in_os,
            aio_in_ol       => aio_in_ol,
            aio_out_en      => aio_out_en,
            aio_out_lr      => aio_out_lr,
            aio_out_bs      => aio_out_bs,
            aio_out_bl      => aio_out_bl,
            aio_out_os      => aio_out_os,
            aio_out_ol      => aio_out_ol,
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

    -- Clock Generation
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Dual Port BRAM
    bram_process : process(clk)
        variable addr_idx : integer;
    begin
        if rising_edge(clk) then
            if ien = '1' then
                addr_idx := to_integer(unsigned(iaddr));
                if iwe = '1' then
                    shared_bram(addr_idx) <= idata_in;
                else
                    idata_out <= shared_bram(addr_idx);
                end if;
            end if;
            if host_we = '1' then
                shared_bram(host_addr) <= host_data;
            end if;
        end if;
    end process;

    -- Main Test Sequence
    stim_proc: process
        variable v_instr : std_logic_vector(127 downto 0);

        -- Helper to write single 32-bit values synchronously
        procedure write_bram(constant addr : in integer; constant data : in std_logic_vector(31 downto 0)) is
        begin
            wait until rising_edge(clk);
            host_addr <= addr;
            host_data <= data;
            host_we   <= '1';
            wait until rising_edge(clk);
            host_we   <= '0';
        end procedure;

        -- Helper to load 128-bit Shader Blocks
        procedure load_instruction(constant base_word_addr : in integer; constant full_instr : in std_logic_vector(127 downto 0)) is
        begin
            write_bram(base_word_addr,     full_instr(127 downto 96));
            write_bram(base_word_addr + 1, full_instr(95 downto 64));
            write_bram(base_word_addr + 2, full_instr(63 downto 32));
            write_bram(base_word_addr + 3, full_instr(31 downto 0));
        end procedure;

    begin		
        rst <= '0';
        aio_new_grain <= '0';
        aio_in_end <= '0'; aio_out_end <= '0'; fft_end <= '0'; vec_end <= '0';
        wait for CLK_PERIOD * 2;

        report "[INIT] Preloading Pointer-Dereference Parameter Memory Tables...";

        -- POPULATE LEFT CHANNEL PARAMETERS (Offsets 1024 to 1051)
        -- We write distinct values (0x100 to 0x11B) so we can verify them later
        for i in 0 to 27 loop
            write_bram(1024 + i, std_logic_vector(to_unsigned(16#100# + i, ARAM_WORD_SIZE)));
        end loop;

        -- POPULATE RIGHT CHANNEL PARAMETERS (Offsets 1536 to 1563)
        -- We write distinct values (0x200 to 0x21B)
        for i in 0 to 27 loop
            write_bram(1536 + i, std_logic_vector(to_unsigned(16#200# + i, ARAM_WORD_SIZE)));
        end loop;

        report "[INIT] Building and Storing Shader Assembly (using 9-bit pointers)...";

        -- 1. AUDIO_IN (Pointers 0, 1, 2, 3)
        v_instr := (others => '0');
        v_instr(127 downto 124) := "1100";
        v_instr(35 downto 27)   := std_logic_vector(to_unsigned(0, 9)); -- bs
        v_instr(26 downto 18)   := std_logic_vector(to_unsigned(1, 9)); -- bl
        v_instr(17 downto 9)    := std_logic_vector(to_unsigned(2, 9)); -- os
        v_instr(8 downto 0)     := std_logic_vector(to_unsigned(3, 9)); -- op_len
        load_instruction(3, v_instr);

        -- 2. FFT (Pointers 4 through 10)
        v_instr := (others => '0');
        v_instr(127 downto 124) := "0001";
        v_instr(123)            := '1'; -- Forward
        v_instr(122)            := '1'; -- Size flag
        v_instr(89 downto 81)   := std_logic_vector(to_unsigned(4, 9)); -- out_bs
        v_instr(80 downto 72)   := std_logic_vector(to_unsigned(5, 9)); -- out_bl
        v_instr(71 downto 63)   := std_logic_vector(to_unsigned(6, 9)); -- out_os
        v_instr(35 downto 27)   := std_logic_vector(to_unsigned(7, 9)); -- in1_bs
        v_instr(26 downto 18)   := std_logic_vector(to_unsigned(8, 9)); -- in1_bl
        v_instr(17 downto 9)    := std_logic_vector(to_unsigned(9, 9)); -- in1_os
        v_instr(8 downto 0)     := std_logic_vector(to_unsigned(10, 9)); -- op_len
        load_instruction(7, v_instr);

        -- 3. ADD_VEC (Pointers 11 through 20)
        v_instr := (others => '0');
        v_instr(127 downto 124) := "0011";
        v_instr(89 downto 81)   := std_logic_vector(to_unsigned(11, 9)); -- out_bs
        v_instr(80 downto 72)   := std_logic_vector(to_unsigned(12, 9)); -- out_bl
        v_instr(71 downto 63)   := std_logic_vector(to_unsigned(13, 9)); -- out_os
        v_instr(62 downto 54)   := std_logic_vector(to_unsigned(14, 9)); -- in2_bs
        v_instr(53 downto 45)   := std_logic_vector(to_unsigned(15, 9)); -- in2_bl
        v_instr(44 downto 36)   := std_logic_vector(to_unsigned(16, 9)); -- in2_os
        v_instr(35 downto 27)   := std_logic_vector(to_unsigned(17, 9)); -- in1_bs
        v_instr(26 downto 18)   := std_logic_vector(to_unsigned(18, 9)); -- in1_bl
        v_instr(17 downto 9)    := std_logic_vector(to_unsigned(19, 9)); -- in1_os
        v_instr(8 downto 0)     := std_logic_vector(to_unsigned(20, 9)); -- op_len
        load_instruction(11, v_instr);

        -- 4. MUL_SCALAR (Pointers 21 to 27)
        v_instr := (others => '0');
        v_instr(127 downto 124) := "1000";
        v_instr(89 downto 81)   := std_logic_vector(to_unsigned(21, 9)); -- out_bs
        v_instr(80 downto 72)   := std_logic_vector(to_unsigned(22, 9)); -- out_bl
        v_instr(71 downto 63)   := std_logic_vector(to_unsigned(23, 9)); -- out_os
        v_instr(51 downto 36)   := X"DEAD";                              -- absolute scalar value
        v_instr(35 downto 27)   := std_logic_vector(to_unsigned(24, 9)); -- in1_bs
        v_instr(26 downto 18)   := std_logic_vector(to_unsigned(25, 9)); -- in1_bl
        v_instr(17 downto 9)    := std_logic_vector(to_unsigned(26, 9)); -- in1_os
        v_instr(8 downto 0)     := std_logic_vector(to_unsigned(27, 9)); -- op_len
        load_instruction(15, v_instr);

        -- 5. STOP Command
        v_instr := (others => '0');
        v_instr(127 downto 124) := "1111";
        load_instruction(19, v_instr);

        -- Release System Reset
        wait until rising_edge(clk);
        rst <= '1';
        wait for CLK_PERIOD * 2;

        report "--- STARTING AUDIO CONTROL UNIT VHDL TESTBENCH RUN ---";

        -- Loop the entire execution sequence 50 times
        for iteration in 1 to 5 loop
            report "=== STARTING ITERATION " & integer'image(iteration) & " ===";

            -- Trigger start flag + assign start_address=3 to addr 1 (Combined value = 3)
            write_bram(1, std_logic_vector(to_unsigned(3, ARAM_WORD_SIZE)));

            -- Wait 3 clock cycles (Fast enough to not miss the hardware execution)
            for i in 0 to 2 loop
                wait until rising_edge(clk);
            end loop;

            -- Clear the start bit (Bit 0 = 0, keeping address bits -> value 2)
            write_bram(1, std_logic_vector(to_unsigned(2, ARAM_WORD_SIZE)));

            -- ====================================================================
            -- PHASE 1: LEFT CHANNEL VALIDATION (Should dereference from 1024+)
            -- ====================================================================
            
            -- 1. AUDIO_IN 
            wait until aio_in_en = '1'; wait for 1 ns;
            assert (unit_select = APU_UNIT_AUDIO_IN) report "Wrong unit selection for Audio In" severity failure;
            assert (aio_in_bs = std_logic_vector(to_unsigned(16#100#, ARAM_ADDR_SIZE))) report "Left Deref Failed: aio_in_bs" severity failure;
            assert (aio_in_bl = std_logic_vector(to_unsigned(16#101#, ARAM_ADDR_SIZE))) report "Left Deref Failed: aio_in_bl" severity failure;
            assert (aio_in_os = std_logic_vector(to_unsigned(16#102#, ARAM_ADDR_SIZE))) report "Left Deref Failed: aio_in_os" severity failure;
            assert (aio_in_ol = std_logic_vector(to_unsigned(16#103#, ARAM_ADDR_SIZE))) report "Left Deref Failed: aio_in_ol" severity failure;
            wait until rising_edge(clk); aio_in_end <= '1'; wait until rising_edge(clk); aio_in_end <= '0';

            -- 2. FFT 
            wait until fft_en = '1'; wait for 1 ns;
            assert (fft_bsw = std_logic_vector(to_unsigned(16#104#, ARAM_ADDR_SIZE))) report "Left Deref Failed: fft_bsw" severity failure;
            assert (fft_bsr = std_logic_vector(to_unsigned(16#107#, ARAM_ADDR_SIZE))) report "Left Deref Failed: fft_bsr" severity failure;
            wait until rising_edge(clk); fft_end <= '1'; wait until rising_edge(clk); fft_end <= '0';

            -- 3. VEC_ADD 
            wait until vec_en = '1'; wait for 1 ns;
            assert (vec_bsw = std_logic_vector(to_unsigned(16#10B#, ARAM_ADDR_SIZE))) report "Left Deref Failed: vec_bsw" severity failure;
            assert (vec_bsr2 = std_logic_vector(to_unsigned(16#10E#, ARAM_ADDR_SIZE))) report "Left Deref Failed: vec_bsr2" severity failure;
            assert (vec_bsr1 = std_logic_vector(to_unsigned(16#111#, ARAM_ADDR_SIZE))) report "Left Deref Failed: vec_bsr1" severity failure;
            wait until rising_edge(clk); vec_end <= '1'; wait until rising_edge(clk); vec_end <= '0';

            -- 4. VEC_MUL_SCALAR 
            wait until vec_en = '1'; wait for 1 ns;
            assert (vec_scalar = X"DEAD") report "Immediate scalar payload mapping missed" severity failure;
            assert (vec_bsw = std_logic_vector(to_unsigned(16#115#, ARAM_ADDR_SIZE))) report "Left Deref Failed: vec_bsw (scalar)" severity failure;
            assert (vec_bsr1 = std_logic_vector(to_unsigned(16#118#, ARAM_ADDR_SIZE))) report "Left Deref Failed: vec_bsr1 (scalar)" severity failure;
            wait until rising_edge(clk); vec_end <= '1'; wait until rising_edge(clk); vec_end <= '0';

            -- Wait for STOP command to flip the internal channel tracking to Right
            wait until aio_in_lr = '1'; 
            wait for 1 ns;

            -- ====================================================================
            -- PHASE 2: RIGHT CHANNEL VALIDATION (Should dereference from 1536+)
            -- ====================================================================
            
            -- 1. AUDIO_IN 
            wait until aio_in_en = '1'; wait for 1 ns;
            assert (aio_in_bs = std_logic_vector(to_unsigned(16#200#, ARAM_ADDR_SIZE))) report "Right Deref Failed: aio_in_bs" severity failure;
            assert (aio_in_bl = std_logic_vector(to_unsigned(16#201#, ARAM_ADDR_SIZE))) report "Right Deref Failed: aio_in_bl" severity failure;
            assert (aio_in_os = std_logic_vector(to_unsigned(16#202#, ARAM_ADDR_SIZE))) report "Right Deref Failed: aio_in_os" severity failure;
            assert (aio_in_ol = std_logic_vector(to_unsigned(16#203#, ARAM_ADDR_SIZE))) report "Right Deref Failed: aio_in_ol" severity failure;
            wait until rising_edge(clk); aio_in_end <= '1'; wait until rising_edge(clk); aio_in_end <= '0';

            -- 2. FFT 
            wait until fft_en = '1'; wait for 1 ns;
            assert (fft_bsw = std_logic_vector(to_unsigned(16#204#, ARAM_ADDR_SIZE))) report "Right Deref Failed: fft_bsw" severity failure;
            assert (fft_bsr = std_logic_vector(to_unsigned(16#207#, ARAM_ADDR_SIZE))) report "Right Deref Failed: fft_bsr" severity failure;
            wait until rising_edge(clk); fft_end <= '1'; wait until rising_edge(clk); fft_end <= '0';

            -- 3. VEC_ADD 
            wait until vec_en = '1'; wait for 1 ns;
            assert (vec_bsw = std_logic_vector(to_unsigned(16#20B#, ARAM_ADDR_SIZE))) report "Right Deref Failed: vec_bsw" severity failure;
            assert (vec_bsr2 = std_logic_vector(to_unsigned(16#20E#, ARAM_ADDR_SIZE))) report "Right Deref Failed: vec_bsr2" severity failure;
            assert (vec_bsr1 = std_logic_vector(to_unsigned(16#211#, ARAM_ADDR_SIZE))) report "Right Deref Failed: vec_bsr1" severity failure;
            wait until rising_edge(clk); vec_end <= '1'; wait until rising_edge(clk); vec_end <= '0';

            -- 4. VEC_MUL_SCALAR 
            wait until vec_en = '1'; wait for 1 ns;
            assert (vec_bsw = std_logic_vector(to_unsigned(16#215#, ARAM_ADDR_SIZE))) report "Right Deref Failed: vec_bsw (scalar)" severity failure;
            assert (vec_bsr1 = std_logic_vector(to_unsigned(16#218#, ARAM_ADDR_SIZE))) report "Right Deref Failed: vec_bsr1 (scalar)" severity failure;
            wait until rising_edge(clk); vec_end <= '1'; wait until rising_edge(clk); vec_end <= '0';
            
            -- Wait for system to safely return to Left channel tracking (and back into IDLE state)
            wait until aio_in_lr = '0';
            wait for 1 ns;
            
            report "[PASS] Iteration " & integer'image(iteration) & " complete.";
        end loop;

        report "----------------------------------------------------";
        report "[PASSED] ALL MULTIPLE-ITERATION TEST CASES CLEAR!";
        report "----------------------------------------------------";

        -- Ensure start bit is strictly 0 (Address 1, Bit 0 = 0. Keeping address bits = 2)
        write_bram(1, std_logic_vector(to_unsigned(2, ARAM_WORD_SIZE)));

        -- Wait for 100 clock cycles and verify no execution units wake up
        for i in 0 to 20 loop
            wait until rising_edge(clk);
            
            -- Assert that all unit enable signals safely remain 0
            assert (aio_in_en = '0' and aio_out_en = '0' and fft_en = '0' and vec_en = '0') 
                report "FATAL: Hardware woke up and executed instructions without start bit!" severity failure;
        end loop;

        report "----------------------------------------------------";
        report "[PASSED] ALL MULTIPLE-ITERATION & IDLE TEST CASES CLEAR!";
        report "----------------------------------------------------";
        
        wait; -- Suspension ends simulation run
    end process;

end sim;