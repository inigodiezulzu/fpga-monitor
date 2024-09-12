-----------------------------------------------------------------------------
-- Monitor Infrastucture Testbench                                         --
--                                                                         --
-- Author: Juan Encinas <juan.encinas@upm.es>                              --
--                                                                         --
-- NOTE: - Traces have one clock cycle of delay                            --
--       - After done = '1' a stop = '1' is needed to move back to IDLE    --
--       - CS_n negative polatity and SCLK positive polarity are assumed   --
--       - The SPI clock frequency will be the closest_below posible freq  --
--         to achievable with the CLK_FREQ                                 --
--       - SCLK_FREQ should be < CLK_FREQ/2,                               --
--         otherwise SCLK_FREQ = CLK_FREQ/2                                --
-----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;

entity monitor_tb is
end monitor_tb;

architecture tb of monitor_tb is

    -- Clock related signals and constants
    signal clk_tb       : std_logic := '0';
    constant CLK_PERIOD : time := 10 ns;
    constant CLK_DELAY  : time := 0.1 * CLK_PERIOD;
    constant ADC_ENABLE : boolean := true;
    constant ADC_DUAL   : boolean := true;

    -- Counter signals
    signal rst_n_tb                   : std_logic;
    signal user_config_vref_tb        : std_logic_vector(1 downto 0);
    signal start_tb                   : std_logic;
    signal stop_tb                    : std_logic;
    signal probes_tb                  : std_logic_vector(6 downto 0) := "0000000";
    signal probes_mask_tb             : std_logic_vector(1 downto 0);
    signal axi_sniffer_en_tb          : std_logic;
    signal axi_sniffer_mask_tb        : std_logic_vector(4 downto 0);
    signal busy_tb                    : std_logic;
    signal done_tb                    : std_logic;
    signal count_tb                   : std_logic_vector(31 downto 0);
    signal power_errors               : std_logic_vector(6 downto 0);
    signal power_bram_read_en_tb      : std_logic := '0';
    signal traces_bram_read_en_tb     : std_logic := '0';
    signal power_bram_read_addr_tb    : std_logic_vector(6 downto 0) := (others => '0');
    signal traces_bram_read_addr_tb   : std_logic_vector(31 downto 0) := (others => '0');
    signal power_bram_read_dout_tb    : std_logic_vector(31 downto 0);
    signal traces_bram_read_dout_tb   : std_logic_vector(63 downto 0);
    signal power_bram_utilization_tb  : std_logic_vector(6 downto 0);
    signal traces_bram_utilization_tb : std_logic_vector(31 downto 0);
    signal SPI_CS_n_tb                : std_logic;
    signal SPI_SCLK_tb                : std_logic;
    signal SPI_MISO_tb                : std_logic := '0';
    signal SPI_MOSI_tb                : std_logic;

