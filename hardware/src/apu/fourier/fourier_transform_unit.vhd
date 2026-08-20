library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fft_unit is
    generic (
        ARAM_ADDR_SIZE  : integer := 15;
        ARAM_COUNT_SIZE : integer := 18
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        -- Control Interface
        en   : in  std_logic;
        size : in  std_logic; -- 0: 256 samples, 1: 512 samples
        fwd_inv  : in  std_logic; -- 0: forward, 1: inverse
        finished  : out std_logic;

        -- Circular buffers parameters
        bsr  : in  std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
        osr  : in  std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
        blr  : in  std_logic_vector(ARAM_COUNT_SIZE-1 downto 0);
        olr  : in  std_logic_vector(ARAM_COUNT_SIZE-1 downto 0);
        bsw  : in  std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
        osw  : in  std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
        blw  : in  std_logic_vector(ARAM_COUNT_SIZE-1 downto 0);
        olw  : in  std_logic_vector(ARAM_COUNT_SIZE-1 downto 0)
    );
end fft_unit;

architecture Behavioral of fft_unit is

    -- AXI interconnect signals
    signal m_axis_fft_config_tdata  : std_logic_vector(15 downto 0);
    signal m_axis_fft_config_tvalid : std_logic;
    signal m_axis_fft_config_tready : std_logic;
    
    signal s_axis_fft_data_tdata    : std_logic_vector(31 downto 0);
    signal s_axis_fft_data_tvalid   : std_logic;
    signal s_axis_fft_data_tlast    : std_logic;
    signal s_axis_fft_data_tready   : std_logic;

    signal m_axis_fft_data_tdata    : std_logic_vector(31 downto 0);
    signal m_axis_fft_data_tvalid   : std_logic;
    signal m_axis_fft_data_tlast    : std_logic;
    signal m_axis_fft_data_tuser    : std_logic_vector(7 downto 0);
    signal m_axis_fft_data_tready   : std_logic;

    signal s_axis_cordic_fwd_tready : std_logic;
    signal m_axis_cordic_fwd_tdata  : std_logic_vector(31 downto 0);
    signal m_axis_cordic_fwd_tvalid : std_logic;
    signal m_axis_cordic_fwd_tlast  : std_logic;
    signal m_axis_cordic_fwd_tuser  : std_logic_vector(7 downto 0);

    signal s_axis_cordic_inv_tready_cart : std_logic;
    signal s_axis_cordic_inv_tready_phase: std_logic;
    signal m_axis_cordic_inv_tdata       : std_logic_vector(31 downto 0);
    signal m_axis_cordic_inv_tvalid      : std_logic;
    signal m_axis_cordic_inv_tlast       : std_logic;

    -- FSM signals
    type state_type is (IDLE, CONFIG_FFT, PROCESSING, DONE);
    signal state, next_state : state_type;
    signal reg_fwd_inv : std_logic;
    signal reg_size    : std_logic;
    signal xilinx_fft_fwd_inv : std_logic;

