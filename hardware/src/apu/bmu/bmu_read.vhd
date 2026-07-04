library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bmu_read is  -- buffer management unit
    generic (
        BUFFER_ADDR_WIDTH : integer := 10; -- width of the address bus for the BRAM blocks
        BUFFER_SIZE_BITS : integer := 18; -- width of the size bus for the buffers
        MODE : std_logic_vector(1 downto 0) := "00" -- 00: parallel4, 01: parallel8 , 10: serial
    );
    Port (
        count_en : in std_logic; -- enable counting of the buffer
        clk, rst : in std_logic; -- clock and reset active low
        buffer_start : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0); -- address of buffer start
        buffer_lenght : in std_logic_vector(BUFFER_SIZE_BITS-1 downto 0); -- lenght of the buffer

        operation_start : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0); -- address of the start of the operation, multiple of 4
        operation_lenght : in std_logic_vector(BUFFER_SIZE_BITS-1 downto 0); -- lenght of the operation

        bram0_port0_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0); -- address to access in BRAM block 0 port0
        bram1_port0_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0); -- address to access in BRAM block 1 port0
        bram2_port0_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0); -- address to access in BRAM block 2 port0
        bram3_port0_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0); -- address to access in BRAM block 3 port0

        bram0_port1_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0); -- address to access in BRAM block 0 port1
        bram1_port1_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0); -- address to access in BRAM block 1 port1
        bram2_port1_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0); -- address to access in BRAM block 2 port1
        bram3_port1_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0); -- address to access in BRAM block 3 port1

        bram0_port0_we : out std_logic; -- write enable for BRAM block 0 port0
        bram1_port0_we : out std_logic; -- write enable for BRAM block 1 port0
        bram2_port0_we : out std_logic; -- write enable for BRAM block 2 port0
        bram3_port0_we : out std_logic; -- write enable for BRAM block 3 port0

        bram0_port1_we : out std_logic; -- write enable for BRAM block 0 port1
        bram1_port1_we : out std_logic; -- write enable for BRAM block 1 port1
        bram2_port1_we : out std_logic; -- write enable for BRAM block 2 port1
        bram3_port1_we : out std_logic; -- write enable for BRAM block 3 port1

        bram0_port0_en : out std_logic; -- enable for BRAM block 0 port0
        bram1_port0_en : out std_logic; -- enable for BRAM block 1 port0
        bram2_port0_en : out std_logic; -- enable for BRAM block 2 port0
        bram3_port0_en : out std_logic; -- enable for BRAM block 3 port0

        bram0_port1_en : out std_logic; -- enable for BRAM block 0 port1
        bram1_port1_en : out std_logic; -- enable for BRAM block 1 port1
        bram2_port1_en : out std_logic; -- enable for BRAM block 2 port1
        bram3_port1_en : out std_logic; -- enable for BRAM block 3 port1

        bram0_port0_data_in : out std_logic_vector(31 downto 0); -- data to write in BRAM block 0 port0
        bram1_port0_data_in : out std_logic_vector(31 downto 0); -- data to write in BRAM block 1 port0
        bram2_port0_data_in : out std_logic_vector(31 downto 0); -- data to write in BRAM block 2 port0
        bram3_port0_data_in : out std_logic_vector(31 downto 0); -- data to write in BRAM block 3 port0

        bram0_port1_data_in : out std_logic_vector(31 downto 0); -- data to write in BRAM block 0 port1
        bram1_port1_data_in : out std_logic_vector(31 downto 0); -- data to write in BRAM block 1 port1
        bram2_port1_data_in : out std_logic_vector(31 downto 0); -- data to write in BRAM block 2 port1
        bram3_port1_data_in : out std_logic_vector(31 downto 0); -- data to write in BRAM block 3 port1

        bram0_port0_data_out : in std_logic_vector(31 downto 0); -- data read from BRAM block 0 port0
        bram1_port0_data_out : in std_logic_vector(31 downto 0); -- data read from BRAM block 1 port0
        bram2_port0_data_out : in std_logic_vector(31 downto 0); -- data read from BRAM block 2 port0
        bram3_port0_data_out : in std_logic_vector(31 downto 0); -- data read from BRAM block 3 port0

        bram0_port1_data_out : in std_logic_vector(31 downto 0); -- data read from BRAM block 0 port1
        bram1_port1_data_out : in std_logic_vector(31 downto 0); -- data read from BRAM block 1 port1
        bram2_port1_data_out : in std_logic_vector(31 downto 0); -- data read from BRAM block 2 port1
        bram3_port1_data_out : in std_logic_vector(31 downto 0) -- data read from BRAM block 3 port1

        data_out_0 : out std_logic_vector(31 downto 0); -- data read from BRAM block 0 port0
        data_out_1 : out std_logic_vector(31 downto 0); -- data read from BRAM block 1 port0
        data_out_2 : out std_logic_vector(31 downto 0); -- data read from BRAM block 2 port0
        data_out_3 : out std_logic_vector(31 downto 0); -- data read from BRAM block 3 port0
        data_out_4 : out std_logic_vector(31 downto 0); -- data read from BRAM block 0 port1
        data_out_5 : out std_logic_vector(31 downto 0); -- data read from BRAM block 1 port1
        data_out_6 : out std_logic_vector(31 downto 0); -- data read from BRAM block 2 port1
        data_out_7 : out std_logic_vector(31 downto 0) -- data read from BRAM block 3 port1
    );
end bmu_read;

architecture Behavioral of bmu_read is
    signal address_counter : std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0) := (others => '0'); -- counter for the address
begin
    process(clk)
    begin 
        bram0_port0_en <= '0';
        bram1_port0_en <= '0';
        bram2_port0_en <= '0';
        bram3_port0_en <= '0';

        bram0_port1_en <= '0';
        bram1_port1_en <= '0';
        bram2_port1_en <= '0';
        bram3_port1_en <= '0';

        bram0_port0_we <= '0';
        bram1_port0_we <= '0';
        bram2_port0_we <= '0';
        bram3_port0_we <= '0';

        bram0_port1_we <= '0';
        bram1_port1_we <= '0';
        bram2_port1_we <= '0';
        bram3_port1_we <= '0';

        if rising_edge(clk) then
            if rst = '0' then
                address_counter <= unsigned(buffer_start) + usnigned(operation_start);
            else
                case MODE is
                    when "00" => -- parallel4
                        if count_en = '1' then
                            address_counter <= std_logic_vector(unsigned(address_counter) + 1);
                            bram0_port0_en <= '1';
                            bram1_port0_en <= '1';
                            bram2_port0_en <= '1';
                            bram3_port0_en <= '1';
                        end if;
                    when "01" => -- parallel8
                        if count_en = '1' then
                        end if;
                    when "10" => -- serial
                        if count_en = '1' then
                        end if;
                    when others =>
                        null; -- do nothing for other modes
                end case;
            end if;
        end if;
    end process;

end Behavioral;