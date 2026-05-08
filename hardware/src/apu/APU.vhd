library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.apu_opcode_pkg.all;
use IEEE.NUMERIC_STD.ALL;

entity APU is
    Port (
        clk : in std_logic;
        rst : in std_logic;

        -- debug
        debug_regs : out std_logic_vector(1023 downto 0)
    );
end APU;

architecture Behavioral of APU is
    -- interface registers
    signal reg_file_opcode : apu_opcode_t;
    signal reg_file_in_buffer1_start : std_logic_vector(17 downto 0);
    signal reg_file_in_buffer1_offset : std_logic_vector(17 downto 0);
    signal reg_file_in_buffer2_start : std_logic_vector(17 downto 0);
    signal reg_file_in_buffer2_offset : std_logic_vector(17 downto 0);
    signal reg_file_in_buffer3_start : std_logic_vector(17 downto 0);
    signal reg_file_in_buffer3_offset : std_logic_vector(17 downto 0);
    signal reg_file_out_buffer1_start : std_logic_vector(17 downto 0);
    signal reg_file_out_buffer1_offset : std_logic_vector(17 downto 0);
    signal reg_file_out_buffer2_start : std_logic_vector(17 downto 0);
    signal reg_file_out_buffer2_offset : std_logic_vector(17 downto 0);
    signal reg_file_action_size : std_logic_vector(17 downto 0);
    signal reg_file_block_size : std_logic_vector(17 downto 0);
    signal reg_file_param1 : std_logic_vector(15 downto 0);
    signal reg_file_param2 : std_logic_vector(15 downto 0);
    signal reg_file_status : std_logic;
    signal reg_file_control : std_logic;

    signal next_reg_file_in_buffer1_start : std_logic_vector(17 downto 0);
    signal next_reg_file_opcode : apu_opcode_t;
    signal next_reg_file_in_buffer1_offset : std_logic_vector(17 downto 0);
    signal next_reg_file_in_buffer2_start : std_logic_vector(17 downto 0);
    signal next_reg_file_in_buffer2_offset : std_logic_vector(17 downto 0);
    signal next_reg_file_in_buffer3_start : std_logic_vector(17 downto 0);
    signal next_reg_file_in_buffer3_offset : std_logic_vector(17 downto 0);
    signal next_reg_file_out_buffer1_start : std_logic_vector(17 downto 0);
    signal next_reg_file_out_buffer1_offset : std_logic_vector(17 downto 0);
    signal next_reg_file_out_buffer2_start : std_logic_vector(17 downto 0);
    signal next_reg_file_out_buffer2_offset : std_logic_vector(17 downto 0);
    signal next_reg_file_action_size : std_logic_vector(17 downto 0);
    signal next_reg_file_block_size : std_logic_vector(17 downto 0);
    signal next_reg_file_param1 : std_logic_vector(15 downto 0);
    signal next_reg_file_param2 : std_logic_vector(15 downto 0);
    signal next_reg_file_status : std_logic;
    signal next_reg_file_control : std_logic;
    
begin
    
    process(clk)
    begin
        if rst = '0' then
            -- reset everything TODO
        elsif rising_edge(clk) then
            next_reg_file_status <= '1';
        end if;
    end process;

end Behavioral;
