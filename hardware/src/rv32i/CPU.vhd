----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/03/2026 04:50:01 PM
-- Design Name: 
-- Module Name: CPU - Behavioral
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
use work.types_pkg.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity CPU is
  Port (
  clk : in std_logic;
  rst : in std_logic;
  
  --instruction memory
  instr_mem_addr : out unsigned(31 downto 0);
  instr_mem_data : in std_logic_vector(31 downto 0);
  instr_mem_ena : out std_logic;
  
  --data memory
  data_mem_addr : out std_logic_vector(31 downto 0);
  data_mem_data_out : out std_logic_vector(31 downto 0);
  data_mem_data_in : in std_logic_vector(31 downto 0);
  data_mem_ena : out std_logic;
  data_mem_wea: out std_logic_vector(3 downto 0);
  
  --debug
  debug_regs : out std_logic_vector(1023 downto 0)
  
  
   );
end CPU;

architecture Behavioral of CPU is

    --REGISTER FILE
    signal reg_file_rs1 : unsigned(4 downto 0);
    signal reg_file_rs2 : unsigned(4 downto 0);
    signal reg_file_rd : unsigned(4 downto 0);
    signal reg_file_rdata1 : std_logic_vector(31 downto 0);
    signal reg_file_rdata2 : std_logic_vector(31 downto 0);
    signal reg_file_wea : std_logic;
    signal reg_file_wdata  : std_logic_vector(31 downto 0);
    
    --ALU
    signal alu_a : std_logic_vector(31 downto 0);
    signal alu_b : std_logic_vector(31 downto 0);
    signal alu_op : alu_op_t;
    signal alu_res : std_logic_vector(31 downto 0);
    
    --PC COUNTER
    signal pc : unsigned(31 downto 0);
    signal pc_next : unsigned(31 downto 0);
    signal pc_write_enable : std_logic;
    
    --SIGN EXTENSION
    signal opcode : std_logic_vector(6 downto 0);
    signal imm_extended : std_logic_vector(31 downto 0);
    
    --BRANCH UNIT
    signal branch_op : branch_op_t;
    signal branch_a : std_logic_vector(31 downto 0);
    signal branch_b : std_logic_vector(31 downto 0);
    signal branch : std_logic;
    signal branch_result : std_logic;
    
    --MUX
    signal mux_alu_in_1 : std_logic;
    signal mux_alu_in_2 : std_logic;
    signal mux_regfile_in : std_logic_vector(1 downto 0);
    
    --STAGE REGISTER
    signal A, B : std_logic_vector(31 downto 0);
    signal ALUOut : std_logic_vector(31 downto 0);
    signal BranchOut : std_logic;
    signal IRWrite, AWrite, BWrite, ALUOutWrite, BranchOutWrite  : std_logic;
    
    --LSU
    signal is_store : std_logic;
    signal lsu_op : lsu_op_t;
    signal data_mem_to_rd : std_logic_vector(31 downto 0);
    
    --debug regs
    signal reg_file_debug_regs : std_logic_vector(1023 downto 0);
    
begin
    pc_reg : entity work.program_counter
        port map (
            clk => clk,
            pc_in => pc_next,
            pc_out => pc,
            pc_reset => rst,
            pc_write_enable => pc_write_enable
        );
    
    reg_file : entity work.register_file
        port map (
            clk => clk,
            rst => rst,
            raddr1 => reg_file_rs1,
            raddr2 => reg_file_rs2,
            rdata1 => reg_file_rdata1,
            rdata2 => reg_file_rdata2,
            waddr => reg_file_rd,
            wdata => reg_file_wdata,
            regwrite => reg_file_wea,
            debug_regs => reg_file_debug_regs
            );
    
    alu : entity work.alu
        port map (
            alu_op => alu_op,
            a => alu_a,
            b => alu_b,
            result => alu_res
        );
        
    branch_unit : entity work.branch_unit
        port map (
            branch => branch,
            branch_op => branch_op,
            a => branch_a,
            b => branch_b,
            take_branch => branch_result
        );
        
    sign_extension_unit : entity work.sign_extension_unit
        port map (
            instr => instr_mem_data,
            opcode => opcode,
            immediate_extended => imm_extended
        );
        
    control_unit : entity work.control_unit
        port map (
            clk => clk,
            rst => rst,
            instr => instr_mem_data,
            
            pc_we => pc_write_enable,
            instr_mem_ena => instr_mem_ena,
            
            reg_file_raddr1 => reg_file_rs1,
            reg_file_raddr2 => reg_file_rs2,
            reg_file_waddr => reg_file_rd,
            reg_file_wea => reg_file_wea,
            
            opcode => opcode,
            
            mux_alu_in_1 => mux_alu_in_1,
            mux_alu_in_2 => mux_alu_in_2,
            alu_op => alu_op,
            
            branch => branch,
            branch_op => branch_op,
            
            data_mem_ena => data_mem_ena,
            
            mux_reg_in => mux_regfile_in,
            IRWrite => IRWrite,
            AWrite => AWrite,
            BWrite => BWrite,
            ALUOutWrite => ALUOutWrite,
            BranchOutWrite => BranchOutWrite,
            
            lsu_op => lsu_op,
            is_store => is_store
        );
        
     load_store_unit : entity work.load_store_unit
        port map (
            lsu_op => lsu_op,
            is_store => is_store,
            addr_lsb => ALUOut(1 downto 0),
            data_in_rs2 => B,
            data_in_mem => data_mem_data_in,
            mem_we => data_mem_wea,
            mem_din => data_mem_data_out,
            reg_rd_data => data_mem_to_rd
        
        );        
   process(clk)
    begin
    if rising_edge(clk) then
        if AWrite = '1' then
            A <= reg_file_rdata1;
        end if;

        if BWrite = '1' then
            B <= reg_file_rdata2;
        end if;

        if ALUOutWrite = '1' then
            ALUOut <= alu_res;
        end if;
        
        if BranchOutWrite = '1' then
            BranchOut <= branch_result;
        end if;
    end if;
    end process;
   
   alu_a <= A when mux_alu_in_1 = '0' else std_logic_vector(pc);
   alu_b <= B when mux_alu_in_2 = '0' else imm_extended;
   
   branch_a <= A;
   branch_b <= B;
   
   pc_next <= pc + 4 when BranchOut = '0' else unsigned(ALUOut);
   
   reg_file_wdata <= ALUOut when mux_regfile_in = "00" 
                     else data_mem_to_rd when mux_regfile_in = "01" 
                     else std_logic_vector(pc + 4) when mux_regfile_in = "10"
                     else imm_extended;
   
   instr_mem_addr <= pc;
   data_mem_addr <= ALUOut;
   
   debug_regs <= reg_file_debug_regs;

end Behavioral;
