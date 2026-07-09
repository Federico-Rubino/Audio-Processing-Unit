library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- ADAU-facing side of audio output: the two per-channel grain buffers
-- between audio_out_unit and the ADAU wrapper.
entity audio_out is
 Port (
    clk          : in  std_logic;
    rst          : in  std_logic;
    new_sample   : in  std_logic; -- from ADAU wrapper: consume the next sample now
    sample_out_l : out std_logic_vector(15 downto 0);
    sample_out_r : out std_logic_vector(15 downto 0);

    -- left channel, towards audio_out_unit
    row_addr_l        : in  std_logic_vector(3 downto 0);
    row_we_l          : in  std_logic;
    row_data_l_0      : in  std_logic_vector(15 downto 0);
    row_data_l_1      : in  std_logic_vector(15 downto 0);
    row_data_l_2      : in  std_logic_vector(15 downto 0);
    row_data_l_3      : in  std_logic_vector(15 downto 0);
    row_data_l_4      : in  std_logic_vector(15 downto 0);
    row_data_l_5      : in  std_logic_vector(15 downto 0);
    row_data_l_6      : in  std_logic_vector(15 downto 0);
    row_data_l_7      : in  std_logic_vector(15 downto 0);
    row_data_l_8      : in  std_logic_vector(15 downto 0);
    row_data_l_9      : in  std_logic_vector(15 downto 0);
    row_data_l_10     : in  std_logic_vector(15 downto 0);
    row_data_l_11     : in  std_logic_vector(15 downto 0);
    row_data_l_12     : in  std_logic_vector(15 downto 0);
    row_data_l_13     : in  std_logic_vector(15 downto 0);
    row_data_l_14     : in  std_logic_vector(15 downto 0);
    row_data_l_15     : in  std_logic_vector(15 downto 0);
    back_write_done_l : in  std_logic;
    need_grain_l      : out std_logic;
    fill_ack_l        : in  std_logic;

    -- right channel, towards audio_out_unit
    row_addr_r        : in  std_logic_vector(3 downto 0);
    row_we_r          : in  std_logic;
    row_data_r_0      : in  std_logic_vector(15 downto 0);
    row_data_r_1      : in  std_logic_vector(15 downto 0);
    row_data_r_2      : in  std_logic_vector(15 downto 0);
    row_data_r_3      : in  std_logic_vector(15 downto 0);
    row_data_r_4      : in  std_logic_vector(15 downto 0);
    row_data_r_5      : in  std_logic_vector(15 downto 0);
    row_data_r_6      : in  std_logic_vector(15 downto 0);
    row_data_r_7      : in  std_logic_vector(15 downto 0);
    row_data_r_8      : in  std_logic_vector(15 downto 0);
    row_data_r_9      : in  std_logic_vector(15 downto 0);
    row_data_r_10     : in  std_logic_vector(15 downto 0);
    row_data_r_11     : in  std_logic_vector(15 downto 0);
    row_data_r_12     : in  std_logic_vector(15 downto 0);
    row_data_r_13     : in  std_logic_vector(15 downto 0);
    row_data_r_14     : in  std_logic_vector(15 downto 0);
    row_data_r_15     : in  std_logic_vector(15 downto 0);
    back_write_done_r : in  std_logic;
    need_grain_r      : out std_logic;
    fill_ack_r        : in  std_logic
 );
end audio_out;

architecture Behavioral of audio_out is
begin

    left_channel_buffer_out : entity work.grain_buffer_out
        port map (
            clk => clk,
            rst => rst,

            row_addr   => row_addr_l,
            row_we     => row_we_l,
            row_data_0 => row_data_l_0, row_data_1 => row_data_l_1,
            row_data_2 => row_data_l_2, row_data_3 => row_data_l_3,
            row_data_4 => row_data_l_4, row_data_5 => row_data_l_5,
            row_data_6 => row_data_l_6, row_data_7 => row_data_l_7,
            row_data_8 => row_data_l_8, row_data_9 => row_data_l_9,
            row_data_10 => row_data_l_10, row_data_11 => row_data_l_11,
            row_data_12 => row_data_l_12, row_data_13 => row_data_l_13,
            row_data_14 => row_data_l_14, row_data_15 => row_data_l_15,

            back_write_done => back_write_done_l,

            read_sample => new_sample,
            sample_out  => sample_out_l,

            need_grain => need_grain_l,
            fill_ack   => fill_ack_l
        );

    right_channel_buffer_out : entity work.grain_buffer_out
        port map (
            clk => clk,
            rst => rst,

            row_addr   => row_addr_r,
            row_we     => row_we_r,
            row_data_0 => row_data_r_0, row_data_1 => row_data_r_1,
            row_data_2 => row_data_r_2, row_data_3 => row_data_r_3,
            row_data_4 => row_data_r_4, row_data_5 => row_data_r_5,
            row_data_6 => row_data_r_6, row_data_7 => row_data_r_7,
            row_data_8 => row_data_r_8, row_data_9 => row_data_r_9,
            row_data_10 => row_data_r_10, row_data_11 => row_data_r_11,
            row_data_12 => row_data_r_12, row_data_13 => row_data_r_13,
            row_data_14 => row_data_r_14, row_data_15 => row_data_r_15,

            back_write_done => back_write_done_r,

            read_sample => new_sample,
            sample_out  => sample_out_r,

            need_grain => need_grain_r,
            fill_ack   => fill_ack_r
        );

end Behavioral;
