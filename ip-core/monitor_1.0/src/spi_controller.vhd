-----------------------------------------------------------------------------
-- SPI Controller implementation                                           -- 
--                                                                         --
-- Author: Juan Encinas <juan.encinas@upm.es>                              --
--                                                                         --
-- NOTE: - CS_n negative polatity and SCLK positive polarity are assumed   --
--       - The SPI clock frequency will be the closest_below posible freq  --
--         to be achievable with the CLK_FREQ                              --
--       - SCLK_FREQ should be < CLK_FREQ/2,                               --
--         otherwise SCLK_FREQ = CLK_FREQ/2                                --
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity spi_controller is
    generic (
        CLK_FREQ   : integer := 100; -- Clock frequency in Hz
        SCLK_FREQ  : integer := 20  -- SPI Clock frequency in Hz
    );
    port (
        -- Clock and reset signals
        clk         : in std_logic;
        rst_n       : in std_logic;
        -- Start signal
        start       : in std_logic;
        -- Ready signal
        ready  : out std_logic;
        -- Input data to send
        send_data   : in std_logic_vector (15 downto 0);
        -- Output data read
        recv_data   : out std_logic_vector (15 downto 0);
        
        ---------
        -- SPI --
        ---------
        
        -- Chip select (negative polatiry)
        SPI_CS_n : out STD_LOGIC;
        -- Clock
        SPI_SCLK : out STD_LOGIC;
        -- Master In - Slave Out
        SPI_MISO : in STD_LOGIC;
        -- Master Out - Slave In
        SPI_MOSI : out STD_LOGIC
    );
    -- DEBUG
    attribute mark_debug : string;
    attribute mark_debug of start     : signal is "TRUE";
    attribute mark_debug of ready     : signal is "TRUE";
    attribute mark_debug of send_data : signal is "TRUE";
    attribute mark_debug of recv_data : signal is "TRUE";
    attribute mark_debug of SPI_CS_n  : signal is "TRUE";
    attribute mark_debug of SPI_SCLK  : signal is "TRUE";
    attribute mark_debug of SPI_MISO  : signal is "TRUE";
    attribute mark_debug of SPI_MOSI  : signal is "TRUE";
end spi_controller;

architecture Behavioral of spi_controller is
    
    -----------------------
    -- Frequency divider --
    -----------------------
    
    constant CNT_CLK    : integer := integer(ceil(real(CLK_FREQ)/real(2*SCLK_FREQ)));         -- Compare value to generate falling-edge transitions in SPI clock
    constant CNT_MAX    : integer := 2*CNT_CLK;                                               -- Compare value to generate both rising edge transitions in SPI clock and data transitions in SPI data
    signal cnt          : integer range 0 to CNT_MAX-1;
    signal read_enable  : std_logic;
    signal write_enable : std_logic;
    
    --------------------------
    -- SPI clock generation --
    --------------------------
    
    signal sclk_aux : std_logic;
    
    -----------------------------------------------------
    -- Parallel to Serial and Serial to Parallel logic --
    -----------------------------------------------------
    
    signal write_shift_reg : std_logic_vector(15 downto 0);        
    signal read_shift_reg  : std_logic_vector(15 downto 0);
    signal write_index     : integer range 0 to 15;
    signal read_index      : integer range 0 to 15;
        
    -----------------
    -- Control FSM --
    -----------------
        
    type state_t is (S_WAIT, S_CAPTURE, S_TRANSMIT, S_LATENCY);
    signal state : state_t;   
    
    -------------------------
    -- Input accommodation --
    -------------------------
    
    -- Since the MISO signal comes from outside, it has to be registered twice, and therefore, the read enable must too
    -- Have in mind that since the SCLK is registered to the outside, that adds a cycle of latency for the MISO, since the external peripheral uses the delayed SCLK    
    signal miso_shift_reg        : std_logic_vector(1 downto 0);
    signal miso_s                : std_logic;
    signal read_enable_shift_reg : std_logic_vector(2 downto 0);
    signal read_enable_delayed   : std_logic;
    
    ---------------------
    -- Output register --
    ---------------------
    
    -- These signals are generated with combinational logic and have to be registered before sending them outside the FPGA
    signal sclk_s : std_logic;
    signal mosi_s : std_logic;
    signal cs_n_s : std_logic;
    
    -- DEBUG
    attribute mark_debug of state                 : signal is "TRUE";
    attribute mark_debug of sclk_aux              : signal is "TRUE";
    attribute mark_debug of write_shift_reg       : signal is "TRUE";
    attribute mark_debug of read_shift_reg        : signal is "TRUE";
    attribute mark_debug of write_index           : signal is "TRUE";
    attribute mark_debug of read_index            : signal is "TRUE";
    attribute mark_debug of miso_shift_reg        : signal is "TRUE";
    attribute mark_debug of miso_s                : signal is "TRUE";
    attribute mark_debug of read_enable_shift_reg : signal is "TRUE";
    attribute mark_debug of read_enable_delayed   : signal is "TRUE";
    attribute mark_debug of sclk_s                : signal is "TRUE";
    attribute mark_debug of mosi_s                : signal is "TRUE";
    attribute mark_debug of cs_n_s                : signal is "TRUE";

