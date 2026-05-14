----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/12/2026 08:10:24 PM
-- Design Name: 
-- Module Name: instr_mem_mux - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity instr_mem_mux is
Port (
    
    instr_mem_addr_in: in std_logic_vector(31 downto 0);
    instr_mem_data_out: out std_logic_vector(31 downto 0);
    instr_mem_ena_in: in std_logic;
    
    boot_mem_addr_out: out std_logic_vector(31 downto 0);
    boot_mem_data_in: in std_logic_vector(31 downto 0);
    boot_mem_ena_out: out std_logic;
    
    instr_mem_addr_out: out std_logic_vector(31 downto 0);
    instr_mem_data_in: in std_logic_vector(31 downto 0);
    instr_mem_ena_out: out std_logic
     );
end instr_mem_mux;

architecture Behavioral of instr_mem_mux is
begin
    -- 1. Indirizzi: Nessun calcolo, solo assegnazione di bit.
    -- La memoria App vedrà l'indirizzo CPU troncato ai 16 bit bassi (0x0000 - 0xFFFF)
    boot_mem_addr_out  <= instr_mem_addr_in;
    instr_mem_addr_out <= x"0000" & instr_mem_addr_in(15 downto 0);
    
    -- 2. Abilitazione (Enable): Logica booleana immediata.
    -- Il bit 16 funge da selettore hardware istantaneo.
    boot_mem_ena_out  <= instr_mem_ena_in AND (NOT instr_mem_addr_in(16));
    instr_mem_ena_out <= instr_mem_ena_in AND instr_mem_addr_in(16);

    -- 3. Dati in uscita (Data Mux): 
    -- Se il timing è ancora critico, questo è il punto dove il dato torna alla CPU.
    instr_mem_data_out <= instr_mem_data_in when (instr_mem_addr_in(16) = '1') else 
                          boot_mem_data_in;

end Behavioral;
