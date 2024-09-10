-----------------------------------------------------------------------------
-- Edge Detector                                                           --
--                                                                         --
-- Author: Juan Encinas <juan.encinas@upm.es>                              --
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity edge_detector is
    port (
        -- Clock and reset signals
        clk   : in std_logic;
        rst_n : in std_logic;
        -- Input signals
        input : in std_logic;
        -- Output pulse
        pulse : out std_logic
    );
    -- DEBUG
    attribute mark_debug : string;
    attribute mark_debug of input : signal is "true";
    attribute mark_debug of pulse : signal is "true";
end edge_detector;

architecture Behavioral of edge_detector is

    -- Signal definitions
    signal r0_input : std_logic;
    signal r1_input : std_logic;
        
    -- DEBUG   
    attribute mark_debug of r0_input : signal is "TRUE";
    attribute mark_debug of r1_input : signal is "TRUE";

begin

    -- Register the input twice
    edge_detection : process(clk, rst_n)
    begin
        -- Asynchronous reset
        if rst_n = '0' then
            -- Reset the registers
            r0_input <= '0';
            r1_input <= '0';
        
        -- Synchronous process
        elsif clk'event and clk = '1' then
            -- Register the input
            r0_input <= input;
            -- Register the signal again
            r1_input <= r0_input;
        end if;
    end process;
    
    -- Generate output pulse when an edge is detected
    pulse <= r1_input xor r0_input;
    
end Behavioral;
