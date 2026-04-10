----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/02/2026 11:23:10 AM
-- Design Name: 
-- Module Name: alu_pkg - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

package opcode_pkg is

    type alu_op_t is (
        OP_ALU_ADD,    -- ADD 6'b011001
        OP_ALU_SUB,    -- SUBTRACT 6'b011011
        OP_ALU_AND,    -- Bitwise AND 6'b011101
        OP_ALU_OR,     --Bitwise OR 6'b011111
        OP_ALU_XOR,    --Bitwise XOR 6'b100001
        OP_ALU_SLT,    --Set Less Than (signed) 6'b100011
        OP_ALU_SLTU,   --Set Less Than (unsigned) 6'b100101
        OP_ALU_SLL,    --Shift Left Logical 6'b100111
        OP_ALU_SRL,    --Shift Right Logical 6'b101001
        OP_ALU_SRA     --Shift Right Arithmetic 6'b101011
    );

end package;

package body opcode_pkg is
end package body;
