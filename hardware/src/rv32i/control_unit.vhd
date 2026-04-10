----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/03/2026 11:13:20 AM
-- Design Name: 
-- Module Name: control_unit - Behavioral
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

entity control_unit is
  Port (
    clk : in std_logic;
    rst : in std_logic;
    instr : in std_logic_vector(31 downto 0);
    
    pc_we : out std_logic;
    
    instr_mem_ena : out std_logic;
    
    reg_file_wea : out std_logic;
    reg_file_raddr1 : out unsigned(4 downto 0);
    reg_file_raddr2 : out unsigned(4 downto 0);
    reg_file_waddr : out unsigned(4 downto 0);
    
    opcode : out std_logic_vector(6 downto 0);
    
    mux_alu_in_1 : out std_logic;
    mux_alu_in_2 : out std_logic;
    alu_op : out alu_op_t;
    
    branch : out std_logic;
    branch_op : out branch_op_t;
    
    data_mem_ena : out std_logic;
    
    mux_reg_in : out std_logic_vector(1 downto 0);
    
    lsu_op : out lsu_op_t;
    is_store : out std_logic;
    
    IRWrite : out std_logic;
    AWrite : out std_logic;
    BWrite : out std_logic;
    ALUOutWrite : out std_logic;
    BranchOutWrite : out std_logic
    
   );
end control_unit;

architecture Behavioral of control_unit is
    type state_t is (FETCH, DECODE, EXECUTE, MEMORY, WRITEBACK);
    signal state, next_state : state_t;
    signal opcode_s : std_logic_vector(6 downto 0);
    signal funct3_s : std_logic_vector(2 downto 0);
    signal funct7_s : std_logic_vector(6 downto 0);
    signal rs1_s, rs2_s, rd_s : unsigned(4 downto 0);
    
begin
    

    opcode <= opcode_s;

    process(clk)
    begin
        if rst = '1' then
            state <= FETCH;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;
    
    opcode_s <= instr(6 downto 0);
    funct3_s <= instr(14 downto 12);
    funct7_s <= instr(31 downto 25);

    rs1_s <= unsigned(instr(19 downto 15));
    rs2_s <= unsigned(instr(24 downto 20));
    rd_s  <= unsigned(instr(11 downto 7));
    
    
    process(state, rs1_s, rs2_s, rd_s, opcode_s, funct3_s, funct7_s)
    begin
    
    --ENABLE SIGNAL ARE 0 DEFAULT
        pc_we <= '0';
        instr_mem_ena <= '0';
        reg_file_wea <= '0';
        data_mem_ena <= '0';
        IRWrite <= '0';
        AWrite <= '0';
        BWrite <= '0';
        ALUOutWrite <= '0';
        BranchOutWrite <= '0';
        branch <= '0';
        is_store <= '0';
    -- end default value
    
        case state is
            
            when FETCH =>
                next_state <= DECODE;
                instr_mem_ena <= '1';
                IRWrite <= '1';
                
            when DECODE =>
                next_state <= EXECUTE;
                
                reg_file_raddr1 <= rs1_s;
                reg_file_raddr2 <= rs2_s;
                reg_file_waddr  <= rd_s;
                AWrite <= '1';
                BWrite <= '1';
                
            
            when EXECUTE =>
                next_state <= MEMORY;
                case opcode_s is
                    when OP_ALU =>
                        mux_alu_in_1 <= '0'; --rs1
                        mux_alu_in_2 <= '0'; --rs2
                        alu_op <= decode_rtype(funct3_s, funct7_s);
                    when OP_ALUI =>
                        mux_alu_in_1 <= '0'; --rs1
                        mux_alu_in_2 <= '1'; --imm_ext
                        alu_op <= decode_itype(funct3_s, funct7_s);
                    
                    when OP_BRANCH =>
                        branch <= '1';
                        mux_alu_in_1 <= '1'; --current pc
                        mux_alu_in_2 <= '1'; --imm_ext
                        alu_op <= OP_ALU_ADD;
                        branch_op <= decode_branch(funct3_s);
                        
                    when OP_JAL =>
                        branch <= '1';
                        mux_alu_in_1 <= '1'; --current pc
                        mux_alu_in_2 <= '1'; --imm_ext
                        alu_op <= OP_ALU_ADD;
                        branch_op <= OP_BRANCH_JAL_JALR;
                    
                    when OP_JALR =>
                        branch<= '1';
                        mux_alu_in_1 <= '0'; --rs1 register
                        mux_alu_in_2 <= '1'; --imme_ext
                        alu_op <= OP_ALU_ADD;
                        branch_op <= OP_BRANCH_JAL_JALR;
                    
                    when OP_AUIPC =>
                        mux_alu_in_1 <= '1'; --current pc
                        mux_alu_in_2 <= '1'; --imm_ext
                        alu_op <= OP_ALU_ADD;
                    
                    when OP_LOAD | OP_STORE =>
                        mux_alu_in_1 <= '0'; --rs1 register
                        mux_alu_in_2 <= '1'; --imme_ext
                        alu_op <= OP_ALU_ADD;
                        
                    
                        
                    when others => null;
                end case;
                ALUOutWrite <= '1';
                BranchOutWrite <= '1';
            
            when MEMORY =>
                next_state <= WRITEBACK;
                pc_we <= '1';
                case opcode_s is
                    when OP_LOAD =>
                      data_mem_ena <= '1';
                    
                    when OP_STORE =>
                       is_store <= '1';
                       lsu_op <= decode_lsutype(funct3_s);
                       data_mem_ena <= '1';
                    when others => null;  
                end case;
                
                
            when WRITEBACK =>
                next_state <= FETCH;
                case opcode_s is
                    when OP_ALU | OP_ALUI | OP_AUIPC =>
                        mux_reg_in <= "00"; --alu res;
                        reg_file_wea <= '1'; -- write alu result in register
                    
                    when OP_JAL | OP_JALR =>
                        mux_reg_in <= "10"; --pc + 4
                        reg_file_wea <= '1';
                    
                    when OP_LUI =>
                        mux_reg_in <= "11"; --imm_extended result
                        reg_file_wea <= '1';
                        
                    when OP_LOAD =>
                        lsu_op <= decode_lsutype(funct3_s);
                        mux_reg_in <= "01"; --lsu result;
                        reg_file_wea <= '1';
                    
                        
                    when others => null;     
                end case;
             when others => null;
        end case;
    end process;
    

end Behavioral;
