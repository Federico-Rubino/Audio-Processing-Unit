----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/06/2026 05:48:31 PM
-- Design Name: 
-- Module Name: load_store_unit - Behavioral
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

entity load_store_unit is
  Port (
        lsu_op : in lsu_op_t;
        is_store : in std_logic;
        
        addr_lsb : in std_logic_vector(1 downto 0);
        data_in_rs2 : in std_logic_vector(31 downto 0);
        data_in_mem : in std_logic_vector(31 downto 0);
        
        mem_we : out std_logic_vector(3 downto 0);
        mem_din : out std_logic_vector(31 downto 0);
        
        reg_rd_data : out std_logic_vector(31 downto 0)
   );
end load_store_unit;

architecture Behavioral of load_store_unit is
begin
    process(lsu_op, is_store, addr_lsb, data_in_rs2, data_in_mem)
    begin
        mem_we <= "0000";
        mem_din <= data_in_rs2;
        reg_rd_data <= data_in_mem;
        
        --STORE
        if is_store = '1' then
            case lsu_op is
                when OP_LSU_B => --Store Byte (SB)
                   case addr_lsb is
                        when "00"   => mem_we <= "0001"; mem_din <= x"000000" & data_in_rs2(7 downto 0);
                        when "01"   => mem_we <= "0010"; mem_din <= x"0000" & data_in_rs2(7 downto 0) & x"00";
                        when "10"   => mem_we <= "0100"; mem_din <= x"00" & data_in_rs2(7 downto 0) & x"0000";
                        when others => mem_we <= "1000"; mem_din <= data_in_rs2(7 downto 0) & x"000000";
                    end case; 
                when OP_LSU_H =>  --Store Halfwrod (SH)
                    if addr_lsb(1) = '0' then
                        mem_we <= "0011"; mem_din <= x"0000" & data_in_rs2(15 downto 0);
                    else
                        mem_we <= "1100"; mem_din <= data_in_rs2(15 downto 0) & x"0000";
                    end if;
                 
               when OP_LSU_W =>
                    mem_we <= "1111";
                    mem_din <= data_in_rs2;
                    
               when others =>
                    mem_we <= "0000";
               
            end case;
        else  --LOAD
            case lsu_op is
                when OP_LSU_B =>
                    case addr_lsb is
                        when "00"   => reg_rd_data <= std_logic_vector(resize(signed(data_in_mem(7 downto 0)), 32));
                        when "01"   => reg_rd_data <= std_logic_vector(resize(signed(data_in_mem(15 downto 8)), 32));
                        when "10"   => reg_rd_data <= std_logic_vector(resize(signed(data_in_mem(23 downto 16)), 32));
                        when others => reg_rd_data <= std_logic_vector(resize(signed(data_in_mem(31 downto 24)), 32));
                    end case;
                    
                when OP_LSU_BU =>
                    case addr_lsb is
                        when "00"   => reg_rd_data <= std_logic_vector(resize(unsigned(data_in_mem(7 downto 0)), 32));
                        when "01"   => reg_rd_data <= std_logic_vector(resize(unsigned(data_in_mem(15 downto 8)), 32));
                        when "10"   => reg_rd_data <= std_logic_vector(resize(unsigned(data_in_mem(23 downto 16)), 32));
                        when others => reg_rd_data <= std_logic_vector(resize(unsigned(data_in_mem(31 downto 24)), 32));
                    end case;
                
                when OP_LSU_H =>
                    if addr_lsb(1) = '0' then
                         reg_rd_data <= std_logic_vector(resize(signed(data_in_mem(15 downto 0)),32));
                    else
                        reg_rd_data <= std_logic_vector(resize(signed(data_in_mem(31 downto 16)),32));
                    end if;
                
               when OP_LSU_HU =>
                    if addr_lsb(1) = '0' then
                         reg_rd_data <= std_logic_vector(resize(unsigned(data_in_mem(15 downto 0)),32));
                    else
                        reg_rd_data <= std_logic_vector(resize(unsigned(data_in_mem(31 downto 16)),32));
                    end if;
               
               when OP_LSU_W => reg_rd_data <= data_in_mem;
               when others => reg_rd_data <= data_in_mem;
            end case;
        
        end if;
    end process;
    

end Behavioral;
