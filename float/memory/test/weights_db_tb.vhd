library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.types.all;

entity weights_db_tb is
end entity weights_db_tb;

architecture sim of weights_db_tb is
    component weight_dram_bus is
        port (
            clk : in std_logic;
    
            -- DRAM bus interface
            data_bus : in std_logic_vector(511 downto 0);
            data_bus_valid : in std_logic;
            data_bus_state : in std_logic_vector(3 downto 0);
            data_bus_state_valid : in std_logic;
            data_bus_dest : in std_logic_vector(18 downto 0);
            data_bus_last : in std_logic_vector(1 downto 0);
    
            data_bus_ready : out std_logic;
    
            -- Local interface
            m_axis_weight_data : out std_logic_vector(3071 downto 0);
            m_axis_weight_data_valid : out std_logic;
            m_axis_weight_data_ready : in std_logic;
            m_axis_weight_data_last : out std_logic;
            m_axis_weight_data_dest : out std_logic_vector(9 downto 0);
            m_axis_weight_data_user : out std_logic_vector(2 downto 0)
        );
    end component weight_dram_bus;

    constant clk_period : time := 10 ns;

    signal clk : std_logic := '0';

    signal data_bus : std_logic_vector(511 downto 0) := (others => 'Z');
    signal data_bus_valid : std_logic := 'Z';
    signal data_bus_state : bus_states_t := IDLE;
    signal data_bus_state_valid : std_logic := '1';
    signal data_bus_dest : std_logic_vector(18 downto 0) := (others => 'Z');
    signal data_bus_last : std_logic_vector(1 downto 0) := "ZZ";

    signal data_bus_ready : std_logic;

    signal m_axis_weight_data : std_logic_vector(3071 downto 0);
    signal m_axis_weight_data_valid : std_logic;
    signal m_axis_weight_data_ready : std_logic := '0';
    signal m_axis_weight_data_last : std_logic;
    signal m_axis_weight_data_dest : std_logic_vector(9 downto 0);
    signal m_axis_weight_data_user : std_logic_vector(2 downto 0);
begin
    process
        variable seed1, seed2 : integer := 999;

        impure function rand_slv(len : integer) return std_logic_vector is
            variable r : real;
            variable slv : std_logic_vector(len - 1 downto 0);
        begin
            for i in slv'range loop
            uniform(seed1, seed2, r);
            if r > 0.5 then
                slv(i) := '1';
            else
                slv(i) := '0';
            end if;
            end loop;
            return slv;
        end function;

        function index_to_bus_state(i : integer) return bus_states_t is
            variable state : bus_states_t;
        begin
            case i is
                when 0 =>
                    state := READ_I_IN_W;
                when 1 =>
                    state := READ_I_HID_W;
                when 2 =>
                    state := READ_F_IN_W;
                when 3 =>
                    state := READ_F_HID_W;
                when 4 =>
                    state := READ_G_IN_W;
                when 5 =>
                    state := READ_G_HID_W;
                when 6 =>
                    state := READ_O_IN_W;
                when 7 =>
                    state := READ_O_HID_W;
                when others =>
                    state := IDLE;
            end case;

            return state;
        end function;

    begin
        wait for clk_period * 10;
   
        m_axis_weight_data_ready <= '1';
        for index in 0 to 7 loop
            for i in 0 to 4607 loop
                if data_bus_ready = '0' then
                    data_bus <= (others => 'Z');
                    data_bus_valid <= 'Z';
                    data_bus_state <= IDLE;
                    data_bus_state_valid <= '1';
                    data_bus_dest <= (others => 'Z');
                    data_bus_last <= "ZZ";
                    wait until data_bus_ready = '1';
                    wait for clk_period / 2;
                end if;

                data_bus <= rand_slv(512);
                data_bus_dest <= std_logic_vector(to_unsigned(i, 19));
                data_bus_valid <= '1';
                data_bus_state <= index_to_bus_state(index);

                if i = 4607 then
                    data_bus_last(0) <= '1';
                    if index = 7 then
                        data_bus_last(1) <= '1';
                    else
                        data_bus_last(1) <= '0';
                    end if;
                else
                    data_bus_last <= "00";
                end if;

                wait for clk_period;
            end loop;

            data_bus <= (others => 'Z');
            data_bus_valid <= 'Z';
            data_bus_state <= IDLE;
            data_bus_state_valid <= '1';
            data_bus_dest <= (others => 'Z');
            data_bus_last <= "ZZ";
        end loop;

        wait;
    end process;

    -- Clock process
    process
    begin
        wait for clk_period / 2;
        clk <= not clk;
    end process;

    DUT: weight_dram_bus
    port map (
        clk => clk,

        data_bus => data_bus,
        data_bus_valid => data_bus_valid,
        data_bus_state => bus_states_to_slv(data_bus_state),
        data_bus_state_valid => data_bus_state_valid,
        data_bus_dest => data_bus_dest,
        data_bus_last => data_bus_last,

        data_bus_ready => data_bus_ready,

        m_axis_weight_data => m_axis_weight_data,
        m_axis_weight_data_valid => m_axis_weight_data_valid,
        m_axis_weight_data_ready => m_axis_weight_data_ready,
        m_axis_weight_data_last => m_axis_weight_data_last,
        m_axis_weight_data_dest => m_axis_weight_data_dest,
        m_axis_weight_data_user => m_axis_weight_data_user
    );  
    
end architecture sim;