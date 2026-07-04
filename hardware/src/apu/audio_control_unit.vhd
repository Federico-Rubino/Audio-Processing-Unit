library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.apu_opcode_pkg.all;
use work.apu_internal_pkg.all;

entity AudioCU is
    Generic(
        RAM_WORD_SIZE : integer := 32;
        ARAM_ADDR_SIZE : integer := 10;
        INSTR_SIZE : integer := 128     -- currently the max is 4*RAM_WORD_SIZE
    );
    Port (
        clk, rst : in std_logic;
        en, update : in std_logic;
        prog_addr_start : in std_logic_vector(RAM_WORD_SIZE-1 downto 0);

        -- ARAM Interfacing
        unit_select : out apu_unit_t;
        
        -- RAM Interfacing
        ram_we, ram_en : out std_logic;
        ram_addr, ram_din : out std_logic_vector(RAM_WORD_SIZE-1 downto 0);
        ram_dout : in std_logic_vector(RAM_WORD_SIZE-1 downto 0);
        
        -- Audio IO Interfacing
        aio_new_grain, aio_end : in std_logic;
        aio_en, aio_lr : out std_logic;
        aio_bs, aio_bl, aio_os, aio_ol : out std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);

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
    type cu_state is (IDLE, FETCH, DECODE, EXECUTE);
    signal state, next_state : cu_state;
    signal lr, next_lr : std_logic; -- 0=left, 1=right
    signal counter, next_counter : std_logic_vector(15 downto 0);
    signal op, next_op : apu_code_t;
    signal instr, next_instr : std_logic_vector(INSTR_SIZE-1 downto 0);
    signal pc, next_pc : std_logic_vector(RAM_WORD_SIZE-1 downto 0);

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
        elsif rising_edge(clk) then
            state <= next_state;
            lr <= next_lr;
            counter <= next_counter;
            op <= next_op;
            instr <= next_instr;
            pc <= next_pc;
        end if;
    end process;

    -- Combinational Process
    process(all)
    begin
        if en = '1' then
            -- Default assignments
            next_state <= state;
            next_lr <= lr;
            next_counter <= counter;
            next_op <= op;
            next_instr <= instr;
            next_pc <= pc;
            
            ram_en <= '0'; ram_we <= '0';
            ram_addr <= (others => '0'); ram_din <= (others => '0');
            unit_select <= APU_UNIT_NONE;
            aio_en <= '0'; aio_lr <= lr;
            aio_bs <= (others => '0'); aio_bl <= (others => '0'); aio_os <= (others => '0'); aio_ol <= (others => '0');
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
                    next_pc <= prog_addr_start;
                    if update = '1' or aio_new_grain = '1' then
                        next_state <= FETCH;
                        next_counter <= std_logic_vector(to_unsigned(INSTR_SIZE / RAM_WORD_SIZE - 1, 16)); 
                        next_pc <= std_logic_vector(unsigned(pc) + 1);

                        ram_en <= '1'; ram_we <= '0';
                        ram_addr <= prog_addr_start;
                    end if;

                when FETCH =>
                    next_counter <= std_logic_vector(unsigned(counter) - 1);
                    next_pc <= std_logic_vector(unsigned(pc) + 1);
                    ram_en <= '1'; ram_we <= '0';
                    ram_addr <= pc;

                    -- Load the correct part of the instruction
                    if    unsigned(counter) = 0 then next_instr(RAM_WORD_SIZE-1 downto 0) <= ram_dout;
                    elsif unsigned(counter) = 1 then next_instr(2*RAM_WORD_SIZE-1 downto RAM_WORD_SIZE) <= ram_dout;
                    elsif unsigned(counter) = 2 then next_instr(3*RAM_WORD_SIZE-1 downto 2*RAM_WORD_SIZE) <= ram_dout;
                    elsif unsigned(counter) = 3 then next_instr(4*RAM_WORD_SIZE-1 downto 3*RAM_WORD_SIZE) <= ram_dout;
                    end if;
                    
                    if unsigned(counter) = 0 then
                        next_state <= DECODE;
                        ram_en <= '0';
                        next_pc <= pc;
                    end if;

                when DECODE =>
                    next_state <= EXECUTE;
                    next_op <= instr(INSTR_SIZE-1 downto INSTR_SIZE-APU_OP_WIDTH);

                    if instr(INSTR_SIZE-1 downto INSTR_SIZE-APU_OP_WIDTH) = APU_OP_STOP then
                        if lr = '0' then    -- last channel was left, going to execute right
                            next_state <= FETCH;
                            next_lr <= '1';
                        else                -- last channel was right, going to idle
                            next_state <= IDLE;
                            next_lr <= '0';
                        end if;
                    end if;
                
                when EXECUTE =>
                    case op is
                        -- Audio IO
                        when APU_OP_AUDIO_IN | APU_OP_AUDIO_OUT =>
                            unit_select <= APU_UNIT_AUDIO_IO;
                            aio_en <= '1';
                            aio_bs <= instr(123 downto 114);
                            aio_bl <= instr(113 downto 104);
                            aio_os <= instr(103 downto 94);
                            aio_ol <= instr(93 downto 84);

                            if aio_end = '1' then
                                next_state <= FETCH;
                                ram_en <= '1'; ram_we <= '0';
                                ram_addr <= pc;
                                next_pc <= std_logic_vector(unsigned(pc) + 1);
                                next_counter <= std_logic_vector(to_unsigned(INSTR_SIZE / RAM_WORD_SIZE - 1, 16));
                            end if;

                        -- FFT/IFFT
                        when APU_OP_FFT | APU_OP_IFFT =>
                            unit_select <= APU_UNIT_FFT;
                            fft_en <= '1';
                            fwd_inv <= '1' when (op = APU_OP_FFT) else '0';
                            fft_size <= instr(123);
                            fft_bsr <= instr(122 downto 113);
                            fft_blr <= instr(112 downto 103);
                            fft_osr <= instr(102 downto 93);
                            fft_olr <= instr(92 downto 83);
                            fft_bsw <= instr(82 downto 73);
                            fft_blw <= instr(72 downto 63);
                            fft_osw <= instr(62 downto 53);
                            fft_olw <= instr(52 downto 43);

                            if fft_end = '1' then
                                next_state <= FETCH;
                                ram_en <= '1'; ram_we <= '0';
                                ram_addr <= pc;
                                next_pc <= std_logic_vector(unsigned(pc) + 1);
                                next_counter <= std_logic_vector(to_unsigned(INSTR_SIZE / RAM_WORD_SIZE - 1, 16));
                            end if;

                        -- Vector/Scalar Parallel Operations
                        when APU_OP_ADD_VECTOR | APU_OP_ADD_SCALAR | 
                             APU_OP_SUB_VECTOR | APU_OP_SUB_SCALAR | 
                             APU_OP_MUL_VECTOR | APU_OP_MUL_SCALAR | 
                             APU_OP_MULC_VECTOR =>
                             
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

                            vec_bsr1 <= instr(123 downto 114);
                            vec_blr1 <= instr(113 downto 104);
                            vec_osr1 <= instr(103 downto 94);
                            vec_olr1 <= instr(93 downto 84);
                            vec_bsw <= instr(43 downto 34);
                            vec_blw <= instr(33 downto 24);
                            vec_osw <= instr(23 downto 14);
                            vec_olw <= instr(13 downto 4);

                            if (op = APU_OP_ADD_SCALAR or op = APU_OP_SUB_SCALAR or op = APU_OP_MUL_SCALAR) then
                                vec_scalar <= instr(83 downto 68);
                                vec_bsr2 <= (others => '0');
                                vec_blr2 <= (others => '0');
                                vec_osr2 <= (others => '0');
                                vec_olr2 <= (others => '0');
                            else
                                vec_scalar <= (others => '0');
                                vec_bsr2 <= instr(83 downto 74);
                                vec_blr2 <= instr(73 downto 64);
                                vec_osr2 <= instr(63 downto 54);
                                vec_olr2 <= instr(53 downto 44);
                            end if;

                            if vec_end = '1' then
                                next_state <= FETCH;
                                ram_en <= '1'; ram_we <= '0';
                                ram_addr <= pc;
                                next_pc <= std_logic_vector(unsigned(pc) + 1);
                                next_counter <= std_logic_vector(to_unsigned(INSTR_SIZE / RAM_WORD_SIZE - 1, 16));
                            end if;

                        when others =>
                            next_state <= IDLE;
                    end case;

                when others =>
                    next_state <= IDLE;
            end case;

        else    -- en = '0' reset every register
            next_state <= IDLE;
            next_lr <= '0';
            next_counter <= (others => '0');
            next_op <= APU_NOP;
            next_instr <= (others => '0');
            next_pc <= prog_addr_start;
            
            ram_en <= '0'; ram_we <= '0';
            ram_addr <= (others => '0'); ram_din <= (others => '0');
            unit_select <= APU_UNIT_NONE;
            aio_en <= '0'; aio_lr <= '0';
            aio_bs <= (others => '0'); aio_bl <= (others => '0'); aio_os <= (others => '0'); aio_ol <= (others => '0');
            fft_en <= '0'; fft_size <= '0'; fwd_inv <= '0';
            fft_bsr <= (others => '0'); fft_blr <= (others => '0'); fft_osr <= (others => '0'); fft_olr <= (others => '0');
            fft_bsw <= (others => '0'); fft_blw <= (others => '0'); fft_osw <= (others => '0'); fft_olw <= (others => '0');
            vec_bsr1 <= (others => '0'); vec_blr1 <= (others => '0'); vec_osr1 <= (others => '0'); vec_olr1 <= (others => '0');
            vec_bsr2 <= (others => '0'); vec_blr2 <= (others => '0'); vec_osr2 <= (others => '0'); vec_olr2 <= (others => '0');
            vec_bsw <= (others => '0'); vec_blw <= (others => '0'); vec_osw <= (others => '0'); vec_olw <= (others => '0');
            vec_en <= '0'; vec_op <= (others => '0');
            vec_scalar <= (others => '0');
        end if;
    end process;

end Behavioral;
