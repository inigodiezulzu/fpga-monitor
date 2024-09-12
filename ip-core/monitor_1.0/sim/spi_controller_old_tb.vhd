-----------------------------------------------------------------------------
-- SPI Controller implementation Testbench                                          --
--                                                                         --
-- Author: Juan Encinas <juan.encinas@upm.es>                              --
--                                                                         --
-- NOTE: CS_n negative polatity and SCLK positive polarity are assumed     --
-----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_controller_old_tb is
end spi_controller_old_tb;

architecture tb of spi_controller_old_tb is

    -- Clock related signals and constants
    signal clk_tb       : std_logic := '0';
    constant CLK_PERIOD : time := 10 ns;
    constant CLK_DELTA  : time := 0.1 * CLK_PERIOD;

    -- Counter signals
    signal rst_n_tb      : std_logic;
    signal start_tb      : std_logic;
    signal ready_tb      : std_logic;
    signal send_data_tb  : std_logic_vector(15 downto 0);
    signal recv_data_tb  : std_logic_vector(15 downto 0);
    signal SPI_CS_n_tb   : std_logic;
    signal SPI_SCLK_tb   : std_logic;
    signal SPI_MISO_tb   : std_logic := '0';
    signal SPI_MOSI_tb   : std_logic;

begin

    -- Instantiation of the Unit Under Test (spi_controller_old)
    UUT: entity work.spi_controller_old
        generic map (
            CLK_FREQ   => 100,
            SCLK_FREQ  => 20,
            DATA_WIDTH => 16
        )
        port map (
            clk        => clk_tb,
            rst_n      => rst_n_tb,
            start      => start_tb,
            ready      => ready_tb,
            send_data  => send_data_tb,
            recv_data  => recv_data_tb,
            SPI_CS_n   => SPI_CS_n_tb,
            SPI_SCLK   => SPI_SCLK_tb,
            SPI_MISO   => SPI_MISO_tb,
            SPI_MOSI   => SPI_MOSI_tb
        );

    -- Generate TB clock
    clk_tb <= not clk_tb after CLK_PERIOD/2;

    -- Generate TB reset
    rst_n_tb <= '0', '1' after 20 ns;

    -- TB stimulus
    stimulus: process
    begin

        -- Initial values
        start_tb <= '0';
        send_data_tb <= (others => '0');
        SPI_MISO_tb <= '0';


        -- Wait for the reset to be released
        wait until rst_n_tb = '1';

        wait for 100 ns;

        send_data_tb <= "1011001110001111";

        start_tb <= '1';

        wait until SPI_CS_n_tb = '0';

        --start_tb <= '0';

        -- MISO and MOSI
        for i in 0 to 7 loop
            wait until SPI_SCLK_tb = '0';
            wait for CLK_DELTA;

            assert SPI_MOSI_tb = send_data_tb(16-(2*i+1))
                report "MOSI Error"
                severity failure;

            SPI_MISO_tb <= '1';
            wait until SPI_SCLK_tb = '1';
            wait for CLK_DELTA;

            wait until SPI_SCLK_tb = '0';
            wait for CLK_DELTA;

            assert SPI_MOSI_tb = send_data_tb(16-(2*i+2))
                report "MOSI Error"
                severity failure;

            SPI_MISO_tb <= '0';
            wait until SPI_SCLK_tb = '1';
            wait for CLK_DELTA;
        end loop;

        wait until ready_tb = '1';
        wait for CLK_DELTA;

        assert recv_data_tb = "1010101010101010"
            report "MISO ERROR"
            severity failure;

        wait until ready_tb = '1';
        wait for CLK_DELTA;

        --start_tb <= '1';

        wait until ready_tb = '1';
        wait for CLK_DELTA;

        -- Success
        assert false
            report "Successfully tested!!"
            severity failure;

    end process;

end tb;
