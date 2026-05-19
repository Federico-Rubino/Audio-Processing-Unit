library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity audio_ram_mux is
    generic (
        --0x00020000 shifted
        C_WORD_BASE_ADDR : unsigned(31 downto 0) := x"00008000"
    );
    Port (
        audioIO_addr      : in std_logic_vector(31 downto 0);
        audioIO_data_in   : in std_logic_vector(31 downto 0);
        audioIO_ena       : in std_logic;
        audioIO_wea       : in std_logic;

        apu_addr          : in std_logic_vector(31 downto 0);
        apu_data_out      : out std_logic_vector(31 downto 0);
        apu_ena           : in std_logic;

        data_mem_addr     : out std_logic_vector(31 downto 0);
        data_mem_data_out : out std_logic_vector(31 downto 0);
        data_mem_ena      : out std_logic;
        data_mem_wea      : out std_logic_vector(3 downto 0);
        data_mem_data_in  : in std_logic_vector(31 downto 0)
    );
end audio_ram_mux;

architecture RTL of audio_ram_mux is
begin

    apu_data_out <= data_mem_data_in;


    process(audioIO_addr, audioIO_data_in, audioIO_ena, audioIO_wea, apu_addr, apu_ena)
    begin
        if audioIO_ena = '1' then
            --audioIO
            data_mem_addr     <= std_logic_vector(unsigned(audioIO_addr) - C_WORD_BASE_ADDR);
            data_mem_data_out <= audioIO_data_in;
            data_mem_ena      <= '1';
            data_mem_wea      <= (others => audioIO_wea);
            
        else
        --apu
            data_mem_addr     <= std_logic_vector(unsigned(apu_addr) - C_WORD_BASE_ADDR);
            data_mem_data_out <= (others => '0');
            data_mem_ena      <= apu_ena;
            data_mem_wea      <= (others => '0');
        end if;
    end process;

end RTL;