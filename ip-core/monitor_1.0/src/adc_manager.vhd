-----------------------------------------------------------------------------
-- ADC Manager                                                             --
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
use ieee.math_real.all;

entity adc_manager is
    generic (
        CLK_FREQ           : integer := 100;  -- Clock frequency in Hz
        SCLK_FREQ          : integer := 20;   -- SPI Clock frequency in Hz
        ADC_DUAL           : boolean := true; -- Indicate if the ADC uses two channels (1 and 3) [true] or just one (0-USB) [false]
        ADC_VREF_IS_DOUBLE : boolean := false -- Indicate the ADC voltage reference (false: 2.5V, true: 5.0V)
    );
    port (
        -- Clock and reset signals
        clk         : in std_logic;
        rst_n       : in std_logic;
        -- Configuration signals
        config_vref : in std_logic_vector(1 downto 0);
        -- Enable signal
        en          : in std_logic;
        -- Clear signal to move back to channel 1 (in dual-channel mode)
        clr         : in std_logic;
        -- Ready signal
        ready       : out std_logic;
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
    attribute mark_debug of en        : signal is "TRUE";
    attribute mark_debug of clr       : signal is "TRUE";
    attribute mark_debug of ready     : signal is "TRUE";
    attribute mark_debug of recv_data : signal is "TRUE";
    attribute mark_debug of SPI_CS_n  : signal is "TRUE";
    attribute mark_debug of SPI_SCLK  : signal is "TRUE";
    attribute mark_debug of SPI_MISO  : signal is "TRUE";
    attribute mark_debug of SPI_MOSI  : signal is "TRUE";
end adc_manager;

architecture Behavioral of adc_manager is

    -------------------------
    -- Contant definitions --
    -------------------------

    -- At least 50ns of cooldown
    constant CLK_PERIOD_NS    : real    := real(1000/CLK_FREQ);
    constant COOLDOWN_TIME_NS : integer := 50;
    constant COOLDOWN_CNT_MAX : integer := integer(ceil(real(COOLDOWN_TIME_NS)/CLK_PERIOD_NS)) - 3;

    ------------------------
    -- Signal definitions --
    ------------------------

    -- SPI Management FSM states (IDLE, CAPTURE, WAIT, COOLDOWN)
    type spi_state_t is (S_IDLE, S_CAPTURE, S_WAIT, S_COOLDOWN);
    signal spi_state : spi_state_t;

    -- General FSM states (CONFIGURATION, RUNNING)
    type adc_general_state_t is (S_CONFIGURATION, S_RUNNING);
    signal state : adc_general_state_t;

    -- ADC configuration FSM states (LOAD_CONTROL_REGISTER, LOAD_SHADOW_REGISTER, WAIT_CONFIGURED, START_TRANSMIT)
    type adc_configuration_state_t is (S_LOAD_CONTROL_REGISTER, S_LOAD_SHADOW_REGISTER, S_WAIT_CONFIGURED, S_START_TRANSMIT);
    --type adc_configuration_state_t is (S_LOAD_CONTROL_REGISTER, S_WAIT_CONFIGURED, S_START_TRANSMIT);
    signal configuration_step : adc_configuration_state_t;

    -- Internal SPI enable signal (will be generated on pulses, thus, assigned on each FSM state)
    signal spi_enable    : std_logic;
    -- Internal SPI data ready signal
    signal spi_ready     : std_logic;
    -- Internal SPI send_data signal
    signal spi_send_data : std_logic_vector(15 downto 0);


    -- Cooldown signals
    signal cooldown_cnt : integer range 0 to COOLDOWN_CNT_MAX-1;
    signal cooled       : std_logic;

    -- Internal signals
    signal internal_enable: std_logic;

    -- DEBUG
    attribute mark_debug of spi_state          : signal is "TRUE";
    attribute mark_debug of state              : signal is "TRUE";
    attribute mark_debug of configuration_step : signal is "TRUE";
    attribute mark_debug of spi_enable         : signal is "TRUE";
    attribute mark_debug of spi_ready          : signal is "TRUE";
    attribute mark_debug of spi_send_data      : signal is "TRUE";
    attribute mark_debug of cooldown_cnt       : signal is "TRUE";
    attribute mark_debug of cooled             : signal is "TRUE";

begin

    -- Instantiation of the SPI Controller
    spi_controller: entity work.spi_controller
        generic map (
            CLK_FREQ  => CLK_FREQ,
            SCLK_FREQ => SCLK_FREQ
        )
        port map (
            clk       => clk,
            rst_n     => rst_n,
            start     => spi_enable,
            ready     => spi_ready,
            send_data => spi_send_data,
            recv_data => recv_data,
            SPI_CS_n  => SPI_CS_n,
            SPI_SCLK  => SPI_SCLK,
            SPI_MISO  => SPI_MISO,
            SPI_MOSI  => SPI_MOSI
        );

    -- SPI FSM: Orchestrates the SPI communication and cooldown
    spi_fsm: process(clk, rst_n)
    begin
        -- Asynchronous reset
        if rst_n = '0' then
            -- Set the initial spi state
            spi_state <= S_IDLE;

        -- Synchronous process
        elsif clk'event and clk = '1' then
            case spi_state is

                -- IDLE state
                when S_IDLE =>
                    -- If the internal enable is HIGH go to capture mode
                    if internal_enable = '1' then
                        spi_state  <= S_CAPTURE;
                    end if;

                -- CAPTURE state (this state is used to signal the spi enable for just one cycle)
                when S_CAPTURE =>
                    spi_state <= S_WAIT;

                -- WAIT state
                when S_WAIT =>
                    -- If the SPI communication has finished, move to COOLDOWN state, unless the system clk is so slow that the cooldown has already happened
                    if spi_ready = '1' then
                        if COOLDOWN_CNT_MAX > 0 then
                            spi_state <= S_COOLDOWN;
                        else
                            spi_state <= S_IDLE;
                        end if;
                    end if;

                -- COOLDOWN state
                when S_COOLDOWN =>
                    -- Wait until the cooldown is done
                    if cooled = '1' then
                        spi_state <= S_IDLE;
                    end if;

                -- OTHER states
                when others =>
                    -- Default state
                    spi_state <= S_IDLE;
            end case;
        end if;
    end process;

    -- spi_enable is HIGH just one pulse
    spi_enable <= '1' when spi_state = S_CAPTURE else '0';

    -- Cooldown
    cooldown: process(clk, rst_n)
    begin
        if rst_n = '0' then
            cooldown_cnt <= 0;
        elsif clk'event and clk = '1' then
            if spi_state = S_COOLDOWN then
                if cooldown_cnt = COOLDOWN_CNT_MAX-1 then
                    cooldown_cnt <= 0;
                else
                    cooldown_cnt <= cooldown_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    -- Cooldown finished when the max count is reached
    cooled <= '1' when cooldown_cnt = COOLDOWN_CNT_MAX-1 else '0';


    -- Generate statement to create slightly different HW depending if the ADC works in dual or mono channel
    -- FSM for dual-channel ADC (CH1 & CH3)
    generate_dual_adc_fsm: if ADC_DUAL = true generate

        constant ADC_CONFIGURATION_REG_DUMMY  : std_logic_vector(15 downto 0) := "1111111111110000";  -- First conversion after power-on doesn't matter, all 1s
        constant ADC_CONFIGURATION_REG_STATIC : std_logic_vector(15 downto 0) := "0000000000000000";  -- After the ADC configuration no 1 is send, to ensure no configuration register modification
        constant ADC_CONFIGURATION_REG_VREF   : std_logic_vector(15 downto 0) := "1000001110110000";  -- ADC configuration with (vref = 2,5v, code = binary, shadow = 1)
        constant ADC_CONFIGURATION_REG_2VREF  : std_logic_vector(15 downto 0) := "1000001110010000";  -- ADC configuration with (vref = 5.0v, code = binary, shadow = 1)
        constant ADC_CONFIGURATION_REG_SHADOW : std_logic_vector(15 downto 0) := "0101000000000000";  -- Shadow register value for reading from CH1 and CH3 in sequence

    begin
        -- FSM: Orchestrates the dual-channel ADC functionality
        adc_fsm: process(clk, rst_n)
            -- Determines the current adc configuration step (LOAD_CONTROL_REGISTER, LOAD_SHADOW_REGISTER, WAIT_CONFIGURED, START_TRANSMIT). Stores part of the state in the FSM
            -- This process comes from the AD7928 datasheet (fig. 12)
            variable old_configuration_step : adc_configuration_state_t;
            -- Local spi vref config variable
            variable spi_config_vref        : std_logic_vector(1 downto 0);
        begin

            -- Asynchronous reset
            if rst_n = '0' then
                spi_send_data          <= ADC_CONFIGURATION_REG_DUMMY;
                -- Set the initial general and adc_configuration FSM states
                state                  <= S_CONFIGURATION;
                configuration_step     <= S_LOAD_CONTROL_REGISTER;
                old_configuration_step := S_LOAD_CONTROL_REGISTER;
                spi_config_vref := (others => '0');

            -- Synchronous process
            elsif clk'event and clk = '1' then
                case state is

                    -- CONFIGURATION state
                    when S_CONFIGURATION =>
                        -- This step is divided in different stages since it contains a series of SPI exchanges
                        case configuration_step is

                            -- Configure the control register (vref = <user-defined>, code = binary, shadow = 1)
                            when S_LOAD_CONTROL_REGISTER =>
                                if spi_state = S_IDLE then

                                    -- Configuring VRef = 2.5V (user at run-time)
                                    if spi_config_vref = "01" then
                                        spi_send_data <= ADC_CONFIGURATION_REG_VREF;

                                    -- Configuring VRef = 5.0V (user at run-time)
                                    elsif spi_config_vref = "10" then
                                        spi_send_data <= ADC_CONFIGURATION_REG_2VREF;

                                    -- Configuring VRef based on a generic (user at design-time)
                                    else
                                        if ADC_VREF_IS_DOUBLE = false then
                                            spi_send_data <= ADC_CONFIGURATION_REG_VREF;
                                        elsif ADC_VREF_IS_DOUBLE = true then
                                            spi_send_data <= ADC_CONFIGURATION_REG_2VREF;
                                        end if;
                                    end if;

                                    --Change the FSM state to "start SPI exchange"
                                    configuration_step     <= S_START_TRANSMIT;
                                    old_configuration_step := configuration_step;
                                    -- Reset spi config vref variable
                                    -- spi_config_vref := (others => '0');
                                end if;

                            -- Configure the shadow register (perform a sequence of conversion from CH1 and CH3)
                            when S_LOAD_SHADOW_REGISTER =>
                                if spi_state = S_IDLE then
                                    spi_send_data          <= ADC_CONFIGURATION_REG_SHADOW;
                                    --Change the FSM state to "start SPI exchange"
                                    configuration_step     <= S_START_TRANSMIT;
                                    old_configuration_step := configuration_step;
                                end if;

                            when S_WAIT_CONFIGURED =>
                                if spi_state = S_IDLE then
                                    state              <= S_RUNNING;
                                    configuration_step <= S_LOAD_CONTROL_REGISTER;
                                    -- For the rest of the general FSM states the SPI must send 0s for the ADC to keep the configured sequence
                                    spi_send_data      <= ADC_CONFIGURATION_REG_STATIC;
                                end if;

                            -- Wail until the SPI communication finishes
                            when S_START_TRANSMIT =>

                                -- Change the FSM state to "next configuration step" depending on the previous step
                                case old_configuration_step is
                                    -- From LOAD_CONTROL_REGISTER to LOAD_SHADOW_REGISTER
                                    when S_LOAD_CONTROL_REGISTER =>
                                        configuration_step <= S_LOAD_SHADOW_REGISTER;
                                    -- From LOAD_SHADOW_REGISTER to WAIT_CONFIGURED, since the configuration has finished
                                    when S_LOAD_SHADOW_REGISTER =>
                                        configuration_step <= S_WAIT_CONFIGURED;
                                    -- Should never happen
                                    when others =>
                                        configuration_step <= S_LOAD_CONTROL_REGISTER;
                                        spi_send_data      <= ADC_CONFIGURATION_REG_DUMMY;

                                end case;
                                old_configuration_step := S_START_TRANSMIT;

                            -- Should never happen
                            when others =>
                                spi_send_data          <= ADC_CONFIGURATION_REG_DUMMY;
                                --Change the FSM state to initial step
                                configuration_step     <= S_LOAD_CONTROL_REGISTER;
                                old_configuration_step := S_LOAD_CONTROL_REGISTER;
                                spi_config_vref := (others => '0');
                        end case;

                    -- IDLE state
                    when S_RUNNING =>
                        -- If the user wants to change the ADC configuration
                        if config_vref /= "00" then
                            state <= S_CONFIGURATION;
                            spi_config_vref := config_vref;
                        -- elsif clr = '1' then
                        --     state <= S_CONFIGURATION;
                        end if;

                    -- OTHER states
                    when others =>
                        -- Default states
                        state                  <= S_CONFIGURATION;
                        configuration_step     <= S_LOAD_CONTROL_REGISTER;
                        old_configuration_step := S_LOAD_CONTROL_REGISTER;
                end case;
            end if;
        end process;

    end generate;

    -- FSM for mono-channel ADC (USB-CH0)
    generate_mono_adc_fsm: if ADC_DUAL = false generate

        constant ADC_CONFIGURATION_REG_DUMMY  : std_logic_vector(15 downto 0) := "1111111111110000";  -- First conversion after power-on doesn't matter, all 1s
        constant ADC_CONFIGURATION_REG_STATIC : std_logic_vector(15 downto 0) := "0000000000000000";  -- After the ADC configuration no 1 is send, to ensure no configuration register modification
        constant ADC_CONFIGURATION_REG_VREF   : std_logic_vector(15 downto 0) := "1000001100110000";  -- ADC configuration with (vref = 2,5v, code = binary, shadow = 0, CH0-USB)
        constant ADC_CONFIGURATION_REG_2VREF  : std_logic_vector(15 downto 0) := "1000001100010000";  -- ADC configuration with (vref = 5.0v, code = binary, shadow = 0, CH0-USB)

    begin
        -- FSM: Orchestrates the mono-channel ADC functionality
        mono_adc_fsm: process(clk, rst_n)
            -- Determines the current adc configuration step (LOAD_CONTROL_REGISTER, WAIT_CONFIGURED, START_TRANSMIT). Stores part of the state in the FSM
            -- This process comes from the AD7928 datasheet (fig. 12)
            variable old_configuration_step : adc_configuration_state_t;
            -- Local spi vref config variable
            variable spi_config_vref        : std_logic_vector(1 downto 0);
        begin

            -- Asynchronous reset
            if rst_n = '0' then
                spi_send_data          <= ADC_CONFIGURATION_REG_DUMMY;
                -- Set the initial general and adc_configuration FSM states
                state                  <= S_CONFIGURATION;
                configuration_step     <= S_LOAD_CONTROL_REGISTER;
                old_configuration_step := S_LOAD_CONTROL_REGISTER;
                spi_config_vref := (others => '0');

            -- Synchronous process
            elsif clk'event and clk = '1' then
                case state is

                    -- CONFIGURATION state
                    when S_CONFIGURATION =>
                        -- This step is divided in different stages since it contains a series of SPI exchanges
                        case configuration_step is

                            -- Configure the control register (vref = <user-defined>, code = binary, shadow = 1)
                            when S_LOAD_CONTROL_REGISTER =>
                                if spi_state = S_IDLE then

                                    -- Configuring VRef = 2.5V (user at run-time)
                                    if spi_config_vref = "01" then
                                        spi_send_data <= ADC_CONFIGURATION_REG_VREF;

                                    -- Configuring VRef = 5.0V (user at run-time)
                                    elsif spi_config_vref = "10" then
                                        spi_send_data <= ADC_CONFIGURATION_REG_2VREF;

                                    -- Configuring VRef based on a generic (user at design-time)
                                    else
                                        if ADC_VREF_IS_DOUBLE = false then
                                            spi_send_data <= ADC_CONFIGURATION_REG_VREF;
                                        elsif ADC_VREF_IS_DOUBLE = true then
                                            spi_send_data <= ADC_CONFIGURATION_REG_2VREF;
                                        end if;
                                    end if;

                                    --Change the FSM state to "start SPI exchange"
                                    configuration_step     <= S_START_TRANSMIT;
                                    old_configuration_step := configuration_step;
                                    -- Reset spi config vref variable
                                    -- spi_config_vref := (others => '0');
                                end if;

                            when S_WAIT_CONFIGURED =>
                                if spi_state = S_IDLE then
                                    state              <= S_RUNNING;
                                    configuration_step <= S_LOAD_CONTROL_REGISTER;
                                    -- For the rest of the general FSM states the SPI must send 0s for the ADC to keep the configured sequence
                                    spi_send_data      <= ADC_CONFIGURATION_REG_STATIC;
                                end if;

                            -- Wail until the SPI communication finishes
                            when S_START_TRANSMIT =>

                                -- Change the FSM state to "next configuration step" depending on the previous step
                                case old_configuration_step is
                                    -- From LOAD_CONTROL_REGISTER to WAIT_CONFIGURED
                                    when S_LOAD_CONTROL_REGISTER =>
                                        configuration_step <= S_WAIT_CONFIGURED;
                                    -- Should never happen
                                    when others =>
                                        configuration_step <= S_LOAD_CONTROL_REGISTER;
                                        spi_send_data      <= ADC_CONFIGURATION_REG_DUMMY;

                                end case;
                                old_configuration_step := S_START_TRANSMIT;

                            -- Should never happen
                            when others =>
                                spi_send_data          <= ADC_CONFIGURATION_REG_DUMMY;
                                --Change the FSM state to initial step
                                configuration_step     <= S_LOAD_CONTROL_REGISTER;
                                old_configuration_step := S_LOAD_CONTROL_REGISTER;
                                spi_config_vref := (others => '0');
                        end case;

                    -- IDLE state
                    when S_RUNNING =>
                        -- If the user wants to change the ADC configuration
                        if config_vref /= "00" then
                            state <= S_CONFIGURATION;
                            spi_config_vref := config_vref;
                        end if;

                    -- OTHER states
                    when others =>
                        -- Default states
                        state                  <= S_CONFIGURATION;
                        configuration_step     <= S_LOAD_CONTROL_REGISTER;
                        old_configuration_step := S_LOAD_CONTROL_REGISTER;
                end case;
            end if;
        end process;

    end generate;

    ------------------------
    -- FSM driven signals --
    ------------------------

    internal_enable <= '1'  when configuration_step = S_START_TRANSMIT    else
                       en   when state = S_RUNNING and config_vref = "00" and clr = '0' else
                       '0';

    ready <= '1' when spi_state = S_IDLE and state = S_RUNNING else '0';

end Behavioral;
