-----------------------------------------------------------------------------
-- AXI Trigger Module                                                      --
--                                                                         --
-- Author: Juan Encinas <juan.encinas@upm.es>                              --
--                                                                         --
-- TODO: Make this triggering module more inteligent                       --
--                                                                         --
-- This module detects when the AXI inputs state exactly matches a         --
-- user-defined mask                                                       --
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity axi_trigger_module is
    generic (
        NUMBER_INPUTS : integer := 32 -- Number of input bits
    );
    port (
        -- Clock and reset signals
        clk     : in std_logic;
        rst_n   : in std_logic;
        -- Enable signal
        en      : in std_logic;
        -- Input signals
        inputs  : in std_logic_vector (NUMBER_INPUTS-1 downto 0);
        -- Comparison mask
        mask    : in std_logic_vector (NUMBER_INPUTS-1 downto 0);
        -- Output trigger detection
        trigger : out std_logic
    );
    -- DEBUG
    attribute mark_debug : string;
    attribute mark_debug of en      : signal is "TRUE";
    attribute mark_debug of inputs  : signal is "TRUE";
    attribute mark_debug of mask    : signal is "TRUE";
    attribute mark_debug of trigger : signal is "TRUE";
end axi_trigger_module;

architecture Behavioral of axi_trigger_module is

begin

    -- Create a synchronized internal enable signal
    trigger_detection_enable: process(clk, rst_n)
        begin
            -- Asynchronous reset
            if rst_n = '0' then
                -- Trigger is 0 by default
                trigger <= '0';

            -- Synchronous process
            elsif clk'event and clk = '1' then
                -- Detection is only performed when enabled
                if en = '1' then
                    -- Trigger is HIGH when the inputs matches the mask, LOW otherwise
                    if inputs = mask then
                        trigger <= '1';
                    else
                        trigger <= '0';
                    end if;
                else
                    trigger <= '0';
                end if;
            end if;
    end process;

end Behavioral;
