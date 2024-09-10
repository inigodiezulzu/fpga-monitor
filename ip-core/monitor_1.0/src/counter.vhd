-----------------------------------------------------------------------------
-- Counter                                                                 --
--                                                                         --
-- Author: Juan Encinas <juan.encinas@upm.es>                              --
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
    generic (
        BITS : integer := 32 -- Number of bits used by the counter
    );
    port ( 
        -- Clock and reset signals
        clk     : in std_logic;
        rst_n   : in std_logic;
        -- Enable and clear signal
        en      : in std_logic;
        clr     : in std_logic;
        -- Counter output
        count   : out std_logic_vector (BITS-1 downto 0)
    );
    -- DEBUG
    attribute mark_debug : string;
    attribute mark_debug of en    : signal is "TRUE";
    attribute mark_debug of clr   : signal is "TRUE";
    attribute mark_debug of count : signal is "TRUE";
end counter;

architecture Behavioral of counter is

    -- Signal definitions
    signal count_aux    : unsigned(count'RANGE);
    signal count_enable : std_logic;
    
    -- DEBUG
    attribute mark_debug of count_aux    : signal is "TRUE";
    attribute mark_debug of count_enable : signal is "TRUE";

begin

    -- Count process
    count_process : process (clk, rst_n)
    begin
        -- Asynchronous reset
        if rst_n = '0' then
            -- Reset the count
            count_aux <= (others => '0');
            
        -- Sychronous process
        elsif clk'event and clk = '1' then
            -- Reset the count when clr
            if clr = '1' then
                count_aux <= (others => '0');
            -- Increment the count when enable
            elsif en = '1' then
                count_aux <= count_aux + 1;
            end if;
        end if;
    end process;
    
    -- Assign the internal signal to the output port (converting from unsignedl to slv)
    count <= std_logic_vector(count_aux);    

end Behavioral;
