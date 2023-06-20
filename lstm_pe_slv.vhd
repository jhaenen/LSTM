library ieee;
use ieee.std_logic_1164.all;

-- Synthesis only
use ieee.fixed_pkg.all; 

-- -- Simulation only
-- library ieee_proposed;
-- use ieee_proposed.float_pkg.all;

use work.rnn_pkg.all;
use work.util_pkg.all;

entity lstm_pe_slv is
    port (
        clk     : in std_logic;
        rst     : in std_logic;

        pe_state : in pe_state_slv_t;
        
        -- input
        data_in     : in std_logic_vector(data_t'length-1 downto 0);
        weight_i_in : in std_logic_vector(data_t'length-1 downto 0);
        weight_g_in : in std_logic_vector(data_t'length-1 downto 0);
        weight_f_in : in std_logic_vector(data_t'length-1 downto 0);
        weight_o_in : in std_logic_vector(data_t'length-1 downto 0);
        
        -- output
        hidden_out  : out std_logic_vector(data_t'length-1 downto 0)
    );
end entity lstm_pe_slv;

architecture behav of lstm_pe_slv is 

component lstm_pe is
    port (
        clk     : in std_logic;
        rst     : in std_logic;

        pe_state : in pe_state_slv_t;
        
        -- input
        data_in     : in data_t;
        weight_i_in : in data_t;
        weight_g_in : in data_t;
        weight_f_in : in data_t;
        weight_o_in : in data_t;

        -- output
        hidden_out  : out data_t
    );
end component;
    signal hidden_out_f : data_t;
begin

    lstm_pe_inst : lstm_pe
        port map (
            clk => clk,
            rst => rst,

            pe_state => pe_state,

            data_in => to_sfixed(data_in, data_t'high, data_t'low),
            weight_i_in => to_sfixed(weight_i_in, data_t'high, data_t'low),
            weight_g_in => to_sfixed(weight_g_in, data_t'high, data_t'low),
            weight_f_in => to_sfixed(weight_f_in, data_t'high, data_t'low),
            weight_o_in => to_sfixed(weight_o_in, data_t'high, data_t'low),
            hidden_out => hidden_out_f
        );

    hidden_out <= to_slv(hidden_out_f);

end architecture behav;