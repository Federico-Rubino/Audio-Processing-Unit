library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bmu_write is  -- buffer management unit
    generic (
        BUFFER_ADDR_WIDTH : integer := 10; -- width of the address bus for the BRAM blocks
        BUFFER_SIZE_BITS : integer := 18; -- width of the size bus for the buffers
        MODE : std_logic_vector(1 downto 0) := "00"; -- 00: parallel4, 01: parallel8 , 10: serial
    );
    Port (
        count_en : in std_logic; -- enable counting of the buffer
        clk, rst : in std_logic; -- clock and reset
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

        data_in_0 : in std_logic_vector(31 downto 0); -- data to write in buffer
        data_in_1 : in std_logic_vector(31 downto 0); -- data to write in buffer
        data_in_2 : in std_logic_vector(31 downto 0); -- data to write in buffer
        data_in_3 : in std_logic_vector(31 downto 0); -- data to write in buffer
        data_in_4 : in std_logic_vector(31 downto 0); -- data to write in buffer
        data_in_5 : in std_logic_vector(31 downto 0); -- data to write in buffer
        data_in_6 : in std_logic_vector(31 downto 0); -- data to write in buffer
        data_in_7 : in std_logic_vector(31 downto 0); -- data to write in buffer
    );
end bmu_write;

architecture Behavioral of bmu_write is

begin

end Behavioral;