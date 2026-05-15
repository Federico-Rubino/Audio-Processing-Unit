----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/10/2026 10:26:24 PM
-- Design Name: 
-- Module Name: audioIO - Behavioral
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

entity audioIO is
  Port (
    clk : in std_logic;
    rst : in std_logic;
    
    --ADAU
    AC_ADR0  : out   STD_LOGIC;  -- control signals to ADAU chip
    AC_ADR1  : out   STD_LOGIC;
    AC_GPIO0 : out   STD_LOGIC;  -- I2S MISO
    AC_GPIO1 : in    STD_LOGIC;  -- I2S MOSI
    AC_GPIO2 : in    STD_LOGIC;  -- I2S_bclk
    AC_GPIO3 : in    STD_LOGIC;  -- I2S_LR
    AC_MCLK  : out   STD_LOGIC;
    AC_SCK   : out   STD_LOGIC;
    AC_SDA   : inout STD_LOGIC;
    
    --memory
    data_mem_addr : out std_logic_vector(31 downto 0);
    data_mem_data_out : out std_logic_vector(31 downto 0);
    data_mem_ena : out std_logic;
    data_mem_wea: out std_logic;
    
    --register interface
    next_ctrl_reg : in std_logic_vector(1 downto 0); -- constrol register value, bit 0: start, bit 1: 0-left, 1-right
    next_start_addr_reg : in std_logic_vector(31 downto 0); -- address register value
    next_offset_reg : in std_logic_vector(31 downto 0); -- offset register value
    status_reg: out std_logic_vector(18 downto 0); -- status register: bit 0: finished, bit 1: new sample in left, bit 2:  new sample in right, bit 3-10: avail left samples, bit 11-18: avail right samples
    
    
    --audio from apu interface
    new_sample_pair : in  std_logic;
    sample_pair     : in  std_logic_vector(31 downto 0);
    channel_sel     : in  std_logic
    
    
   );
end audioIO;

architecture Behavioral of audioIO is
    signal new_sample : std_logic := '0';
    signal line_in_l, line_in_r: std_logic_vector(15 downto 0) := (others => '0');
    signal line_in_l_24b, line_in_r_24b: std_logic_vector(23 downto 0):= (others => '0');
    signal line_out_l, line_out_r: std_logic_vector(15 downto 0) := (others => '0');
    signal line_out_l_24b, line_out_r_24b: std_logic_vector(23 downto 0) := (others => '0');
    signal sample_clk_48k : std_logic;
    
begin
    audio_in_inst: entity work.audio_in
        port map(
            clk => clk,
            rst => rst,
            new_sample => new_sample,
            line_in_l => line_in_l,
            line_in_r => line_in_r,
            data_mem_addr => data_mem_addr,
            data_mem_data_out => data_mem_data_out,
            data_mem_ena => data_mem_ena,
            data_mem_wea => data_mem_wea,
            next_ctrl_reg => next_ctrl_reg,
            next_start_addr_reg => next_start_addr_reg,
            next_offset_reg => next_offset_reg,
            status_reg  => status_reg
        );
        
        audio_adau : entity work.audio_top
            port map(
                clk_100  => clk, 
                AC_ADR0  => AC_ADR0,
                AC_ADR1  => AC_ADR1,
                AC_GPIO0 => AC_GPIO0,
                AC_GPIO1 => AC_GPIO1,
                AC_GPIO2 => AC_GPIO2,
                AC_GPIO3 => AC_GPIO3,
                AC_MCLK  => AC_MCLK,
                AC_SCK   => AC_SCK,
                AC_SDA   => AC_SDA,
      
                hphone_l  => line_out_l_24b,
                hphone_l_valid => new_sample,
                hphone_r  => line_out_r_24b,
                hphone_r_valid_dummy => new_sample,   --  this valid will be discarded later
      
                line_in_l => line_in_l_24b,  
                line_in_r => line_in_r_24b,

                new_sample => new_sample,
                sample_clk_48k => sample_clk_48k
            );
            
        audio_out_inst : entity work.audio_out
            port map(
                clk => clk,
                rst => rst,
                
                new_sample => new_sample,
                sample_out_l => line_out_l,
                sample_out_r => line_out_r,
                
                new_sample_pair => new_sample_pair,
                sample_pair => sample_pair,
                channel_sel => channel_sel
                
            );
            
        line_out_l_24b <= line_out_l & x"00";
        line_out_r_24b <= line_out_r & x"00";
        
        line_in_l <= line_in_l_24b(23 downto 8);
        line_in_r <= line_in_r_24b(23 downto 8);
        


end Behavioral;
