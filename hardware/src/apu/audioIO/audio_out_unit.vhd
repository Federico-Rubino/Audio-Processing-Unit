library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- on enable: fills 256-sample grain (left_right = channel) from a-ram
-- via bmu_read, parallel8, into grain_buffer_out. pulses finished.
entity audio_out_unit is
    generic (
        BUFFER_ADDR_WIDTH : integer := 10;
        BUFFER_SIZE_BITS  : integer := 18
    );
    Port (
        clk, rst : in std_logic;

        -- CU control
        enable           : in  std_logic;
        left_right       : in  std_logic; -- 0: left, 1: right
        buffer_start     : in  std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        buffer_length    : in  std_logic_vector(BUFFER_SIZE_BITS-1 downto 0);
        operation_start  : in  std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        finished         : out std_logic;

        -- grain_buffer_out (left)
        row_addr_l   : out std_logic_vector(4 downto 0);
        row_we_l     : out std_logic;
        row_data_l_0 : out std_logic_vector(15 downto 0);
        row_data_l_1 : out std_logic_vector(15 downto 0);
        row_data_l_2 : out std_logic_vector(15 downto 0);
        row_data_l_3 : out std_logic_vector(15 downto 0);
        row_data_l_4 : out std_logic_vector(15 downto 0);
        row_data_l_5 : out std_logic_vector(15 downto 0);
        row_data_l_6 : out std_logic_vector(15 downto 0);
        row_data_l_7 : out std_logic_vector(15 downto 0);
        back_write_done_l : out std_logic;
        fill_ack_l   : out std_logic;

        -- grain_buffer_out (right)
        row_addr_r   : out std_logic_vector(4 downto 0);
        row_we_r     : out std_logic;
        row_data_r_0 : out std_logic_vector(15 downto 0);
        row_data_r_1 : out std_logic_vector(15 downto 0);
        row_data_r_2 : out std_logic_vector(15 downto 0);
        row_data_r_3 : out std_logic_vector(15 downto 0);
        row_data_r_4 : out std_logic_vector(15 downto 0);
        row_data_r_5 : out std_logic_vector(15 downto 0);
        row_data_r_6 : out std_logic_vector(15 downto 0);
        row_data_r_7 : out std_logic_vector(15 downto 0);
        back_write_done_r : out std_logic;
        fill_ack_r   : out std_logic;

        -- mem a-ram
        bram0_port0_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        bram1_port0_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        bram2_port0_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        bram3_port0_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);

        bram0_port1_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        bram1_port1_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        bram2_port1_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        bram3_port1_addr : out std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);

        bram0_port0_we : out std_logic;
        bram1_port0_we : out std_logic;
        bram2_port0_we : out std_logic;
        bram3_port0_we : out std_logic;

        bram0_port1_we : out std_logic;
        bram1_port1_we : out std_logic;
        bram2_port1_we : out std_logic;
        bram3_port1_we : out std_logic;

        bram0_port0_en : out std_logic;
        bram1_port0_en : out std_logic;
        bram2_port0_en : out std_logic;
        bram3_port0_en : out std_logic;

        bram0_port1_en : out std_logic;
        bram1_port1_en : out std_logic;
        bram2_port1_en : out std_logic;
        bram3_port1_en : out std_logic;

        bram0_port0_data_in : out std_logic_vector(31 downto 0);
        bram1_port0_data_in : out std_logic_vector(31 downto 0);
        bram2_port0_data_in : out std_logic_vector(31 downto 0);
        bram3_port0_data_in : out std_logic_vector(31 downto 0);

        bram0_port1_data_in : out std_logic_vector(31 downto 0);
        bram1_port1_data_in : out std_logic_vector(31 downto 0);
        bram2_port1_data_in : out std_logic_vector(31 downto 0);
        bram3_port1_data_in : out std_logic_vector(31 downto 0);

        bram0_port0_data_out : in std_logic_vector(31 downto 0);
        bram1_port0_data_out : in std_logic_vector(31 downto 0);
        bram2_port0_data_out : in std_logic_vector(31 downto 0);
        bram3_port0_data_out : in std_logic_vector(31 downto 0);

        bram0_port1_data_out : in std_logic_vector(31 downto 0);
        bram1_port1_data_out : in std_logic_vector(31 downto 0);
        bram2_port1_data_out : in std_logic_vector(31 downto 0);
        bram3_port1_data_out : in std_logic_vector(31 downto 0)
    );
end audio_out_unit;

architecture Behavioral of audio_out_unit is

    constant GRAIN_SAMPLES : integer := 256;

    type state_t is (IDLE, START, RUN, FLUSH1, FLUSH2);
    signal state : state_t := IDLE;

    signal row_cnt : unsigned(4 downto 0) := (others => '0');

    -- 2-cycle delay: addr_gen registers addr (+1), a-ram registers read
    -- (+1). FLUSH1/FLUSH2 drain rows 30/31.
    signal row_addr_d1, row_addr_d2 : unsigned(4 downto 0) := (others => '0');
    signal row_we_d1, row_we_d2      : std_logic := '0';

    signal br_start, br_count_en, br_done : std_logic;
    signal data_out_0, data_out_1, data_out_2, data_out_3 : std_logic_vector(31 downto 0);
    signal data_out_4, data_out_5, data_out_6, data_out_7 : std_logic_vector(31 downto 0);

