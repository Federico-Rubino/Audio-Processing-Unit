library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.audioIO_types.all;

entity circular_channel_buffer_in is
    Port (
        clk          : in  std_logic;
        rst        : in  std_logic;

        new_sample   : in  std_logic;
        sample_in    : in  std_logic_vector(15 downto 0);

        read_pair  : in  std_logic; 
        sample_pair_out   : out std_logic_vector(31 downto 0);
        has_data     : out std_logic;  -- 1 if w_ptr = r_ptr
        avail_samples : out std_logic_vector(9 downto 0) -- number of available samples 
    );
end circular_channel_buffer_in;

architecture RTL of circular_channel_buffer_in is
    signal circ_reg : aio_internal_regs_t := (others => (others => '0'));
    signal w_ptr    : integer range 0 to DEPTH-1 := 0;
    signal r_ptr    : integer range 0 to DEPTH-1 := 0;

    signal occupancy : integer range 0 to DEPTH := 0;
begin

    has_data <= '1' when occupancy >= 2 else '0';
    avail_samples <=  std_logic_vector(to_unsigned(occupancy, 10));
    sample_pair_out <= circ_reg((r_ptr + 1) mod DEPTH) & circ_reg(r_ptr);

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                w_ptr <= 0;
                r_ptr <= 0;
                occupancy <= 0;
            else
                -- Write Logic
                if new_sample = '1' then
                    circ_reg(w_ptr) <= sample_in;
                    w_ptr <= (w_ptr + 1) mod DEPTH;
                    if occupancy < DEPTH then
                        occupancy <= occupancy + 1;
                    end if;
                end if;
                
               if read_pair = '1' and occupancy >= 2 then
                    r_ptr <= (r_ptr + 2) mod DEPTH;
                    -- If a write happens at the same time as a double-read
                    if new_sample = '1' then
                        occupancy <= occupancy - 1; -- +1 from write, -2 from read
                    else
                        occupancy <= occupancy - 2;
                    end if;
                end if;
            end if;
        end if;
    end process;
end RTL;