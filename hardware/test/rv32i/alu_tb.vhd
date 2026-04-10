----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/02/2026 12:10:55 PM
-- Design Name: 
-- Module Name: alu_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.opcode_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity alu_tb is
--  Port ( );
end alu_tb;

architecture Behavioral of alu_tb is
    signal i_a : std_logic_vector(31 downto 0);
    signal i_b : std_logic_vector(31 downto 0);
    signal alu_OP : alu_op_t;
    signal o_result : std_logic_vector(31 downto 0);
begin
    alu_inst : entity work.alu 
        port map(
            alu_op => alu_OP,
            a => i_a,
            b => i_b,
            result => o_result
        );
    
    sim : process
    begin
    --add_test_1 4+6
    i_a <= std_logic_vector(to_signed(4, 32));
    i_b <= std_logic_vector(to_signed(6, 32));
    alu_op <= OP_ALU_ADD;
    wait for 10 ns;
    
    --add_test_2 4+-5
    i_a <= std_logic_vector(to_signed(4, 32));
    i_b <= std_logic_vector(to_signed(-5, 32));
    alu_op <= OP_ALU_ADD;
    wait for 10 ns;
    
    --add_test_3 -10+-5
    i_a <= std_logic_vector(to_signed(-10, 32));
    i_b <= std_logic_vector(to_signed(-5, 32));
    alu_op <= OP_ALU_ADD;
    wait for 10 ns;
    
    --sub_test_1 500-30
    i_a <= std_logic_vector(to_signed(500, 32));
    i_b <= std_logic_vector(to_signed(30, 32));
    alu_op <= OP_ALU_SUB;
    wait for 10 ns;
    
    --sub_test_2 500-600
    i_a <= std_logic_vector(to_signed(500, 32));
    i_b <= std_logic_vector(to_signed(600, 32));
    alu_op <= OP_ALU_SUB;
    wait for 10 ns;
    
    --sub_test_3 -500--600
    i_a <= std_logic_vector(to_signed(-500, 32));
    i_b <= std_logic_vector(to_signed(-600, 32));
    alu_op <= OP_ALU_SUB;
    wait for 10 ns;
    
    --and_test_1 5 and 5
    i_a <= std_logic_vector(to_signed(5, 32));
    i_b <= std_logic_vector(to_signed(5, 32));
    alu_op <= OP_ALU_AND;
    wait for 10 ns;
    
    --xor_test_1 5 xor 6
    i_a <= std_logic_vector(to_signed(5, 32));
    i_b <= std_logic_vector(to_signed(6, 32));
    alu_op <= OP_ALU_XOR;
    wait for 10 ns;
    
    
    wait;
    
    end process;
end Behavioral;
