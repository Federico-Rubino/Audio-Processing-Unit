----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/05/2026 
-- Design Name: 
-- Module Name: audioIO
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
use work.audioIO_types.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity audio_in is
  Port (
    clk : in std_logic;
    rst : in std_logic;
    
    new_sample : in std_logic;
    line_in_l, line_in_r : in std_logic_vector(15 downto 0);
    

    --to memory
    data_mem_addr : out std_logic_vector(31 downto 0);
    data_mem_data_out : out std_logic_vector(31 downto 0);
    data_mem_ena : out std_logic;
    data_mem_wea: out std_logic;

    --register interface
    next_ctrl_reg : in std_logic_vector(1 downto 0); -- constrol register value, bit 0: start, bit 1: 0-left, 1-right
    next_start_addr_reg : in std_logic_vector(31 downto 0); -- address register value
    next_offset_reg : in std_logic_vector(31 downto 0); -- offset register value
    status_reg: out std_logic_vector(22 downto 0) -- status register: bit 0: finished, bit 1: new sample in left, bit 2:  new sample in right, bit 3-12: avail left samples, bit 13-22: avail right samples
   );
end audio_in;

architecture Behavioral of audio_in is


    signal ctrl_reg : std_logic_vector(1 downto 0);
    signal ctrl_reg_ena : std_logic;
    signal ctrl_reg_clear : std_logic;

    signal start_addr_reg : std_logic_vector(31 downto 0);
    signal start_addr_reg_ena : std_logic;
    signal offset_reg : std_logic_vector(31 downto 0);
    signal offset_reg_ena : std_logic;

    signal next_status_reg : std_logic_vector(22 downto 0);

    signal read_pair_l, read_pair_r : std_logic;
    signal sample_pair_l, sample_pair_r : std_logic_vector(31 downto 0);

    --address generator signals
    signal addr_gen_start : std_logic;
    signal current_addr : std_logic_vector(31 downto 0);
    signal addr_gen_ready : std_logic;
    signal addr_gen_valid : std_logic;

    --memory interface signals
    signal data_mem_out_lr: std_logic;


begin

    left_channel_buffer_in : entity work.circular_channel_buffer_in
        port map (
            clk => clk,
            rst => rst,
            new_sample => new_sample,
            sample_in => line_in_l, 
            read_pair => read_pair_l,
            sample_pair_out => sample_pair_l,
            has_data => next_status_reg(1),
            avail_samples => next_status_reg(12 downto 3) --update status register bits for available samples in left channel
        );

    right_channel_buffer_in : entity work.circular_channel_buffer_in
        port map (
            clk => clk,
            rst => rst,
            new_sample => new_sample,
            sample_in => line_in_r,
            read_pair => read_pair_r,
            sample_pair_out => sample_pair_r,
            has_data => next_status_reg(2), 
            avail_samples => next_status_reg(22 downto 13) -- update status register bits for available samples in right channel
        );

    address_gen : entity work.audioIO_address_generator
        port map (
            clk => clk,
            rst => rst,
            start => addr_gen_start,
            base_addr => start_addr_reg,
            offset => '0' & offset_reg(31 downto 1), -- shift to transform in address offset
            current_addr => current_addr,
            ready => addr_gen_ready,
            addr_valid => addr_gen_valid
        );

    control_unit : entity work.audioIO_control_unit
        port map (
            clk => clk,
            rst => rst,
            ctrl_reg => ctrl_reg,
            ctrl_reg_ena => ctrl_reg_ena,
            ctrl_reg_clear => ctrl_reg_clear,
            start_addr_reg_ena => start_addr_reg_ena,
            offset_reg_ena => offset_reg_ena,
            finished => next_status_reg(0),
            addr_gen_ready => addr_gen_ready,
            addr_gen_start => addr_gen_start,
            read_pair_l => read_pair_l,
            read_pair_r => read_pair_r,
            data_mem_ena => data_mem_ena,
            data_mem_out_lr => data_mem_out_lr
        );


        process(clk, rst)
        begin
            if rst = '1' then
                ctrl_reg <= (others => '0');
                start_addr_reg <= (others => '0');
                offset_reg <= (others => '0');
                status_reg <= (others => '0');
            elsif rising_edge(clk) then
                if ctrl_reg_clear = '1' then
                    ctrl_reg <= "00";
                elsif ctrl_reg_ena = '1' then
                    ctrl_reg <= next_ctrl_reg;
                end if;
                if start_addr_reg_ena = '1' then
                    start_addr_reg <= next_start_addr_reg;
                end if;
                if offset_reg_ena = '1' then
                    offset_reg <= next_offset_reg;
                end if;
                status_reg <= next_status_reg;
            end if;
        end process;
        
        
        data_mem_data_out <= sample_pair_r when data_mem_out_lr = '1' else sample_pair_l;
        data_mem_addr <= current_addr;
        data_mem_wea <= addr_gen_valid;
            

    

end Behavioral;