begin

    -- Instantiation of the Unit Under Test (monitor)
    UUT: entity work.monitor
        generic map (
            CLK_FREQ               => 100,
            SCLK_FREQ              => 20,
            ADC_ENABLE             => ADC_ENABLE,
            ADC_DUAL               => ADC_DUAL,
            ADC_VREF_IS_DOUBLE     => false,
            COUNTER_BITS           => 32,
            NUMBER_PROBES          => 2,
            AXI_SNIFFER_ENABLE     => true,
            AXI_SNIFFER_DATA_WIDTH => 5,
            POWER_DATA_WIDTH       => 32,
            POWER_ADDR_WIDTH       => 7,
            POWER_DEPTH            => 12,
            TRACES_DATA_WIDTH      => 64,
            TRACES_ADDR_WIDTH      => 32,
            TRACES_DEPTH           => 20
        )
        port map (
            clk                     => clk_tb,
            rst_n                   => rst_n_tb,
            user_config_vref        => user_config_vref_tb,
            start                   => start_tb,
            stop                    => stop_tb,
            probes                  => probes_tb,
            probes_mask             => probes_mask_tb,
            axi_sniffer_en          => axi_sniffer_en_tb,
            axi_sniffer_mask        => axi_sniffer_mask_tb,
            busy                    => busy_tb,
            done                    => done_tb,
            count                   => count_tb,
            power_errors            => power_errors,
            power_bram_read_en      => power_bram_read_en_tb,
            traces_bram_read_en     => traces_bram_read_en_tb,
            power_bram_read_addr    => power_bram_read_addr_tb,
            traces_bram_read_addr   => traces_bram_read_addr_tb,
            power_bram_read_dout    => power_bram_read_dout_tb,
            traces_bram_read_dout   => traces_bram_read_dout_tb,
            power_bram_utilization  => power_bram_utilization_tb,
            traces_bram_utilization => traces_bram_utilization_tb,
            SPI_CS_n                => SPI_CS_n_tb,
            SPI_SCLK                => SPI_SCLK_tb,
            SPI_MISO                => SPI_MISO_tb,
            SPI_MOSI                => SPI_MOSI_tb
        );

    -- Generate TB clock
    clk_tb <= not clk_tb after CLK_PERIOD/2;

    -- Generate TB reset
    rst_n_tb <= '0', '1' after 20 ns;

    -- TB stimulus
    stimulus: process
    begin

        -- Initial values
        user_config_vref_tb <= "00";
        start_tb            <= '0';
        stop_tb             <= '0';
        probes_tb           <= (others => '0');
        probes_mask_tb      <= (others => '0');
        axi_sniffer_en_tb   <= '0';
        axi_sniffer_mask_tb <= (others => '0');

        -- Wait for ADC to be initially configured
        wait until busy_tb = '0';
        wait for CLK_DELAY;

        -- Test user configuration
        user_config_vref_tb <= "01";
        wait until clk_tb = '1';
        wait for CLK_DELAY;
        user_config_vref_tb <= "00";

        assert busy_tb = '1' and done_tb = '0'
            report "User config error!"
            severity failure;

        wait until busy_tb = '0';
        wait for CLK_DELAY;

        -- Test start
        start_tb <= '1';
        wait until clk_tb = '1';
        wait for CLK_DELAY;
        start_tb <= '0';

        assert busy_tb = '1' and done_tb = '0'
            report "Start error!"
            severity failure;

        -- Test stop (full power)
        wait until done_tb = '1';

        wait for 50 * CLK_PERIOD;
        stop_tb <= '1';
        wait until clk_tb = '1';
        wait for CLK_DELAY;
        stop_tb <= '0';

        wait until clk_tb = '1';
        wait for CLK_DELAY;

        if ADC_DUAL = true then
            assert done_tb = '0'
                report "Stop error!"
                severity failure;
            wait until busy_tb = '0';
        else
            assert busy_tb = '0' and done_tb = '0'
                report "Stop error!"
                severity failure;
        end if;

        wait for 50 * CLK_PERIOD;
        wait until clk_tb = '1';
        wait for CLK_DELAY;

        -- Test probe start
        probes_mask_tb <= "01";
        wait until clk_tb = '1';
        wait for CLK_DELAY;

        probes_tb(6) <= '1';
        wait until clk_tb = '1';
        wait for CLK_DELAY;

        assert busy_tb = '0' and done_tb = '0'
            report "false start"
            severity failure;

        wait for 5 * CLK_PERIOD;
        wait until clk_tb = '1';
        wait for CLK_DELAY;

        probes_tb(5) <= '1';
        wait until clk_tb = '1';
        wait for CLK_DELAY;
        probes_tb(5) <= '0';

        -- There is one clk cycle of delay (changing state)
        wait until clk_tb = '1';
        wait for CLK_DELAY;

        assert busy_tb = '1' and done_tb = '0'
            report "No-start error"
            severity failure;

        for i in 0 to 19 loop

            probes_tb(5) <= not probes_tb(5);
            wait until clk_tb = '1';
            wait for CLK_DELAY;

        end loop;

        -- There is one cycle of delay
        wait until clk_tb = '1';
        wait for CLK_PERIOD;

        assert done_tb = '1'
            report "Traces Full error"
            severity failure;

        wait until clk_tb = '1';
        wait for CLK_DELAY;
        stop_tb <= '1';
        wait until clk_tb = '1';
        wait for CLK_DELAY;
        stop_tb <= '0';

        wait until busy_tb = '0';
        wait for 5 * CLK_PERIOD;

        -- Test AXI start
        axi_sniffer_en_tb   <= '1';
        probes_mask_tb <= "00";
        axi_sniffer_mask_tb <= "11100";
        wait until clk_tb = '1';
        wait for CLK_DELAY;

        probes_tb(0) <= '1';
        wait until clk_tb = '1';
        wait for CLK_DELAY;

        assert busy_tb = '0' and done_tb = '0'
            report "false start"
            severity failure;

        wait for 5 * CLK_PERIOD;
        wait until clk_tb = '1';
        wait for CLK_DELAY;

        probes_tb(4 downto 0) <= "11100";
        wait until clk_tb = '1';
        wait for CLK_DELAY;
        probes_tb(4 downto 0) <= "00000";

        -- There is one clk cycle of delay (changing state)
        wait until clk_tb = '1';
        wait for CLK_DELAY;

        assert busy_tb = '1' and done_tb = '0'
            report "No-start error"
            severity failure;

        for i in 0 to 19 loop

            probes_tb(4 downto 0) <= not probes_tb(4 downto 0);
            wait until clk_tb = '1';
            wait for CLK_DELAY;

        end loop;

        -- There is one cycle of delay
        wait until clk_tb = '1';
        wait for CLK_PERIOD;

        assert done_tb = '1'
            report "Traces Full error"
            severity failure;

        wait until clk_tb = '1';
        wait for CLK_DELAY;
        stop_tb <= '1';
        wait until clk_tb = '1';
        wait for CLK_DELAY;
        stop_tb <= '0';

        wait until busy_tb = '0';
        wait for 5 * CLK_PERIOD;

        -- Success
        assert false
            report "Successfully tested!!"
            severity failure;

    end process;

end tb;
