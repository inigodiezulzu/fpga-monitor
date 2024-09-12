library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity monitor_v1_0 is
	generic (
		-- Users to add parameters here
        CLK_FREQ               : integer := 100;        -- Clock frequency in Hz
        SCLK_FREQ              : integer := 20;         -- SPI Clock frequency in Hz
        ADC_ENABLE             : boolean := true;       -- Power consumption monitoring enable (true, false)
        ADC_DUAL               : boolean := true;       -- Indicate if the ADC uses two channels (1 and 3) [true] or just one (0-USB) [false]
        ADC_VREF_IS_DOUBLE     : boolean := false;      -- Indicate the ADC voltage reference (false: 2.5V, true: 5.0V)
        COUNTER_BITS           : integer := 32;         -- Number of bits used for the counter count
        NUMBER_PROBES          : integer := 32;         -- Number of accelerator-related digital probes
        AXI_SNIFFER_ENABLE     : boolean := false;      -- AXI BUS SNIFFER ENABLE (ENABLED, DISABLED)
        AXI_SNIFFER_DATA_WIDTH : integer := 0;          -- AXI bus data width to be sniffed (This should be defined by user in future versions, now is hard-coded)
        POWER_DEPTH            : integer := 64;         -- Number of power measurement to store (maximum)
        TRACES_DEPTH           : integer := 64;         -- Number of traces samples to store (maximum)
		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 4;

		-- Parameters of Axi Slave Bus Interface S01_AXI
		C_S01_AXI_ID_WIDTH	    : integer	:= 1;
		C_S01_AXI_DATA_WIDTH	: integer	:= 32;
		C_S01_AXI_ADDR_WIDTH	: integer	:= 8;  -- ceil(log2(POWER_DEPTH * (C_S01_AXI_DATA_WIDTH/8))) | (Nº data * (nº bytes per data)) -> To num bits
		C_S01_AXI_AWUSER_WIDTH	: integer	:= 0;
		C_S01_AXI_ARUSER_WIDTH	: integer	:= 0;
		C_S01_AXI_WUSER_WIDTH	: integer	:= 0;
		C_S01_AXI_RUSER_WIDTH	: integer	:= 0;
		C_S01_AXI_BUSER_WIDTH	: integer	:= 0;

		-- Parameters of Axi Slave Bus Interface S02_AXI
		C_S02_AXI_ID_WIDTH	    : integer	:= 1;
		C_S02_AXI_DATA_WIDTH	: integer	:= 64;      -- Dependent on the number of probes and counter bits
		C_S02_AXI_ADDR_WIDTH	: integer	:= 9;       -- ceil(log2(TRACES_DEPTH * (C_S01_AXI_DATA_WIDTH/8))) | (Nº data * (nº bytes per data)) -> To num bits
		C_S02_AXI_AWUSER_WIDTH	: integer	:= 0;
		C_S02_AXI_ARUSER_WIDTH	: integer	:= 0;
		C_S02_AXI_WUSER_WIDTH	: integer	:= 0;
		C_S02_AXI_RUSER_WIDTH	: integer	:= 0;
		C_S02_AXI_BUSER_WIDTH	: integer	:= 0;

        -- Parameters of Axi Slave Bus Interface S_SNIFFER_IN
        C_S_SNIFFER_IN_AXI_DATA_WIDTH    : integer    := 32;
        C_S_SNIFFER_IN_AXI_ADDR_WIDTH    : integer    := 32;

        -- Parameters of Axi Master Bus Interface M_SNIFFER_OUT
        C_M_SNIFFER_OUT_AXI_DATA_WIDTH    : integer    := 32;
        C_M_SNIFFER_OUT_AXI_ADDR_WIDTH    : integer    := 32
	);
	port (
		-- Users to add ports here

        ---------
        -- SPI --
        ---------

        -- Chip select (negative polatiry)
        SPI_CS_n  : out STD_LOGIC;
        -- Clock
        SPI_SCLK  : out STD_LOGIC;
        -- Master In - Slave Out
        SPI_MISO  : in STD_LOGIC;
        -- Master Out - Slave In
        SPI_MOSI  : out STD_LOGIC;

        -- Input probes
        probes    : in std_logic_vector(NUMBER_PROBES-1 downto 0);

        -- Interrupt signal (rising-edge sensitive)
        interrupt : out std_logic;

		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic;

		-- Ports of Axi Slave Bus Interface S01_AXI
		s01_axi_aclk	: in std_logic;
		s01_axi_aresetn	: in std_logic;
		s01_axi_awid	: in std_logic_vector(C_S01_AXI_ID_WIDTH-1 downto 0);
		s01_axi_awaddr	: in std_logic_vector(C_S01_AXI_ADDR_WIDTH-1 downto 0);
		s01_axi_awlen	: in std_logic_vector(7 downto 0);
		s01_axi_awsize	: in std_logic_vector(2 downto 0);
		s01_axi_awburst	: in std_logic_vector(1 downto 0);
		s01_axi_awlock	: in std_logic;
		s01_axi_awcache	: in std_logic_vector(3 downto 0);
		s01_axi_awprot	: in std_logic_vector(2 downto 0);
		s01_axi_awqos	: in std_logic_vector(3 downto 0);
		s01_axi_awregion	: in std_logic_vector(3 downto 0);
		s01_axi_awuser	: in std_logic_vector(C_S01_AXI_AWUSER_WIDTH-1 downto 0);
		s01_axi_awvalid	: in std_logic;
		s01_axi_awready	: out std_logic;
		s01_axi_wdata	: in std_logic_vector(C_S01_AXI_DATA_WIDTH-1 downto 0);
		s01_axi_wstrb	: in std_logic_vector((C_S01_AXI_DATA_WIDTH/8)-1 downto 0);
		s01_axi_wlast	: in std_logic;
		s01_axi_wuser	: in std_logic_vector(C_S01_AXI_WUSER_WIDTH-1 downto 0);
		s01_axi_wvalid	: in std_logic;
		s01_axi_wready	: out std_logic;
		s01_axi_bid	: out std_logic_vector(C_S01_AXI_ID_WIDTH-1 downto 0);
		s01_axi_bresp	: out std_logic_vector(1 downto 0);
		s01_axi_buser	: out std_logic_vector(C_S01_AXI_BUSER_WIDTH-1 downto 0);
		s01_axi_bvalid	: out std_logic;
		s01_axi_bready	: in std_logic;
		s01_axi_arid	: in std_logic_vector(C_S01_AXI_ID_WIDTH-1 downto 0);
		s01_axi_araddr	: in std_logic_vector(C_S01_AXI_ADDR_WIDTH-1 downto 0);
		s01_axi_arlen	: in std_logic_vector(7 downto 0);
		s01_axi_arsize	: in std_logic_vector(2 downto 0);
		s01_axi_arburst	: in std_logic_vector(1 downto 0);
		s01_axi_arlock	: in std_logic;
		s01_axi_arcache	: in std_logic_vector(3 downto 0);
		s01_axi_arprot	: in std_logic_vector(2 downto 0);
		s01_axi_arqos	: in std_logic_vector(3 downto 0);
		s01_axi_arregion	: in std_logic_vector(3 downto 0);
		s01_axi_aruser	: in std_logic_vector(C_S01_AXI_ARUSER_WIDTH-1 downto 0);
		s01_axi_arvalid	: in std_logic;
		s01_axi_arready	: out std_logic;
		s01_axi_rid	: out std_logic_vector(C_S01_AXI_ID_WIDTH-1 downto 0);
		s01_axi_rdata	: out std_logic_vector(C_S01_AXI_DATA_WIDTH-1 downto 0);
		s01_axi_rresp	: out std_logic_vector(1 downto 0);
		s01_axi_rlast	: out std_logic;
		s01_axi_ruser	: out std_logic_vector(C_S01_AXI_RUSER_WIDTH-1 downto 0);
		s01_axi_rvalid	: out std_logic;
		s01_axi_rready	: in std_logic;

		-- Ports of Axi Slave Bus Interface S02_AXI
		s02_axi_aclk	: in std_logic;
		s02_axi_aresetn	: in std_logic;
		s02_axi_awid	: in std_logic_vector(C_S02_AXI_ID_WIDTH-1 downto 0);
		s02_axi_awaddr	: in std_logic_vector(C_S02_AXI_ADDR_WIDTH-1 downto 0);
		s02_axi_awlen	: in std_logic_vector(7 downto 0);
		s02_axi_awsize	: in std_logic_vector(2 downto 0);
		s02_axi_awburst	: in std_logic_vector(1 downto 0);
		s02_axi_awlock	: in std_logic;
		s02_axi_awcache	: in std_logic_vector(3 downto 0);
		s02_axi_awprot	: in std_logic_vector(2 downto 0);
		s02_axi_awqos	: in std_logic_vector(3 downto 0);
		s02_axi_awregion	: in std_logic_vector(3 downto 0);
		s02_axi_awuser	: in std_logic_vector(C_S02_AXI_AWUSER_WIDTH-1 downto 0);
		s02_axi_awvalid	: in std_logic;
		s02_axi_awready	: out std_logic;
		s02_axi_wdata	: in std_logic_vector(C_S02_AXI_DATA_WIDTH-1 downto 0);
		s02_axi_wstrb	: in std_logic_vector((C_S02_AXI_DATA_WIDTH/8)-1 downto 0);
		s02_axi_wlast	: in std_logic;
		s02_axi_wuser	: in std_logic_vector(C_S02_AXI_WUSER_WIDTH-1 downto 0);
		s02_axi_wvalid	: in std_logic;
		s02_axi_wready	: out std_logic;
		s02_axi_bid	: out std_logic_vector(C_S02_AXI_ID_WIDTH-1 downto 0);
		s02_axi_bresp	: out std_logic_vector(1 downto 0);
		s02_axi_buser	: out std_logic_vector(C_S02_AXI_BUSER_WIDTH-1 downto 0);
		s02_axi_bvalid	: out std_logic;
		s02_axi_bready	: in std_logic;
		s02_axi_arid	: in std_logic_vector(C_S02_AXI_ID_WIDTH-1 downto 0);
		s02_axi_araddr	: in std_logic_vector(C_S02_AXI_ADDR_WIDTH-1 downto 0);
		s02_axi_arlen	: in std_logic_vector(7 downto 0);
		s02_axi_arsize	: in std_logic_vector(2 downto 0);
		s02_axi_arburst	: in std_logic_vector(1 downto 0);
		s02_axi_arlock	: in std_logic;
		s02_axi_arcache	: in std_logic_vector(3 downto 0);
		s02_axi_arprot	: in std_logic_vector(2 downto 0);
		s02_axi_arqos	: in std_logic_vector(3 downto 0);
		s02_axi_arregion	: in std_logic_vector(3 downto 0);
		s02_axi_aruser	: in std_logic_vector(C_S02_AXI_ARUSER_WIDTH-1 downto 0);
		s02_axi_arvalid	: in std_logic;
		s02_axi_arready	: out std_logic;
		s02_axi_rid	: out std_logic_vector(C_S02_AXI_ID_WIDTH-1 downto 0);
		s02_axi_rdata	: out std_logic_vector(C_S02_AXI_DATA_WIDTH-1 downto 0);
		s02_axi_rresp	: out std_logic_vector(1 downto 0);
		s02_axi_rlast	: out std_logic;
		s02_axi_ruser	: out std_logic_vector(C_S02_AXI_RUSER_WIDTH-1 downto 0);
		s02_axi_rvalid	: out std_logic;
		s02_axi_rready	: in std_logic;

		-- Ports of Axi Slave Bus Interface S_SNIFFER_IN
        s_sniffer_in_axi_aclk       : in std_logic;
        s_sniffer_in_axi_aresetn    : in std_logic;
        s_sniffer_in_axi_awaddr     : in std_logic_vector(C_S_SNIFFER_IN_AXI_ADDR_WIDTH-1 downto 0);
        s_sniffer_in_axi_awprot     : in std_logic_vector(2 downto 0);
        s_sniffer_in_axi_awvalid    : in std_logic;
        s_sniffer_in_axi_awready    : out std_logic;
        s_sniffer_in_axi_wdata      : in std_logic_vector(C_S_SNIFFER_IN_AXI_DATA_WIDTH-1 downto 0);
        s_sniffer_in_axi_wstrb      : in std_logic_vector((C_S_SNIFFER_IN_AXI_DATA_WIDTH/8)-1 downto 0);
        s_sniffer_in_axi_wvalid     : in std_logic;
        s_sniffer_in_axi_wready     : out std_logic;
        s_sniffer_in_axi_bresp      : out std_logic_vector(1 downto 0);
        s_sniffer_in_axi_bvalid     : out std_logic;
        s_sniffer_in_axi_bready     : in std_logic;
        s_sniffer_in_axi_araddr     : in std_logic_vector(C_S_SNIFFER_IN_AXI_ADDR_WIDTH-1 downto 0);
        s_sniffer_in_axi_arprot     : in std_logic_vector(2 downto 0);
        s_sniffer_in_axi_arvalid    : in std_logic;
        s_sniffer_in_axi_arready    : out std_logic;
        s_sniffer_in_axi_rdata      : out std_logic_vector(C_S_SNIFFER_IN_AXI_DATA_WIDTH-1 downto 0);
        s_sniffer_in_axi_rresp      : out std_logic_vector(1 downto 0);
        s_sniffer_in_axi_rvalid     : out std_logic;
        s_sniffer_in_axi_rready     : in std_logic;

        -- Ports of Axi Master Bus Interface M_SNIFFER_OUT
        m_sniffer_out_axi_aclk       : in std_logic;
        m_sniffer_out_axi_aresetn    : in std_logic;
        m_sniffer_out_axi_awaddr    : out std_logic_vector(C_M_SNIFFER_OUT_AXI_ADDR_WIDTH-1 downto 0);
        m_sniffer_out_axi_awprot    : out std_logic_vector(2 downto 0);
        m_sniffer_out_axi_awvalid   : out std_logic;
        m_sniffer_out_axi_awready   : in std_logic;
        m_sniffer_out_axi_wdata     : out std_logic_vector(C_M_SNIFFER_OUT_AXI_DATA_WIDTH-1 downto 0);
        m_sniffer_out_axi_wstrb     : out std_logic_vector((C_M_SNIFFER_OUT_AXI_DATA_WIDTH/8)-1 downto 0);
        m_sniffer_out_axi_wvalid    : out std_logic;
        m_sniffer_out_axi_wready    : in std_logic;
        m_sniffer_out_axi_bresp     : in std_logic_vector(1 downto 0);
        m_sniffer_out_axi_bvalid    : in std_logic;
        m_sniffer_out_axi_bready    : out std_logic;
        m_sniffer_out_axi_araddr    : out std_logic_vector(C_M_SNIFFER_OUT_AXI_ADDR_WIDTH-1 downto 0);
        m_sniffer_out_axi_arprot    : out std_logic_vector(2 downto 0);
        m_sniffer_out_axi_arvalid   : out std_logic;
        m_sniffer_out_axi_arready   : in std_logic;
        m_sniffer_out_axi_rdata     : in std_logic_vector(C_M_SNIFFER_OUT_AXI_DATA_WIDTH-1 downto 0);
        m_sniffer_out_axi_rresp     : in std_logic_vector(1 downto 0);
        m_sniffer_out_axi_rvalid    : in std_logic;
        m_sniffer_out_axi_rready    : out std_logic


	);
