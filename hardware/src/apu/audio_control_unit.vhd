library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.apu_opcode_pkg.all;
use work.apu_internal_pkg.all;

entity AudioCU is
    Port (
        clk, rst : in std_logic;

        -- Read Register File
        opcode : in apu_opcode_t;                               -- Opcode: 0000 copy, 0001 out, ...
        in_buffer1_start : in std_logic_vector(9 downto 0);     -- Address of the first input buffer in the BRAM block 0
        in_buffer1_offset : in std_logic_vector(17 downto 0);   -- Where in the first input buffer to start the operation [bit 17: 0 for sample 15:0, 1 for sample 31:16;  bits 16-10: select the BRAM block;  bits 9-0: actual address in the BRAM block]
        in_buffer2_start : in std_logic_vector(9 downto 0);     -- Address of the second input buffer in the BRAM block 0
        in_buffer2_offset : in std_logic_vector(17 downto 0);   -- Where in the second input buffer to start the operation [bit 17: 0 for sample 15:0, 1 for sample 31:16;  bits 16-10: select the BRAM block;  bits 9-0: actual address in the BRAM block]
        in_buffer3_start : in std_logic_vector(9 downto 0);     -- Address of the third input buffer in the BRAM block 0
        in_buffer3_offset : in std_logic_vector(17 downto 0);   -- Where in the third input buffer to start the operation [bit 17: 0 for sample 15:0, 1 for sample 31:16;  bits 16-10: select the BRAM block;  bits 9-0: actual address in the BRAM block]
        out_buffer1_start : in std_logic_vector(9 downto 0);    -- Address of the first output buffer in the BRAM block 0
        out_buffer1_offset : in std_logic_vector(17 downto 0);  -- Where in the first output buffer to start the operation [bit 17: 0 for sample 15:0, 1 for sample 31:16;  bits 16-10: select the BRAM block;  bits 9-0: actual address in the BRAM block]
        out_buffer2_start : in std_logic_vector(9 downto 0);    -- Address of the second output buffer in the BRAM block 0
        out_buffer2_offset : in std_logic_vector(17 downto 0);  -- Where in the second output buffer to start the operation [bit 17: 0 for sample 15:0, 1 for sample 31:16;  bits 16-10: select the BRAM block;  bits 9-0: actual address in the BRAM block]
        action_size : in std_logic_vector(17 downto 0);         -- On how many samples the operation should be applied (consider there are 2 samples for each memory access)
        block_size : in std_logic_vector(9 downto 0);           -- Length of the buffer in BRAM block 0
        param1 : in std_logic_vector(15 downto 0);              -- First 16 bit parameter used for an operation
        param2 : in std_logic_vector(15 downto 0);              -- Second 16 bit parameter used for an operation
        start_ram_address : in std_logic_vector(31 downto 0);   -- Starting address of the buffer in the RAM (for the 'copy' operation)
        left_right : in std_logic;                              -- 0: left; 1: right
        start : in std_logic;                                   -- 0: do nothing; 1: do the operation

        -- Write Register File
        next_status : out std_logic_vector(31 downto 0);        -- bits 31-16: result of the operation;  bit 15-1: reserved for future use; bit 0: 1 if it is ready to execute, 0 if it is executing some operation
        
        -- TODO not used by now
        started : out std_logic;

        -- Control Signals
        enable : out std_logic;
        mode : out std_logic_vector(1 downto 0);
        we_a : out std_logic;
        addr_a : out std_logic_vector(9 downto 0);        
        select_a : out std_logic_vector(7 downto 0);
        we_b : out std_logic;
        addr_b : out std_logic_vector(9 downto 0);
        select_b : out std_logic_vector(7 downto 0);
        ram_we : out std_logic;
        ram_addr : out std_logic_vector(31 downto 0);
        mux_index : out std_logic_vector(7 downto 0);
        write_from : out std_logic_vector(1 downto 0);
        audio_out_enable : out std_logic;
        audio_out_lr : out std_logic
    );
end AudioCU;

architecture Behavioral of AudioCU is
    type state is (idle, fetch, copy, audio_out, wait_pipeline);
    signal cu_state : state;
    signal op : apu_opcode_t;
    signal error : std_logic;
    signal counter : std_logic_vector(17 downto 0);
    signal address : std_logic_vector(17 downto 0);
    signal ram_address : std_logic_vector(31 downto 0);
    signal upper_bound : std_logic_vector(9 downto 0);
    signal lower_bound : std_logic_vector(9 downto 0);
    signal last_result : std_logic_vector(15 downto 0);

    signal next_cu_state : state;
    signal next_op : apu_opcode_t;
    signal next_error : std_logic;
    signal next_counter : std_logic_vector(17 downto 0);
    signal next_address : std_logic_vector(17 downto 0);
    signal next_ram_address : std_logic_vector(31 downto 0);
    signal next_upper_bound : std_logic_vector(9 downto 0);
    signal next_lower_bound : std_logic_vector(9 downto 0);
    signal next_last_result : std_logic_vector(15 downto 0);

