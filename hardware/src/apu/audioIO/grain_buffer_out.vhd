library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.audioIO_types.all;

-- mirror of grain_buffer_in. swap only when front fully drained AND back
-- fully written -- unrelated clocks (audio rate vs a-ram burst rate).
-- each row is 16 samples, matching one a-ram row of 8 packed cells.
entity grain_buffer_out is
    Port (
        clk, rst : in std_logic;

        row_addr    : in std_logic_vector(3 downto 0); -- 0..15, one of 16 rows of 16 samples
        row_we      : in std_logic;
        row_data_0  : in std_logic_vector(15 downto 0);
        row_data_1  : in std_logic_vector(15 downto 0);
        row_data_2  : in std_logic_vector(15 downto 0);
        row_data_3  : in std_logic_vector(15 downto 0);
        row_data_4  : in std_logic_vector(15 downto 0);
        row_data_5  : in std_logic_vector(15 downto 0);
        row_data_6  : in std_logic_vector(15 downto 0);
        row_data_7  : in std_logic_vector(15 downto 0);
        row_data_8  : in std_logic_vector(15 downto 0);
        row_data_9  : in std_logic_vector(15 downto 0);
        row_data_10 : in std_logic_vector(15 downto 0);
        row_data_11 : in std_logic_vector(15 downto 0);
        row_data_12 : in std_logic_vector(15 downto 0);
        row_data_13 : in std_logic_vector(15 downto 0);
        row_data_14 : in std_logic_vector(15 downto 0);
        row_data_15 : in std_logic_vector(15 downto 0);

        back_write_done : in std_logic; -- pulse: audio_out_unit finished writing all rows

        read_sample : in  std_logic; -- from the ADAU wrapper: consume the next sample now
        sample_out  : out std_logic_vector(15 downto 0);

        need_grain : out std_logic; -- level: back buffer is empty, needs filling
        fill_ack   : in  std_logic  -- pulse: audio_out_unit has started filling it
    );
end grain_buffer_out;

architecture Behavioral of grain_buffer_out is
    signal front_buf : aio_internal_regs_t := (others => (others => '0'));
    signal back_buf  : aio_internal_regs_t := (others => (others => '0'));

    signal read_count   : integer range 0 to DEPTH := 0;
    signal back_written : std_logic := '0';
    signal row_base     : integer range 0 to DEPTH-1;
begin

    row_base <= to_integer(unsigned(row_addr)) * 16;

    sample_out <= front_buf(read_count) when read_count < DEPTH else front_buf(DEPTH-1);

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '0' then
                read_count   <= 0;
                back_written <= '0';
                need_grain   <= '1'; -- nothing loaded yet: ask for a grain immediately
            else
                if fill_ack = '1' then
                    need_grain <= '0';
                end if;

                if row_we = '1' then
                    back_buf(row_base + 0)  <= row_data_0;
                    back_buf(row_base + 1)  <= row_data_1;
                    back_buf(row_base + 2)  <= row_data_2;
                    back_buf(row_base + 3)  <= row_data_3;
                    back_buf(row_base + 4)  <= row_data_4;
                    back_buf(row_base + 5)  <= row_data_5;
                    back_buf(row_base + 6)  <= row_data_6;
                    back_buf(row_base + 7)  <= row_data_7;
                    back_buf(row_base + 8)  <= row_data_8;
                    back_buf(row_base + 9)  <= row_data_9;
                    back_buf(row_base + 10) <= row_data_10;
                    back_buf(row_base + 11) <= row_data_11;
                    back_buf(row_base + 12) <= row_data_12;
                    back_buf(row_base + 13) <= row_data_13;
                    back_buf(row_base + 14) <= row_data_14;
                    back_buf(row_base + 15) <= row_data_15;
                end if;

                if back_write_done = '1' then
                    back_written <= '1';
                end if;

                if read_sample = '1' and read_count < DEPTH then
                    read_count <= read_count + 1;
                end if;

                if read_count = DEPTH and back_written = '1' then
                    -- swap: back becomes the new front; old front just
                    -- gets overwritten next time audio_out_unit fills back
                    for i in 0 to DEPTH-1 loop
                        front_buf(i) <= back_buf(i);
                    end loop;
                    read_count   <= 0;
                    back_written <= '0';
                    need_grain   <= '1';
                end if;
            end if;
        end if;
    end process;

end Behavioral;
