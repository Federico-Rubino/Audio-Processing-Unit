library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.audioIO_types.all;

-- double buffer, one channel. front fills 1 sample/cycle, swaps to back at
-- 256, back drains via audio_in_unit while front starts the next grain.
entity grain_buffer_in is
    Port (
        clk, rst   : in std_logic;

        new_sample : in std_logic;
        sample_in  : in std_logic_vector(15 downto 0);

        grain_ready : out std_logic; -- level: a full grain is waiting in the back buffer
        grain_ack   : in  std_logic; -- pulse: audio_in_unit has started draining it

        row_addr    : in  std_logic_vector(4 downto 0); -- 0..31, one of 32 rows of 8 samples
        row_data_0  : out std_logic_vector(15 downto 0);
        row_data_1  : out std_logic_vector(15 downto 0);
        row_data_2  : out std_logic_vector(15 downto 0);
        row_data_3  : out std_logic_vector(15 downto 0);
        row_data_4  : out std_logic_vector(15 downto 0);
        row_data_5  : out std_logic_vector(15 downto 0);
        row_data_6  : out std_logic_vector(15 downto 0);
        row_data_7  : out std_logic_vector(15 downto 0)
    );
end grain_buffer_in;

architecture Behavioral of grain_buffer_in is
    signal front_buf : aio_internal_regs_t := (others => (others => '0'));
    signal back_buf  : aio_internal_regs_t := (others => (others => '0'));
    signal write_ptr : integer range 0 to DEPTH-1 := 0;
    signal row_base  : integer range 0 to DEPTH-1;
begin

    row_base <= to_integer(unsigned(row_addr)) * 8;

    row_data_0 <= back_buf(row_base + 0);
    row_data_1 <= back_buf(row_base + 1);
    row_data_2 <= back_buf(row_base + 2);
    row_data_3 <= back_buf(row_base + 3);
    row_data_4 <= back_buf(row_base + 4);
    row_data_5 <= back_buf(row_base + 5);
    row_data_6 <= back_buf(row_base + 6);
    row_data_7 <= back_buf(row_base + 7);

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                write_ptr   <= 0;
                grain_ready <= '0';
            else
                if grain_ack = '1' then
                    grain_ready <= '0';
                end if;

                if new_sample = '1' then
                    front_buf(write_ptr) <= sample_in;

                    if write_ptr = DEPTH-1 then
                        -- grain done: front -> back in one shot, fold in
                        -- this cycle's sample directly (not in front_buf yet)
                        for i in 0 to DEPTH-2 loop
                            back_buf(i) <= front_buf(i);
                        end loop;
                        back_buf(DEPTH-1) <= sample_in;

                        write_ptr   <= 0;
                        grain_ready <= '1';
                    else
                        write_ptr <= write_ptr + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
