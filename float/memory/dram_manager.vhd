library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.util_pkg.all;
use work.types.all;

entity dram_manager is
    port (
        clk : in std_logic;

        -- DRAM bus interface
        data_bus : inout std_logic_vector(511 downto 0) := (others => 'Z');
        data_bus_valid : inout std_logic := 'Z';
        data_bus_state : out std_logic_vector(4 downto 0);
        data_bus_state_valid : out std_logic := '0';
        data_bus_dest : inout std_logic_vector(18 downto 0) := (others => 'Z');
        data_bus_last : inout std_logic_vector(1 downto 0) := (others => 'Z');

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
end entity dram_manager;

architecture behav of dram_manager is
    constant vector_size : natural := 12;
    constant weight_size : natural := 4608;

    constant read_size : natural := clogb2(512 / 8);
    constant read_burst_v : std_logic_vector(1 downto 0) := "01";

    type data_t is (C_T, H_T,
                    I_BIAS, F_BIAS, G_BIAS, O_BIAS, 
                    I_INPUT_WEIGHT, F_INPUT_WEIGHT, G_INPUT_WEIGHT, O_INPUT_WEIGHT,
                    I_HIDDEN_WEIGHT, F_HIDDEN_WEIGHT, G_HIDDEN_WEIGHT, O_HIDDEN_WEIGHT);

    type dram_address_t is record
        index : natural range 0 to weight_size - 1;
        data : data_t;
        layer : layer_info_t;
    end record;

    function data_t_to_slv(data : data_t) return std_logic_vector is
        variable result : std_logic_vector(2 downto 0);
    begin
        case data is
            when C_T => result := "000";
            when H_T => result := "001";
            when I_BIAS => result := "010";
            when F_BIAS => result := "011";
            when G_BIAS => result := "100";
            when O_BIAS => result := "101";
            when I_INPUT_WEIGHT => result := "110";
            when F_INPUT_WEIGHT => result := "111";
            when G_INPUT_WEIGHT => result := "000";
            when O_INPUT_WEIGHT => result := "001";
            when I_HIDDEN_WEIGHT => result := "010";
            when F_HIDDEN_WEIGHT => result := "011";
            when G_HIDDEN_WEIGHT => result := "100";
            when O_HIDDEN_WEIGHT => result := "101";
            when others => result := (others => 'X');
        end case;
        return result;
    end function;

    function dram_address_to_slv(address : dram_address_t) return std_logic_vector is
        variable result : std_logic_vector(18 downto 0);
    begin
        result := std_logic_vector(to_unsigned(address.index, 19));
        result(18 downto 16) := layer_info_to_slv(address.layer);
        result(15 downto 13) := data_t_to_slv(address.data);
        return result;
    end function;

    function calc_axi_read_length(current_index: in natural; length: in natural) return natural is
        constant max_read_length : natural := 256;
        variable result : natural := 0;
    begin
        if length > max_read_length then
            if length - current_index > max_read_length then
                result := max_read_length;
            else
                result := length - current_index;
            end if;
        else
            result := length;
        end if;

        return result;
    end function;

    signal next_bus_state : bus_states_t := IDLE;
    signal bus_state : bus_states_t := IDLE;

    signal initial_layer : boolean := true;
    signal current_layer : layer_info_t := LAYER1;
begin
    data_bus_state <= bus_states_to_slv(bus_state);

    process(clk)
        variable read_counter : natural range 0 to weight_size - 1 := 0;
        variable read_req : boolean := true;

        type write_state_t is (DB_REQUEST_DATA, DRAM_WRITE);
        variable write_state : write_state_t := DB_REQUEST_DATA;
        variable write_req : boolean := true;

        variable write_ready : boolean := false;

        procedure read_request(data_type : in data_t; layer : in layer_info_t; read_length : in natural; next_state : in bus_states_t; last : in boolean) is
            variable read_address : dram_address_t := (index => 0, data => O_INPUT_WEIGHT, layer => LAYER3);
            variable read_response : axi_response_t := OKAY;
        begin
            s_axis_read_req_ready <= '1';
            if s_axis_read_ready = '1' then
                if read_req then
                    read_address.index := read_counter;
                    read_address.data := data_type;
                    read_address.layer := layer;

                    s_axis_read_dest <= dram_address_to_slv(read_address);
                    s_axis_read_size <= std_logic_vector(to_unsigned(read_size, 3));
                    s_axis_read_length <= std_logic_vector(to_unsigned(calc_axi_read_length(read_counter, read_length) - 1, 8));
                    s_axis_read_burst <= read_burst_v;

                    s_axis_read_req_valid <= '1';
                    read_req := false;

                    -- Disable the data bus
                    data_bus <= (others => '0');
                    data_bus_last <= (others => '0');
                    data_bus_valid <= '0';
                    data_bus_dest <= (others => '0');
                else
                    s_axis_read_req_valid <= '0';

                    read_response := slv_to_axi_response(s_axis_read_response);
                    if s_axis_read_data_valid = '1' and read_response = OKAY then
                        data_bus <= s_axis_read_data;
                        data_bus_valid <= '1';
                        data_bus_dest <= std_logic_vector(to_unsigned(read_counter, 19));

                        read_counter := read_counter + 1;

                        if s_axis_read_last = '1' then
                            read_req := true;

                            if read_counter >= read_length then
                                next_bus_state <= next_state;
                                data_bus_last(0) <= '1';
                                read_counter := 0;

                                if last then
                                    data_bus_last(1) <= '1';
                                else
                                    data_bus_last(1) <= '0';
                                end if;
                            else
                                data_bus_last <= (others => '0');
                            end if;
                        end if;
                    else
                        data_bus <= (others => '0');
                        data_bus_last <= (others => '0');
                        data_bus_valid <= '0';
                        data_bus_dest <= (others => '0');
                    end if;
                end if; 
            else
                data_bus <= (others => '0');
                data_bus_valid <= '0';
                data_bus_last <= (others => '0');
                data_bus_dest <= (others => '0');
            end if;

            data_bus_c_t_ready <= '0';
            data_bus_hidden_out_ready <= '0';

            s_axis_write_dest <= (others => '0');
            s_axis_write_data <= (others => '0');
            s_axis_write_data_valid <= '0';
            s_axis_write_req_valid <= '0';
            s_axis_write_last <= '0';
            s_axis_write_size <= (others => '0');
            s_axis_write_length <= (others => '0');
            s_axis_write_burst <= (others => '0');
            s_axis_write_strb <= (others => '0');
            s_axis_write_response_ready <= '0';
        end procedure;

        procedure write_request(data_type : in data_t; layer : in layer_info_t; next_state : in bus_states_t) is
            variable write_address : dram_address_t := (index => 0, data => O_INPUT_WEIGHT, layer => LAYER3);
            variable response : axi_response_t := OKAY;
        begin
            if not write_ready then
                write_ready := true;

                data_bus <= (others => 'Z');
                data_bus_last <= (others => 'Z');
                data_bus_valid <= 'Z';
                data_bus_dest <= (others => 'Z');

                s_axis_write_data_valid <= '0';
                s_axis_write_req_valid <= '0';
                s_axis_write_response_ready <= '0';
                data_bus_c_t_ready <= '0';
                data_bus_hidden_out_ready <= '0';
            else
                if s_axis_write_ready = '1' then
                    case data_type is
                        when C_T =>
                            data_bus_c_t_ready <= '1';
                            data_bus_hidden_out_ready <= '0';
                        when H_T =>
                            data_bus_c_t_ready <= '0';
                            data_bus_hidden_out_ready <= '1';
                        when others =>
                            data_bus_c_t_ready <= '0';
                            data_bus_hidden_out_ready <= '0';
                    end case;

                    if data_bus_valid = '1' then
                        if write_req = true then
                            write_address.index := 0;
                            write_address.data := data_type;
                            write_address.layer := layer;

                            s_axis_write_dest <= dram_address_to_slv(write_address);
                            s_axis_write_size <= std_logic_vector(to_unsigned(read_size, 3));
                            s_axis_write_length <= std_logic_vector(to_unsigned(vector_size - 1, 8));
                            s_axis_write_burst <= read_burst_v;

                            s_axis_write_req_valid <= '1';

                            write_req := false;
                        else
                            s_axis_write_req_valid <= '0';
                        end if;

                        s_axis_write_data <= data_bus;
                        s_axis_write_data_valid <= '1';
                        s_axis_write_last <= data_bus_last(0);
                        s_axis_write_strb <= (others => '1');
                    else
                        s_axis_write_data_valid <= '0';
                        s_axis_write_req_valid <= '0';
                    end if;

                    s_axis_write_response_ready <= '1';
                    if s_axis_write_response_valid = '1' then
                        response := slv_to_axi_response(s_axis_write_response);
                        if response = OKAY then
                            write_req := true;
                            next_bus_state <= next_state;
                            write_ready := false;
                        end if;
                    end if;
                else
                    data_bus <= (others => 'Z');
                    data_bus_last <= (others => 'Z');
                    data_bus_valid <= 'Z';
                    data_bus_dest <= (others => 'Z');

                    s_axis_write_data_valid <= '0';
                    s_axis_write_req_valid <= '0';
                    s_axis_write_response_ready <= '0';
                    data_bus_c_t_ready <= '0';
                    data_bus_hidden_out_ready <= '0';
                end if;
            end if;

            s_axis_read_dest <= (others => '0');
            s_axis_read_req_valid <= '0';
            s_axis_read_req_ready <= '0';
            s_axis_read_size <= (others => '0');
            s_axis_read_length <= (others => '0');
            s_axis_read_burst <= (others => '0');
        end procedure;


        variable layer : layer_info_t := LAYER1;
    begin
        if rising_edge(clk) then
            bus_state <= next_bus_state;

            if next_bus_state = IDLE then
                s_axis_control_ready <= '1';
            else
                s_axis_control_ready <= '0';
            end if;
            
            case next_bus_state is
                when IDLE =>
                    if s_axis_control_valid = '1' then
                        next_bus_state <= READ_C_T;
                        data_bus_state_valid <= '1';
                        current_layer <= slv_to_dram_control(s_axis_control_data).layer_info;
                        initial_layer <= slv_to_dram_control(s_axis_control_data).initial;
                    end if;

                    s_axis_read_req_valid <= '0';
                    s_axis_read_req_ready <= '0';
                    s_axis_read_dest <= (others => '0');
                    s_axis_read_size <= (others => '0');
                    s_axis_read_length <= (others => '0');
                    s_axis_read_burst <= (others => '0');

                    data_bus_c_t_ready <= '0';
                    data_bus_hidden_out_ready <= '0';

                    s_axis_write_dest <= (others => '0');
                    s_axis_write_data <= (others => '0');
                    s_axis_write_data_valid <= '0';
                    s_axis_write_req_valid <= '0';
                    s_axis_write_last <= '0';
                    s_axis_write_size <= (others => '0');
                    s_axis_write_length <= (others => '0');
                    s_axis_write_burst <= (others => '0');
                    s_axis_write_strb <= (others => '0');
                    s_axis_write_response_ready <= '0';

                    data_bus <= (others => 'Z');
                    data_bus_last <= (others => 'Z');
                    data_bus_valid <= 'Z';
                    data_bus_dest <= (others => 'Z');
                when READ_C_T =>
                    if data_bus_c_and_biases_ready = '1' then
                        layer := current_layer;
                        read_request(C_T, layer, vector_size, READ_I_B, false);
                    else
                        data_bus <= (others => 'Z');
                        data_bus_last <= (others => 'Z');
                        data_bus_valid <= 'Z';
                        data_bus_dest <= (others => 'Z');
                    end if;
                when READ_I_B =>
                    if data_bus_c_and_biases_ready = '1' then
                        layer := current_layer;
                        read_request(I_BIAS, layer, vector_size, READ_F_B, false);
                    else
                        data_bus <= (others => 'Z');
                        data_bus_last <= (others => 'Z');
                        data_bus_valid <= 'Z';
                        data_bus_dest <= (others => 'Z');
                    end if;
                when READ_F_B =>
                    if data_bus_c_and_biases_ready = '1' then
                        layer := current_layer;
                        read_request(F_BIAS, layer, vector_size, READ_G_B, false);
                    else
                        data_bus <= (others => 'Z');
                        data_bus_last <= (others => 'Z');
                        data_bus_valid <= 'Z';
                        data_bus_dest <= (others => 'Z');
                    end if;
                when READ_G_B =>
                    if data_bus_c_and_biases_ready = '1' then
                        layer := current_layer;
                        read_request(G_BIAS, layer, vector_size, READ_O_B, false);
                    else
                        data_bus <= (others => 'Z');
                        data_bus_last <= (others => 'Z');
                        data_bus_valid <= 'Z';
                        data_bus_dest <= (others => 'Z');
                    end if;
                when READ_O_B =>
                    if data_bus_c_and_biases_ready = '1' then
                        layer := current_layer;
                        read_request(O_BIAS, layer, vector_size, WRITE_PREV_H, false);
                    else
                        data_bus <= (others => 'Z');
                        data_bus_last <= (others => 'Z');
                        data_bus_valid <= 'Z';
                        data_bus_dest <= (others => 'Z');
                    end if;
                when WRITE_PREV_H =>
                    if initial_layer then
                        next_bus_state <= READ_I_IN_W;
                        data_bus <= (others => 'Z');
                        data_bus_last <= (others => 'Z');
                        data_bus_valid <= 'Z';
                        data_bus_dest <= (others => 'Z');
                    else
                        layer := get_prev_layer(current_layer);
                        write_request(H_T, layer, READ_I_IN_W);
                    end if;
                when READ_I_IN_W =>
                    if initial_layer then
                        layer := current_layer;
                    else
                        layer := get_next_layer(current_layer);
                    end if;
                    if data_bus_weights_ready = '1' then
                        read_request(I_INPUT_WEIGHT, layer, weight_size, READ_I_HID_W, false);
                    else
                        data_bus <= (others => 'Z');
                        data_bus_last <= (others => 'Z');
                        data_bus_valid <= 'Z';
                        data_bus_dest <= (others => 'Z');
                    end if;
                when READ_I_HID_W =>
                    if initial_layer then
                        layer := current_layer;
                    else
                        layer := get_next_layer(current_layer);
                    end if;
                    if data_bus_weights_ready = '1' then
                        read_request(I_HIDDEN_WEIGHT, layer, weight_size, READ_F_IN_W, false);
                    else
                        data_bus <= (others => 'Z');
                        data_bus_last <= (others => 'Z');
                        data_bus_valid <= 'Z';
                        data_bus_dest <= (others => 'Z');
                    end if;
                when READ_F_IN_W =>
                    if initial_layer then
                        layer := current_layer;
                    else
                        layer := get_next_layer(current_layer);
                    end if;
                    if data_bus_weights_ready = '1' then
                        read_request(F_INPUT_WEIGHT, layer, weight_size, READ_F_HID_W, false);
                    else
                        data_bus <= (others => 'Z');
                        data_bus_last <= (others => 'Z');
                        data_bus_valid <= 'Z';
                        data_bus_dest <= (others => 'Z');
                    end if;
                when READ_F_HID_W =>
                    if initial_layer then
                        layer := current_layer;
                    else
                        layer := get_next_layer(current_layer);
                    end if;
                    if data_bus_weights_ready = '1' then
                        read_request(F_HIDDEN_WEIGHT, layer, weight_size, READ_G_IN_W, false);
                    else
                        data_bus <= (others => 'Z');
                        data_bus_last <= (others => 'Z');
                        data_bus_valid <= 'Z';
                        data_bus_dest <= (others => 'Z');
                    end if;
                when READ_G_IN_W =>
                    if initial_layer then
                        layer := current_layer;
                    else
                        layer := get_next_layer(current_layer);
                    end if;
                    if data_bus_weights_ready = '1' then
                        read_request(G_INPUT_WEIGHT, layer, weight_size, READ_G_HID_W, false);
                    else
                        data_bus <= (others => 'Z');
                        data_bus_last <= (others => 'Z');
                        data_bus_valid <= 'Z';
                        data_bus_dest <= (others => 'Z');
                    end if;
                when READ_G_HID_W =>
                    if initial_layer then
                        layer := current_layer;
                    else
                        layer := get_next_layer(current_layer);
                    end if;
                    if data_bus_weights_ready = '1' then
                        read_request(G_HIDDEN_WEIGHT, layer, weight_size, READ_O_IN_W, false);
                    else
                        data_bus <= (others => 'Z');
                        data_bus_last <= (others => 'Z');
                        data_bus_valid <= 'Z';
                        data_bus_dest <= (others => 'Z');
                    end if;
                when READ_O_IN_W =>
                    if initial_layer then
                        layer := current_layer;
                    else
                        layer := get_next_layer(current_layer);
                    end if;
                    if data_bus_weights_ready = '1' then
                        read_request(O_INPUT_WEIGHT, layer, weight_size, READ_O_HID_W, false);
                    else
                        data_bus <= (others => 'Z');
                        data_bus_last <= (others => 'Z');
                        data_bus_valid <= 'Z';
                        data_bus_dest <= (others => 'Z');
                    end if;
                when READ_O_HID_W =>
                    if initial_layer then
                        layer := current_layer;
                    else
                        layer := get_next_layer(current_layer);
                    end if;
                    if data_bus_weights_ready = '1' then
                        read_request(O_HIDDEN_WEIGHT, layer, weight_size, READ_NEXT_H, true);
                    else
                        data_bus <= (others => 'Z');
                        data_bus_last <= (others => 'Z');
                        data_bus_valid <= 'Z';
                        data_bus_dest <= (others => 'Z');
                    end if;
                when READ_NEXT_H =>
                    if data_bus_hidden_in_ready = '1' then
                        layer := get_next_layer(current_layer);
                        read_request(H_T, layer, vector_size, WRITE_C_T, false);
                    else
                        data_bus <= (others => 'Z');
                        data_bus_last <= (others => 'Z');
                        data_bus_valid <= 'Z';
                        data_bus_dest <= (others => 'Z');
                    end if;
                when WRITE_C_T =>
                    layer := current_layer;
                    write_request(C_T, layer, IDLE);
                when others =>
                    next_bus_state <= IDLE;
            end case;
        end if;
    end process;
end architecture behav;