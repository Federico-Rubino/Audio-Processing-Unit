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
        select_a : in std_logic_vector(7 downto 0);
        we_b : in std_logic;
        addr_b : in std_logic_vector(9 downto 0);
        select_b : in std_logic_vector(7 downto 0);

        -- ram signals
        ram_en : in std_logic;
        ram_addr : in std_logic_vector(31 downto 0);

        -- mux signals
        mux_index : in std_logic_vector(7 downto 0);
        
        -- write signals
        write_from : in std_logic_vector(1 downto 0);

        -- audio out signals
        audio_out_enable : in std_logic;
        audio_out_lr : in std_logic;

        -- outputs
        audio_out : out std_logic_vector(31 downto 0);
        lr_out, enable_out : out std_logic;

        -- RAM interface
        ram_en_out : out std_logic;
        ram_addr_out : out std_logic_vector(31 downto 0);
        ram_out : in std_logic_vector(31 downto 0)
    );
end AudioDataPath;

architecture Behavioral of AudioDataPath is
    -----------------------------------------------------------------------------------------
    -- REGISTERS
    -----------------------------------------------------------------------------------------

    -- Audio Out Multiplexer
    signal mux_index_1 : std_logic_vector(7 downto 0);
    signal next_mux_index_1 : std_logic_vector(7 downto 0);

    -- Audio Out
    signal audio_out_enable_2 : std_logic;
    signal next_audio_out_enable_2 : std_logic;
    signal audio_out_enable_1 : std_logic;
    signal next_audio_out_enable_1 : std_logic;
    signal audio_out_lr_2 : std_logic;
    signal next_audio_out_lr_2 : std_logic;
    signal audio_out_lr_1 : std_logic;
    signal next_audio_out_lr_1 : std_logic;

    -- Write
    signal write_from_2 : std_logic_vector(1 downto 0);
    signal next_write_from_2 : std_logic_vector(1 downto 0);
    signal write_from_1 : std_logic_vector(1 downto 0);
    signal next_write_from_1 : std_logic_vector(1 downto 0);
    signal we_a_2 : std_logic;
    signal next_we_a_2 : std_logic;
    signal we_a_1 : std_logic;
    signal next_we_a_1 : std_logic;
    signal we_b_2 : std_logic;
    signal next_we_b_2 : std_logic;
    signal we_b_1 : std_logic;
    signal next_we_b_1 : std_logic;
    signal addr_a_2 : std_logic_vector (9 downto 0);
    signal next_addr_a_2 : std_logic_vector (9 downto 0);
    signal addr_a_1 : std_logic_vector (9 downto 0);
    signal next_addr_a_1 : std_logic_vector (9 downto 0);
    signal addr_b_2 : std_logic_vector (9 downto 0);
    signal next_addr_b_2 : std_logic_vector (9 downto 0);
    signal addr_b_1 : std_logic_vector (9 downto 0);
    signal next_addr_b_1 : std_logic_vector (9 downto 0);
    signal sel_a_2 : std_logic_vector (7 downto 0);
    signal next_sel_a_2 : std_logic_vector (7 downto 0);
    signal sel_a_1 : std_logic_vector (7 downto 0);
    signal next_sel_a_1 : std_logic_vector (7 downto 0);
    signal sel_b_2 : std_logic_vector (7 downto 0);
    signal next_sel_b_2 : std_logic_vector (7 downto 0);
    signal sel_b_1 : std_logic_vector (7 downto 0);
    signal next_sel_b_1 : std_logic_vector (7 downto 0);
    signal in_a_2 : logic_aoa(109 downto 0)(31 downto 0);
    -- signal next_in_a_2 : std_logic_vector (31 downto 0);  -- It is not a register anymore, but asynchronous signal
    signal in_b_2 : logic_aoa(109 downto 0)(31 downto 0);
    -- signal next_in_b_2 : std_logic_vector (31 downto 0);  -- It is not a register anymore, but asynchronous signal
    signal out_a_1 : logic_aoa(109 downto 0)(31 downto 0);
    -- signal next_out_a_1 : logic_aoa(109 downto 0)(31 downto 0);
    signal out_b_1 : logic_aoa(109 downto 0)(31 downto 0);
    -- signal next_out_b_1 : logic_aoa(109 downto 0)(31 downto 0);

    -- Audio Out Mux Outputs
    signal sample1_2 : std_logic_vector(15 downto 0);
    signal sample2_2 : std_logic_vector(15 downto 0);
    signal next_sample1_2 : std_logic_vector(15 downto 0);
    signal next_sample2_2 : std_logic_vector(15 downto 0);

    -- RAM Interface Outputs
    signal data1_1 : std_logic_vector(15 downto 0);
    -- signal next_data1_1 : std_logic_vector(15 downto 0);
    signal data2_1 : std_logic_vector(15 downto 0);
    -- signal next_data2_1 : std_logic_vector(15 downto 0);

    -- Data In Outputs
    signal new_data_2 : std_logic_vector(31 downto 0);
    signal next_new_data_2 : std_logic_vector(31 downto 0);

    -----------------------------------------------------------------------------------------
    -- AUDIO MEMORY SIGNALS
    -----------------------------------------------------------------------------------------
    signal mem_we_a, mem_we_b : std_logic;
    signal mem_addr_a, mem_addr_b : std_logic_vector(9 downto 0);
    signal mem_sel_a, mem_sel_b : std_logic_vector(7 downto 0);
    signal mem_in_a, mem_in_b : logic_aoa(109 downto 0)(31 downto 0);
    signal mem_out_a, mem_out_b : logic_aoa(109 downto 0)(31 downto 0);

    -----------------------------------------------------------------------------------------
    -- OTHER SIGNALS
    -----------------------------------------------------------------------------------------
    signal data_in_a : logic_aoa(109 downto 0)(31 downto 0);
    signal data_in_b : logic_aoa(109 downto 0)(31 downto 0);

