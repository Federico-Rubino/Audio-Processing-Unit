library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.apu_internal_pkg.all;

entity AudioDataPath is
    Port (
        clk, rst, enable : in std_logic;
        mode : in std_logic_vector(1 downto 0);    -- do not change this value while an operation is running, it will change the pipeline structure

        -- memory signals
        we_a : in std_logic;
        addr_a : in std_logic_vector(9 downto 0);
        data_in_a : in std_logic_vector(31 downto 0);
        we_b : in std_logic;
        addr_b : in std_logic_vector(9 downto 0);
        data_in_b : in std_logic_vector(31 downto 0);

        -- mux signals
        mux_index : in std_logic_vector(6 downto 0);
        mux_enable : in std_logic;

        -- audio out signals
        audio_out_enable : in std_logic;
        audio_out_lr : in std_logic;

        -- outputs
        audio_out : out std_logic_vector(31 downto 0);
        lr_out : out std_logic
    );
end AudioDataPath;

architecture Behavioral of AudioDataPath is

    -- config signal
    signal config_enum : datapath_config; 

    -- BRAM signals
    signal we_a_signal : std_logic;
    signal addr_a_signal : std_logic_vector(9 downto 0);
    signal data_in_a_signal : std_logic_vector(31 downto 0);
    signal data_out_a_signal : logic_aoa(7 downto 0)(31 downto 0);
    signal we_b_signal : std_logic;
    signal addr_b_signal : std_logic_vector(9 downto 0);
    signal data_in_b_signal : std_logic_vector(31 downto 0);
    signal data_out_b_signal : logic_aoa(7 downto 0)(31 downto 0);

    -- stage 1 registers
    signal mux_index_1 : std_logic_vector(6 downto 0);
    signal audio_out_enable_1 : std_logic;
    signal audio_out_lr_1 : std_logic;
    signal mux_enable_1 : std_logic;
    signal we_a_1 : std_logic;
    signal addr_a_1 : std_logic_vector(9 downto 0);
    signal data_in_a_1 : std_logic_vector(31 downto 0);
    signal we_b_1 : std_logic;
    signal addr_b_1 : std_logic_vector(9 downto 0);
    signal data_in_b_1 : std_logic_vector(31 downto 0);
    signal data_out_a_1 : logic_aoa(7 downto 0)(31 downto 0);
    signal data_out_b_1 : logic_aoa(7 downto 0)(31 downto 0);

    -- stage 2 registers
    signal audio_out_enable_2 : std_logic;
    signal audio_out_lr_2 : std_logic;
    signal audio_out_sample1_2 : std_logic_vector(15 downto 0);
    signal audio_out_sample2_2 : std_logic_vector(15 downto 0);
    signal we_a_2 : std_logic;
    signal addr_a_2 : std_logic_vector(9 downto 0);
    signal data_in_a_2 : std_logic_vector(31 downto 0);
    signal we_b_2 : std_logic;
    signal addr_b_2 : std_logic_vector(9 downto 0);
    signal data_in_b_2 : std_logic_vector(31 downto 0);
    signal data_out_a_2 : logic_aoa(7 downto 0)(31 downto 0);
    signal data_out_b_2 : logic_aoa(7 downto 0)(31 downto 0);

    -- pipeline end registers
    signal data_out_a_3 : logic_aoa(7 downto 0)(31 downto 0);
    signal data_out_b_3 : logic_aoa(7 downto 0)(31 downto 0);

begin

    -- BRAM memory
    MEMORY : entity work.AudioMemory
        port map (
            clk => clk,
            rst => rst,
            we_a => we_a_signal,
            addr_a => addr_a_signal,
            data_in_a => data_in_a_signal,
            data_out_a => data_out_a_signal,
            we_b => we_b_signal,
            addr_b => addr_b_signal,
            data_in_b => data_in_b_signal,
            data_out_b => data_out_b_signal
        );
    
    -- stage 1 entities

    -- stage 2 entities
    MUX : entity work.MemorySamplesMux
        port map(
            clk => clk,
            enable => mux_enable_1,
            samples => data_out_a_1,
            index => mux_index_1,
            sample1 => audio_out_sample1_2,
            sample2 => audio_out_sample2_2
        );

    -- stage 3 entities
    AUDIO_OUTPUT : entity work.AudioOut
        port map (
            clk => clk,
            enable => audio_out_enable_2,
            sample1 => audio_out_sample1_2,
            sample2 => audio_out_sample2_2,
            lr => audio_out_lr_2,
            audio_out => audio_out,
            lr_out => lr_out
        );


    process(clk, rst)
    begin
        if rst = '0' then
            
        elsif rising_edge(clk) then
            -- routing port signals
            
            config_enum <= datapath_config'val(to_integer(unsigned(mode)));
            case config_enum is
                -- both ports reading in stage 0
                when double_read =>

                -- port A reading in stage 0, port B writing in stage 2
                when mixed =>
                    we_a_signal <= we_a;
                    addr_a_signal <= addr_a;
                    data_in_a_signal <= data_in_a;
                    data_out_a_signal <= data_out_a_1;
                    we_b_signal <= we_b_2;
                    addr_b_signal <= addr_b_2;
                    data_in_b_signal <= data_in_b_2;
                    data_out_b_signal <= data_out_b_3;

                -- both ports writing in stage 2
                when double_write =>

            end case;

            -- signals passing to stage 2
            audio_out_enable_2 <= audio_out_enable_1;
            audio_out_lr_2 <= audio_out_lr_1;
            we_a_2 <= we_a_1;
            addr_a_2 <= addr_a_1;
            data_in_a_2 <= data_in_a_1;
            data_out_a_2 <= data_out_a_1;
            we_b_2 <= we_b_1;
            addr_b_2 <= addr_b_1;
            data_in_b_2 <= data_in_b_1;
            data_out_b_2 <= data_out_b_1;

            -- signals passing to stage 1
            mux_index_1 <= mux_index;
            mux_enable_1 <= mux_enable;
            audio_out_enable_1 <= audio_out_enable;
            audio_out_lr_1 <= audio_out_lr;
            we_a_1 <= we_a;
            addr_a_1 <= addr_a;
            data_in_a_1 <= data_in_a;
            we_b_1 <= we_b;
            addr_b_1 <= addr_b;
            data_in_b_1 <= data_in_b;
        end if;
    end process;

end Behavioral;