begin

    -----------------------
    -- Frequency divider --
    -----------------------
    
    freqdiv: process(clk, rst_n)
    begin
        if rst_n = '0' then
            cnt <= 0;
        elsif clk'event and clk = '1' then
            if state = S_TRANSMIT then      
                if cnt = CNT_MAX-1 then
                    cnt <= 0;
                else
                    cnt <= cnt + 1;
                end if;
            end if;
        end if;
    end process;
    
    write_enable <= '1' when cnt = CNT_MAX-1 else '0';
    read_enable  <= '1' when cnt = CNT_CLK-1 else '0';
    
    -- Since the SCLK to the output is registered, the read enable should be delay one clk cycle, to be in sync with the sclk seen by the peripheral
    -- but since the MISO is an external signal and we have to register it twice to remove metastability...
    -- the read must be delayed 3 cycles
    --read_enable  <= '1' when cnt = CNT_CLK+2 else '0';
    
    -- The sclk_aux will toggle one clk clycle later since is clocked (one clock cycle of delay)
    -- That is ideal since these enables are used under a clock to drive the miso and mosi (so will also have one clock cycle of delay9
    -- So sclk miso and mosi will be update on the same clk cycle
    
    --------------------------
    -- SPI clock generation --
    --------------------------
    
    spiclock: process(clk, rst_n)
    begin
        if rst_n = '0' then
            sclk_aux <= '1';
        elsif clk'event and clk = '1' then
            if state = S_TRANSMIT then
                if cnt = CNT_CLK-1 then
                    sclk_aux <= '0';
                end if;
                if cnt = CNT_MAX-1 then
                    sclk_aux <= '1';
                end if;
            end if;
        end if;
    end process;
        
    sclk_s <= sclk_aux when state = S_TRANSMIT else '1';
    
    --------------------------------------------------------------------
    -- Control FSM and parallel to serial and seria to parallel logic --
    --------------------------------------------------------------------
    
    control: process(clk, rst_n)
    variable latency_ack : std_logic;
   begin
        if rst_n = '0' then
            write_shift_reg <= (others => '0');
            read_shift_reg  <= (others => '0');
            write_index     <= 0;
            read_index      <= 0;
            state           <= S_WAIT;
            latency_ack     := '0';
        elsif clk'event and clk = '1' then
            case state is
                when S_WAIT =>
                    if start = '1' then
                        state <= S_CAPTURE;
                    end if;
                when S_CAPTURE =>
                    write_shift_reg <= send_data;
                    read_shift_reg  <= (others => '0');
                    write_index     <= 15;
                    read_index      <= 15;
                    state           <= S_TRANSMIT;
                when S_TRANSMIT =>
                    if read_enable_delayed = '1' then
                        -- Poner un registro de desplazamiento real
                        read_shift_reg(read_index) <= miso_s;
                        if read_index = 0 then
                            latency_ack := '1';
                        else
                            read_index <= read_index - 1;
                        end if;
                    end if;
                    if write_enable = '1' then
                        if write_index = 0 then
                            if latency_ack = '1' then
                                state <= S_WAIT;
                                latency_ack := '0';
                            else
                                state <= S_LATENCY;
                            end if;
                        else
                            write_index <= write_index - 1;
                        end if;
                    end if;
                -- This state is used when the MISO accommodation delay extend the read operation further that the write operation (for small clk_freq/sclk_freq ratios)
                when S_LATENCY =>
                    if read_enable_delayed = '1' then
                        -- Poner un registro de desplazamiento real
                        read_shift_reg(read_index) <= miso_s;
                        if read_index = 0 then
                            state <= S_WAIT;
                        else
                            read_index <= read_index - 1;
                        end if;
                    end if;
            end case;
        end if;
    end process;
    
    ready     <= '1' when state = S_WAIT else '0';
    recv_data <= read_shift_reg when state = S_WAIT else (others => '0');
    
    mosi_s <= write_shift_reg(write_index) when state = S_TRANSMIT else '0';
    cs_n_s <= '0' when state = S_TRANSMIT else '1';
    
    -------------------------
    -- Input accommodation --
    -------------------------
    
    inputreg: process(clk, rst_n)    
    begin
        if rst_n = '0' then
            miso_shift_reg        <= (others => '0');
            read_enable_shift_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if state = S_TRANSMIT or state = S_LATENCY then
                miso_shift_reg        <= miso_shift_reg(0) & SPI_MISO;
                read_enable_shift_reg <= read_enable_shift_reg(1 downto 0) & read_enable;
            else
                miso_shift_reg <= (others => '0');
                read_enable_shift_reg <= (others => '0');
            end if;
        end if;
    end process;
    
    miso_s              <= miso_shift_reg(1);
    read_enable_delayed <= read_enable_shift_reg(2);
         
    ---------------------
    -- Output register --
    ---------------------
    
    outputreg: process(clk, rst_n)
    begin
        if rst_n = '0' then
            SPI_SCLK <= '1';
            SPI_MOSI <= '0';
            SPI_CS_n <= '1';
        elsif clk'event and clk = '1' then
            SPI_SCLK <= sclk_s;
            SPI_MOSI <= mosi_s;
            SPI_CS_n <= cs_n_s;
        end if;
    end process;
                
end Behavioral;
