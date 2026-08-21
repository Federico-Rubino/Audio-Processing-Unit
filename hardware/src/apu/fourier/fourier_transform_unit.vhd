library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fft_unit is
    generic (
        ARAM_ADDR_SIZE    : integer := 15
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        -- Control Interface
        en       : in  std_logic;
        size     : in  std_logic; -- 0: 256 samples, 1: 512 samples
        fwd_inv  : in  std_logic; -- 0: forward, 1: inverse
        finished : out std_logic;

        -- Circular buffer parameters
        bsr : in std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
        osr : in std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
        blr : in std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
        olr : in std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
        bsw : in std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
        osw : in std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
        blw : in std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
        olw : in std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);

        bram0_port0_addr : out std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
        bram1_port0_addr : out std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
        bram2_port0_addr : out std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
        bram3_port0_addr : out std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
        bram0_port1_addr : out std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
        bram1_port1_addr : out std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
        bram2_port1_addr : out std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
        bram3_port1_addr : out std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);

        bram0_port0_we   : out std_logic;
        bram1_port0_we   : out std_logic;
        bram2_port0_we   : out std_logic;
        bram3_port0_we   : out std_logic;
        bram0_port1_we   : out std_logic;
        bram1_port1_we   : out std_logic;
        bram2_port1_we   : out std_logic;
        bram3_port1_we   : out std_logic;

        bram0_port0_en   : out std_logic;
        bram1_port0_en   : out std_logic;
        bram2_port0_en   : out std_logic;
        bram3_port0_en   : out std_logic;
        bram0_port1_en   : out std_logic;
        bram1_port1_en   : out std_logic;
        bram2_port1_en   : out std_logic;
        bram3_port1_en   : out std_logic;

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

    signal s_axis_cordic_inv_tready_cart  : std_logic;
    signal s_axis_cordic_inv_tready_phase : std_logic;
    signal m_axis_cordic_inv_tdata        : std_logic_vector(31 downto 0);
    signal m_axis_cordic_inv_tvalid       : std_logic;
    signal m_axis_cordic_inv_tlast        : std_logic;

    -- BMU control signals
    signal bw_start, bw_count_en, bw_done : std_logic;
    signal br_start, br_count_en, br_done : std_logic;
    signal bw_data_in_0                   : std_logic_vector(31 downto 0);
    signal br_data_out_0                  : std_logic_vector(31 downto 0);

    -- BMU read pipeline registers
    signal br_data_valid : std_logic;
    signal br_data_last  : std_logic;
    signal read_cnt      : unsigned(ARAM_ADDR_SIZE-1 downto 0);
    signal block_size    : unsigned(ARAM_ADDR_SIZE-1 downto 0);

    -- intermediate BRAM signals
    signal bw_p0_addr, br_p0_addr : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal bw_p1_addr, br_p1_addr : std_logic_vector(ARAM_ADDR_SIZE-1 downto 0);
    signal bw_p0_en,   br_p0_en   : std_logic;
    signal bw_p1_en,   br_p1_en   : std_logic;
    signal bw_p0_we,   bw_p1_we   : std_logic;
    signal bw_p0_din,  bw_p1_din  : std_logic_vector(31 downto 0);

    -- FSM signals
    type state_type is (IDLE, CONFIG_FFT, PROCESSING, DONE);
    signal state, next_state : state_type;
    signal reg_fwd_inv : std_logic;
    signal reg_size    : std_logic;
    signal xilinx_fft_fwd_inv : std_logic;

