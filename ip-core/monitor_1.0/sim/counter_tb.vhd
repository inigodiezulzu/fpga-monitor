-----------------------------------------------------------------------------
-- Monitor - Counter Testbench                                             -- 
--                                                                         --
-- Author: Juan Encinas <juan.encinas@upm.es>                              --
--                                                                         --
-- This testbench tests the counter module                                 --
-----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter_tb is
end counter_tb;

architecture tb of counter_tb is

    -- Clock related signals and constants
    signal clk_tb       : std_logic := '0';
    constant CLK_PERIOD : time := 10 ns;
    constant CLK_DELTA  : time := 0.1 * CLK_PERIOD;
    
    -- Counter signals
    signal rst_n_tb : std_logic;
    signal en_tb    : std_logic;
    signal clr_tb   : std_logic;
    signal count_tb : std_logic_vector(2 downto 0);

begin

    -- Instantiation of the Unit Under Test (counter)
    UUT: entity work.counter
    Generic map (BITS => 3)
    Port map (
        clk   => clk_tb,
        rst_n => rst_n_tb,
        en    => en_tb,
        clr   => clr_tb,
        count => count_tb
    );
    
    -- Generate TB clock
    clk_tb <= not clk_tb after CLK_PERIOD/2;
    
    -- Generate TB reset
    rst_n_tb <= '0', '1' after 20 ns;
    
    -- TB stimulus
    stimulus: process
    begin
    
        -- Initial values
        clr_tb <= '0';
        en_tb  <= '0';
    
        -- Wait for the reset to be released
        wait until rst_n_tb = '1';
        
        -- Test enable
        for i in 1 to 5 loop
            wait until clk_tb'event and clk_tb = '1';
            wait for CLK_DELTA;
            assert count_tb = std_logic_vector(to_unsigned(0, count_tb'length))
                report "Enable error"
                severity failure;
        end loop; 
        
        -- Test clear
        wait for 15 ns;
        en_tb <= '1';
        
        for i in 1 to 3 loop
            wait until clk_tb'event and clk_tb = '1';
            wait for CLK_DELTA;
            assert count_tb = std_logic_vector(to_unsigned(i, count_tb'length))
                report "Wrong count"
                severity failure;
        end loop;
        
        wait for 10 ns;
        clr_tb <= '1';
        
        wait until clk_tb'event and clk_tb = '1';
        wait for CLK_DELTA;
        assert count_tb = std_logic_vector(to_unsigned(0, count_tb'length))
            report "Clear error"
            severity failure;
        
        wait for 10 ns;
        clr_tb <= '0';
        
        -- Test count
        for i in 1 to 40 loop
            wait until clk_tb'event and clk_tb = '1';
            wait for CLK_DELTA;
            assert count_tb = std_logic_vector(to_unsigned(i mod 8, count_tb'length))
                report "Count error"
                severity failure;
        end loop; 

        -- Success    
        assert false
            report "Successfully tested!!"
            severity failure;
            
    end process;
            
end tb;