begin

    xilinx_fft_fwd_inv <= '1' when reg_fwd_inv = '0' else '0';

    fft_inst : entity work.fft
    port map (
        aclk                 => clk,
        aresetn              => rst,
        s_axis_config_tdata  => m_axis_fft_config_tdata,
        s_axis_config_tvalid => m_axis_fft_config_tvalid,
        s_axis_config_tready => m_axis_fft_config_tready,
        s_axis_data_tdata    => s_axis_fft_data_tdata,
        s_axis_data_tvalid   => s_axis_fft_data_tvalid,
        s_axis_data_tlast    => s_axis_fft_data_tlast,
        s_axis_data_tready   => s_axis_fft_data_tready,
        m_axis_data_tdata    => m_axis_fft_data_tdata,
        m_axis_data_tuser    => m_axis_fft_data_tuser,
        m_axis_data_tvalid   => m_axis_fft_data_tvalid,
        m_axis_data_tlast    => m_axis_fft_data_tlast,
        m_axis_data_tready   => m_axis_fft_data_tready
    );

    cordic_fwd_inst : entity work.cordic_to_polar
    port map (
        aclk                    => clk,
        s_axis_cartesian_tdata  => m_axis_fft_data_tdata,   -- from FFT
        s_axis_cartesian_tvalid => m_axis_fft_data_tvalid,
        s_axis_cartesian_tlast  => m_axis_fft_data_tlast,
        s_axis_cartesian_tuser  => m_axis_fft_data_tuser,   -- FFT exponent
        s_axis_cartesian_tready => s_axis_cordic_fwd_tready,
        m_axis_dout_tdata       => m_axis_cordic_fwd_tdata,
        m_axis_dout_tvalid      => m_axis_cordic_fwd_tvalid,
        m_axis_dout_tlast       => m_axis_cordic_fwd_tlast,
        m_axis_dout_tuser       => m_axis_cordic_fwd_tuser,
        m_axis_dout_tready      => m_axis_aram_tready
    );

    cordic_inv_inst : entity work.cordic_to_cartesian
    port map (
        aclk                    => clk,
        -- Splitting the bundled 32-bit ARAM read [Phase | Magnitude]
        s_axis_phase_tdata      => s_axis_aram_tdata(31 downto 16),
        s_axis_phase_tvalid     => s_axis_aram_tvalid,
        s_axis_phase_tready     => s_axis_cordic_inv_tready_phase,
        s_axis_cartesian_tdata(31 downto 16) => x"0000", -- Y component is 0
        s_axis_cartesian_tdata(15 downto 0)  => s_axis_aram_tdata(15 downto 0), -- X component is Magnitude
        s_axis_cartesian_tvalid => s_axis_aram_tvalid,
        s_axis_cartesian_tlast  => s_axis_aram_tlast,
        s_axis_cartesian_tready => s_axis_cordic_inv_tready_cart,
        m_axis_dout_tdata       => m_axis_cordic_inv_tdata,
        m_axis_dout_tvalid      => m_axis_cordic_inv_tvalid,
        m_axis_dout_tlast       => m_axis_cordic_inv_tlast,
        m_axis_dout_tready      => s_axis_fft_data_tready   -- Backpressure from FFT
    );


    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '0' then
                state <= IDLE;
                reg_fwd_inv <= '0';
                reg_size <= '0';
            else
                state <= next_state;
                if state = IDLE and en = '1' then
                    reg_fwd_inv <= fwd_inv;
                    reg_size    <= size;
                end if;
            end if;
        end if;
    end process;

    process(state, en, m_axis_fft_config_tready, m_axis_cordic_fwd_tlast, m_axis_cordic_fwd_tvalid, m_axis_fft_data_tlast, m_axis_fft_data_tvalid, reg_fwd_inv)
    begin
        next_state <= state;
        finished <= '0';
        m_axis_fft_config_tvalid <= '0';
        m_axis_fft_config_tdata  <= (others => '0');

        case state is
            when IDLE =>
                if en = '1' then
                    next_state <= CONFIG_FFT;
                end if;

            when CONFIG_FFT =>
                m_axis_fft_config_tvalid <= '1';
                if reg_size = '0' then
                    m_axis_fft_config_tdata <= "000" & "01000" & "0000000" & xilinx_fft_fwd_inv;
                else
                    m_axis_fft_config_tdata <= "000" & "01001" & "0000000" & xilinx_fft_fwd_inv;
                end if;

                if m_axis_fft_config_tready = '1' then
                    next_state <= PROCESSING;
                end if;

            when PROCESSING =>
                if reg_fwd_inv = '0' then
                    if m_axis_cordic_fwd_tlast = '1' and m_axis_cordic_fwd_tvalid = '1' and m_axis_aram_tready = '1' then
                        next_state <= DONE;
                    end if;
                else
                    if m_axis_fft_data_tlast = '1' and m_axis_fft_data_tvalid = '1' and m_axis_aram_tready = '1' then
                        next_state <= DONE;
                    end if;
                end if;

            when DONE =>
                finished <= '1';
                if en = '0' then
                    next_state <= IDLE;
                end if;

            when others =>
                next_state <= IDLE;
        end case;
    end process;

    -- Data Path
    process(reg_fwd_inv, s_axis_aram_tdata, s_axis_aram_tvalid, s_axis_aram_tlast, 
            s_axis_fft_data_tready, m_axis_fft_data_tdata, m_axis_fft_data_tvalid, m_axis_fft_data_tlast, m_axis_fft_data_tuser,
            s_axis_cordic_inv_tready_cart, m_axis_cordic_inv_tdata, m_axis_cordic_inv_tvalid, m_axis_cordic_inv_tlast,
            m_axis_cordic_fwd_tdata, m_axis_cordic_fwd_tvalid, m_axis_cordic_fwd_tlast, m_axis_cordic_fwd_tuser)
    begin
        if reg_fwd_inv = '0' then
            -- FORWARD: ARAM -> FFT 
            s_axis_fft_data_tdata  <= s_axis_aram_tdata;
            s_axis_fft_data_tvalid <= s_axis_aram_tvalid;
            s_axis_fft_data_tlast  <= s_axis_aram_tlast;
            s_axis_aram_tready     <= s_axis_fft_data_tready;
            
            -- FORWARD: CORDIC -> ARAM Write
            m_axis_aram_tdata      <= m_axis_cordic_fwd_tdata;
            m_axis_aram_tvalid     <= m_axis_cordic_fwd_tvalid;
            m_axis_aram_tlast      <= m_axis_cordic_fwd_tlast;
            m_axis_aram_tuser      <= m_axis_cordic_fwd_tuser;
            
            -- Tie off unused inverse routing
            m_axis_fft_data_tready <= s_axis_cordic_fwd_tready;

        else
            -- INVERSE: ARAM -> INV CORDIC (Split inputs handled in port map)
            s_axis_aram_tready     <= s_axis_cordic_inv_tready_cart; -- Phase and Cart valids/readies are identical
            
            -- INVERSE: CORDIC -> FFT
            s_axis_fft_data_tdata  <= m_axis_cordic_inv_tdata;
            s_axis_fft_data_tvalid <= m_axis_cordic_inv_tvalid;
            s_axis_fft_data_tlast  <= m_axis_cordic_inv_tlast;
            
            -- INVERSE: FFT -> ARAM Write
            m_axis_aram_tdata      <= m_axis_fft_data_tdata;
            m_axis_aram_tvalid     <= m_axis_fft_data_tvalid;
            m_axis_aram_tlast      <= m_axis_fft_data_tlast;
            m_axis_aram_tuser      <= m_axis_fft_data_tuser;

            -- Tie off unused forward routing
            m_axis_fft_data_tready <= m_axis_aram_tready;
        end if;
    end process;

end Behavioral;
