library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.apu_internal_pkg.all;

entity aram_mux is
    generic (
        BUFFER_ADDR_WIDTH : integer := 10;
        BUFFER_SIZE_BITS  : integer := 18
  );
    port (
        unit_select : in apu_unit_t;

        --audio in unit

        ain_bram0_port0_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        ain_bram1_port0_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        ain_bram2_port0_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        ain_bram3_port0_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        ain_bram0_port1_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        ain_bram1_port1_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        ain_bram2_port1_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        ain_bram3_port1_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);

        ain_bram0_port0_we : in std_logic;
        ain_bram1_port0_we : in std_logic;
        ain_bram2_port0_we : in std_logic;
        ain_bram3_port0_we : in std_logic;
        ain_bram0_port1_we : in std_logic;
        ain_bram1_port1_we : in std_logic;
        ain_bram2_port1_we : in std_logic;
        ain_bram3_port1_we : in std_logic;

        ain_bram0_port0_en : in std_logic;
        ain_bram1_port0_en : in std_logic;
        ain_bram2_port0_en : in std_logic;
        ain_bram3_port0_en : in std_logic;
        ain_bram0_port1_en : in std_logic;
        ain_bram1_port1_en : in std_logic;
        ain_bram2_port1_en : in std_logic;
        ain_bram3_port1_en : in std_logic;

        ain_bram0_port0_data_in : in std_logic_vector(31 downto 0);
        ain_bram1_port0_data_in : in std_logic_vector(31 downto 0);
        ain_bram2_port0_data_in : in std_logic_vector(31 downto 0);
        ain_bram3_port0_data_in : in std_logic_vector(31 downto 0);
        ain_bram0_port1_data_in : in std_logic_vector(31 downto 0);
        ain_bram1_port1_data_in : in std_logic_vector(31 downto 0);
        ain_bram2_port1_data_in : in std_logic_vector(31 downto 0);
        ain_bram3_port1_data_in : in std_logic_vector(31 downto 0);

        ain_bram0_port0_data_out : out std_logic_vector(31 downto 0);
        ain_bram1_port0_data_out : out std_logic_vector(31 downto 0);
        ain_bram2_port0_data_out : out std_logic_vector(31 downto 0);
        ain_bram3_port0_data_out : out std_logic_vector(31 downto 0);
        ain_bram0_port1_data_out : out std_logic_vector(31 downto 0);
        ain_bram1_port1_data_out : out std_logic_vector(31 downto 0);
        ain_bram2_port1_data_out : out std_logic_vector(31 downto 0);
        ain_bram3_port1_data_out : out std_logic_vector(31 downto 0);

        -- audio out unit

        aout_bram0_port0_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        aout_bram1_port0_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        aout_bram2_port0_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        aout_bram3_port0_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        aout_bram0_port1_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        aout_bram1_port1_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        aout_bram2_port1_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        aout_bram3_port1_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);

        aout_bram0_port0_we : in std_logic;
        aout_bram1_port0_we : in std_logic;
        aout_bram2_port0_we : in std_logic;
        aout_bram3_port0_we : in std_logic;
        aout_bram0_port1_we : in std_logic;
        aout_bram1_port1_we : in std_logic;
        aout_bram2_port1_we : in std_logic;
        aout_bram3_port1_we : in std_logic;

        aout_bram0_port0_en : in std_logic;
        aout_bram1_port0_en : in std_logic;
        aout_bram2_port0_en : in std_logic;
        aout_bram3_port0_en : in std_logic;
        aout_bram0_port1_en : in std_logic;
        aout_bram1_port1_en : in std_logic;
        aout_bram2_port1_en : in std_logic;
        aout_bram3_port1_en : in std_logic;

        aout_bram0_port0_data_in : in std_logic_vector(31 downto 0);
        aout_bram1_port0_data_in : in std_logic_vector(31 downto 0);
        aout_bram2_port0_data_in : in std_logic_vector(31 downto 0);
        aout_bram3_port0_data_in : in std_logic_vector(31 downto 0);
        aout_bram0_port1_data_in : in std_logic_vector(31 downto 0);
        aout_bram1_port1_data_in : in std_logic_vector(31 downto 0);
        aout_bram2_port1_data_in : in std_logic_vector(31 downto 0);
        aout_bram3_port1_data_in : in std_logic_vector(31 downto 0);

        aout_bram0_port0_data_out : out std_logic_vector(31 downto 0);
        aout_bram1_port0_data_out : out std_logic_vector(31 downto 0);
        aout_bram2_port0_data_out : out std_logic_vector(31 downto 0);
        aout_bram3_port0_data_out : out std_logic_vector(31 downto 0);
        aout_bram0_port1_data_out : out std_logic_vector(31 downto 0);
        aout_bram1_port1_data_out : out std_logic_vector(31 downto 0);
        aout_bram2_port1_data_out : out std_logic_vector(31 downto 0);
        aout_bram3_port1_data_out : out std_logic_vector(31 downto 0);

        -- vpu unit

        vpu_bram0_port0_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        vpu_bram1_port0_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        vpu_bram2_port0_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        vpu_bram3_port0_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        vpu_bram0_port1_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        vpu_bram1_port1_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        vpu_bram2_port1_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        vpu_bram3_port1_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);

        vpu_bram0_port0_we : in std_logic;
        vpu_bram1_port0_we : in std_logic;
        vpu_bram2_port0_we : in std_logic;
        vpu_bram3_port0_we : in std_logic;
        vpu_bram0_port1_we : in std_logic;
        vpu_bram1_port1_we : in std_logic;
        vpu_bram2_port1_we : in std_logic;
        vpu_bram3_port1_we : in std_logic;

        vpu_bram0_port0_en : in std_logic;
        vpu_bram1_port0_en : in std_logic;
        vpu_bram2_port0_en : in std_logic;
        vpu_bram3_port0_en : in std_logic;
        vpu_bram0_port1_en : in std_logic;
        vpu_bram1_port1_en : in std_logic;
        vpu_bram2_port1_en : in std_logic;
        vpu_bram3_port1_en : in std_logic;

        vpu_bram0_port0_data_in : in std_logic_vector(31 downto 0);
        vpu_bram1_port0_data_in : in std_logic_vector(31 downto 0);
        vpu_bram2_port0_data_in : in std_logic_vector(31 downto 0);
        vpu_bram3_port0_data_in : in std_logic_vector(31 downto 0);
        vpu_bram0_port1_data_in : in std_logic_vector(31 downto 0);
        vpu_bram1_port1_data_in : in std_logic_vector(31 downto 0);
        vpu_bram2_port1_data_in : in std_logic_vector(31 downto 0);
        vpu_bram3_port1_data_in : in std_logic_vector(31 downto 0);

        vpu_bram0_port0_data_out : out std_logic_vector(31 downto 0);
        vpu_bram1_port0_data_out : out std_logic_vector(31 downto 0);
        vpu_bram2_port0_data_out : out std_logic_vector(31 downto 0);
        vpu_bram3_port0_data_out : out std_logic_vector(31 downto 0);
        vpu_bram0_port1_data_out : out std_logic_vector(31 downto 0);
        vpu_bram1_port1_data_out : out std_logic_vector(31 downto 0);
        vpu_bram2_port1_data_out : out std_logic_vector(31 downto 0);
        vpu_bram3_port1_data_out : out std_logic_vector(31 downto 0);

        --ifft/fft unit

        fft_bram0_port0_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        fft_bram1_port0_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        fft_bram2_port0_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        fft_bram3_port0_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        fft_bram0_port1_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        fft_bram1_port1_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        fft_bram2_port1_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        fft_bram3_port1_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);

        fft_bram0_port0_we : in std_logic;
        fft_bram1_port0_we : in std_logic;
        fft_bram2_port0_we : in std_logic;
        fft_bram3_port0_we : in std_logic;
        fft_bram0_port1_we : in std_logic;
        fft_bram1_port1_we : in std_logic;
        fft_bram2_port1_we : in std_logic;
        fft_bram3_port1_we : in std_logic;

        fft_bram0_port0_en : in std_logic;
        fft_bram1_port0_en : in std_logic;
        fft_bram2_port0_en : in std_logic;
        fft_bram3_port0_en : in std_logic;
        fft_bram0_port1_en : in std_logic;
        fft_bram1_port1_en : in std_logic;
        fft_bram2_port1_en : in std_logic;
        fft_bram3_port1_en : in std_logic;

        fft_bram0_port0_data_in : in std_logic_vector(31 downto 0);
        fft_bram1_port0_data_in : in std_logic_vector(31 downto 0);
        fft_bram2_port0_data_in : in std_logic_vector(31 downto 0);
        fft_bram3_port0_data_in : in std_logic_vector(31 downto 0);
        fft_bram0_port1_data_in : in std_logic_vector(31 downto 0);
        fft_bram1_port1_data_in : in std_logic_vector(31 downto 0);
        fft_bram2_port1_data_in : in std_logic_vector(31 downto 0);
        fft_bram3_port1_data_in : in std_logic_vector(31 downto 0);

        fft_bram0_port0_data_out : out std_logic_vector(31 downto 0);
        fft_bram1_port0_data_out : out std_logic_vector(31 downto 0);
        fft_bram2_port0_data_out : out std_logic_vector(31 downto 0);
        fft_bram3_port0_data_out : out std_logic_vector(31 downto 0);
        fft_bram0_port1_data_out : out std_logic_vector(31 downto 0);
        fft_bram1_port1_data_out : out std_logic_vector(31 downto 0);
        fft_bram2_port1_data_out : out std_logic_vector(31 downto 0);
        fft_bram3_port1_data_out : out std_logic_vector(31 downto 0);

        --pitch shift unit

        ps_bram0_port0_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        ps_bram1_port0_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        ps_bram2_port0_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        ps_bram3_port0_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        ps_bram0_port1_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        ps_bram1_port1_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        ps_bram2_port1_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);
        ps_bram3_port1_addr : in std_logic_vector(BUFFER_ADDR_WIDTH-1 downto 0);

        ps_bram0_port0_we : in std_logic;
        ps_bram1_port0_we : in std_logic;
        ps_bram2_port0_we : in std_logic;
        ps_bram3_port0_we : in std_logic;
        ps_bram0_port1_we : in std_logic;
        ps_bram1_port1_we : in std_logic;
        ps_bram2_port1_we : in std_logic;
        ps_bram3_port1_we : in std_logic;

        ps_bram0_port0_en : in std_logic;
        ps_bram1_port0_en : in std_logic;
        ps_bram2_port0_en : in std_logic;
        ps_bram3_port0_en : in std_logic;
        ps_bram0_port1_en : in std_logic;
        ps_bram1_port1_en : in std_logic;
        ps_bram2_port1_en : in std_logic;
        ps_bram3_port1_en : in std_logic;

        ps_bram0_port0_data_in : in std_logic_vector(31 downto 0);
        ps_bram1_port0_data_in : in std_logic_vector(31 downto 0);
        ps_bram2_port0_data_in : in std_logic_vector(31 downto 0);
        ps_bram3_port0_data_in : in std_logic_vector(31 downto 0);
        ps_bram0_port1_data_in : in std_logic_vector(31 downto 0);
        ps_bram1_port1_data_in : in std_logic_vector(31 downto 0);
        ps_bram2_port1_data_in : in std_logic_vector(31 downto 0);
        ps_bram3_port1_data_in : in std_logic_vector(31 downto 0);

        ps_bram0_port0_data_out : out std_logic_vector(31 downto 0);
        ps_bram1_port0_data_out : out std_logic_vector(31 downto 0);
        ps_bram2_port0_data_out : out std_logic_vector(31 downto 0);
        ps_bram3_port0_data_out : out std_logic_vector(31 downto 0);
        ps_bram0_port1_data_out : out std_logic_vector(31 downto 0);
        ps_bram1_port1_data_out : out std_logic_vector(31 downto 0);
        ps_bram2_port1_data_out : out std_logic_vector(31 downto 0);
        ps_bram3_port1_data_out : out std_logic_vector(31 downto 0);

        --to a-ram
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