begin

    -- BRAM memory
    MEMORY : entity work.AudioMemory
        port map (
            clk => clk,
            rst => rst,
            we_a => mem_we_a,
            addr_a => mem_addr_a,
            select_a => mem_sel_a,
            data_in_a => mem_in_a,
            data_out_a => mem_out_a,
            we_b => mem_we_b,
            addr_b => mem_addr_b,
            select_b => mem_sel_b,
            data_in_b => mem_in_b,
            data_out_b => mem_out_b
        );
    
    -- stage 1 entities: RAM Inferface, Memory Read

    -- stage 2 entities
    MUX : entity work.MemorySamplesMux
        port map(
            samples => out_a_1,
            index => mux_index_1,
            sample1 => next_sample1_2,
            sample2 => next_sample2_2
        );

    DATA_INPUT : entity work.DataIn
        port map(
            data1 => data1_1,
            data2 => data2_1,
            new_data_in => next_new_data_2
        );

    -- stage 3 entities
    AUDIO_OUTPUT : entity work.AudioOut
        port map (
            clk => clk,
            enable => audio_out_enable_2,
            sample1 => sample1_2,
            sample2 => sample2_2,
            lr => audio_out_lr_2,
            audio_out => audio_out,
            lr_out => lr_out,
            enable_out => enable_out
        );

    process(clk, rst)
    begin
        if rst = '0' then
            
        elsif rising_edge(clk) and enable = '1' then
            mux_index_1 <= next_mux_index_1;
            audio_out_enable_2 <= next_audio_out_enable_2;
            audio_out_enable_1 <= next_audio_out_enable_1;
            audio_out_lr_2 <= next_audio_out_lr_2;
            audio_out_lr_1 <= next_audio_out_lr_1;
            write_from_2 <= next_write_from_2;
            write_from_1 <= next_write_from_1;
            we_a_2 <= next_we_a_2;
            we_a_1 <= next_we_a_1;
            we_b_2 <= next_we_b_2;
            we_b_1 <= next_we_b_1;
            addr_a_2 <= next_addr_a_2;
            addr_a_1 <= next_addr_a_1;
            addr_b_2 <= next_addr_b_2;
            addr_b_1 <= next_addr_b_1;
            sel_a_2 <= next_sel_a_2;
            sel_a_1 <= next_sel_a_1;
            sel_b_2 <= next_sel_b_2;
            sel_b_1 <= next_sel_b_1;
            -- in_a_2 <= next_in_a_2;  -- 'in_a_2' is not a register, it comes from an asynchronous mux
            -- in_b_2 <= next_in_b_2;  -- 'in_b_2' is not a register, it comes from an asynchronous mux
            -- out_a_1 <= next_out_a_1;
            -- out_b_1 <= next_out_b_1;
            sample1_2 <= next_sample1_2;
            sample2_2 <= next_sample2_2;
            new_data_2 <= next_new_data_2;
            -- data1_1 <= next_data1_1;  -- not a register
            -- data2_1 <= next_data2_1;  -- not a register
            data_in_a <= (others => (others => '0'));
            data_in_b <= (others => (others => '0'));
        end if;
    end process;

    process(
        mode, 
        we_a, addr_a, select_a, data_in_a, mem_out_a,
        we_b, addr_b, select_b, data_in_b, mem_out_b,
        we_b_2, addr_b_2, sel_b_2, in_b_2,
        we_a_2, addr_a_2, sel_a_2,
        mux_index, audio_out_enable_1, audio_out_enable, 
        audio_out_lr_1, audio_out_lr, write_from_1, write_from,
        new_data_2, ram_en, ram_addr, ram_out
    )
    begin
        -- Configure Memory Connections
        case mode is
            -- Double Read Mode
            when "00" =>
                mem_we_a <= we_a;
                mem_addr_a <= addr_a;
                mem_sel_a <= select_a;
                mem_in_a <= data_in_a;
                out_a_1 <= mem_out_a;
                mem_we_b <= we_b;
                mem_addr_b <= addr_b;
                mem_sel_b <= select_b;
                mem_in_b <= data_in_b;
                out_b_1 <= mem_out_b;

            -- Mixed Read/Write Mode
            when "01" =>
                mem_we_a <= we_a;
                mem_addr_a <= addr_a;
                mem_sel_a <= select_a;
                mem_in_a <= data_in_a;
                out_a_1 <= mem_out_a;
                mem_we_b <= we_b_2;
                mem_addr_b <= addr_b_2;
                mem_sel_b <= sel_b_2;
                mem_in_b <= in_b_2;

            -- Double Write Mode
            when "11" =>
                mem_we_a <= we_a_2;
                mem_addr_a <= addr_a_2;
                mem_sel_a <= sel_a_2;
                mem_in_a <= in_a_2;
                mem_we_b <= we_b_2;
                mem_addr_b <= addr_b_2;
                mem_sel_b <= sel_b_2;
                mem_in_b <= in_b_2;

            when others =>
        end case;

        -- Next Register Values
        next_mux_index_1 <= mux_index;
        next_audio_out_enable_2 <= audio_out_enable_1;
        next_audio_out_enable_1 <= audio_out_enable;
        next_audio_out_lr_2 <= audio_out_lr_1;
        next_audio_out_lr_1 <= audio_out_lr;
        next_write_from_2 <= write_from_1;
        next_write_from_1 <= write_from;
        next_we_a_1 <= we_a;
        next_we_a_2 <= we_a_1;
        next_we_b_1 <= we_b;
        next_we_b_2 <= we_b_1;
        next_addr_a_1 <= addr_a;
        next_addr_a_2 <= addr_a_1;
        next_addr_b_1 <= addr_b;
        next_addr_b_2 <= addr_b_1;
        next_sel_a_1 <= select_a;
        next_sel_a_2 <= sel_a_1;
        next_sel_b_1 <= select_b;
        next_sel_b_2 <= sel_b_1;

        -- Write Back
        case write_from is
            when "00" =>    -- From Data In
                for i in in_a_2'range loop
                    in_a_2(i) <= new_data_2;
                    in_b_2(i) <= new_data_2;
                end loop; 
            when others =>  -- TODO
        end case;

        -- RAM Inferface
        ram_en_out <= ram_en;
        ram_addr_out <= ram_addr;
        data1_1 <= ram_out(15 downto 0);
        data2_1 <= ram_out(31 downto 16);

    end process;

end Behavioral;
