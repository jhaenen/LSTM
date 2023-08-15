library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.types.all;

entity dram_man_tb is
end entity dram_man_tb;

architecture sim of dram_man_tb is
    component dram_manager is
        port (
            clk : in std_logic;
    
            -- DRAM bus interface
            data_bus : inout std_logic_vector(511 downto 0) := (others => 'Z');
            data_bus_valid : inout std_logic := 'Z';
            data_bus_state : out std_logic_vector(4 downto 0);
            data_bus_state_valid : out std_logic := '0';
            data_bus_dest : inout std_logic_vector(18 downto 0) := (others => 'Z');
            data_bus_last : inout std_logic := 'Z';
    
            data_bus_hidden_out_ready : out std_logic;
            data_bus_c_t_ready : out std_logic;

            data_bus_c_and_biases_ready : in std_logic;
            data_bus_weights_ready : in std_logic;
            data_bus_hidden_in_ready : in std_logic;
    
            -- Control interface
            s_axis_control_valid : in std_logic;
            s_axis_control_data : in std_logic_vector(3 downto 0);
            s_axis_control_ready : out std_logic;
    
            -- Read DRAM interface
            s_axis_read_dest : out std_logic_vector(18 downto 0);
            s_axis_read_data : in std_logic_vector(511 downto 0);
            s_axis_read_data_valid : in std_logic;
            s_axis_read_req_valid : out std_logic;
            s_axis_read_req_ready : out std_logic;
            s_axis_read_ready : in std_logic;
            s_axis_read_last : in std_logic;
            s_axis_read_size : out std_logic_vector(2 downto 0);
            s_axis_read_length : out std_logic_vector(7 downto 0);
            s_axis_read_burst : out std_logic_vector(1 downto 0);
            s_axis_read_response : in std_logic_vector(1 downto 0);
    
            -- Write DRAM interface
            s_axis_write_dest : out std_logic_vector(18 downto 0);
            s_axis_write_data : out std_logic_vector(511 downto 0);
            s_axis_write_data_valid : out std_logic;
            s_axis_write_req_valid : out std_logic;
            s_axis_write_ready : in std_logic;
            s_axis_write_last : out std_logic;
            s_axis_write_size : out std_logic_vector(2 downto 0);
            s_axis_write_length : out std_logic_vector(7 downto 0);
            s_axis_write_burst : out std_logic_vector(1 downto 0);
            s_axis_write_strb : out std_logic_vector(63 downto 0);
    
            s_axis_write_response : in std_logic_vector(1 downto 0);
            s_axis_write_response_valid : in std_logic;
            s_axis_write_response_ready : out std_logic
        );
    end component dram_manager;

    constant CLK_PERIOD : time := 10 ns;

    signal clk : std_logic := '0';
    signal data_bus : std_logic_vector(511 downto 0) := (others => 'Z');
    signal data_bus_valid : std_logic := 'Z';
    signal data_bus_state : std_logic_vector(4 downto 0);
    signal bus_state : bus_states_t;
    signal data_bus_state_valid : std_logic;
    signal data_bus_dest : std_logic_vector(18 downto 0) := (others => 'Z');
    signal data_bus_last : std_logic := 'Z';

    signal data_bus_hidden_out_ready : std_logic;
    signal data_bus_c_t_ready : std_logic;

    signal data_bus_c_and_biases_ready : std_logic := '1';
    signal data_bus_weights_ready : std_logic := '1';
    signal data_bus_hidden_in_ready : std_logic := '1';

    signal s_axis_control_valid : std_logic := '0';
    signal s_axis_control_data : dram_control_t := (layer_info => LAYER1, initial => false);
    signal s_axis_control_ready : std_logic;

    signal s_axis_read_dest : std_logic_vector(18 downto 0);
    signal s_axis_read_data : std_logic_vector(511 downto 0) := (others => '0');
    signal s_axis_read_data_valid : std_logic := '0';
    signal s_axis_read_req_valid : std_logic;
    signal s_axis_read_req_ready : std_logic;
    signal s_axis_read_ready : std_logic := '0';
    signal s_axis_read_last : std_logic := '0';
    signal s_axis_read_size : std_logic_vector(2 downto 0);
    signal s_axis_read_length : std_logic_vector(7 downto 0);
    signal s_axis_read_burst : std_logic_vector(1 downto 0);
    signal s_axis_read_response : axi_response_t := OKAY;

    signal s_axis_write_dest : std_logic_vector(18 downto 0);
    signal s_axis_write_data : std_logic_vector(511 downto 0);
    signal s_axis_write_data_valid : std_logic;
    signal s_axis_write_req_valid : std_logic;
    signal s_axis_write_ready : std_logic := '0';
    signal s_axis_write_last : std_logic;
    signal s_axis_write_size : std_logic_vector(2 downto 0);
    signal s_axis_write_length : std_logic_vector(7 downto 0);
    signal s_axis_write_burst : std_logic_vector(1 downto 0);
    signal s_axis_write_strb : std_logic_vector(63 downto 0);

    signal s_axis_write_response : axi_response_t := OKAY;
    signal s_axis_write_response_valid : std_logic := '0';
    signal s_axis_write_response_ready : std_logic;