end aram_mux;

architecture Behavioral of aram_mux is
begin

    process(all)
    begin
        bram0_port0_addr <= (others => '0');
        bram1_port0_addr <= (others => '0');
        bram2_port0_addr <= (others => '0');
        bram3_port0_addr <= (others => '0');
        bram0_port1_addr <= (others => '0');
        bram1_port1_addr <= (others => '0');
        bram2_port1_addr <= (others => '0');
        bram3_port1_addr <= (others => '0');

        bram0_port0_we <= '0'; bram1_port0_we <= '0'; bram2_port0_we <= '0'; bram3_port0_we <= '0';
        bram0_port1_we <= '0'; bram1_port1_we <= '0'; bram2_port1_we <= '0'; bram3_port1_we <= '0';

        bram0_port0_en <= '0'; bram1_port0_en <= '0'; bram2_port0_en <= '0'; bram3_port0_en <= '0';
        bram0_port1_en <= '0'; bram1_port1_en <= '0'; bram2_port1_en <= '0'; bram3_port1_en <= '0';

        bram0_port0_data_in <= (others => '0');
        bram1_port0_data_in <= (others => '0');
        bram2_port0_data_in <= (others => '0');
        bram3_port0_data_in <= (others => '0');
        bram0_port1_data_in <= (others => '0');
        bram1_port1_data_in <= (others => '0');
        bram2_port1_data_in <= (others => '0');
        bram3_port1_data_in <= (others => '0');

        case unit_select is
            when APU_UNIT_NONE =>
                null;

            when APU_UNIT_AUDIO_IN =>
                bram0_port0_addr <= ain_bram0_port0_addr; bram1_port0_addr <= ain_bram1_port0_addr;
                bram2_port0_addr <= ain_bram2_port0_addr; bram3_port0_addr <= ain_bram3_port0_addr;
                bram0_port1_addr <= ain_bram0_port1_addr; bram1_port1_addr <= ain_bram1_port1_addr;
                bram2_port1_addr <= ain_bram2_port1_addr; bram3_port1_addr <= ain_bram3_port1_addr;

                bram0_port0_we <= ain_bram0_port0_we; bram1_port0_we <= ain_bram1_port0_we;
                bram2_port0_we <= ain_bram2_port0_we; bram3_port0_we <= ain_bram3_port0_we;
                bram0_port1_we <= ain_bram0_port1_we; bram1_port1_we <= ain_bram1_port1_we;
                bram2_port1_we <= ain_bram2_port1_we; bram3_port1_we <= ain_bram3_port1_we;

                bram0_port0_en <= ain_bram0_port0_en; bram1_port0_en <= ain_bram1_port0_en;
                bram2_port0_en <= ain_bram2_port0_en; bram3_port0_en <= ain_bram3_port0_en;
                bram0_port1_en <= ain_bram0_port1_en; bram1_port1_en <= ain_bram1_port1_en;
                bram2_port1_en <= ain_bram2_port1_en; bram3_port1_en <= ain_bram3_port1_en;

                bram0_port0_data_in <= ain_bram0_port0_data_in; bram1_port0_data_in <= ain_bram1_port0_data_in;
                bram2_port0_data_in <= ain_bram2_port0_data_in; bram3_port0_data_in <= ain_bram3_port0_data_in;
                bram0_port1_data_in <= ain_bram0_port1_data_in; bram1_port1_data_in <= ain_bram1_port1_data_in;
                bram2_port1_data_in <= ain_bram2_port1_data_in; bram3_port1_data_in <= ain_bram3_port1_data_in;

            when APU_UNIT_AUDIO_OUT =>
                bram0_port0_addr <= aout_bram0_port0_addr; bram1_port0_addr <= aout_bram1_port0_addr;
                bram2_port0_addr <= aout_bram2_port0_addr; bram3_port0_addr <= aout_bram3_port0_addr;
                bram0_port1_addr <= aout_bram0_port1_addr; bram1_port1_addr <= aout_bram1_port1_addr;
                bram2_port1_addr <= aout_bram2_port1_addr; bram3_port1_addr <= aout_bram3_port1_addr;

                bram0_port0_we <= aout_bram0_port0_we; bram1_port0_we <= aout_bram1_port0_we;
                bram2_port0_we <= aout_bram2_port0_we; bram3_port0_we <= aout_bram3_port0_we;
                bram0_port1_we <= aout_bram0_port1_we; bram1_port1_we <= aout_bram1_port1_we;
                bram2_port1_we <= aout_bram2_port1_we; bram3_port1_we <= aout_bram3_port1_we;

                bram0_port0_en <= aout_bram0_port0_en; bram1_port0_en <= aout_bram1_port0_en;
                bram2_port0_en <= aout_bram2_port0_en; bram3_port0_en <= aout_bram3_port0_en;
                bram0_port1_en <= aout_bram0_port1_en; bram1_port1_en <= aout_bram1_port1_en;
                bram2_port1_en <= aout_bram2_port1_en; bram3_port1_en <= aout_bram3_port1_en;

                bram0_port0_data_in <= aout_bram0_port0_data_in; bram1_port0_data_in <= aout_bram1_port0_data_in;
                bram2_port0_data_in <= aout_bram2_port0_data_in; bram3_port0_data_in <= aout_bram3_port0_data_in;
                bram0_port1_data_in <= aout_bram0_port1_data_in; bram1_port1_data_in <= aout_bram1_port1_data_in;
                bram2_port1_data_in <= aout_bram2_port1_data_in; bram3_port1_data_in <= aout_bram3_port1_data_in;

            when APU_UNIT_VEC =>
                bram0_port0_addr <= vpu_bram0_port0_addr; bram1_port0_addr <= vpu_bram1_port0_addr;
                bram2_port0_addr <= vpu_bram2_port0_addr; bram3_port0_addr <= vpu_bram3_port0_addr;
                bram0_port1_addr <= vpu_bram0_port1_addr; bram1_port1_addr <= vpu_bram1_port1_addr;
                bram2_port1_addr <= vpu_bram2_port1_addr; bram3_port1_addr <= vpu_bram3_port1_addr;

                bram0_port0_we <= vpu_bram0_port0_we; bram1_port0_we <= vpu_bram1_port0_we;
                bram2_port0_we <= vpu_bram2_port0_we; bram3_port0_we <= vpu_bram3_port0_we;
                bram0_port1_we <= vpu_bram0_port1_we; bram1_port1_we <= vpu_bram1_port1_we;
                bram2_port1_we <= vpu_bram2_port1_we; bram3_port1_we <= vpu_bram3_port1_we;

                bram0_port0_en <= vpu_bram0_port0_en; bram1_port0_en <= vpu_bram1_port0_en;
                bram2_port0_en <= vpu_bram2_port0_en; bram3_port0_en <= vpu_bram3_port0_en;
                bram0_port1_en <= vpu_bram0_port1_en; bram1_port1_en <= vpu_bram1_port1_en;
                bram2_port1_en <= vpu_bram2_port1_en; bram3_port1_en <= vpu_bram3_port1_en;

                bram0_port0_data_in <= vpu_bram0_port0_data_in; bram1_port0_data_in <= vpu_bram1_port0_data_in;
                bram2_port0_data_in <= vpu_bram2_port0_data_in; bram3_port0_data_in <= vpu_bram3_port0_data_in;
                bram0_port1_data_in <= vpu_bram0_port1_data_in; bram1_port1_data_in <= vpu_bram1_port1_data_in;
                bram2_port1_data_in <= vpu_bram2_port1_data_in; bram3_port1_data_in <= vpu_bram3_port1_data_in;

            when APU_UNIT_FFT =>
                bram0_port0_addr <= fft_bram0_port0_addr; bram1_port0_addr <= fft_bram1_port0_addr;
                bram2_port0_addr <= fft_bram2_port0_addr; bram3_port0_addr <= fft_bram3_port0_addr;
                bram0_port1_addr <= fft_bram0_port1_addr; bram1_port1_addr <= fft_bram1_port1_addr;
                bram2_port1_addr <= fft_bram2_port1_addr; bram3_port1_addr <= fft_bram3_port1_addr;

                bram0_port0_we <= fft_bram0_port0_we; bram1_port0_we <= fft_bram1_port0_we;
                bram2_port0_we <= fft_bram2_port0_we; bram3_port0_we <= fft_bram3_port0_we;
                bram0_port1_we <= fft_bram0_port1_we; bram1_port1_we <= fft_bram1_port1_we;
                bram2_port1_we <= fft_bram2_port1_we; bram3_port1_we <= fft_bram3_port1_we;

                bram0_port0_en <= fft_bram0_port0_en; bram1_port0_en <= fft_bram1_port0_en;
                bram2_port0_en <= fft_bram2_port0_en; bram3_port0_en <= fft_bram3_port0_en;
                bram0_port1_en <= fft_bram0_port1_en; bram1_port1_en <= fft_bram1_port1_en;
                bram2_port1_en <= fft_bram2_port1_en; bram3_port1_en <= fft_bram3_port1_en;

                bram0_port0_data_in <= fft_bram0_port0_data_in; bram1_port0_data_in <= fft_bram1_port0_data_in;
                bram2_port0_data_in <= fft_bram2_port0_data_in; bram3_port0_data_in <= fft_bram3_port0_data_in;
                bram0_port1_data_in <= fft_bram0_port1_data_in; bram1_port1_data_in <= fft_bram1_port1_data_in;
                bram2_port1_data_in <= fft_bram2_port1_data_in; bram3_port1_data_in <= fft_bram3_port1_data_in;

            when APU_UNIT_PITCH =>
                bram0_port0_addr <= ps_bram0_port0_addr; bram1_port0_addr <= ps_bram1_port0_addr;
                bram2_port0_addr <= ps_bram2_port0_addr; bram3_port0_addr <= ps_bram3_port0_addr;
                bram0_port1_addr <= ps_bram0_port1_addr; bram1_port1_addr <= ps_bram1_port1_addr;
                bram2_port1_addr <= ps_bram2_port1_addr; bram3_port1_addr <= ps_bram3_port1_addr;

                bram0_port0_we <= ps_bram0_port0_we; bram1_port0_we <= ps_bram1_port0_we;
                bram2_port0_we <= ps_bram2_port0_we; bram3_port0_we <= ps_bram3_port0_we;
                bram0_port1_we <= ps_bram0_port1_we; bram1_port1_we <= ps_bram1_port1_we;
                bram2_port1_we <= ps_bram2_port1_we; bram3_port1_we <= ps_bram3_port1_we;

                bram0_port0_en <= ps_bram0_port0_en; bram1_port0_en <= ps_bram1_port0_en;
                bram2_port0_en <= ps_bram2_port0_en; bram3_port0_en <= ps_bram3_port0_en;
                bram0_port1_en <= ps_bram0_port1_en; bram1_port1_en <= ps_bram1_port1_en;
                bram2_port1_en <= ps_bram2_port1_en; bram3_port1_en <= ps_bram3_port1_en;

                bram0_port0_data_in <= ps_bram0_port0_data_in; bram1_port0_data_in <= ps_bram1_port0_data_in;
                bram2_port0_data_in <= ps_bram2_port0_data_in; bram3_port0_data_in <= ps_bram3_port0_data_in;
                bram0_port1_data_in <= ps_bram0_port1_data_in; bram1_port1_data_in <= ps_bram1_port1_data_in;
                bram2_port1_data_in <= ps_bram2_port1_data_in; bram3_port1_data_in <= ps_bram3_port1_data_in;

            when others =>
                null;
        end case;
    end process;

    -- data_out fans back to every unit unconditionally; only the selected
    -- one is actually driving count_en on its own bmu, so only it cares
    ain_bram0_port0_data_out  <= bram0_port0_data_out;
    aout_bram0_port0_data_out <= bram0_port0_data_out;
    vpu_bram0_port0_data_out  <= bram0_port0_data_out;
    fft_bram0_port0_data_out  <= bram0_port0_data_out;
    ps_bram0_port0_data_out   <= bram0_port0_data_out;

    ain_bram1_port0_data_out  <= bram1_port0_data_out;
    aout_bram1_port0_data_out <= bram1_port0_data_out;
    vpu_bram1_port0_data_out  <= bram1_port0_data_out;
    fft_bram1_port0_data_out  <= bram1_port0_data_out;
    ps_bram1_port0_data_out   <= bram1_port0_data_out;

    ain_bram2_port0_data_out  <= bram2_port0_data_out;
    aout_bram2_port0_data_out <= bram2_port0_data_out;
    vpu_bram2_port0_data_out  <= bram2_port0_data_out;
    fft_bram2_port0_data_out  <= bram2_port0_data_out;
    ps_bram2_port0_data_out   <= bram2_port0_data_out;

    ain_bram3_port0_data_out  <= bram3_port0_data_out;
    aout_bram3_port0_data_out <= bram3_port0_data_out;
    vpu_bram3_port0_data_out  <= bram3_port0_data_out;
    fft_bram3_port0_data_out  <= bram3_port0_data_out;
    ps_bram3_port0_data_out   <= bram3_port0_data_out;

    ain_bram0_port1_data_out  <= bram0_port1_data_out;
    aout_bram0_port1_data_out <= bram0_port1_data_out;
    vpu_bram0_port1_data_out  <= bram0_port1_data_out;
    fft_bram0_port1_data_out  <= bram0_port1_data_out;
    ps_bram0_port1_data_out   <= bram0_port1_data_out;

    ain_bram1_port1_data_out  <= bram1_port1_data_out;
    aout_bram1_port1_data_out <= bram1_port1_data_out;
    vpu_bram1_port1_data_out  <= bram1_port1_data_out;
    fft_bram1_port1_data_out  <= bram1_port1_data_out;
    ps_bram1_port1_data_out   <= bram1_port1_data_out;

    ain_bram2_port1_data_out  <= bram2_port1_data_out;
    aout_bram2_port1_data_out <= bram2_port1_data_out;
    vpu_bram2_port1_data_out  <= bram2_port1_data_out;
    fft_bram2_port1_data_out  <= bram2_port1_data_out;
    ps_bram2_port1_data_out   <= bram2_port1_data_out;

    ain_bram3_port1_data_out  <= bram3_port1_data_out;
    aout_bram3_port1_data_out <= bram3_port1_data_out;
    vpu_bram3_port1_data_out  <= bram3_port1_data_out;
    fft_bram3_port1_data_out  <= bram3_port1_data_out;
    ps_bram3_port1_data_out   <= bram3_port1_data_out;

end Behavioral;
