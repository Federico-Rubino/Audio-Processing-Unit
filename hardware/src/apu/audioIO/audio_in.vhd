library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- ADAU-facing side of audio input: no more AXI/data_mem coupling, just the
-- two per-channel grain buffers between the ADAU wrapper and audio_in_unit.
entity audio_in is
  Port (
    clk : in std_logic;
    rst : in std_logic;

    new_sample : in std_logic;
    line_in_l, line_in_r : in std_logic_vector(15 downto 0);

    -- left channel, towards audio_in_unit
    grain_ready_l : out std_logic;
    grain_ack_l   : in  std_logic;
    row_addr_l    : in  std_logic_vector(4 downto 0);
    row_data_l_0  : out std_logic_vector(15 downto 0);
    row_data_l_1  : out std_logic_vector(15 downto 0);
    row_data_l_2  : out std_logic_vector(15 downto 0);
    row_data_l_3  : out std_logic_vector(15 downto 0);
    row_data_l_4  : out std_logic_vector(15 downto 0);
    row_data_l_5  : out std_logic_vector(15 downto 0);
    row_data_l_6  : out std_logic_vector(15 downto 0);
    row_data_l_7  : out std_logic_vector(15 downto 0);

    -- right channel, towards audio_in_unit
    grain_ready_r : out std_logic;
    grain_ack_r   : in  std_logic;
    row_addr_r    : in  std_logic_vector(4 downto 0);
    row_data_r_0  : out std_logic_vector(15 downto 0);
    row_data_r_1  : out std_logic_vector(15 downto 0);
    row_data_r_2  : out std_logic_vector(15 downto 0);
    row_data_r_3  : out std_logic_vector(15 downto 0);
    row_data_r_4  : out std_logic_vector(15 downto 0);
    row_data_r_5  : out std_logic_vector(15 downto 0);
    row_data_r_6  : out std_logic_vector(15 downto 0);
    row_data_r_7  : out std_logic_vector(15 downto 0)
   );
end audio_in;

architecture Behavioral of audio_in is
begin

    left_channel_buffer_in : entity work.grain_buffer_in
        port map (
            clk => clk,
            rst => rst,
            new_sample => new_sample,
            sample_in  => line_in_l,

            grain_ready => grain_ready_l,
            grain_ack   => grain_ack_l,

            row_addr   => row_addr_l,
            row_data_0 => row_data_l_0, row_data_1 => row_data_l_1,
            row_data_2 => row_data_l_2, row_data_3 => row_data_l_3,
            row_data_4 => row_data_l_4, row_data_5 => row_data_l_5,
            row_data_6 => row_data_l_6, row_data_7 => row_data_l_7
        );

    right_channel_buffer_in : entity work.grain_buffer_in
        port map (
            clk => clk,
            rst => rst,
            new_sample => new_sample,
            sample_in  => line_in_r,

            grain_ready => grain_ready_r,
            grain_ack   => grain_ack_r,

            row_addr   => row_addr_r,
            row_data_0 => row_data_r_0, row_data_1 => row_data_r_1,
            row_data_2 => row_data_r_2, row_data_3 => row_data_r_3,
            row_data_4 => row_data_r_4, row_data_5 => row_data_r_5,
            row_data_6 => row_data_r_6, row_data_7 => row_data_r_7
        );

end Behavioral;