begin
    bus_state <= slv_to_bus_states(data_bus_state);

    -- Read process
    process
        variable num_reads : integer := 0;

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
    begin
        s_axis_read_data <= (others => '0');
        s_axis_read_data_valid <= '0';
        s_axis_read_ready <= '0';
        s_axis_read_last <= '0';

        if s_axis_read_req_ready /= '1' then
            wait until s_axis_read_req_ready = '1';
        end if;

        s_axis_read_ready <= '1';

        wait until s_axis_read_req_valid = '1';
        num_reads := to_integer(unsigned(s_axis_read_length));

        wait for CLK_PERIOD;

        for i in 0 to num_reads loop
            s_axis_read_data <= rand_slv(512);
            s_axis_read_data_valid <= '1';

            if i = num_reads then
                s_axis_read_last <= '1';
            else 
                s_axis_read_last <= '0';
            end if;

            wait for CLK_PERIOD;
        end loop;
    end process;


    -- Write process
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
    begin
        s_axis_write_ready <= '1';
        data_bus <= (others => 'Z');
        data_bus_valid <= 'Z';
        data_bus_last <= 'Z';
        data_bus_dest <= (others => 'Z');
    
        wait until data_bus_c_t_ready = '1' or data_bus_hidden_out_ready = '1';

        for i in 0 to 11 loop
            data_bus <= rand_slv(512);
            data_bus_valid <= '1';
            data_bus_dest <= std_logic_vector(to_unsigned(i, 19));

            if i = 11 then
                data_bus_last <= '1';
            else 
                data_bus_last <= '0';
            end if;

            wait for CLK_PERIOD;
        end loop;

        while bus_state = WRITE_C_T or bus_state = WRITE_PREV_H loop
            data_bus <= (others => '0');
            data_bus_valid <= '0';
            data_bus_last <= '0';
            data_bus_dest <= (others => '0');
            wait for CLK_PERIOD;
        end loop;
    end process;

    -- DRAM write response process
    process
    begin
        s_axis_write_response_valid <= '0';

        if s_axis_write_response_ready /= '1' then
            wait until s_axis_write_response_ready = '1';
        end if;

        wait until s_axis_write_last = '1';
        wait for CLK_PERIOD;

        s_axis_write_response <= OKAY;
        s_axis_write_response_valid <= '1';

        wait for CLK_PERIOD;
    end process;

    -- Control process
    process
    begin
        wait for CLK_PERIOD * 10;

        if s_axis_control_ready /= '1' then
            wait until s_axis_control_ready = '1';
        end if;

        s_axis_control_data <= (layer_info => LAYER1, initial => true);
        s_axis_control_valid <= '1';

        wait for CLK_PERIOD;

        s_axis_control_valid <= '0';

        wait for CLK_PERIOD * 10;
        wait until s_axis_control_ready = '1';

        s_axis_control_data <= (layer_info => LAYER2, initial => false);
        s_axis_control_valid <= '1';

        wait for CLK_PERIOD;

        s_axis_control_valid <= '0';

        wait;
    end process;

    -- Clock generation
    clk <= not clk after CLK_PERIOD / 2;

    DUT: dram_manager
    port map (
        clk => clk,
        data_bus => data_bus,
        data_bus_valid => data_bus_valid,
        data_bus_state => data_bus_state,
        data_bus_state_valid => data_bus_state_valid,
        data_bus_dest => data_bus_dest,
        data_bus_last => data_bus_last,

        data_bus_hidden_out_ready => data_bus_hidden_out_ready,
        data_bus_c_t_ready => data_bus_c_t_ready,

        data_bus_c_and_biases_ready => data_bus_c_and_biases_ready,
        data_bus_weights_ready => data_bus_weights_ready,
        data_bus_hidden_in_ready => data_bus_hidden_in_ready,

        s_axis_control_valid => s_axis_control_valid,
        s_axis_control_data => dram_control_to_slv(s_axis_control_data),
        s_axis_control_ready => s_axis_control_ready,

        s_axis_read_dest => s_axis_read_dest,
        s_axis_read_data => s_axis_read_data,
        s_axis_read_data_valid => s_axis_read_data_valid,
        s_axis_read_req_valid => s_axis_read_req_valid,
        s_axis_read_req_ready => s_axis_read_req_ready,
        s_axis_read_ready => s_axis_read_ready,
        s_axis_read_last => s_axis_read_last,
        s_axis_read_size => s_axis_read_size,
        s_axis_read_length => s_axis_read_length,
        s_axis_read_burst => s_axis_read_burst,
        s_axis_read_response => axi_response_to_slv(s_axis_read_response),

        s_axis_write_dest => s_axis_write_dest,
        s_axis_write_data => s_axis_write_data,
        s_axis_write_data_valid => s_axis_write_data_valid,
        s_axis_write_req_valid => s_axis_write_req_valid,
        s_axis_write_ready => s_axis_write_ready,
        s_axis_write_last => s_axis_write_last,
        s_axis_write_size => s_axis_write_size,
        s_axis_write_length => s_axis_write_length,
        s_axis_write_burst => s_axis_write_burst,
        s_axis_write_strb => s_axis_write_strb,

        s_axis_write_response => axi_response_to_slv(s_axis_write_response),
        s_axis_write_response_valid => s_axis_write_response_valid,
        s_axis_write_response_ready => s_axis_write_response_ready
    );    
end architecture sim;