library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AXI_AudioIO is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI_AudioIO
		C_S00_AXI_AudioIO_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_AudioIO_ADDR_WIDTH	: integer	:= 4
	);
	port (
		-- Users to add ports here
		AC_ADR0  : out   STD_LOGIC;  -- control signals to ADAU chip
        AC_ADR1  : out   STD_LOGIC;
        AC_GPIO0 : out   STD_LOGIC;  -- I2S MISO
        AC_GPIO1 : in    STD_LOGIC;  -- I2S MOSI
        AC_GPIO2 : in    STD_LOGIC;  -- I2S_bclk
        AC_GPIO3 : in    STD_LOGIC;  -- I2S_LR
        AC_MCLK  : out   STD_LOGIC;
        AC_SCK   : out   STD_LOGIC;
        AC_SDA   : inout STD_LOGIC;
    
        --memory
        data_mem_addr : out std_logic_vector(31 downto 0);
        data_mem_data_out : out std_logic_vector(31 downto 0);
        data_mem_ena : out std_logic;
        data_mem_wea: out std_logic;
    
        --audio from apu interface
        new_sample_pair : in  std_logic;
        sample_pair     : in  std_logic_vector(31 downto 0);
        channel_sel     : in  std_logic;

		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI_AudioIO
		s00_axi_audioio_aclk	: in std_logic;
		s00_axi_audioio_aresetn	: in std_logic;
		s00_axi_audioio_awaddr	: in std_logic_vector(C_S00_AXI_AudioIO_ADDR_WIDTH-1 downto 0);
		s00_axi_audioio_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_audioio_awvalid	: in std_logic;
		s00_axi_audioio_awready	: out std_logic;
		s00_axi_audioio_wdata	: in std_logic_vector(C_S00_AXI_AudioIO_DATA_WIDTH-1 downto 0);
		s00_axi_audioio_wstrb	: in std_logic_vector((C_S00_AXI_AudioIO_DATA_WIDTH/8)-1 downto 0);
		s00_axi_audioio_wvalid	: in std_logic;
		s00_axi_audioio_wready	: out std_logic;
		s00_axi_audioio_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_audioio_bvalid	: out std_logic;
		s00_axi_audioio_bready	: in std_logic;
		s00_axi_audioio_araddr	: in std_logic_vector(C_S00_AXI_AudioIO_ADDR_WIDTH-1 downto 0);
		s00_axi_audioio_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_audioio_arvalid	: in std_logic;
		s00_axi_audioio_arready	: out std_logic;
		s00_axi_audioio_rdata	: out std_logic_vector(C_S00_AXI_AudioIO_DATA_WIDTH-1 downto 0);
		s00_axi_audioio_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_audioio_rvalid	: out std_logic;
		s00_axi_audioio_rready	: in std_logic
	);
end AXI_AudioIO;

architecture arch_imp of AXI_AudioIO is

	-- component declaration
	component AXI_AudioIO_slave_lite_v1_0_S00_AXI_AudioIO is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 4
		);
		port (
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic;
		
		--ADAU
        AC_ADR0  : out   STD_LOGIC;  -- control signals to ADAU chip
        AC_ADR1  : out   STD_LOGIC;
        AC_GPIO0 : out   STD_LOGIC;  -- I2S MISO
        AC_GPIO1 : in    STD_LOGIC;  -- I2S MOSI
        AC_GPIO2 : in    STD_LOGIC;  -- I2S_bclk
        AC_GPIO3 : in    STD_LOGIC;  -- I2S_LR
        AC_MCLK  : out   STD_LOGIC;
        AC_SCK   : out   STD_LOGIC;
        AC_SDA   : inout STD_LOGIC;
    
        --memory
        data_mem_addr : out std_logic_vector(31 downto 0);
        data_mem_data_out : out std_logic_vector(31 downto 0);
        data_mem_ena : out std_logic;
        data_mem_wea: out std_logic;
    
        --audio from apu interface
        new_sample_pair : in  std_logic;
        sample_pair     : in  std_logic_vector(31 downto 0);
        channel_sel     : in  std_logic
		);
	end component AXI_AudioIO_slave_lite_v1_0_S00_AXI_AudioIO;

begin

-- Instantiation of Axi Bus Interface S00_AXI_AudioIO
AXI_AudioIO_slave_lite_v1_0_S00_AXI_AudioIO_inst : AXI_AudioIO_slave_lite_v1_0_S00_AXI_AudioIO
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_AudioIO_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_AudioIO_ADDR_WIDTH
	)
	port map (
		S_AXI_ACLK	=> s00_axi_audioio_aclk,
		S_AXI_ARESETN	=> s00_axi_audioio_aresetn,
		S_AXI_AWADDR	=> s00_axi_audioio_awaddr,
		S_AXI_AWPROT	=> s00_axi_audioio_awprot,
		S_AXI_AWVALID	=> s00_axi_audioio_awvalid,
		S_AXI_AWREADY	=> s00_axi_audioio_awready,
		S_AXI_WDATA	=> s00_axi_audioio_wdata,
		S_AXI_WSTRB	=> s00_axi_audioio_wstrb,
		S_AXI_WVALID	=> s00_axi_audioio_wvalid,
		S_AXI_WREADY	=> s00_axi_audioio_wready,
		S_AXI_BRESP	=> s00_axi_audioio_bresp,
		S_AXI_BVALID	=> s00_axi_audioio_bvalid,
		S_AXI_BREADY	=> s00_axi_audioio_bready,
		S_AXI_ARADDR	=> s00_axi_audioio_araddr,
		S_AXI_ARPROT	=> s00_axi_audioio_arprot,
		S_AXI_ARVALID	=> s00_axi_audioio_arvalid,
		S_AXI_ARREADY	=> s00_axi_audioio_arready,
		S_AXI_RDATA	=> s00_axi_audioio_rdata,
		S_AXI_RRESP	=> s00_axi_audioio_rresp,
		S_AXI_RVALID	=> s00_axi_audioio_rvalid,
		S_AXI_RREADY	=> s00_axi_audioio_rready,
    
        --ADAU
        AC_ADR0  => AC_ADR0, -- control signals to ADAU chip
        AC_ADR1  => AC_ADR1,
        AC_GPIO0 => AC_GPIO0,  -- I2S MISO
        AC_GPIO1 => AC_GPIO1,  -- I2S MOSI
        AC_GPIO2 => AC_GPIO2,  -- I2S_bclk
        AC_GPIO3 => AC_GPIO3, -- I2S_LR
        AC_MCLK  => AC_MCLK,
        AC_SCK   => AC_SCK,
        AC_SDA   => AC_SDA,
    
        --memory
        data_mem_addr => data_mem_addr,
        data_mem_data_out => data_mem_data_out,
        data_mem_ena => data_mem_ena,
        data_mem_wea => data_mem_wea,
    
        --audio from apu interface
        new_sample_pair => new_sample_pair,
        sample_pair => sample_pair,
        channel_sel => channel_sel
	);

	-- Add user logic here

	-- User logic ends

end arch_imp;