end monitor_v1_0;

architecture arch_imp of monitor_v1_0 is

    ----------------------
    -- Internal signals --
    ----------------------
    signal user_config_vref        : std_logic_vector(1 downto 0);
    signal start                   : std_logic;
    signal stop                    : std_logic;
    signal probes_aux              : std_logic_vector(NUMBER_PROBES + AXI_SNIFFER_DATA_WIDTH - 1 downto 0);
    signal probes_mask             : std_logic_vector(NUMBER_PROBES-1 downto 0);
    signal axi_sniffer_en          : std_logic;
    signal axi_sniffer_mask        : std_logic_vector(AXI_SNIFFER_DATA_WIDTH-1 downto 0);
    signal busy                    : std_logic;
    signal done                    : std_logic;
    signal count                   : std_logic_vector(COUNTER_BITS-1 downto 0);
    signal power_errors            : std_logic_vector(C_S01_AXI_ADDR_WIDTH-1 downto 0);
    signal power_bram_read_en      : std_logic;
    signal traces_bram_read_en     : std_logic;
    signal power_bram_read_addr    : std_logic_vector(C_S01_AXI_ADDR_WIDTH-1 downto 0);
    signal traces_bram_read_addr   : std_logic_vector(C_S02_AXI_ADDR_WIDTH-1 downto 0);
    signal power_bram_read_dout    : std_logic_vector(C_S01_AXI_DATA_WIDTH-1 downto 0);
    signal traces_bram_read_dout   : std_logic_vector(C_S02_AXI_DATA_WIDTH-1 downto 0);
	signal power_bram_utilization  : std_logic_vector(C_S01_AXI_ADDR_WIDTH-1 downto 0);
	signal traces_bram_utilization : std_logic_vector(C_S02_AXI_ADDR_WIDTH-1 downto 0);

    -- AXI sniffer signal
    signal axi_sniffer_signals     : std_logic_vector(AXI_SNIFFER_DATA_WIDTH-1 downto 0);

    -- Interrupt signal
    signal interrupt_s : std_logic; -- Internal signal to generate interrupt requests to an external uP

    -- DEBUG
    attribute mark_debug : string;
    attribute mark_debug of user_config_vref        : signal is "true";
    attribute mark_debug of start                   : signal is "true";
    attribute mark_debug of stop                    : signal is "true";
    attribute mark_debug of probes_aux              : signal is "true";
    attribute mark_debug of probes_mask             : signal is "true";
    attribute mark_debug of axi_sniffer_en          : signal is "true";
    attribute mark_debug of axi_sniffer_mask        : signal is "true";
    attribute mark_debug of busy                    : signal is "true";
    attribute mark_debug of done                    : signal is "true";
    attribute mark_debug of count                   : signal is "true";
    attribute mark_debug of power_bram_read_en      : signal is "true";
    attribute mark_debug of traces_bram_read_en     : signal is "true";
    attribute mark_debug of power_bram_read_addr    : signal is "true";
    attribute mark_debug of traces_bram_read_addr   : signal is "true";
    attribute mark_debug of power_bram_read_dout    : signal is "true";
    attribute mark_debug of traces_bram_read_dout   : signal is "true";
    attribute mark_debug of power_bram_utilization  : signal is "true";
    attribute mark_debug of traces_bram_utilization : signal is "true";
    attribute mark_debug of interrupt_s 	        : signal is "true";

