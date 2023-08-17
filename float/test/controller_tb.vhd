library ieee;
use ieee.std_logic_1164.all;

use work.types.all;

entity controller_tb is
end entity controller_tb;

architecture sim of controller_tb is
    component controller is
        generic (
            CHUNK_SIZE : natural := 1000
        );
        port (
            clk : in std_logic;
    
            m_axis_counter_data : out std_logic_vector(8 downto 0);
            m_axis_counter_last : out std_logic_vector(1 downto 0);
            m_axis_counter_valid : out std_logic;
            m_axis_counter_user : out std_logic_vector(3 downto 0);
            m_axis_weights_ready : in std_logic;
            m_axis_in_hid_ready : in std_logic;
    
            m_axis_dram_control_data : out std_logic_vector(3 downto 0);
            m_axis_dram_control_valid : out std_logic;
            m_axis_dram_control_ready : in std_logic;
    
            post_allowed : out std_logic;
    
            data_bus_state : in std_logic_vector(4 downto 0)
        );
    end component controller;

    constant clk_period : time := 10 ns;
    
    signal clk : std_logic := '0';

    signal m_axis_counter_data : std_logic_vector(8 downto 0);
    signal m_axis_counter_last : last_t;
    signal m_axis_counter_valid : std_logic;
    signal m_axis_counter_user : inference_data_t;
    signal m_axis_weights_ready : std_logic := '0';
    signal m_axis_in_hid_ready : std_logic := '0';

    signal m_axis_dram_control_data : dram_control_t;
    signal m_axis_dram_control_valid : std_logic;
    signal m_axis_dram_control_ready : std_logic := '0';

    signal post_allowed : std_logic;

    signal bus_state : bus_states_t := IDLE;

    signal madcd : std_logic_vector(3 downto 0);
    signal macu : std_logic_vector(3 downto 0);
    signal macl : std_logic_vector(1 downto 0);
begin
    m_axis_dram_control_data <= slv_to_dram_control(madcd);
    m_axis_counter_user <= slv_to_inference_data(macu);
    m_axis_counter_last <= slv_to_last(macl);

    process
        constant weight_wait : natural := 4608;
        variable vector_wait : natural := 12;
        variable initial : boolean;
    begin
        bus_state <= IDLE;

        m_axis_dram_control_ready <= '1';

        if m_axis_dram_control_valid /= '1' then
            wait until m_axis_dram_control_valid = '1';
        end if;

        wait for clk_period;
        initial := m_axis_dram_control_data.initial;
        wait for clk_period;

        m_axis_dram_control_ready <= '0';

        if initial then
            bus_state <= READ_I_IN_W;
            wait for clk_period * weight_wait;
            bus_state <= READ_I_HID_W;
            wait for clk_period * weight_wait;
            bus_state <= READ_F_IN_W;
            wait for clk_period * weight_wait;
            bus_state <= READ_F_HID_W;
            wait for clk_period * weight_wait;
            bus_state <= READ_G_IN_W;
            wait for clk_period * weight_wait;
            bus_state <= READ_G_HID_W;
            wait for clk_period * weight_wait;
            bus_state <= READ_O_IN_W;
            wait for clk_period * weight_wait;
            bus_state <= READ_O_HID_W;
            wait for clk_period * weight_wait;
        else
            bus_state <= READ_C_T;
            wait for clk_period * vector_wait;
            bus_state <= READ_I_B;
            wait for clk_period * vector_wait;
            bus_state <= READ_F_B;
            wait for clk_period * vector_wait;
            bus_state <= READ_G_B;
            wait for clk_period * vector_wait;
            bus_state <= READ_O_B;
            wait for clk_period * vector_wait;
            bus_state <= WRITE_PREV_H;
            wait for clk_period * vector_wait;

            bus_state <= READ_I_IN_W;
            wait for clk_period * weight_wait;
            bus_state <= READ_I_HID_W;
            wait for clk_period * weight_wait;
            bus_state <= READ_F_IN_W;
            wait for clk_period * weight_wait;
            bus_state <= READ_F_HID_W;
            wait for clk_period * weight_wait;
            bus_state <= READ_G_IN_W;
            wait for clk_period * weight_wait;
            bus_state <= READ_G_HID_W;
            wait for clk_period * weight_wait;
            bus_state <= READ_O_IN_W;
            wait for clk_period * weight_wait;
            bus_state <= READ_O_HID_W;
            wait for clk_period * weight_wait;

            bus_state <= READ_NEXT_H;
            wait for clk_period * vector_wait;
            bus_state <= WRITE_C_T;
            wait for clk_period * vector_wait;
        end if;
    end process;

    process
    begin
        m_axis_in_hid_ready <= '1';
        m_axis_weights_ready <= '1';

        if m_axis_counter_last /= SEQ_LAST and m_axis_counter_last /= LAYER_LAST then
            wait until m_axis_counter_last = SEQ_LAST or m_axis_counter_last = LAYER_LAST;
        end if;
        wait for clk_period;

        m_axis_in_hid_ready <= '0';
        m_axis_weights_ready <= '0';

        wait for clk_period * 20;
    end process;
    
    DUT: controller
    generic map (
        CHUNK_SIZE => 1000
    )
    port map (
        clk => clk,
        
        m_axis_counter_data => m_axis_counter_data,
        m_axis_counter_last => macl,
        m_axis_counter_valid => m_axis_counter_valid,
        m_axis_counter_user => macu,
        m_axis_weights_ready => m_axis_weights_ready,
        m_axis_in_hid_ready => m_axis_in_hid_ready,
        
        m_axis_dram_control_data => madcd,
        m_axis_dram_control_valid => m_axis_dram_control_valid,
        m_axis_dram_control_ready => m_axis_dram_control_ready,
        
        post_allowed => post_allowed,
        
        data_bus_state => bus_states_to_slv(bus_state)
    );

    clk <= not clk after clk_period / 2;
    
end architecture sim;