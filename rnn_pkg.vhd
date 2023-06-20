-- Synthesis only
library ieee;
use ieee.std_logic_1164.all;
use ieee.fixed_pkg.all; 

-- Simulation only
-- library ieee_proposed;
-- use ieee_proposed.fixed_pkg.all;

package rnn_pkg is
    subtype data_t is sfixed(3 downto -12);
    subtype acc_t is sfixed(7 downto -24);
    subtype sigmoid_t is ufixed(0 downto -15);
    subtype tanh_t is sfixed(1 downto -14);

    type pe_state_t is (IDLE, ACCUMULATE, POST, RESET);
    subtype pe_state_slv_t is std_logic_vector(1 downto 0);
    
    -- Create function to convert from and to pe_state_t to std_logic_vector
    function to_pe_state (state : pe_state_slv_t) return pe_state_t;
    function to_slv (state : pe_state_t) return pe_state_slv_t;
end;

package body rnn_pkg is
    function to_pe_state (state : pe_state_slv_t) return pe_state_t is
        variable result : pe_state_t;
    begin
        case state is
            when "00" => result := IDLE;
            when "01" => result := ACCUMULATE;
            when "10" => result := POST;
            when "11" => result := RESET;
            when others => result := IDLE;
        end case;
        return result;
    end function;

    function to_slv (state : pe_state_t) return std_logic_vector is
        variable result : pe_state_slv_t;
    begin
        case state is
            when IDLE => result := "00";
            when ACCUMULATE => result := "01";
            when POST => result := "10";
            when RESET => result := "11";
            when others => result := "00";
        end case;
        return result;
    end function;
end;