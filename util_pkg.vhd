library ieee;
use ieee.std_logic_1164.all;

package util_pkg is
    function clogb2(bit_depth : in natural ) return integer; 
    function flogb2(bit_depth : in natural ) return integer;   

    type layer_info_t is (LAYER1, LAYER2, LAYER3, LAYER4, LAYER5);
    function layer_info_to_slv (layer_info : in layer_info_t) return std_logic_vector;
    function slv_to_layer_info (slv : in std_logic_vector) return layer_info_t;

    type weight_dest_t is (I_INPUT, I_HIDDEN, F_INPUT, F_HIDDEN, G_INPUT, G_HIDDEN, O_INPUT, O_HIDDEN);
    function weight_dest_to_slv (weight_dest : in weight_dest_t) return std_logic_vector;
    function slv_to_weight_dest (slv : in std_logic_vector) return weight_dest_t;
end package util_pkg;

package body util_pkg is
    function flogb2(bit_depth : in natural ) return integer is
        variable result         : integer := 0;
        variable bit_depth_buff : natural := bit_depth;
    begin
        while bit_depth_buff>1 loop
            bit_depth_buff := bit_depth_buff/2;
            result         := result+1;
        end loop; 
        return result;
    end function flogb2;

    function clogb2 (bit_depth : in natural ) return integer is
        variable result : integer := 0;
    begin
        result := flogb2(bit_depth);
        if (bit_depth > (2**result)) then
            return(result + 1);
        else
            return result;
        end if;
    end function clogb2;

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
end package body;