----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/03/2026 11:13:20 AM
-- Design Name: 
-- Module Name: audioIO_control_unit 
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

entity audioIO_control_unit is
  Port (
    clk : in std_logic;
    rst : in std_logic;

    --register
    ctrl_reg: in std_logic_vector(1 downto 0);
    ctrl_reg_ena : out std_logic;
    ctrl_reg_clear : out std_logic;
    start_addr_reg_ena : out std_logic;
    offset_reg_ena : out std_logic;
    finished: out std_logic;

    --addr gen unit
    addr_gen_ready : in std_logic;
    addr_gen_start : out std_logic;

    --circular buffer
    read_pair_l : out std_logic;
    read_pair_r : out std_logic;

    --memory
    data_mem_ena : out std_logic;
    data_mem_out_lr : out std_logic
   );
end audioIO_control_unit;

architecture Behavioral of audioIO_control_unit is
    type state_t is (IDLE, START_L, START_R, COPY_L, COPY_R);
    signal state, next_state : state_t;
begin
    

    process(clk, rst)
    begin
        if rst = '1' then
            state <= IDLE;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    process(state, ctrl_reg, addr_gen_ready)
    begin

        next_state <= state;
        ctrl_reg_ena <= '0';
        ctrl_reg_clear <= '0';
        start_addr_reg_ena <= '0';
        offset_reg_ena <= '0';
        finished <= '0';
        addr_gen_start <= '0';
        read_pair_l <= '0';
        read_pair_r <= '0';
        data_mem_ena <= '0';
        data_mem_out_lr <= '0';

        case state is
            when IDLE =>
                ctrl_reg_ena <= '1';
                start_addr_reg_ena <= '1';
                offset_reg_ena <= '1';
                finished <= '1';

                if ctrl_reg = "01" then  --start left
                    next_state <= START_L;
                elsif ctrl_reg = "11" then --start right
                    next_state <= START_R;
                    
                end if;

            when START_L =>
                next_state <= COPY_L;
                addr_gen_start <= '1';
                ctrl_reg_clear <= '1';

            when COPY_L =>
                if addr_gen_ready = '0' then
                    next_state <= COPY_L;
                    read_pair_l <= '1';
                    data_mem_ena <= '1';
                    data_mem_out_lr <= '0'; --left channel data to memory

                elsif addr_gen_ready = '1' then 
                    next_state <= IDLE;
                end if;

            when START_R =>
                next_state <= COPY_R;
                addr_gen_start <= '1';
                ctrl_reg_clear <= '1';

            when COPY_R =>
                if addr_gen_ready = '0' then
                    next_state <= COPY_R;
                    read_pair_r <= '1';
                    data_mem_ena <= '1';
                    data_mem_out_lr <= '1'; --right channel data to memory

                elsif addr_gen_ready = '1' then 
                    next_state <= IDLE;
                end if;
        end case;

    end process;
    

end Behavioral;
