library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.apu_opcode_pkg.all;
use IEEE.NUMERIC_STD.ALL;

entity APU is
    Generic (
        ARAM_WORD_SIZE : integer := 32;     -- word size of aram and iram
        ARAM_ADDR_SIZE : integer := 16;     -- size needed to address a ARAM location
        INSTR_ADDR_SIZE : integer := 11;    -- size needed to address a instruction RAM location
        UPARAM_SIZE : integer := 9;         -- size of a uniform param address
        INSTR_SIZE : integer := 128;        -- currently the max is 4*ARAM_WORD_SIZE
        COUNTER_SIZE : integer := 16
    );
    Port (
        clk, rst : in std_logic;

        -- ADAU
        AC_ADR0  : out   std_logic;
        AC_ADR1  : out   std_logic;
        AC_GPIO0 : out   std_logic;
        AC_GPIO1 : in    std_logic;
        AC_GPIO2 : in    std_logic;
        AC_GPIO3 : in    std_logic;
        AC_MCLK  : out   std_logic;
        AC_SCK   : out   std_logic;
        AC_SDA   : inout std_logic;

        -- Instr BRAM to AXI
        we, en   : in  std_logic;
        addr     : in  std_logic_vector(10 downto 0);
        data_in  : in  std_logic_vector(31 downto 0);
        data_out : out std_logic_vector(31 downto 0);
    );
end APU;

architecture Behavioural of APU is

begin

end Behavioural;