begin

    xilinx_fft_fwd_inv <= '1' when reg_fwd_inv = '0' else '0';
    block_size <= to_unsigned(256, ARAM_ADDR_SIZE) when reg_size = '0' else to_unsigned(512, ARAM_ADDR_SIZE);

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
        m_axis_data_tready   => m_axis_fft_data_tready,
        m_axis_status_tready => '1'
    );

    cordic_fwd_inst : entity work.cordic_to_polar
    port map (
        aclk                    => clk,
        aresetn                 => rst,
        s_axis_cartesian_tdata  => m_axis_fft_data_tdata,
        s_axis_cartesian_tvalid => m_axis_fft_data_tvalid,
        s_axis_cartesian_tlast  => m_axis_fft_data_tlast,
        s_axis_cartesian_tuser  => m_axis_fft_data_tuser,
        s_axis_cartesian_tready => s_axis_cordic_fwd_tready,
        m_axis_dout_tdata       => m_axis_cordic_fwd_tdata,
        m_axis_dout_tvalid      => m_axis_cordic_fwd_tvalid,
        m_axis_dout_tlast       => m_axis_cordic_fwd_tlast,
        m_axis_dout_tuser       => m_axis_cordic_fwd_tuser,
        m_axis_dout_tready      => '1'
    );

    cordic_inv_inst : entity work.cordic_to_cartesian
    port map (  
        aclk                    => clk,
        aresetn                 => rst,
        s_axis_phase_tdata      => br_data_out_0(31 downto 16),
        s_axis_phase_tvalid     => br_data_valid,
        s_axis_phase_tready     => s_axis_cordic_inv_tready_phase,
        s_axis_cartesian_tdata(31 downto 16) => x"0000",
        s_axis_cartesian_tdata(15 downto 0)  => br_data_out_0(15 downto 0),
        s_axis_cartesian_tvalid => br_data_valid,
        s_axis_cartesian_tlast  => br_data_last,
        s_axis_cartesian_tready => s_axis_cordic_inv_tready_cart,
        s_axis_phase_tuser      => (others => '0'),
        s_axis_phase_tlast      => '0',
        m_axis_dout_tdata       => m_axis_cordic_inv_tdata,
        m_axis_dout_tvalid      => m_axis_cordic_inv_tvalid,
        m_axis_dout_tlast       => m_axis_cordic_inv_tlast,
        m_axis_dout_tready      => s_axis_fft_data_tready
    );

    bw : entity work.bmu_write
        generic map (
            BUFFER_ADDR_WIDTH => ARAM_ADDR_SIZE,
            BUFFER_SIZE_BITS  => ARAM_ADDR_SIZE,
            LANES             => 1 -- serial streaming
        )
        port map (
            clk => clk, rst => rst, start => bw_start, count_en => bw_count_en,

            buffer_start     => bsw(ARAM_ADDR_SIZE-1 downto 0),
            buffer_length    => blw(ARAM_ADDR_SIZE-1 downto 0),
            operation_start  => osw(ARAM_ADDR_SIZE-1 downto 0),
            operation_length => olw(ARAM_ADDR_SIZE-1 downto 0),

            bram0_port0_addr => bw_p0_addr, bram1_port0_addr => open,
            bram2_port0_addr => open,       bram3_port0_addr => open,
            bram0_port1_addr => bw_p1_addr, bram1_port1_addr => open,
            bram2_port1_addr => open,       bram3_port1_addr => open,

            bram0_port0_we   => bw_p0_we,   bram1_port0_we   => open,
            bram2_port0_we   => open,       bram3_port0_we   => open,
            bram0_port1_we   => bw_p1_we,   bram1_port1_we   => open,
            bram2_port1_we   => open,       bram3_port1_we   => open,

            bram0_port0_en   => bw_p0_en,   bram1_port0_en   => open,
            bram2_port0_en   => open,       bram3_port0_en   => open,
            bram0_port1_en   => bw_p1_en,   bram1_port1_en   => open,
            bram2_port1_en   => open,       bram3_port1_en   => open,

            bram0_port0_data_in => bw_p0_din, bram1_port0_data_in => open,
            bram2_port0_data_in => open,      bram3_port0_data_in => open,
            bram0_port1_data_in => bw_p1_din, bram1_port1_data_in => open,
            bram2_port1_data_in => open,      bram3_port1_data_in => open,

            bram0_port0_data_out => (others => '0'), bram1_port0_data_out => (others => '0'),
            bram2_port0_data_out => (others => '0'), bram3_port0_data_out => (others => '0'),
            bram0_port1_data_out => (others => '0'), bram1_port1_data_out => (others => '0'),
            bram2_port1_data_out => (others => '0'), bram3_port1_data_out => (others => '0'),

            data_in_0 => bw_data_in_0, data_in_1 => (others => '0'),
            data_in_2 => (others => '0'), data_in_3 => (others => '0'),
            data_in_4 => (others => '0'), data_in_5 => (others => '0'),
            data_in_6 => (others => '0'), data_in_7 => (others => '0'),

            done => bw_done
        );

    br : entity work.bmu_read
        generic map (
            BUFFER_ADDR_WIDTH => ARAM_ADDR_SIZE,
            BUFFER_SIZE_BITS  => ARAM_ADDR_SIZE,
            LANES             => 1 -- serial streaming
        )
        port map (
            clk => clk, rst => rst, start => br_start, count_en => br_count_en,

            buffer_start     => bsr(ARAM_ADDR_SIZE-1 downto 0),
            buffer_length    => blr(ARAM_ADDR_SIZE-1 downto 0),
            operation_start  => osr(ARAM_ADDR_SIZE-1 downto 0),
            operation_length => olr(ARAM_ADDR_SIZE-1 downto 0),

            bram0_port0_addr => br_p0_addr, bram1_port0_addr => open,
            bram2_port0_addr => open,       bram3_port0_addr => open,
            bram0_port1_addr => br_p1_addr, bram1_port1_addr => open,
            bram2_port1_addr => open,       bram3_port1_addr => open,

            bram0_port0_we   => open,       bram1_port0_we   => open,
            bram2_port0_we   => open,       bram3_port0_we   => open,
            bram0_port1_we   => open,       bram1_port1_we   => open,
            bram2_port1_we   => open,       bram3_port1_we   => open,

            bram0_port0_en   => br_p0_en,   bram1_port0_en   => open,   -- TODO check: we need to write on all brams, not only bram0
            bram2_port0_en   => open,       bram3_port0_en   => open,
            bram0_port1_en   => br_p1_en,   bram1_port1_en   => open,
            bram2_port1_en   => open,       bram3_port1_en   => open,

            bram0_port0_data_in => open, bram1_port0_data_in => open,
            bram2_port0_data_in => open, bram3_port0_data_in => open,
            bram0_port1_data_in => open, bram1_port1_data_in => open,
            bram2_port1_data_in => open, bram3_port1_data_in => open,

            bram0_port0_data_out => bram0_port0_data_out, bram1_port0_data_out => bram1_port0_data_out,
            bram2_port0_data_out => bram2_port0_data_out, bram3_port0_data_out => bram3_port0_data_out,
            bram0_port1_data_out => bram0_port1_data_out, bram1_port1_data_out => bram1_port1_data_out,
            bram2_port1_data_out => bram2_port1_data_out, bram3_port1_data_out => bram3_port1_data_out,

            data_out_0 => br_data_out_0, data_out_1 => open,
            data_out_2 => open,          data_out_3 => open,
            data_out_4 => open,          data_out_5 => open,
            data_out_6 => open,          data_out_7 => open,

            done => br_done
        );

    -- BRAM multiplexing
    bram0_port0_addr    <= bw_p0_addr when bw_p0_en = '1' else br_p0_addr;
    bram1_port0_addr    <= bw_p0_addr when bw_p0_en = '1' else br_p0_addr;
    bram2_port0_addr    <= bw_p0_addr when bw_p0_en = '1' else br_p0_addr;
    bram3_port0_addr    <= bw_p0_addr when bw_p0_en = '1' else br_p0_addr;

    bram0_port1_addr    <= bw_p1_addr when bw_p1_en = '1' else br_p1_addr;
    bram1_port1_addr    <= bw_p1_addr when bw_p1_en = '1' else br_p1_addr;
    bram2_port1_addr    <= bw_p1_addr when bw_p1_en = '1' else br_p1_addr;
    bram3_port1_addr    <= bw_p1_addr when bw_p1_en = '1' else br_p1_addr;

    bram0_port0_en      <= bw_p0_en or br_p0_en;
    bram1_port0_en      <= bw_p0_en or br_p0_en;
    bram2_port0_en      <= bw_p0_en or br_p0_en;
    bram3_port0_en      <= bw_p0_en or br_p0_en;

    bram0_port1_en      <= bw_p1_en or br_p1_en;
    bram1_port1_en      <= bw_p1_en or br_p1_en;
    bram2_port1_en      <= bw_p1_en or br_p1_en;
    bram3_port1_en      <= bw_p1_en or br_p1_en;

    bram0_port0_we      <= bw_p0_we;  bram1_port0_we <= bw_p0_we;
    bram2_port0_we      <= bw_p0_we;  bram3_port0_we <= bw_p0_we;
    bram0_port1_we      <= bw_p1_we;  bram1_port1_we <= bw_p1_we;
    bram2_port1_we      <= bw_p1_we;  bram3_port1_we <= bw_p1_we;

    bram0_port0_data_in <= bw_p0_din; bram1_port0_data_in <= bw_p0_din;
    bram2_port0_data_in <= bw_p0_din; bram3_port0_data_in <= bw_p0_din;
    bram0_port1_data_in <= bw_p1_din; bram1_port1_data_in <= bw_p1_din;
    bram2_port1_data_in <= bw_p1_din; bram3_port1_data_in <= bw_p1_din;

    -- BMU read
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '0' or state = IDLE then
                br_data_valid <= '0';
                br_data_last  <= '0';
                read_cnt      <= (others => '0');
            else
                br_data_valid <= br_count_en;
                
                if br_count_en = '1' then
                    read_cnt <= read_cnt + 1;
                    if read_cnt = block_size - 2 then
                        br_data_last <= '1';
                    else
                        br_data_last <= '0';
                    end if;
                else
                    br_data_last <= '0';
                end if;
            end if;
        end if;
    end process;

    -- FSM sequential
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '0' then
                state       <= IDLE;
                reg_fwd_inv <= '0';
                reg_size    <= '0';
            else
                state <= next_state;
                if state = IDLE and en = '1' then
                    reg_fwd_inv <= fwd_inv;
                    reg_size    <= size;
                end if;
            end if;
        end if;
    end process;

    -- FSM combinational
    process(state, en, m_axis_fft_config_tready, m_axis_cordic_fwd_tlast, m_axis_cordic_fwd_tvalid, 
            m_axis_fft_data_tlast, m_axis_fft_data_tvalid, reg_fwd_inv, reg_size, xilinx_fft_fwd_inv, bw_done)
    begin
        next_state               <= state;
        finished                 <= '0';
        m_axis_fft_config_tvalid <= '0';
        m_axis_fft_config_tdata  <= (others => '0');
        br_start                 <= '0';
        bw_start                 <= '0';

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
                    br_start   <= '1';
                    bw_start   <= '1';
                    next_state <= PROCESSING;
                end if;

            when PROCESSING =>
                if reg_fwd_inv = '0' then
                    if m_axis_cordic_fwd_tlast = '1' and m_axis_cordic_fwd_tvalid = '1' and bw_done = '1' then
                        next_state <= DONE;
                    end if;
                else
                    if m_axis_fft_data_tlast = '1' and m_axis_fft_data_tvalid = '1' and bw_done = '1' then
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

    process(reg_fwd_inv, br_data_out_0, br_data_valid, br_data_last, br_done,
            s_axis_fft_data_tready, m_axis_fft_data_tdata, m_axis_fft_data_tvalid, 
            m_axis_fft_data_tlast, m_axis_fft_data_tuser, s_axis_cordic_inv_tready_cart, 
            m_axis_cordic_inv_tdata, m_axis_cordic_inv_tvalid, m_axis_cordic_inv_tlast,
            m_axis_cordic_fwd_tdata, m_axis_cordic_fwd_tvalid, s_axis_cordic_fwd_tready)
    begin
        if reg_fwd_inv = '0' then
            -- FORWARD MODE: ARAM -> FFT -> CORDIC FWD -> ARAM
            s_axis_fft_data_tdata  <= br_data_out_0;
            s_axis_fft_data_tvalid <= br_data_valid;
            s_axis_fft_data_tlast  <= br_data_last;
            
            br_count_en <= s_axis_fft_data_tready and not br_done;
            bw_data_in_0 <= m_axis_cordic_fwd_tdata;
            bw_count_en  <= m_axis_cordic_fwd_tvalid;

            m_axis_fft_data_tready <= s_axis_cordic_fwd_tready;

        else
            -- INVERSE MODE: ARAM -> CORDIC INV -> FFT -> ARAM
            
            br_count_en <= s_axis_cordic_inv_tready_cart and not br_done;

            s_axis_fft_data_tdata  <= m_axis_cordic_inv_tdata;
            s_axis_fft_data_tvalid <= m_axis_cordic_inv_tvalid;
            s_axis_fft_data_tlast  <= m_axis_cordic_inv_tlast;

            bw_data_in_0 <= m_axis_fft_data_tdata;
            bw_count_en  <= m_axis_fft_data_tvalid;

            m_axis_fft_data_tready <= '1';
        end if;
    end process;

end Behavioral;