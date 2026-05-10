library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity audioIO_address_generator is
    Port (
        clk          : in  std_logic;
        rst          : in  std_logic;
        
        -- Control
        start        : in  std_logic;
        base_addr    : in  std_logic_vector(31 downto 0);
        offset       : in  std_logic_vector(31 downto 0);
        
        -- Output
        current_addr : out std_logic_vector(31 downto 0);
        ready        : out std_logic; --'1' idle
        addr_valid   : out std_logic  --'1' current_addr is valid 
    );
end audioIO_address_generator;

architecture Behavioral of audioIO_address_generator is
    signal addr_reg     : unsigned(31 downto 0) := (others => '0');
    signal stop_addr    : unsigned(31 downto 0) := (others => '0');
    signal running      : std_logic := '0';
begin

    current_addr <= std_logic_vector(addr_reg);
    ready        <= not running;
    addr_valid   <= running;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                addr_reg  <= (others => '0');
                stop_addr <= (others => '0');
                running   <= '0';
            else
                if start = '1' then
                    addr_reg  <= unsigned(base_addr);
                    stop_addr <= unsigned(base_addr) + unsigned(offset);
                    
                    if unsigned(offset) > 0 then
                        running <= '1';
                    else
                        running <= '0';
                    end if;
                    
                elsif running = '1' then
                    --prevent unsigned underflow
                    if (addr_reg + 1) < stop_addr then
                        addr_reg <= addr_reg + 1;
                    else
                        running <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;