begin

    -- Instantiation of AXI Bus Interface S00_AXI
    monitor_control : entity work.monitor_control
        generic map (
            COUNTER_BITS              => COUNTER_BITS,
            NUMBER_PROBES             => NUMBER_PROBES,
            AXI_SNIFFER_ENABLE        => AXI_SNIFFER_ENABLE,
            AXI_SNIFFER_DATA_WIDTH    => AXI_SNIFFER_DATA_WIDTH,
            POWER_BRAM_ADDRESS_WIDTH  => C_S01_AXI_ADDR_WIDTH,
            TRACES_BRAM_ADDRESS_WIDTH => C_S02_AXI_ADDR_WIDTH,
            C_S_AXI_DATA_WIDTH        => C_S00_AXI_DATA_WIDTH,
            C_S_AXI_ADDR_WIDTH        => C_S00_AXI_ADDR_WIDTH
        )
        port map (
            user_start              => start,
            user_stop               => stop,
            user_config_vreg        => user_config_vref(0),
            user_config_2vreg       => user_config_vref(1),
            user_axi_sniffer_mask   => axi_sniffer_mask,
            user_axi_sniffer_enable => axi_sniffer_en,
            user_probes_mask        => probes_mask,
            device_busy             => busy,
            user_done               => done,
            user_count              => count,
            user_power_errors       => power_errors,
            user_power_bram_utilization		=> power_bram_utilization,
            user_traces_bram_utilization	=> traces_bram_utilization,
            S_AXI_ACLK	=> s00_axi_aclk,
            S_AXI_ARESETN	=> s00_axi_aresetn,
            S_AXI_AWADDR	=> s00_axi_awaddr,
            S_AXI_AWPROT	=> s00_axi_awprot,
            S_AXI_AWVALID	=> s00_axi_awvalid,
            S_AXI_AWREADY	=> s00_axi_awready,
            S_AXI_WDATA	=> s00_axi_wdata,
            S_AXI_WSTRB	=> s00_axi_wstrb,
            S_AXI_WVALID	=> s00_axi_wvalid,
            S_AXI_WREADY	=> s00_axi_wready,
            S_AXI_BRESP	=> s00_axi_bresp,
            S_AXI_BVALID	=> s00_axi_bvalid,
            S_AXI_BREADY	=> s00_axi_bready,
            S_AXI_ARADDR	=> s00_axi_araddr,
            S_AXI_ARPROT	=> s00_axi_arprot,
            S_AXI_ARVALID	=> s00_axi_arvalid,
            S_AXI_ARREADY	=> s00_axi_arready,
            S_AXI_RDATA	=> s00_axi_rdata,
            S_AXI_RRESP	=> s00_axi_rresp,
            S_AXI_RVALID	=> s00_axi_rvalid,
            S_AXI_RREADY	=> s00_axi_rready
        );

    -- Instantiation of Axi Bus Interface S01_AXI
    power_enabler: if ADC_ENABLE = true generate

        monitor_power_data : entity work.monitor_power_data
            generic map (
                C_S_AXI_ID_WIDTH	=> C_S01_AXI_ID_WIDTH,
                C_S_AXI_DATA_WIDTH	=> C_S01_AXI_DATA_WIDTH,
                C_S_AXI_ADDR_WIDTH	=> C_S01_AXI_ADDR_WIDTH,
                C_S_AXI_AWUSER_WIDTH	=> C_S01_AXI_AWUSER_WIDTH,
                C_S_AXI_ARUSER_WIDTH	=> C_S01_AXI_ARUSER_WIDTH,
                C_S_AXI_WUSER_WIDTH	=> C_S01_AXI_WUSER_WIDTH,
                C_S_AXI_RUSER_WIDTH	=> C_S01_AXI_RUSER_WIDTH,
                C_S_AXI_BUSER_WIDTH	=> C_S01_AXI_BUSER_WIDTH
            )
            port map (
                power_bram_read_en   => power_bram_read_en,
                power_bram_read_addr => power_bram_read_addr,
                power_bram_read_dout => power_bram_read_dout,
                S_AXI_ACLK	=> s01_axi_aclk,
                S_AXI_ARESETN	=> s01_axi_aresetn,
                S_AXI_AWID	=> s01_axi_awid,
                S_AXI_AWADDR	=> s01_axi_awaddr,
                S_AXI_AWLEN	=> s01_axi_awlen,
                S_AXI_AWSIZE	=> s01_axi_awsize,
                S_AXI_AWBURST	=> s01_axi_awburst,
                S_AXI_AWLOCK	=> s01_axi_awlock,
                S_AXI_AWCACHE	=> s01_axi_awcache,
                S_AXI_AWPROT	=> s01_axi_awprot,
                S_AXI_AWQOS	=> s01_axi_awqos,
                S_AXI_AWREGION	=> s01_axi_awregion,
                S_AXI_AWUSER	=> s01_axi_awuser,
                S_AXI_AWVALID	=> s01_axi_awvalid,
                S_AXI_AWREADY	=> s01_axi_awready,
                S_AXI_WDATA	=> s01_axi_wdata,
                S_AXI_WSTRB	=> s01_axi_wstrb,
                S_AXI_WLAST	=> s01_axi_wlast,
                S_AXI_WUSER	=> s01_axi_wuser,
                S_AXI_WVALID	=> s01_axi_wvalid,
                S_AXI_WREADY	=> s01_axi_wready,
                S_AXI_BID	=> s01_axi_bid,
                S_AXI_BRESP	=> s01_axi_bresp,
                S_AXI_BUSER	=> s01_axi_buser,
                S_AXI_BVALID	=> s01_axi_bvalid,
                S_AXI_BREADY	=> s01_axi_bready,
                S_AXI_ARID	=> s01_axi_arid,
                S_AXI_ARADDR	=> s01_axi_araddr,
                S_AXI_ARLEN	=> s01_axi_arlen,
                S_AXI_ARSIZE	=> s01_axi_arsize,
                S_AXI_ARBURST	=> s01_axi_arburst,
                S_AXI_ARLOCK	=> s01_axi_arlock,
                S_AXI_ARCACHE	=> s01_axi_arcache,
                S_AXI_ARPROT	=> s01_axi_arprot,
                S_AXI_ARQOS	=> s01_axi_arqos,
                S_AXI_ARREGION	=> s01_axi_arregion,
                S_AXI_ARUSER	=> s01_axi_aruser,
                S_AXI_ARVALID	=> s01_axi_arvalid,
                S_AXI_ARREADY	=> s01_axi_arready,
                S_AXI_RID	=> s01_axi_rid,
                S_AXI_RDATA	=> s01_axi_rdata,
                S_AXI_RRESP	=> s01_axi_rresp,
                S_AXI_RLAST	=> s01_axi_rlast,
                S_AXI_RUSER	=> s01_axi_ruser,
                S_AXI_RVALID	=> s01_axi_rvalid,
                S_AXI_RREADY	=> s01_axi_rready
            );
    end generate;

    -- Instantiation of Axi Bus Interface S02_AXI
    monitor_traces_data : entity work.monitor_traces_data
        generic map (
            C_S_AXI_ID_WIDTH	=> C_S02_AXI_ID_WIDTH,
            C_S_AXI_DATA_WIDTH	=> C_S02_AXI_DATA_WIDTH,
            C_S_AXI_ADDR_WIDTH	=> C_S02_AXI_ADDR_WIDTH,
            C_S_AXI_AWUSER_WIDTH	=> C_S02_AXI_AWUSER_WIDTH,
            C_S_AXI_ARUSER_WIDTH	=> C_S02_AXI_ARUSER_WIDTH,
            C_S_AXI_WUSER_WIDTH	=> C_S02_AXI_WUSER_WIDTH,
            C_S_AXI_RUSER_WIDTH	=> C_S02_AXI_RUSER_WIDTH,
            C_S_AXI_BUSER_WIDTH	=> C_S02_AXI_BUSER_WIDTH
        )
        port map (
            traces_bram_read_en   => traces_bram_read_en,
            traces_bram_read_addr => traces_bram_read_addr,
            traces_bram_read_dout => traces_bram_read_dout,
            S_AXI_ACLK	=> s02_axi_aclk,
            S_AXI_ARESETN	=> s02_axi_aresetn,
            S_AXI_AWID	=> s02_axi_awid,
            S_AXI_AWADDR	=> s02_axi_awaddr,
            S_AXI_AWLEN	=> s02_axi_awlen,
            S_AXI_AWSIZE	=> s02_axi_awsize,
            S_AXI_AWBURST	=> s02_axi_awburst,
            S_AXI_AWLOCK	=> s02_axi_awlock,
            S_AXI_AWCACHE	=> s02_axi_awcache,
            S_AXI_AWPROT	=> s02_axi_awprot,
            S_AXI_AWQOS	=> s02_axi_awqos,
            S_AXI_AWREGION	=> s02_axi_awregion,
            S_AXI_AWUSER	=> s02_axi_awuser,
            S_AXI_AWVALID	=> s02_axi_awvalid,
            S_AXI_AWREADY	=> s02_axi_awready,
            S_AXI_WDATA	=> s02_axi_wdata,
            S_AXI_WSTRB	=> s02_axi_wstrb,
            S_AXI_WLAST	=> s02_axi_wlast,
            S_AXI_WUSER	=> s02_axi_wuser,
            S_AXI_WVALID	=> s02_axi_wvalid,
            S_AXI_WREADY	=> s02_axi_wready,
            S_AXI_BID	=> s02_axi_bid,
            S_AXI_BRESP	=> s02_axi_bresp,
            S_AXI_BUSER	=> s02_axi_buser,
            S_AXI_BVALID	=> s02_axi_bvalid,
            S_AXI_BREADY	=> s02_axi_bready,
            S_AXI_ARID	=> s02_axi_arid,
            S_AXI_ARADDR	=> s02_axi_araddr,
            S_AXI_ARLEN	=> s02_axi_arlen,
            S_AXI_ARSIZE	=> s02_axi_arsize,
            S_AXI_ARBURST	=> s02_axi_arburst,
            S_AXI_ARLOCK	=> s02_axi_arlock,
            S_AXI_ARCACHE	=> s02_axi_arcache,
            S_AXI_ARPROT	=> s02_axi_arprot,
            S_AXI_ARQOS	=> s02_axi_arqos,
            S_AXI_ARREGION	=> s02_axi_arregion,
            S_AXI_ARUSER	=> s02_axi_aruser,
            S_AXI_ARVALID	=> s02_axi_arvalid,
            S_AXI_ARREADY	=> s02_axi_arready,
            S_AXI_RID	=> s02_axi_rid,
            S_AXI_RDATA	=> s02_axi_rdata,
            S_AXI_RRESP	=> s02_axi_rresp,
            S_AXI_RLAST	=> s02_axi_rlast,
            S_AXI_RUSER	=> s02_axi_ruser,
            S_AXI_RVALID	=> s02_axi_rvalid,
            S_AXI_RREADY	=> s02_axi_rready
        );

	-- Add user logic

    -- Instantiate the monitor logic
    monitor : entity work.monitor
        generic map (
            CLK_FREQ               => CLK_FREQ,
            SCLK_FREQ              => SCLK_FREQ,
            ADC_ENABLE             => ADC_ENABLE,
            ADC_DUAL               => ADC_DUAL,
            ADC_VREF_IS_DOUBLE     => ADC_VREF_IS_DOUBLE,
            COUNTER_BITS           => COUNTER_BITS,
            NUMBER_PROBES          => NUMBER_PROBES,
            AXI_SNIFFER_ENABLE     => AXI_SNIFFER_ENABLE,
            AXI_SNIFFER_DATA_WIDTH => AXI_SNIFFER_DATA_WIDTH,
            POWER_DATA_WIDTH       => C_S01_AXI_DATA_WIDTH,
            POWER_ADDR_WIDTH       => C_S01_AXI_ADDR_WIDTH,
            POWER_DEPTH            => POWER_DEPTH,
            TRACES_DATA_WIDTH      => C_S02_AXI_DATA_WIDTH,
            TRACES_ADDR_WIDTH      => C_S02_AXI_ADDR_WIDTH,
            TRACES_DEPTH           => TRACES_DEPTH
        )
        port map (
            clk              => s00_axi_aclk,
            rst_n            => s00_axi_aresetn,
            user_config_vref => user_config_vref,
            start            => start,
            stop             => stop,
            probes           => probes_aux,
            probes_mask      => probes_mask,
            axi_sniffer_en   => axi_sniffer_en,
            axi_sniffer_mask => axi_sniffer_mask,
            busy             => busy,
            done             => done,
            count            => count,
            power_errors     => power_errors,
            -- BRAMs
            power_bram_read_en      => power_bram_read_en,
            traces_bram_read_en     => traces_bram_read_en,
            power_bram_read_addr    => power_bram_read_addr,
            traces_bram_read_addr   => traces_bram_read_addr,
            power_bram_read_dout    => power_bram_read_dout,
            traces_bram_read_dout   => traces_bram_read_dout,
            -- BRAM utilization indicators (last written address)
            power_bram_utilization  => power_bram_utilization,
            traces_bram_utilization => traces_bram_utilization,
            -- SPI
            SPI_MISO => SPI_MISO,
            SPI_CS_n => SPI_CS_n,
            SPI_SCLK => SPI_SCLK,
            SPI_MOSI => SPI_MOSI
        );

      -- Probes aux
      probes_aux <= probes & axi_sniffer_signals;

    ---------------------
    -- Interrupt logic --
    ---------------------

    -- Rising-edge sensitive interrupt generation logic.
    interrupt_gen: process(s00_axi_aclk)
        variable done_reg : std_logic;
    begin
        if s00_axi_aclk'event and s00_axi_aclk = '1' then
            if s00_axi_aresetn = '0' then
                interrupt_s <= '0';
                done_reg:= '0';
            else
                -- Interrupt generation
                interrupt_s <= '0';
                -- Interrupts are generated whenever a change in the done bit
                if done /= done_reg and done = '1' then
                    interrupt_s <= '1';
                end if;
                -- Whe have to register the done value to check if it changes.
                done_reg := done;
            end if;
        end if;
    end process;

    -- Connect internal signal with output port
    interrupt <= interrupt_s;

    -- AXI BUS SNIFFER LOGIC
    axi_sniffer_enabler: if AXI_SNIFFER_ENABLE = true generate

        -- This should be configurable from the user side in a future version
        axi_sniffer_signals <= s_sniffer_in_axi_awaddr(21 downto 0) & s_sniffer_in_axi_wdata(7 downto 0) & s_sniffer_in_axi_wvalid & m_sniffer_out_axi_wready;

        -- bypass
        m_sniffer_out_axi_awaddr  <= s_sniffer_in_axi_awaddr;
        m_sniffer_out_axi_awprot  <= s_sniffer_in_axi_awprot;
        m_sniffer_out_axi_awvalid <= s_sniffer_in_axi_awvalid;
        s_sniffer_in_axi_awready  <= m_sniffer_out_axi_awready;
        m_sniffer_out_axi_wdata   <= s_sniffer_in_axi_wdata;
        m_sniffer_out_axi_wstrb   <= s_sniffer_in_axi_wstrb;
        m_sniffer_out_axi_wvalid  <= s_sniffer_in_axi_wvalid;
        s_sniffer_in_axi_wready   <= m_sniffer_out_axi_wready;
        s_sniffer_in_axi_bresp    <= m_sniffer_out_axi_bresp;
        s_sniffer_in_axi_bvalid   <= m_sniffer_out_axi_bvalid;
        m_sniffer_out_axi_bready  <= s_sniffer_in_axi_bready;
        m_sniffer_out_axi_araddr  <= s_sniffer_in_axi_araddr;
        m_sniffer_out_axi_arprot  <= s_sniffer_in_axi_arprot;
        m_sniffer_out_axi_arvalid <= s_sniffer_in_axi_arvalid;
        s_sniffer_in_axi_arready  <= m_sniffer_out_axi_arready;
        s_sniffer_in_axi_rdata    <= m_sniffer_out_axi_rdata;
        s_sniffer_in_axi_rresp    <= m_sniffer_out_axi_rresp;
        s_sniffer_in_axi_rvalid   <= m_sniffer_out_axi_rvalid;
        m_sniffer_out_axi_rready  <= s_sniffer_in_axi_rready;

    end generate;

    -- User logic ends

end arch_imp;
