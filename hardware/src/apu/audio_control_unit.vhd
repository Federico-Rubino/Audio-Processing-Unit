library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.apu_opcode_pkg.all;
use work.apu_internal_pkg.all;

entity AudioCU is
    Generic(
        ARAM_WORD_SIZE : integer := 32;     -- word size of aram and iram
        ARAM_ADDR_SIZE : integer := 16;     -- size needed to address a ARAM location
        INSTR_ADDR_SIZE : integer := 11;    -- size needed to address a instruction RAM location
        UPARAM_SIZE : integer := 9;         -- size of a uniform param
        INSTR_SIZE : integer := 128;        -- currently the max is 4*ARAM_WORD_SIZE
        COUNTER_SIZE : integer := 16
    );
    Port (
        clk, rst : in std_logic;

        -- ARAM Interfacing
        unit_select : out apu_unit_t;

        -- Instr RAM Interfacing
        iwe, ien  : out std_logic;
        iaddr     : out std_logic_vector(INSTR_ADDR_SIZE-1 downto 0);
        idata_in  : out std_logic_vector(ARAM_WORD_SIZE-1 downto 0);
        idata_out : in  std_logic_vector(ARAM_WORD_SIZE-1 downto 0);
        
        -- Audio IO Interfacing
        aio_new_grain, aio_in_end, aio_out_end : in std_logic;
        aio_in_en, aio_in_lr : out std_logic;
        aio_in_bs, aio_in_bl, aio_in_os, aio_in_ol : out std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
        aio_out_en, aio_out_lr : out std_logic;
        aio_out_bs, aio_out_bl, aio_out_os, aio_out_ol : out std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);

        -- FFT Unit Interfacing
        fft_end : in std_logic;
        fft_en, fft_size, fwd_inv : out std_logic;
        fft_bsr, fft_blr, fft_osr, fft_olr : out std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
        fft_bsw, fft_blw, fft_osw, fft_olw : out std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);

        -- Parallel ALU Interfacing
        vec_end : in std_logic;
        vec_en : out std_logic;
        vec_op : out vec_op_t;
        vec_scalar : out std_logic_vector(15 downto 0);
        vec_bsr1, vec_blr1, vec_osr1, vec_olr1 : out std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
        vec_bsr2, vec_blr2, vec_osr2, vec_olr2 : out std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
        vec_bsw, vec_blw, vec_osw, vec_olw : out std_logic_vector(ARAM_ADDR_SIZE-1 downto 0)
    );
end AudioCU;

architecture Behavioral of AudioCU is
    -- TODO implement load operation with a STORE stage
    type cu_state is (IDLE, SETUP, FETCH, DECODE, LOAD, EXECUTE);
    signal state, next_state : cu_state;
    signal lr, next_lr : std_logic; -- 0=left, 1=right
    signal counter, next_counter : std_logic_vector(COUNTER_SIZE-1 downto 0);
    signal op, next_op : apu_code_t;
    signal instr, next_instr : std_logic_vector(INSTR_SIZE-1 downto 0);
    signal pc, next_pc : std_logic_vector(INSTR_ADDR_SIZE-2 downto 0);
    signal buf1, next_buf1 : std_logic_vector(ARAM_ADDR_SIZE*3-1 downto 0); -- 29:20 buff start, 19:10 buff len, 9:0 op start
    signal buf2, next_buf2 : std_logic_vector(ARAM_ADDR_SIZE*3-1 downto 0);
    signal buf3, next_buf3 : std_logic_vector(ARAM_ADDR_SIZE*3-1 downto 0);
    signal op_len, next_op_len : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal new_grain, next_new_grain : std_logic;
    signal start_addr, next_start_addr : std_logic_vector(INSTR_ADDR_SIZE-2 downto 0);

    constant TO_CPU_ADDR : std_logic_vector(INSTR_ADDR_SIZE-1 downto 0) := (others => '0');
    constant FROM_CPU_ADDR : std_logic_vector(INSTR_ADDR_SIZE-1 downto 0) := std_logic_vector(to_unsigned(1, INSTR_ADDR_SIZE));
    constant SHADER_MEM_OFFSET : integer := 2; -- shader_mem[0] is instr_bram word 2, after status (word 0) and control (word 1)

