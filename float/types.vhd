library ieee;
use ieee.std_logic_1164.all;

package types is
    type layer_info_t is (LAYER1, LAYER2, LAYER3, LAYER4, LAYER5);
    function layer_info_to_slv (layer_info : in layer_info_t) return std_logic_vector;
    function slv_to_layer_info (slv : in std_logic_vector) return layer_info_t;
    function get_next_layer (layer_info : in layer_info_t) return layer_info_t;
    function get_prev_layer (layer_info : in layer_info_t) return layer_info_t;

    type inference_data_t is record
        layer_info : layer_info_t;
        last_inf   : boolean;
    end record inference_data_t;
    function inference_data_to_slv (inference_data : in inference_data_t) return std_logic_vector;
    function slv_to_inference_data (slv : in std_logic_vector) return inference_data_t;

    type dram_control_t is record
        layer_info : layer_info_t;
        initial : boolean;
    end record dram_control_t;
    function dram_control_to_slv (dram_control : in dram_control_t) return std_logic_vector;
    function slv_to_dram_control (slv : in std_logic_vector) return dram_control_t;

    type weight_dest_t is (I_INPUT, I_HIDDEN, F_INPUT, F_HIDDEN, G_INPUT, G_HIDDEN, O_INPUT, O_HIDDEN);
    function weight_dest_to_slv (weight_dest : in weight_dest_t) return std_logic_vector;
    function slv_to_weight_dest (slv : in std_logic_vector) return weight_dest_t;

    type last_t is (NOT_LAST, SEQ_LAST, LAYER_LAST);
    function last_to_slv (last : in last_t) return std_logic_vector;
    function slv_to_last (slv : in std_logic_vector) return last_t;

    type valid_t is (INVALID, VALID);
    function valid_to_sl (valid_val : in valid_t) return std_logic;
    function sl_to_valid (slv : in std_logic) return valid_t;

    type bus_states_t is (IDLE, 
        READ_C_T, WRITE_C_T, 
        READ_I_B, READ_F_B, READ_G_B, READ_O_B, 
        WRITE_PREV_H, READ_NEXT_H,
        READ_I_IN_W, READ_I_HID_W, READ_F_IN_W, READ_F_HID_W, READ_G_IN_W, READ_G_HID_W, READ_O_IN_W, READ_O_HID_W);

    function bus_states_to_slv (bus_states : in bus_states_t) return std_logic_vector;
    function slv_to_bus_states (slv : in std_logic_vector) return bus_states_t;

    type axi_response_t is (OKAY, EXOKAY, SLVERR, DECERR);
    function axi_response_to_slv (axi_response_val : in axi_response_t) return std_logic_vector;
    function slv_to_axi_response (slv : in std_logic_vector) return axi_response_t;
end package types;

