-----------------------------------------------------------------------------
-- Monitor - Edge Detector Testbench                                       -- 
--                                                                         --
-- Author: Juan Encinas <juan.encinas@upm.es>                              --
--                                                                         --
-- This testbench tests the edge detector module                           --
-----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

entity edge_detector_tb is
end edge_detector_tb;
           
architecture tb of edge_detector_tb is

    -- Clock related signals and constants
    signal clk_tb       : std_logic := '0';
    constant CLK_PERIOD : time := 10 ns;
    constant CLK_DELTA  : time := 0.1 * CLK_PERIOD;
    
    -- Edge detector signals
    signal rst_n_tb : std_logic;
    signal input_tb : std_logic;
    signal pulse_tb : std_logic;

begin

    -- Instantiation of the Unit Under Test (edge detector)
    UUT: entity work.edge_detector
    Port map (
        clk   => clk_tb,
        rst_n => rst_n_tb,
        input => input_tb,
        pulse => pulse_tb
    );
    
    -- Generate TB clock
    clk_tb <= not clk_tb after CLK_PERIOD/2;
    
    -- Generate TB reset
    rst_n_tb <= '0', '1' after 20 ns;
    
    -- TB stimulus
    stimulus: process
    begin
    
        -- Initial values
        input_tb <= '0';
    
        -- Wait for the reset to be released
        wait until rst_n_tb = '1';
        
        -- Test edge detection (there is a 2 clk period delay, because the signal is registered twice)
        input_tb <= '1';
        wait until clk_tb'event and clk_tb = '1';
        wait for CLK_DELTA;
        
        assert pulse_tb = '1'
            report "Edge detection error"
            severity failure;
        
        wait until clk_tb'event and clk_tb = '1';
        wait for CLK_DELTA;
        
        assert pulse_tb = '0'
            report "No edge error"
            severity failure;
            
        input_tb <= '0';
        wait until clk_tb'event and clk_tb = '1';
        wait for CLK_DELTA;
        
        assert pulse_tb = '1'
            report "Edge detection error"
            severity failure;
                    
        wait until clk_tb'event and clk_tb = '1';
        wait for CLK_DELTA;
        
        assert pulse_tb = '0'
            report "No edge error"
            severity failure;
        
        -- Success                
        assert false
            report "Successfully tested!!"
            severity failure;
            
    end process;
            
end tb;

