-----------------------------------------------------------------------------
-- Monitor - Probes Trigger Module Testbench                               -- 
--                                                                         --
-- Author: Juan Encinas <juan.encinas@upm.es>                              --
--                                                                         --
-- This testbench tests the probes trigger module                          --
-----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity probes_trigger_module_tb is
end probes_trigger_module_tb;
           
architecture tb of probes_trigger_module_tb is

    -- Clock related signals and constants
    signal clk_tb       : std_logic := '0';
    constant CLK_PERIOD : time := 10 ns;
    constant CLK_DELTA  : time := 0.1 * CLK_PERIOD;
    
    -- Edge detector signals
    signal rst_n_tb   : std_logic;
    signal en_tb      : std_logic;
    signal inputs_tb  : std_logic_vector (2 downto 0);
    signal mask_tb    : std_logic_vector (2 downto 0);
    signal trigger_tb : std_logic;
    
begin

    -- Instantiation of the Unit Under Test (probes trigger module)
    UUT: entity work.probes_trigger_module
    Generic map (NUMBER_INPUTS => 3)
    Port map (
        clk     => clk_tb,
        rst_n   => rst_n_tb,
        en      => en_tb,
        inputs  => inputs_tb,
        mask    => mask_tb,
        trigger => trigger_tb
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
        inputs_tb <= (others => '0'); 
        mask_tb   <= (others => '0');
        
        wait for 50 ns;
        
        en_tb <= '1';
        wait until clk_tb'event and clk_tb = '1';
        wait for CLK_DELTA;
        
        
        wait for 50 ns;
                
        -- Test trigger
       
        for i in 0 to 7 loop
        
            mask_tb <= std_logic_vector(to_unsigned(i, mask_tb'length));  
            wait until clk_tb'event and clk_tb = '1';
            wait for CLK_DELTA;
        
            for j in 0 to 7 loop
                inputs_tb <= std_logic_vector(to_unsigned(j, inputs_tb'length));        
                wait until clk_tb'event and clk_tb = '1';
                wait for CLK_DELTA;
                
                if (inputs_tb and mask_tb) > (inputs_tb'range => '0') then
                    assert trigger_tb = '1'
                        report "Trigger ON error"
                        severity failure;
                else
                    assert trigger_tb = '0'
                        report "Trigger OFF error"
                        severity failure;
                end if;
           end loop;
            
        end loop;
        
        -- Success                
        assert false
            report "Successfully tested!!"
            severity failure;
            
    end process;
            
end tb;