package body types is
    function inference_data_to_slv (inference_data : in inference_data_t) return std_logic_vector is
        variable result : std_logic_vector(3 downto 0);
    begin
        case inference_data.layer_info is
            when LAYER1 => result(2 downto 0) := "000";
            when LAYER2 => result(2 downto 0) := "001";
            when LAYER3 => result(2 downto 0) := "010";
            when LAYER4 => result(2 downto 0) := "011";
            when LAYER5 => result(2 downto 0) := "100";
            when others => result(2 downto 0) := "000";
        end case;
        if inference_data.last_inf then
            result(3) := '1';
        else
            result(3) := '0';
        end if;
        return result;
    end function inference_data_to_slv;

    function slv_to_inference_data (slv : in std_logic_vector) return inference_data_t is
        variable result : inference_data_t;
    begin
        case slv(2 downto 0) is
            when "000" => result.layer_info := LAYER1;
            when "001" => result.layer_info := LAYER2;
            when "010" => result.layer_info := LAYER3;
            when "011" => result.layer_info := LAYER4;
            when "100" => result.layer_info := LAYER5;
            when others => result.layer_info := LAYER1;
        end case;
        if slv(3) = '1' then
            result.last_inf := true;
        else
            result.last_inf := false;
        end if;
        return result;
    end function slv_to_inference_data;

    function dram_control_to_slv (dram_control : in dram_control_t) return std_logic_vector is
        variable result : std_logic_vector(3 downto 0);
    begin
        case dram_control.layer_info is
            when LAYER1 => result(2 downto 0) := "000";
            when LAYER2 => result(2 downto 0) := "001";
            when LAYER3 => result(2 downto 0) := "010";
            when LAYER4 => result(2 downto 0) := "011";
            when LAYER5 => result(2 downto 0) := "100";
            when others => result(2 downto 0) := "000";
        end case;
        if dram_control.initial then
            result(3) := '1';
        else
            result(3) := '0';
        end if;
        return result;
    end function dram_control_to_slv;

    function slv_to_dram_control (slv : in std_logic_vector) return dram_control_t is
        variable result : dram_control_t;
    begin
        case slv(2 downto 0) is
            when "000" => result.layer_info := LAYER1;
            when "001" => result.layer_info := LAYER2;
            when "010" => result.layer_info := LAYER3;
            when "011" => result.layer_info := LAYER4;
            when "100" => result.layer_info := LAYER5;
            when others => result.layer_info := LAYER1;
        end case;
        if slv(3) = '1' then
            result.initial := true;
        else
            result.initial := false;
        end if;
        return result;
    end function slv_to_dram_control;

    function weight_dest_to_slv (weight_dest : in weight_dest_t) return std_logic_vector is
        variable result : std_logic_vector(2 downto 0);
    begin
        case weight_dest is
            when I_INPUT   => result := "000";
            when I_HIDDEN  => result := "001";
            when F_INPUT   => result := "010";
            when F_HIDDEN  => result := "011";
            when G_INPUT   => result := "100";
            when G_HIDDEN  => result := "101";
            when O_INPUT  => result := "110";
            when O_HIDDEN  => result := "111";
            when others    => result := "000";
        end case;
        return result;
    end function weight_dest_to_slv;

    function slv_to_weight_dest (slv : in std_logic_vector) return weight_dest_t is
        variable result : weight_dest_t;
    begin
        case slv is
            when "000" => result := I_INPUT;
            when "001" => result := I_HIDDEN;
            when "010" => result := F_INPUT;
            when "011" => result := F_HIDDEN;
            when "100" => result := G_INPUT;
            when "101" => result := G_HIDDEN;
            when "110" => result := O_INPUT;
            when "111" => result := O_HIDDEN;
            when others => result := I_INPUT;
        end case;
        return result;
    end function slv_to_weight_dest;

    function layer_info_to_slv (layer_info : in layer_info_t) return std_logic_vector is
        variable result : std_logic_vector(2 downto 0);
    begin
        case layer_info is
            when LAYER1 => result := "000";
            when LAYER2 => result := "001";
            when LAYER3 => result := "010";
            when LAYER4 => result := "011";
            when LAYER5 => result := "100";
            when others => result := "000";
        end case;
        return result;
    end function layer_info_to_slv;

    function slv_to_layer_info (slv : in std_logic_vector) return layer_info_t is
        variable result : layer_info_t;
    begin
        case slv is
            when "000" => result := LAYER1;
            when "001" => result := LAYER2;
            when "010" => result := LAYER3;
            when "011" => result := LAYER4;
            when "100" => result := LAYER5;
            when others => result := LAYER1;
        end case;
        return result;
    end function slv_to_layer_info;

    function get_next_layer (layer_info : in layer_info_t) return layer_info_t is
        variable result : layer_info_t;
    begin
        case layer_info is
            when LAYER1 => result := LAYER2;
            when LAYER2 => result := LAYER3;
            when LAYER3 => result := LAYER4;
            when LAYER4 => result := LAYER5;
            when LAYER5 => result := LAYER1;
            when others => result := LAYER1;
        end case;
        return result;
    end function get_next_layer;

    function get_prev_layer (layer_info : in layer_info_t) return layer_info_t is
        variable result : layer_info_t;
    begin
        case layer_info is
            when LAYER1 => result := LAYER5;
            when LAYER2 => result := LAYER1;
            when LAYER3 => result := LAYER2;
            when LAYER4 => result := LAYER3;
            when LAYER5 => result := LAYER4;
            when others => result := LAYER1;
        end case;
        return result;
    end function get_prev_layer;

    function last_to_slv (last : in last_t) return std_logic_vector is
        variable result : std_logic_vector(1 downto 0);
    begin
        case last is
            when NOT_LAST   => result := "00";
            when SEQ_LAST   => result := "01";
            when LAYER_LAST => result := "10";
            when others     => result := "00";
        end case;
        return result;
    end function last_to_slv;

    function slv_to_last (slv : in std_logic_vector) return last_t is
        variable result : last_t;
    begin
        case slv is
            when "00" => result := NOT_LAST;
            when "01" => result := SEQ_LAST;
            when "10" => result := LAYER_LAST;
            when others => result := NOT_LAST;
        end case;
        return result;
    end function slv_to_last;

    function valid_to_sl (valid_val : in valid_t) return std_logic is
        variable result : std_logic;
    begin
        case valid is
            when INVALID => result := '0';
            when VALID   => result := '1';
            when others  => result := '0';
        end case;
        return result;
    end function valid_to_sl;

    function sl_to_valid (slv : in std_logic) return valid_t is
        variable result : valid_t;
    begin
        case slv is
            when '0' => result := INVALID;
            when '1' => result := VALID;
            when others => result := INVALID;
        end case;
        return result;
    end function sl_to_valid;

    function bus_states_to_slv (bus_states : in bus_states_t) return std_logic_vector is
        variable result : std_logic_vector(3 downto 0);
    begin
        case bus_states is
            when IDLE => result := "0000";
            when READ_C_T => result := "0001";
            when READ_I_B => result := "0010";
            when READ_F_B => result := "0011";
            when READ_G_B => result := "0100";
            when READ_O_B => result := "0101";
            when WRITE_PREV_H => result := "0110";
            when READ_NEXT_H => result := "0111";
            when READ_I_IN_W => result := "1000";
            when READ_I_HID_W => result := "1001";
            when READ_F_IN_W => result := "1010";
            when READ_F_HID_W => result := "1011";
            when READ_G_IN_W => result := "1100";
            when READ_G_HID_W => result := "1101";
            when READ_O_IN_W => result := "1110";
            when READ_O_HID_W => result := "1111";
            when others => result := "0000";
        end case;
        return result;
    end function bus_states_to_slv;

    function slv_to_bus_states (slv : in std_logic_vector) return bus_states_t is
        variable result : bus_states_t;
    begin
        case slv is
            when "0000" => result := IDLE;
            when "0001" => result := READ_C_T;
            when "0010" => result := READ_I_B;
            when "0011" => result := READ_F_B;
            when "0100" => result := READ_G_B;
            when "0101" => result := READ_O_B;
            when "0110" => result := WRITE_PREV_H;
            when "0111" => result := READ_NEXT_H;
            when "1000" => result := READ_I_IN_W;
            when "1001" => result := READ_I_HID_W;
            when "1010" => result := READ_F_IN_W;
            when "1011" => result := READ_F_HID_W;
            when "1100" => result := READ_G_IN_W;
            when "1101" => result := READ_G_HID_W;
            when "1110" => result := READ_O_IN_W;
            when "1111" => result := READ_O_HID_W;
            when others => result := IDLE;
        end case;
        return result;
    end function slv_to_bus_states;

    function axi_response_to_slv (axi_response_val : in axi_response_t) return std_logic_vector is
        variable result : std_logic_vector(1 downto 0);
    begin
        case axi_response_val is
            when OKAY   => result := "00";
            when EXOKAY => result := "01";
            when SLVERR => result := "10";
            when DECERR => result := "11";
            when others => result := "00";
        end case;
        return result;
    end function axi_response_to_slv;

    function slv_to_axi_response (slv : in std_logic_vector) return axi_response_t is
        variable result : axi_response_t;
    begin
        case slv is
            when "00" => result := OKAY;
            when "01" => result := EXOKAY;
            when "10" => result := SLVERR;
            when "11" => result := DECERR;
            when others => result := OKAY;
        end case;
        return result;
    end function slv_to_axi_response;
end package body types;