begin

    error <= '0';
    next_error <= '0';

    process(clk, rst)
    begin
        if rst = '0' then
            cu_state <= idle;                               
            last_result <= (others => '0');
        elsif rising_edge(clk) then
            cu_state <= next_cu_state;
            op <= next_op;
            error <= next_error;
            counter <= next_counter;
            address <= next_address;
            ram_address <= next_ram_address;
            lower_bound <= next_lower_bound;
            upper_bound <= next_upper_bound;
            last_result <= next_last_result;
        end if;
    end process;

    process(
        cu_state, op, counter, address, ram_address, upper_bound, lower_bound, last_result,
        opcode, in_buffer1_start, in_buffer1_offset, in_buffer2_start, in_buffer2_offset, in_buffer3_start, in_buffer3_offset,
        out_buffer1_start, out_buffer1_offset, out_buffer2_start, out_buffer2_offset,
        action_size, block_size,
        param1, param2, start_ram_address, left_right, start
    )
    begin
        next_last_result <= last_result;    -- default assignment
        next_status(31 downto 16) <= last_result;
        next_status(15 downto 0)  <= (others => '0');
    
        case cu_state is

            when idle =>
                -- State Transition
                if start = '1' then
                    next_cu_state <= fetch;
                end if;

                next_op <= opcode;
                next_error <= '0';
                next_counter <= (others => '0');
                next_address <= (others => '0');
                next_ram_address <= (others => '0');
                next_lower_bound <= (others => '0');
                next_upper_bound <= (others => '0');
                
                -- Outputs
                enable <= '0';

            when fetch =>
                next_status(0) <= '1';

                case op is
                    when APU_OP_COPY =>
                        next_cu_state <= copy;
                        next_op <= APU_OP_COPY;
                        next_lower_bound <= in_buffer1_start;
                        next_upper_bound <= std_logic_vector(unsigned(in_buffer1_start) +
                                                             unsigned(block_size));
                        next_address     <= std_logic_vector(unsigned(in_buffer1_start) +
                                                             unsigned(in_buffer1_offset));
                        next_counter <= '0' & std_logic_vector(unsigned(action_size(17 downto 1)) - 1);
                        next_ram_address <= start_ram_address;
                    when APU_OP_AUDIO_OUT =>
                        next_cu_state <= audio_out;
                        next_op <= APU_OP_AUDIO_OUT;
                        next_lower_bound <= in_buffer1_start;
                        next_upper_bound <= std_logic_vector(unsigned(in_buffer1_start) +
                                                             unsigned(block_size));
                        next_address     <= std_logic_vector(unsigned(in_buffer1_start) +
                                                             unsigned(in_buffer1_offset));
                        next_counter <= action_size;
                        next_ram_address <= (others => '0');
                    when others =>
                        next_cu_state <= idle;
                end case;

            when copy =>
                next_status(0) <= '1';
                
                -- Datapath Control Signals (Outputs)
                enable <= '1';
                mode <= "01";   -- Mixed Read/Write Mode
                we_a <= '0';
                addr_a <= (others => '0');
                select_a <= broadcast;
                we_b <= '1';
                addr_b <= address(9 downto 0);
                select_b <= address(17 downto 10);
                ram_we <= '0';
                ram_addr <= ram_address;
                write_from <= "00"; -- write from RAM
                audio_out_enable <= '0';
                audio_out_lr <= '0';
            
                -- Update Registers (State Transition)
                if counter = std_logic_vector(to_unsigned(0, 18)) then
                    next_cu_state <= wait_pipeline;
                    next_counter <= std_logic_vector(to_unsigned(2, 18));   -- Wait 2 clock cycles
                    next_address <= (others => '0');
                    next_lower_bound <= (others => '0');
                    next_upper_bound <= (others => '0');
                else
                    next_op <= opcode;
                    next_counter <= std_logic_vector(unsigned(counter) - 1);
                    if unsigned(address(17 downto 10)) = 109 then
                        next_address(9 downto 0)   <= std_logic_vector(unsigned(next_address(9 downto 0)) + 1);
                        next_address(17 downto 10) <= (others => '0');
                    else
                        next_address(17 downto 10) <= std_logic_vector(unsigned(next_address(17 downto 10)) + 1);
                    end if;
                    next_ram_address <= std_logic_vector(unsigned(ram_address) + 1);
                end if;
                
            when audio_out =>
                next_status(0) <= '1';
                
                -- Datapath Control Signals (Outputs)
                enable <= '1';
                mode <= "01";   -- Mixed Read/Write Mode
                we_a <= '0';
                addr_a <= address(9 downto 0);
                select_a <= address(17 downto 10);
                we_b <= '0';
                addr_b <= (others => '0');
                select_b <= broadcast;
                ram_we <= '0';
                ram_addr <= ram_address;
                write_from <= "00";
                mux_index <= address(17 downto 10);
                audio_out_enable <= '1';
                audio_out_lr <= left_right;

                if unsigned(counter) = 0 then
                    next_counter <= std_logic_vector(to_unsigned(2, 18));
                    next_cu_state <= wait_pipeline;
                    next_address <= (others => '0');
                    next_lower_bound <= (others => '0');
                    next_upper_bound <= (others => '0');
                else
                    next_counter <= std_logic_vector(unsigned(counter) - 1);
                    if unsigned(address(17 downto 10)) = 109 then
                        next_address(9 downto 0)   <= std_logic_vector(unsigned(next_address(9 downto 0)) + 1);
                        next_address(17 downto 10) <= (others => '0');
                    else
                        next_address(17 downto 10) <= std_logic_vector(unsigned(next_address(17 downto 10)) + 1);
                    end if;
                end if;
                
            when wait_pipeline =>   -- going to this state requires setting the 'counter' value
                next_status(0) <= '1';
                
                -- Reset Output Signals (do not reset 'enable' and 'mode', they will be reset in idle state)
                we_a <= '0';
                we_b <= '0';
                ram_we <= '0';  -- TODO
                audio_out_enable <= '0';

                -- State Transition
                if unsigned(counter) = 0 then
                    next_cu_state <= idle;
                else
                    next_counter <= std_logic_vector(unsigned(counter) - 1);
                    next_cu_state <= wait_pipeline;
                end if;

            when others =>
                next_cu_state <= idle;
                next_error <= '1';
        end case;
    end process;

end Behavioral;
