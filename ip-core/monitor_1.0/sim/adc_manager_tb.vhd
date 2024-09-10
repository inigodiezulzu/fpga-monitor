-----------------------------------------------------------------------------
-- ADC Manager Testbench                                                   --
--                                                                         --
-- Author: Juan Encinas <juan.encinas@upm.es>                              --
--                                                                         --
-- NOTE: - CS_n negative polatity and SCLK positive polarity are assumed   --
--       - The SPI clock frequency will be the closest_below posible freq  --
--         to achievable with the CLK_FREQ                                 --
--       - SCLK_FREQ should be < CLK_FREQ/2,                               --
--         otherwise SCLK_FREQ = CLK_FREQ/2                                --
-----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;

entity adc_manager_tb is
end adc_manager_tb;

architecture tb of adc_manager_tb is

    -- Clock related signals and constants
    signal clk_tb       : std_logic := '0';
    constant CLK_PERIOD : time := 10 ns;
    constant CLK_DELAY  : time := 0.1 * CLK_PERIOD;
    
    -- Counter signals
    signal rst_n_tb       : std_logic;
    signal config_vref_tb : std_logic_vector(1 downto 0);
    signal en_tb          : std_logic;
    signal clr_tb         : std_logic;
    signal ready_tb       : std_logic;
    signal recv_data_tb   : std_logic_vector(15 downto 0);
    signal SPI_CS_n_tb    : std_logic;
    signal SPI_SCLK_tb    : std_logic;
    signal SPI_MISO_tb    : std_logic := '0';
    signal SPI_MOSI_tb    : std_logic;

begin

    -- Instantiation of the Unit Under Test (adc_manager)
    UUT: entity work.adc_manager
        generic map (
            CLK_FREQ           => 100,
            SCLK_FREQ          => 20,
            ADC_DUAL           => true,
            ADC_VREF_IS_DOUBLE => false
        )
        port map (
            clk         => clk_tb,
            rst_n       => rst_n_tb,
            config_vref => config_vref_tb,
            en          => en_tb,
            clr         => clr_tb,
            ready       => ready_tb,
            recv_data   => recv_data_tb,
            SPI_CS_n    => SPI_CS_n_tb,
            SPI_SCLK    => SPI_SCLK_tb,
            SPI_MISO    => SPI_MISO_tb,
            SPI_MOSI    => SPI_MOSI_tb
        );
    
    -- Generate TB clock
    clk_tb <= not clk_tb after CLK_PERIOD/2;
    
    -- Generate TB MISO
    SPI_MISO_tb <= not SPI_MISO_tb after 8 * CLK_PERIOD;
    
    -- Generate TB reset
    rst_n_tb <= '0', '1' after 20 ns;
    
    -- TB stimulus
    stimulus: process
    begin
    
        -- Initial values
        config_vref_tb <= (others => '0');
        en_tb          <= '0';
        clr_tb         <= '0';
        --SPI_MISO_tb    <= '0';
            
    
        -- Wait for the reset to be released
        wait until rst_n_tb = '1';
        
        -- Wait until the initial configuration has been performed
        wait until ready_tb = '1';
        wait for CLK_DELAY;
                
        wait until clk_tb = '1';
        
        -- Test user vref config
        config_vref_tb <= "01";
        wait until clk_tb = '1';
        config_vref_tb <= "00";
        
        wait until ready_tb = '1';
        wait for CLK_DELAY;
        
        wait until clk_tb = '1';
        
        -- Test user 2vref config
        config_vref_tb <= "10";
        wait until clk_tb = '1';
        config_vref_tb <= "00";
        
        wait until ready_tb = '1';
        wait for CLK_DELAY;
        
        wait for 3 * CLK_PERIOD;
        wait until clk_tb = '1';
        wait for CLK_DELAY;
        
        -- Test capture
        en_tb <= '1';
        
        wait until ready_tb = '1';
        wait until ready_tb = '1';
        wait until ready_tb = '1';
        
        wait for CLK_DELAY;
        
        -- Test IDLE
        en_tb <= '0';
        wait until clk_tb = '1';
       
        wait for 50 * CLK_PERIOD;
       
        -- Test single capture
        wait until clk_tb = '1';
        wait for CLK_DELAY;
       
        en_tb <= '1';
        wait until clk_tb = '1';
        wait for CLK_DELAY;
        en_tb <= '0';
               
        wait until ready_tb = '1';
        wait until clk_tb = '1';
        wait for CLK_DELAY;
        
        en_tb <= '1';
        wait until clk_tb = '1';
        wait for CLK_DELAY;
        en_tb <= '0';
        
        wait until ready_tb = '1';
        wait until clk_tb = '1';
        wait for CLK_DELAY;
        
        en_tb <= '1';
        wait until clk_tb = '1';
        wait for CLK_DELAY;
        en_tb <= '0';
        
        wait until ready_tb = '1';
        wait until clk_tb = '1';
        wait for CLK_DELAY;
              
        en_tb <= '1';
        wait until clk_tb = '1';
        wait for CLK_DELAY;
        en_tb <= '0';
                
        wait until ready_tb = '1';
        wait until clk_tb = '1';
        wait for CLK_DELAY;
                
        wait for 50 * CLK_PERIOD;
        
        -- Test clear
        wait for CLK_DELAY;
        clr_tb <= '1';
        wait until clk_tb = '1';
        wait for CLK_DELAY;
        clr_tb <= '0';
        wait until ready_tb = '1';
        
        wait for 50 * CLK_PERIOD;
        
        wait until clk_tb = '1';
        wait for CLK_DELAY;
              
        -- test configuration priority over enable
        en_tb <= '1';
        wait until clk_tb = '1';
        wait for CLK_DELAY;
                        
        wait until ready_tb = '1';
        
        config_vref_tb <= "01";
        wait until clk_tb = '1';
        config_vref_tb <= "00";
        en_tb <= '0';
                        
        wait until ready_tb = '1';
        
        

        -- Success    
        assert false
            report "Successfully tested!!"
            severity failure;
                  
    end process;
            
end tb;
