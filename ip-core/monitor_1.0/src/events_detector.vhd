-----------------------------------------------------------------------------
-- Events Detector (combination of Edge Detectors)                         --
--                                                                         --
-- Author: Juan Encinas <juan.encinas@upm.es>                              --
-----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

entity events_detector is
    generic (
        NUMBER_INPUTS : integer := 32 -- Number of bits to perform detection on
    );
    port (
        --Clock and reset signals
        clk              : in std_logic;
        rst_n            : in std_logic;
        -- Enable signal
        en               : in std_logic;
        -- Input signals
        inputs           : in std_logic_vector (NUMBER_INPUTS-1 downto 0);
        -- Delayed inputs
        inputs_delayed   : out std_logic_vector(NUMBER_INPUTS-1 downto 0);
        -- Output detection signal
        event_detected   : out std_logic;
        -- Output edges detected
        edges            : out std_logic_vector(NUMBER_INPUTS-1 downto 0)
    );
    -- DEBUG
    attribute mark_debug : string;
    attribute mark_debug of en             : signal is "true";
    attribute mark_debug of inputs         : signal is "true";
    attribute mark_debug of inputs_delayed : signal is "true";
    attribute mark_debug of event_detected : signal is "true";
    attribute mark_debug of edges          : signal is "true";
end events_detector;

architecture Behavioral of events_detector is

    -- Signal definition
    signal edges_aux       : std_logic_vector(NUMBER_INPUTS-1 downto 0);
    signal internal_en     : std_logic;

    -- DEBUG
    attribute mark_debug of edges_aux   : signal is "TRUE";
    attribute mark_debug of internal_en : signal is "TRUE";

begin

    -- Instatiation of NUMBER_INPUTS Edge Detector modules
    edge_detections: for i in 0 to NUMBER_INPUTS-1 generate
        edge_detector_i: entity work.edge_detector
            port map (
                clk     => clk,
                rst_n   => rst_n,
                input   => inputs(i),
                pulse   => edges_aux(i));
    end generate;

    -- Create a synchronized internal enable signal
    enable_detection: process(clk, rst_n)
    begin
        -- Asynchronous reset
        if rst_n = '0' then
            internal_en <= '0';

        -- Synchronous process
        elsif clk'event and clk = '1' then
            inputs_delayed <= inputs;
            if en = '1' then
                internal_en <= '1';
            else
                internal_en <= '0';
            end if;
        end if;
    end process;

    -- Edges output port
    edges <= edges_aux when internal_en = '1' else (edges'range => '0');

    -- Event detection
    event_detected <= '0' when (edges_aux = (edges_aux'range => '0') or internal_en = '0')  else
                      '1';

end Behavioral;