begin

    -- Sequential Process
    process(clk, rst)
    begin
        if rst = '0' then
            state <= IDLE;
            lr <= '0';
            counter <= (others => '0');
            op <= APU_NOP;
            instr <= (others => '0');
            pc <= (others => '0');
            buf1 <= (others => '0');
            buf2 <= (others => '0');
            buf3 <= (others => '0');
            op_len <= (others => '0');
            new_grain <= '0';
            start_addr <= (others => '0');
        elsif rising_edge(clk) then
            state <= next_state;
            lr <= next_lr;
            counter <= next_counter;
            op <= next_op;
            instr <= next_instr;
            pc <= next_pc;
            buf1 <= next_buf1;
            buf2 <= next_buf2;
            buf3 <= next_buf3;
            op_len <= next_op_len;
            new_grain <= next_new_grain;
            start_addr <= next_start_addr;
        end if;
    end process;

    -- Combinational Process
    process(all)
    begin
        -- Default assignments
        next_state <= state;
        next_lr <= lr;
        next_counter <= counter;
        next_op <= op;
        next_instr <= instr;
        next_pc <= pc;
        next_buf1 <= buf1;
        next_buf2 <= buf2;
        next_buf3 <= buf3;
        next_op_len <= op_len;
        next_new_grain <= new_grain;
        next_start_addr <= start_addr;
        
        ien <= '0'; iwe <= '0';
        iaddr <= (others => '0'); idata_in <= (others => '0');
        unit_select <= APU_UNIT_NONE;
        aio_in_en <= '0'; aio_in_lr <= lr;
        aio_in_bs <= (others => '0'); aio_in_bl <= (others => '0'); aio_in_os <= (others => '0'); aio_in_ol <= (others => '0');
        aio_out_en <= '0'; aio_out_lr <= lr;
        aio_out_bs <= (others => '0'); aio_out_bl <= (others => '0'); aio_out_os <= (others => '0'); aio_out_ol <= (others => '0');
        fft_en <= '0'; fft_size <= '0'; fwd_inv <= '0';
        fft_bsr <= (others => '0'); fft_blr <= (others => '0'); fft_osr <= (others => '0'); fft_olr <= (others => '0');
        fft_bsw <= (others => '0'); fft_blw <= (others => '0'); fft_osw <= (others => '0'); fft_olw <= (others => '0');
        vec_en <= '0'; vec_op <= (others => '0');
        vec_scalar <= (others => '0');
        vec_bsr1 <= (others => '0'); vec_blr1 <= (others => '0'); vec_osr1 <= (others => '0'); vec_olr1 <= (others => '0');
        vec_bsr2 <= (others => '0'); vec_blr2 <= (others => '0'); vec_osr2 <= (others => '0'); vec_olr2 <= (others => '0');
        vec_bsw <= (others => '0'); vec_blw <= (others => '0'); vec_osw <= (others => '0'); vec_olw <= (others => '0');

        case state is
            when IDLE =>
                ien <= '1'; iwe <= '0';
                iaddr <= FROM_CPU_ADDR;

                if idata_out(0) = '1' then  -- check start signal written by CPU (on the first iteration idata_out is relative to another address, but bit 0 is always '0' so is doesn't go to state SETUP)
                    next_state <= SETUP;
                    next_start_addr <= idata_out(INSTR_ADDR_SIZE-1 downto 1);

                    -- set 'busy' to 1
                    ien <= '1'; iwe <= '1';
                    iaddr <= TO_CPU_ADDR;
                    idata_in <= (others => '0');
                    idata_in(1) <= '1';
                    idata_in(2) <= new_grain;

                elsif new_grain = '0' and aio_new_grain = '1' then  -- update new grain value
                    iwe <= '1';
                    iaddr <= TO_CPU_ADDR;
                    idata_in <= (others => '0');
                    idata_in(2) <= '1';
                    next_new_grain <= '1';

                end if;

            when SETUP =>
                next_state <= FETCH;
                next_counter <= std_logic_vector(to_unsigned(INSTR_SIZE / ARAM_WORD_SIZE - 1, COUNTER_SIZE));
                next_pc <= std_logic_vector(unsigned(start_addr) + SHADER_MEM_OFFSET + 1);

                ien <= '1'; iwe <= '0';
                iaddr <= (others => '0');
                iaddr(INSTR_ADDR_SIZE-2 downto 0) <= std_logic_vector(unsigned(start_addr) + SHADER_MEM_OFFSET);

            when FETCH =>
                next_counter <= std_logic_vector(unsigned(counter) - 1);
                next_pc <= std_logic_vector(unsigned(pc) + 1);
                ien <= '1'; iwe <= '0';
                iaddr <= (others => '0');
                iaddr (INSTR_ADDR_SIZE-2 downto 0) <= pc;

                -- Load the correct part of the instruction
                if    unsigned(counter) = 0 then next_instr(ARAM_WORD_SIZE-1 downto 0) <= idata_out;
                elsif unsigned(counter) = 1 then next_instr(2*ARAM_WORD_SIZE-1 downto ARAM_WORD_SIZE) <= idata_out;
                elsif unsigned(counter) = 2 then next_instr(3*ARAM_WORD_SIZE-1 downto 2*ARAM_WORD_SIZE) <= idata_out;
                elsif unsigned(counter) = 3 then next_instr(4*ARAM_WORD_SIZE-1 downto 3*ARAM_WORD_SIZE) <= idata_out;
                end if;

                if unsigned(counter) = 0 then
                    next_state <= DECODE;
                    ien <= '0';
                    next_pc <= pc;
                end if;

            when DECODE =>
                next_op <= instr(INSTR_SIZE-1 downto INSTR_SIZE-APU_OP_WIDTH);

                -- if op is stop, then execute go to idle or to the other channel,
                -- otherwise transition to load state
                if instr(INSTR_SIZE-1 downto INSTR_SIZE-APU_OP_WIDTH) = APU_OP_STOP then
                    if lr = '0' then    -- last channel was left, going to execute right
                        next_state <= FETCH;
                        next_lr <= '1';

                        next_counter <= std_logic_vector(to_unsigned(INSTR_SIZE / ARAM_WORD_SIZE - 1, COUNTER_SIZE));
                        next_pc <= std_logic_vector(unsigned(start_addr) + SHADER_MEM_OFFSET + 1);

                        ien <= '1'; iwe <= '0';
                        iaddr <= (others => '0');
                        iaddr(INSTR_ADDR_SIZE-2 downto 0) <= std_logic_vector(unsigned(start_addr) + SHADER_MEM_OFFSET);
                    else                -- last channel was right, going to idle
                        next_state <= IDLE;
                        next_lr <= '0';

                        -- reset 'busy' to 0
                        ien <= '1'; iwe <= '1';
                        iaddr <= TO_CPU_ADDR;
                        idata_in <= (others => '0');
                        idata_in(2) <= new_grain;
                    end if;

                else
                    next_state <= LOAD;
                    case instr(INSTR_SIZE-1 downto INSTR_SIZE-APU_OP_WIDTH) is
                        when APU_OP_AUDIO_IN | APU_OP_AUDIO_OUT =>
                            next_counter <= std_logic_vector(to_unsigned(3, COUNTER_SIZE));
                            iwe <= '0'; ien <= '1';
                            iaddr <= (others => '0');
                            iaddr(UPARAM_SIZE+1) <= '1';
                            iaddr(UPARAM_SIZE) <= lr;
                            iaddr(UPARAM_SIZE-1 downto 0) <= instr(4*UPARAM_SIZE-1 downto 3*UPARAM_SIZE);

                        when APU_OP_FFT | APU_OP_IFFT =>
                            next_counter <= std_logic_vector(to_unsigned(9, COUNTER_SIZE));
                            iwe <= '0'; ien <= '1';
                            iaddr <= (others => '0');
                            iaddr(UPARAM_SIZE+1) <= '1';
                            iaddr(UPARAM_SIZE) <= lr;
                            iaddr(UPARAM_SIZE-1 downto 0) <= instr(10*UPARAM_SIZE-1 downto 9*UPARAM_SIZE);

                        when APU_OP_ADD_VECTOR | APU_OP_SUB_VECTOR | APU_OP_MUL_VECTOR | APU_OP_MULC_VECTOR |
                             APU_OP_ADD_SCALAR | APU_OP_SUB_SCALAR | APU_OP_MUL_SCALAR =>
                            next_counter <= std_logic_vector(to_unsigned(9, COUNTER_SIZE));
                            iwe <= '0'; ien <= '1';
                            iaddr <= (others => '0');
                            iaddr(UPARAM_SIZE+1) <= '1';
                            iaddr(UPARAM_SIZE) <= lr;
                            iaddr(UPARAM_SIZE-1 downto 0) <= instr(10*UPARAM_SIZE-1 downto 9*UPARAM_SIZE);

                        when APU_OP_LOAD =>
                            -- TODO save immediate parameters
                            next_counter <= std_logic_vector(to_unsigned(3, COUNTER_SIZE));
                            iwe <= '0'; ien <= '1';
                            iaddr <= (others => '0');
                            iaddr(UPARAM_SIZE+1) <= '1';
                            iaddr(UPARAM_SIZE) <= lr;
                            iaddr(UPARAM_SIZE-1 downto 0) <= instr(4*UPARAM_SIZE-1 downto 3*UPARAM_SIZE);

                        when others =>
                    end case;

                end if;

            when LOAD =>
                next_counter <= std_logic_vector(unsigned(counter) - 1);
                iwe <= '0'; ien <= '1';
                iaddr <= (others => '0');
                if unsigned(counter) > 0 then
                    iaddr(UPARAM_SIZE+1) <= '1';
                    iaddr(UPARAM_SIZE) <= lr;
                    iaddr(UPARAM_SIZE-1 downto 0) <= instr(to_integer(unsigned(counter)) * UPARAM_SIZE - 1 downto (to_integer(unsigned(counter)) - 1) * UPARAM_SIZE);
                end if;

                -- Unified parameter mapping
                if    unsigned(counter) = 9 then next_buf3(ARAM_ADDR_SIZE*1-1 downto 0)                <= idata_out(ARAM_ADDR_SIZE-1 downto 0); -- out_bs
                elsif unsigned(counter) = 8 then next_buf3(ARAM_ADDR_SIZE*2-1 downto ARAM_ADDR_SIZE*1) <= idata_out(ARAM_ADDR_SIZE-1 downto 0); -- out_bl
                elsif unsigned(counter) = 7 then next_buf3(ARAM_ADDR_SIZE*3-1 downto ARAM_ADDR_SIZE*2) <= idata_out(ARAM_ADDR_SIZE-1 downto 0); -- out_os
                elsif unsigned(counter) = 6 then next_buf2(ARAM_ADDR_SIZE*1-1 downto 0)                <= idata_out(ARAM_ADDR_SIZE-1 downto 0); -- in2_bs
                elsif unsigned(counter) = 5 then next_buf2(ARAM_ADDR_SIZE*2-1 downto ARAM_ADDR_SIZE*1) <= idata_out(ARAM_ADDR_SIZE-1 downto 0); -- in2_bl
                elsif unsigned(counter) = 4 then next_buf2(ARAM_ADDR_SIZE*3-1 downto ARAM_ADDR_SIZE*2) <= idata_out(ARAM_ADDR_SIZE-1 downto 0); -- in2_os
                elsif unsigned(counter) = 3 then next_buf1(ARAM_ADDR_SIZE*1-1 downto 0)                <= idata_out(ARAM_ADDR_SIZE-1 downto 0); -- in1_bs
                elsif unsigned(counter) = 2 then next_buf1(ARAM_ADDR_SIZE*2-1 downto ARAM_ADDR_SIZE*1) <= idata_out(ARAM_ADDR_SIZE-1 downto 0); -- in1_bl
                elsif unsigned(counter) = 1 then next_buf1(ARAM_ADDR_SIZE*3-1 downto ARAM_ADDR_SIZE*2) <= idata_out(ARAM_ADDR_SIZE-1 downto 0); -- in1_os
                elsif unsigned(counter) = 0 then next_op_len                                           <= idata_out(ARAM_ADDR_SIZE-1 downto 0); -- op_len
                end if;

                if unsigned(counter) = 0 then
                    next_state <= EXECUTE;
                    ien <= '0';
                end if;
            
            when EXECUTE =>
                case op is
                    -- Audio In
                    when APU_OP_AUDIO_IN =>
                        unit_select <= APU_UNIT_AUDIO_IN;
                        aio_in_en <= '1';
                        aio_in_bs <= buf1(ARAM_ADDR_SIZE*1-1 downto 0);
                        aio_in_bl <= buf1(ARAM_ADDR_SIZE*2-1 downto ARAM_ADDR_SIZE*1);
                        aio_in_os <= buf1(ARAM_ADDR_SIZE*3-1 downto ARAM_ADDR_SIZE*2);
                        aio_in_ol <= op_len;

                        if aio_in_end = '1' then
                            next_state <= FETCH;
                            ien <= '1'; iwe <= '0';
                            iaddr <= (others => '0');
                            iaddr(INSTR_ADDR_SIZE-2 downto 0) <= pc;
                            next_pc <= std_logic_vector(unsigned(pc) + 1);
                            next_counter <= std_logic_vector(to_unsigned(INSTR_SIZE / ARAM_WORD_SIZE - 1, COUNTER_SIZE));
                        end if;

                    -- Audio Out
                    when APU_OP_AUDIO_OUT =>
                        unit_select <= APU_UNIT_AUDIO_OUT;
                        aio_out_en <= '1';
                        aio_out_bs <= buf1(ARAM_ADDR_SIZE*1-1 downto 0);
                        aio_out_bl <= buf1(ARAM_ADDR_SIZE*2-1 downto ARAM_ADDR_SIZE*1);
                        aio_out_os <= buf1(ARAM_ADDR_SIZE*3-1 downto ARAM_ADDR_SIZE*2);
                        aio_out_ol <= op_len;

                        if aio_out_end = '1' then
                            next_state <= FETCH;
                            ien <= '1'; iwe <= '0';
                            iaddr <= (others => '0');
                            iaddr(INSTR_ADDR_SIZE-2 downto 0) <= pc;
                            next_pc <= std_logic_vector(unsigned(pc) + 1);
                            next_counter <= std_logic_vector(to_unsigned(INSTR_SIZE / ARAM_WORD_SIZE - 1, COUNTER_SIZE));
                        end if;

                    -- FFT/IFFT
                    when APU_OP_FFT | APU_OP_IFFT =>
                        unit_select <= APU_UNIT_FFT;
                        fft_en <= '1';
                        
                        -- Immediate flags directly from instruction bits
                        fwd_inv <= instr(123);
                        fft_size <= instr(122);
                        
                        fft_bsr <= buf1(ARAM_ADDR_SIZE*1-1 downto 0);
                        fft_blr <= buf1(ARAM_ADDR_SIZE*2-1 downto ARAM_ADDR_SIZE*1);
                        fft_osr <= buf1(ARAM_ADDR_SIZE*3-1 downto ARAM_ADDR_SIZE*2);
                        fft_olr <= op_len;
                        
                        fft_bsw <= buf3(ARAM_ADDR_SIZE*1-1 downto 0);
                        fft_blw <= buf3(ARAM_ADDR_SIZE*2-1 downto ARAM_ADDR_SIZE*1);
                        fft_osw <= buf3(ARAM_ADDR_SIZE*3-1 downto ARAM_ADDR_SIZE*2);
                        fft_olw <= op_len;

                        if fft_end = '1' then
                            next_state <= FETCH;
                            ien <= '1'; iwe <= '0';
                            iaddr <= (others => '0');
                            iaddr(INSTR_ADDR_SIZE-2 downto 0) <= pc;
                            next_pc <= std_logic_vector(unsigned(pc) + 1);
                            next_counter <= std_logic_vector(to_unsigned(INSTR_SIZE / ARAM_WORD_SIZE - 1, COUNTER_SIZE));
                        end if;

                    -- Vector/Scalar Parallel Operations
                    when APU_OP_ADD_VECTOR | APU_OP_ADD_SCALAR | 
                         APU_OP_SUB_VECTOR | APU_OP_SUB_SCALAR | 
                         APU_OP_MUL_VECTOR | APU_OP_MUL_SCALAR | APU_OP_MULC_VECTOR =>
                            
                        unit_select <= APU_UNIT_VEC;
                        vec_en <= '1';
                        
                        case op is
                            when APU_OP_ADD_SCALAR  => vec_op <= VEC_OP_ADDS;
                            when APU_OP_ADD_VECTOR  => vec_op <= VEC_OP_ADDV;
                            when APU_OP_SUB_SCALAR  => vec_op <= VEC_OP_SUBS;
                            when APU_OP_SUB_VECTOR  => vec_op <= VEC_OP_SUBV;
                            when APU_OP_MUL_SCALAR  => vec_op <= VEC_OP_MULS;
                            when APU_OP_MUL_VECTOR  => vec_op <= VEC_OP_MULV;
                            when APU_OP_MULC_VECTOR => vec_op <= VEC_OP_MULCV;
                            when others             => vec_op <= (others => '0');
                        end case;

                        vec_bsr1 <= buf1(ARAM_ADDR_SIZE*1-1 downto 0);
                        vec_blr1 <= buf1(ARAM_ADDR_SIZE*2-1 downto ARAM_ADDR_SIZE*1);
                        vec_osr1 <= buf1(ARAM_ADDR_SIZE*3-1 downto ARAM_ADDR_SIZE*2);
                        vec_olr1 <= op_len;
                        
                        vec_bsw <= buf3(ARAM_ADDR_SIZE*1-1 downto 0);
                        vec_blw <= buf3(ARAM_ADDR_SIZE*2-1 downto ARAM_ADDR_SIZE*1);
                        vec_osw <= buf3(ARAM_ADDR_SIZE*3-1 downto ARAM_ADDR_SIZE*2);
                        vec_olw <= op_len;

                        if (op = APU_OP_ADD_SCALAR or op = APU_OP_SUB_SCALAR or op = APU_OP_MUL_SCALAR) then
                            -- scalar resolved from param memory via the in2_bs slot, unused
                            -- by scalar ops otherwise (same indirection as a buffer descriptor field)
                            vec_scalar <= std_logic_vector(resize(unsigned(buf2(ARAM_ADDR_SIZE*1-1 downto 0)), 16));
                            vec_bsr2 <= (others => '0');
                            vec_blr2 <= (others => '0');
                            vec_osr2 <= (others => '0');
                            vec_olr2 <= (others => '0');
                        else
                            vec_scalar <= (others => '0');
                            vec_bsr2 <= buf2(ARAM_ADDR_SIZE*1-1 downto 0);
                            vec_blr2 <= buf2(ARAM_ADDR_SIZE*2-1 downto ARAM_ADDR_SIZE*1);
                            vec_osr2 <= buf2(ARAM_ADDR_SIZE*3-1 downto ARAM_ADDR_SIZE*2);
                            vec_olr2 <= op_len;
                        end if;

                        if vec_end = '1' then
                            next_state <= FETCH;
                            ien <= '1'; iwe <= '0';
                            iaddr <= (others => '0');
                            iaddr(INSTR_ADDR_SIZE-2 downto 0) <= pc;
                            next_pc <= std_logic_vector(unsigned(pc) + 1);
                            next_counter <= std_logic_vector(to_unsigned(INSTR_SIZE / ARAM_WORD_SIZE - 1, COUNTER_SIZE));
                        end if;

                    when others =>
                        next_state <= IDLE;
                end case;

            when others =>
                next_state <= IDLE;
            end case;

    end process;

end Behavioral;
