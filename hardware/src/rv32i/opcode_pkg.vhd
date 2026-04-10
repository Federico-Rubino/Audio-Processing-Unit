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
        OP_ALU_ADD,    -- ADD                       6'b011001
        OP_ALU_SUB,    -- SUBTRACT                  6'b011011
        OP_ALU_AND,    -- Bitwise AND               6'b011101
        OP_ALU_OR,     --Bitwise OR                 6'b011111
        OP_ALU_XOR,    --Bitwise XOR                6'b100001
        OP_ALU_SLT,    --Set Less Than (signed)     6'b100011
        OP_ALU_SLTU,   --Set Less Than (unsigned)   6'b100101
        OP_ALU_SLL,    --Shift Left Logical         6'b100111
        OP_ALU_SRL,    --Shift Right Logical        6'b101001
        OP_ALU_SRA     --Shift Right Arithmetic     6'b101011
    );
    
    type branch_op_t is (
        OP_BRANCH_BEQ,      --Branche equal                             3'b000
        OP_BRANCH_BNE,      --Branch not equal                          3'b001
        OP_BRANCH_BLT,      --Branch less than                          3'b100
        OP_BRANCH_BGE,      --Branch greater than or equal              3'b101
        OP_BRANCH_BLTU,     --Branch less than equal unsigned           3'b110
        OP_BRANCH_BGEU,     --Branch greater than or equal unsigned     3'b111
        OP_BRANCH_JAL_JALR, --Jump in case of JAL or JALR instruction   3'b010
        OP_BRANCH_NOP
    );
    
    type lsu_op_t is (
        OP_LSU_W,   --word
        OP_LSU_H,   --half word
        OP_LSU_HU,  --half word unsigned, only for load
        OP_LSU_B,   --byte
        OP_LSU_BU   --byte unsigned, only for load
    );
    
    -- Op codes
    constant OP_LUI   : std_logic_vector(6 downto 0) := "0110111"; --OK
    constant OP_AUIPC : std_logic_vector(6 downto 0) := "0010111"; --OK
    constant OP_JAL   : std_logic_vector(6 downto 0) := "1101111"; --OK
    constant OP_JALR  : std_logic_vector(6 downto 0) := "1100111"; --OK
    constant OP_BRANCH: std_logic_vector(6 downto 0) := "1100011"; --OK
    constant OP_STORE : std_logic_vector(6 downto 0) := "0100011"; --OK
    constant OP_ALU   : std_logic_vector(6 downto 0) := "0110011"; --OK
    constant OP_LOAD  : std_logic_vector(6 downto 0) := "0000011"; --OK
    constant OP_ALUI  : std_logic_vector(6 downto 0) := "0010011"; --OK 
   
    
    
    function decode_rtype(f3: std_logic_vector(2 downto 0); f7 : std_logic_vector(6 downto 0)) return alu_op_t;
    function decode_branch(f3 : std_logic_vector(2 downto 0)) return branch_op_t;
    function decode_itype(f3: std_logic_vector(2 downto 0); f7 : std_logic_vector(6 downto 0)) return alu_op_t;
    function decode_lsutype(f3: std_logic_vector(2 downto 0)) return lsu_op_t;
    
end package;

package body opcode_pkg is
    function decode_rtype(f3: std_logic_vector(2 downto 0); f7 : std_logic_vector(6 downto 0)) return alu_op_t is
    begin
        if f7 = "0000000" then
            case f3 is 
                when "000" => return OP_ALU_ADD;
                when "001" => return OP_ALU_SLL;
                when "100" => return OP_ALU_XOR;
                when "101" => return OP_ALU_SRL;
                when "110" => return OP_ALU_OR;
                when "111" => return OP_ALU_AND;
                when "010" => return OP_ALU_SLT;
                when "011" => return OP_ALU_SLTU;
                    
                when others => return OP_ALU_ADD;
            end case;
        elsif f7 = "0100000" then
            case f3 is
                when "000" => return OP_ALU_SUB;
                when "101" => return OP_ALU_SRA;
                    
                when others => return OP_ALU_ADD;
            end case;
        else return OP_ALU_ADD;
        end if;
    end function;
    
    
    function decode_branch(f3 : std_logic_vector(2 downto 0)) return branch_op_t is
    begin
        case f3 is
            when "000" => return OP_BRANCH_BEQ;
            when "001" => return OP_BRANCH_BNE;
            when "100" => return OP_BRANCH_BLT;
            when "101" => return OP_BRANCH_BGE;
            when "110" => return OP_BRANCH_BLTU;
            when "111" => return OP_BRANCH_BGEU;
            when "010" => return OP_BRANCH_JAL_JALR; 
            when others => return OP_BRANCH_NOP;
        end case;
    end function;
    
    function decode_itype(f3: std_logic_vector(2 downto 0); f7 : std_logic_vector(6 downto 0)) return alu_op_t is
    begin
        case f3 is 
            when "000" => return OP_ALU_ADD;
            when "010" => return OP_ALU_SLT;
            when "011" => return OP_ALU_SLTU;
            when "100" => return OP_ALU_XOR;
            when "110" => return OP_ALU_OR;
            when "111" => return OP_ALU_AND;
            when "001" => return OP_ALU_SLL;
            
            when "101" =>
                if f7 = "0000000" then 
                    return OP_ALU_SRL;
                elsif f7 = "0100000" then
                    return OP_ALU_SRA;
                end if;
            when others => return OP_ALU_ADD;
        end case;
    end function;
    
    function decode_lsutype(f3: std_logic_vector(2 downto 0)) return lsu_op_t is
    begin
        case f3 is
            when "000" => return OP_LSU_B;
            when "001" => return OP_LSU_H;
            when "010" => return OP_LSU_W;
            when "100" => return OP_LSU_BU;
            when "101" => return OP_LSU_HU;
            when others => return OP_LSU_W;
        end case;
    end function;
end package body;
