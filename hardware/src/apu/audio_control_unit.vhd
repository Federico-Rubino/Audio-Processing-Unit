library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.apu_opcode_pkg.all;
use IEEE.NUMERIC_STD.ALL;

entity AudioCU is
    Port (
        clk, rst : in std_logic;
        opcode : in apu_opcode_t;
        in_buffer1_start : in std_logic_vector(17 downto 0);
        in_buffer1_offset : in std_logic_vector(17 downto 0);
        in_buffer2_start : in std_logic_vector(17 downto 0);
        in_buffer2_offset : in std_logic_vector(17 downto 0);
        in_buffer3_start : in std_logic_vector(17 downto 0);
        in_buffer3_offset : in std_logic_vector(17 downto 0);
        out_buffer1_start : in std_logic_vector(17 downto 0);
        out_buffer1_offset : in std_logic_vector(17 downto 0);
        out_buffer2_start : in std_logic_vector(17 downto 0);
        out_buffer2_offset : in std_logic_vector(17 downto 0);
        action_size : in std_logic_vector(17 downto 0);
        block_size : in std_logic_vector(17 downto 0);
        param1 : in std_logic_vector(15 downto 0);
        param2 : in std_logic_vector(15 downto 0);
        start : in std_logic;
        next_start : out std_logic;
        next_status : out std_logic
    );
end AudioCU;

architecture Behavioral of AudioCU is
    type state is (idle, fetch, copy, reset);
    signal cu_state : state;
    signal op : apu_opcode_t;
    signal error : std_logic;

    signal next_cu_state : state;
    signal next_op : apu_opcode_t;
    signal next_error : std_logic;

begin

    error <= '0';
    next_error <= '0';

    process(clk, rst)
    begin
        if rst = '0' then
            cu_state <= idle;
        elsif rising_edge(clk) then
            cu_state <= next_cu_state;
            op <= next_op;
        end if;
    end process;

    process(cu_state, opcode)
    begin
        case cu_state is

            when idle =>
                if start = '1' then
                    next_cu_state <= fetch;
                    next_status <= '0';
                    next_op <= opcode;
                    next_start <= '0';
                end if;

            when fetch =>
                case op is
                    when APU_OP_COPY =>
                        next_cu_state <= copy;
                    when others =>
                        next_cu_state <= idle;
                end case;

            when copy =>
                next_cu_state <= reset;

            when reset =>
                next_cu_state <= idle;
                next_status <= '1';

            when others =>
                next_cu_state <= idle;
                next_error <= '1';
        end case;
    end process;

end Behavioral;