begin

    br : entity work.bmu_read
        generic map (
            BUFFER_ADDR_WIDTH => BUFFER_ADDR_WIDTH,
            BUFFER_SIZE_BITS  => BUFFER_SIZE_BITS,
            LANES             => 8
        )
        port map (
            clk => clk, rst => rst, start => br_start, count_en => br_count_en,

            buffer_start     => buffer_start,
            buffer_length    => buffer_length,
            operation_start  => operation_start,
            operation_length => std_logic_vector(to_unsigned(GRAIN_SAMPLES, BUFFER_SIZE_BITS)),

            bram0_port0_addr => bram0_port0_addr, bram1_port0_addr => bram1_port0_addr,
            bram2_port0_addr => bram2_port0_addr, bram3_port0_addr => bram3_port0_addr,
            bram0_port1_addr => bram0_port1_addr, bram1_port1_addr => bram1_port1_addr,
            bram2_port1_addr => bram2_port1_addr, bram3_port1_addr => bram3_port1_addr,

            bram0_port0_we => bram0_port0_we, bram1_port0_we => bram1_port0_we,
            bram2_port0_we => bram2_port0_we, bram3_port0_we => bram3_port0_we,
            bram0_port1_we => bram0_port1_we, bram1_port1_we => bram1_port1_we,
            bram2_port1_we => bram2_port1_we, bram3_port1_we => bram3_port1_we,

            bram0_port0_en => bram0_port0_en, bram1_port0_en => bram1_port0_en,
            bram2_port0_en => bram2_port0_en, bram3_port0_en => bram3_port0_en,
            bram0_port1_en => bram0_port1_en, bram1_port1_en => bram1_port1_en,
            bram2_port1_en => bram2_port1_en, bram3_port1_en => bram3_port1_en,

            bram0_port0_data_in => bram0_port0_data_in, bram1_port0_data_in => bram1_port0_data_in,
            bram2_port0_data_in => bram2_port0_data_in, bram3_port0_data_in => bram3_port0_data_in,
            bram0_port1_data_in => bram0_port1_data_in, bram1_port1_data_in => bram1_port1_data_in,
            bram2_port1_data_in => bram2_port1_data_in, bram3_port1_data_in => bram3_port1_data_in,

            bram0_port0_data_out => bram0_port0_data_out, bram1_port0_data_out => bram1_port0_data_out,
            bram2_port0_data_out => bram2_port0_data_out, bram3_port0_data_out => bram3_port0_data_out,
            bram0_port1_data_out => bram0_port1_data_out, bram1_port1_data_out => bram1_port1_data_out,
            bram2_port1_data_out => bram2_port1_data_out, bram3_port1_data_out => bram3_port1_data_out,

            data_out_0 => data_out_0, data_out_1 => data_out_1,
            data_out_2 => data_out_2, data_out_3 => data_out_3,
            data_out_4 => data_out_4, data_out_5 => data_out_5,
            data_out_6 => data_out_6, data_out_7 => data_out_7,

            done => br_done
        );

    -- a-ram word -> 16-bit PCM, low bits back (undoes audio_in_unit's sign-extend)
    row_data_l_0 <= data_out_0(15 downto 0); row_data_r_0 <= data_out_0(15 downto 0);
    row_data_l_1 <= data_out_1(15 downto 0); row_data_r_1 <= data_out_1(15 downto 0);
    row_data_l_2 <= data_out_2(15 downto 0); row_data_r_2 <= data_out_2(15 downto 0);
    row_data_l_3 <= data_out_3(15 downto 0); row_data_r_3 <= data_out_3(15 downto 0);
    row_data_l_4 <= data_out_4(15 downto 0); row_data_r_4 <= data_out_4(15 downto 0);
    row_data_l_5 <= data_out_5(15 downto 0); row_data_r_5 <= data_out_5(15 downto 0);
    row_data_l_6 <= data_out_6(15 downto 0); row_data_r_6 <= data_out_6(15 downto 0);
    row_data_l_7 <= data_out_7(15 downto 0); row_data_r_7 <= data_out_7(15 downto 0);

    -- only the selected channel actually latches, so gating we is enough
    row_we_l <= row_we_d2 when left_right = '0' else '0';
    row_we_r <= row_we_d2 when left_right = '1' else '0';

    row_addr_l <= std_logic_vector(row_addr_d2);
    row_addr_r <= std_logic_vector(row_addr_d2);

    back_write_done_l <= '1' when (state = FLUSH2 and left_right = '0') else '0';
    back_write_done_r <= '1' when (state = FLUSH2 and left_right = '1') else '0';

    br_start    <= '1' when state = START else '0';
    br_count_en <= '1' when state = RUN   else '0';

    process(clk)
    begin
        if rising_edge(clk) then
            finished    <= '0';
            fill_ack_l  <= '0';
            fill_ack_r  <= '0';

            -- two cascaded 1-cycle delays, matching addr_gen + a-ram latency
            row_addr_d1 <= row_cnt;
            row_addr_d2 <= row_addr_d1;
            row_we_d1   <= br_count_en;
            row_we_d2   <= row_we_d1;

            if rst = '1' then
                state   <= IDLE;
                row_cnt <= (others => '0');
            else
                case state is
                    when IDLE =>
                        if enable = '1' then
                            row_cnt <= (others => '0');
                            if left_right = '0' then
                                fill_ack_l <= '1';
                            else
                                fill_ack_r <= '1';
                            end if;
                            state <= START;
                        end if;

                    when START =>
                        state <= RUN;

                    when RUN =>
                        -- 32 pulses, rows 0..31, then FLUSH1/2 drain rows 30/31
                        if row_cnt = 31 then
                            state <= FLUSH1;
                        else
                            row_cnt <= row_cnt + 1;
                        end if;

                    when FLUSH1 =>
                        -- row 30 lands here
                        state <= FLUSH2;

                    when FLUSH2 =>
                        -- row 31 (the last one) lands here
                        finished <= '1';
                        state    <= IDLE;
                end case;
            end if;
        end if;
    end process;

end Behavioral;
