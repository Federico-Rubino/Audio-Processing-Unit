library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- on enable: drains 256-sample grain (left_right = channel) from
-- grain_buffer_in to a-ram via bmu_write, parallel8. pulses finished.
entity audio_in_unit is
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

        -- grain_buffer_in (left)
        row_addr_l   : out std_logic_vector(4 downto 0);
        row_data_l_0 : in  std_logic_vector(15 downto 0);
        row_data_l_1 : in  std_logic_vector(15 downto 0);
        row_data_l_2 : in  std_logic_vector(15 downto 0);
        row_data_l_3 : in  std_logic_vector(15 downto 0);
        row_data_l_4 : in  std_logic_vector(15 downto 0);
        row_data_l_5 : in  std_logic_vector(15 downto 0);
        row_data_l_6 : in  std_logic_vector(15 downto 0);
        row_data_l_7 : in  std_logic_vector(15 downto 0);
        grain_ack_l  : out std_logic;

        -- grain_buffer_in (right)
        row_addr_r   : out std_logic_vector(4 downto 0);
        row_data_r_0 : in  std_logic_vector(15 downto 0);
        row_data_r_1 : in  std_logic_vector(15 downto 0);
        row_data_r_2 : in  std_logic_vector(15 downto 0);
        row_data_r_3 : in  std_logic_vector(15 downto 0);
        row_data_r_4 : in  std_logic_vector(15 downto 0);
        row_data_r_5 : in  std_logic_vector(15 downto 0);
        row_data_r_6 : in  std_logic_vector(15 downto 0);
        row_data_r_7 : in  std_logic_vector(15 downto 0);
        grain_ack_r  : out std_logic;

        -- a-ram side (bmu_write's full flat interface)
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
end audio_in_unit;

architecture Behavioral of audio_in_unit is

    constant GRAIN_SAMPLES : integer := 256; -- fixed by audioIO_types.DEPTH

    type state_t is (IDLE, START, RUN, FLUSH);
    signal state : state_t := IDLE;

    signal row_cnt : unsigned(4 downto 0) := (others => '0');

    -- 1-cycle delay: bmu_write addr/we land 1 cycle after count_en,
    -- grain_buffer_in read is immediate. FLUSH = extra cycle for row 31.
    signal row_addr_d : unsigned(4 downto 0) := (others => '0');

    signal bw_start, bw_count_en, bw_done : std_logic;
    signal data_in_0, data_in_1, data_in_2, data_in_3 : std_logic_vector(31 downto 0);
    signal data_in_4, data_in_5, data_in_6, data_in_7 : std_logic_vector(31 downto 0);

begin

    bw : entity work.bmu_write
        generic map (
            BUFFER_ADDR_WIDTH => BUFFER_ADDR_WIDTH,
            BUFFER_SIZE_BITS  => BUFFER_SIZE_BITS,
            LANES             => 8
        )
        port map (
            clk => clk, rst => rst, start => bw_start, count_en => bw_count_en,

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

            data_in_0 => data_in_0, data_in_1 => data_in_1,
            data_in_2 => data_in_2, data_in_3 => data_in_3,
            data_in_4 => data_in_4, data_in_5 => data_in_5,
            data_in_6 => data_in_6, data_in_7 => data_in_7,

            done => bw_done
        );

    -- pick the enabled channel, sign-extend 16-bit PCM to 32-bit a-ram words
    data_in_0 <= std_logic_vector(resize(signed(row_data_l_0), 32)) when left_right = '0' else std_logic_vector(resize(signed(row_data_r_0), 32));
    data_in_1 <= std_logic_vector(resize(signed(row_data_l_1), 32)) when left_right = '0' else std_logic_vector(resize(signed(row_data_r_1), 32));
    data_in_2 <= std_logic_vector(resize(signed(row_data_l_2), 32)) when left_right = '0' else std_logic_vector(resize(signed(row_data_r_2), 32));
    data_in_3 <= std_logic_vector(resize(signed(row_data_l_3), 32)) when left_right = '0' else std_logic_vector(resize(signed(row_data_r_3), 32));
    data_in_4 <= std_logic_vector(resize(signed(row_data_l_4), 32)) when left_right = '0' else std_logic_vector(resize(signed(row_data_r_4), 32));
    data_in_5 <= std_logic_vector(resize(signed(row_data_l_5), 32)) when left_right = '0' else std_logic_vector(resize(signed(row_data_r_5), 32));
    data_in_6 <= std_logic_vector(resize(signed(row_data_l_6), 32)) when left_right = '0' else std_logic_vector(resize(signed(row_data_r_6), 32));
    data_in_7 <= std_logic_vector(resize(signed(row_data_l_7), 32)) when left_right = '0' else std_logic_vector(resize(signed(row_data_r_7), 32));

    row_addr_l <= std_logic_vector(row_addr_d);
    row_addr_r <= std_logic_vector(row_addr_d);

    bw_start    <= '1' when state = START else '0';
    bw_count_en <= '1' when state = RUN   else '0';

    process(clk)
    begin
        if rising_edge(clk) then
            finished    <= '0';
            grain_ack_l <= '0';
            grain_ack_r <= '0';

            -- 1 cycle behind row_cnt
            row_addr_d <= row_cnt;

            if rst = '1' then
                state   <= IDLE;
                row_cnt <= (others => '0');
            else
                case state is
                    when IDLE =>
                        if enable = '1' then
                            row_cnt <= (others => '0');
                            if left_right = '0' then
                                grain_ack_l <= '1';
                            else
                                grain_ack_r <= '1';
                            end if;
                            state <= START;
                        end if;

                    when START =>
                        state <= RUN;

                    when RUN =>
                        -- 32 pulses, rows 0..31, then FLUSH lets row 31 land
                        if row_cnt = 31 then
                            state <= FLUSH;
                        else
                            row_cnt <= row_cnt + 1;
                        end if;

                    when FLUSH =>
                        -- row_addr_d is still 31 here, so row 31's write lands
                        finished <= '1';
                        state    <= IDLE;
                end case;
            end if;
        end if;
    end process;

end Behavioral;
