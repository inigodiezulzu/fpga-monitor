-----------------------------------------------------------------------------
-- Monitor - Events Detector Testbench                                     -- 
--                                                                         --
-- Author: Juan Encinas <juan.encinas@upm.es>                              --
--                                                                         --
-- This testbench tests the events detector module                         --
-----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity events_detector_tb is
end events_detector_tb;
           
architecture tb of events_detector_tb is

    -- Clock related signals and constants
    signal clk_tb       : std_logic := '0';
    constant CLK_PERIOD : time := 10 ns;
    constant CLK_DELTA  : time := 0.1 * CLK_PERIOD;
    
    -- Edge detector signals
    signal rst_n_tb          : std_logic;
    signal en_tb             : std_logic;
    signal inputs_tb         : std_logic_vector (2 downto 0);
    signal event_detected_tb : std_logic;
    signal edges_tb          : std_logic_vector (2 downto 0);
    signal inputs_delayed_tb : std_logic_vector (2 downto 0);
    
    -- Aux signals
    signal old_inputs : std_logic_vector (2 downto 0);
    
begin

    -- Instantiation of the Unit Under Test (events detector)
    UUT: entity work.events_detector
    Generic map (NUMBER_INPUTS => 3)
    Port map (
        clk            => clk_tb,
        rst_n          => rst_n_tb,
        en             => en_tb,
        inputs         => inputs_tb,
        inputs_delayed => inputs_delayed_tb,
        event_detected => event_detected_tb,
        edges          => edges_tb
    );
    
    -- Generate TB clock
    clk_tb <= not clk_tb after CLK_PERIOD/2;
    
    -- Generate TB reset
    rst_n_tb <= '0', '1' after 20 ns;
    
    -- TB stimulus
    stimulus: process
    begin
        
        -- Initial values
        en_tb     <= '0';
        inputs_tb <= (others => '1'); 
        
        wait for 50 ns;
        
        wait until clk_tb = '1';
        wait for CLK_DELTA;
        
        en_tb <= '1';
        wait until clk_tb'event and clk_tb = '1';
        wait for CLK_DELTA;
                
        -- Test detection
        for i in 0 to 10 loop
        
            -- Store old inputs for debug purpose
            old_inputs <= inputs_tb;
            
            inputs_tb <= std_logic_vector(to_unsigned(i, inputs_tb'length));
                    
            wait until clk_tb'event and clk_tb = '1';
            wait for CLK_DELTA;
            assert event_detected_tb = '1' and edges_tb = (inputs_tb xor old_inputs)
                report "Event detection error"
                severity failure;
            
            wait until clk_tb'event and clk_tb = '1';
            wait for CLK_DELTA;
            assert event_detected_tb = '0' and edges_tb = (edges_tb'range => '0')
                report "Event detection error"
                severity failure;
                
        end loop; 
        
        -- Test enable
        en_tb <= '0';
        wait until clk_tb'event and clk_tb = '1';
        for i in 0 to 10 loop
            
            inputs_tb <= std_logic_vector(to_unsigned(i, inputs_tb'length));
                    
            wait until clk_tb'event and clk_tb = '1';
            wait for CLK_DELTA;
            assert event_detected_tb = '0' and edges_tb = (edges_tb'range => '0')
                report "Enable error"
                severity failure;
                
        end loop; 
                        
        en_tb <= '1';
        wait until clk_tb'event and clk_tb = '1';
        wait for CLK_DELTA;
                
        -- Test detection
        for i in 0 to 10 loop
        
            -- Store old inputs for debug purpose
            old_inputs <= inputs_tb;
            
            inputs_tb <= std_logic_vector(to_unsigned(i, inputs_tb'length));
                    
            wait until clk_tb'event and clk_tb = '1';
            wait for CLK_DELTA;
            assert event_detected_tb = '1' and edges_tb = (inputs_tb xor old_inputs)
                report "Event detection error"
                severity failure;
            
            wait until clk_tb'event and clk_tb = '1';
            wait for CLK_DELTA;
            assert event_detected_tb = '0' and edges_tb = (edges_tb'range => '0')
                report "Event detection error"
                severity failure;
                
        end loop; 
        
        
        -- Success                
        assert false
            report "Successfully tested!!"
            severity failure;
            
    end process;
            
end tb;
