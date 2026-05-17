library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.apu_internal_pkg.all;

entity AudioMemory is
    Port (
        clk, rst  : in  std_logic;

        -- Ports A Interface
        we_a       : in  std_logic;
        addr_a     : in  std_logic_vector(9 downto 0);
        data_in_a  : in  std_logic_vector(31 downto 0);
        data_out_a : out logic_aoa(7 downto 0)(31 downto 0);

        -- Port B Interface
        we_b       : in  std_logic;
        addr_b     : in  std_logic_vector(9 downto 0);
        data_in_b  : in  std_logic_vector(31 downto 0);
        data_out_b : out logic_aoa(7 downto 0)(31 downto 0)
    );
end AudioMemory;

architecture Structural of AudioMemory is

    component MemoryBlock is
        Port (
            clk, rst   : in  std_logic;
        
            -- Port A Interface
            we_a       : in  std_logic;
            addr_a     : in  std_logic_vector(9 downto 0);
            data_in_a  : in  std_logic_vector(31 downto 0);
            data_out_a : out std_logic_vector(31 downto 0);
            
            -- Port B Interface
            we_b       : in  std_logic;
            addr_b     : in  std_logic_vector(9 downto 0);
            data_in_b  : in  std_logic_vector(31 downto 0);
            data_out_b : out std_logic_vector(31 downto 0)
        );
    end component;

begin

    GEN_MEM_BLOCKS: for i in 0 to 7 generate
        MEM_INST : MemoryBlock
            port map (
                clk      => clk,
                rst     => rst,
                we_a       => we_a,
                addr_a     => addr_a,
                data_in_a  => data_in_a,
                data_out_a => data_out_a(i),
                we_b       => we_b,
                addr_b     => addr_b,
                data_in_b  => data_in_b,
                data_out_b => data_out_b(i)
            );
    end generate GEN_MEM_BLOCKS;

end Structural;
