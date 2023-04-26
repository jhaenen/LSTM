-- Testbench for fixed point MAC

library ieee;

use ieee.std_logic_1164.all;

-- Simulation only
library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

use work.rrn_pkg.all;

entity mac_tb is
end entity mac_tb;

architecture sim of mac_tb is

    constant clk_period : time := 10 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    signal input : data_t;
    signal weight : data_t;
    signal output : data_t;

    component mac is
        port ( 
            clk         : in std_logic;
            rst         : in std_logic;

            data_in     : in data_t;
            weight_in   : in data_t;

            data_out    : out data_t
        );
    end component mac;

begin

    -- Test process
    process
        variable input_v : real := 0.0;
        variable weight_v : real := 0.0;
        variable output_v : real := 0.0;
        variable output_expected : real := 0.0;
    begin
        input_v := 2.4;
        weight_v := 10.3;

        input <= to_sfixed(input_v, data_t'high, data_t'low);
        weight <= to_sfixed(weight_v, data_t'high, data_t'low);

        wait for clk_period * 10;

        rst <= '1';
        wait for clk_period * 10;
        rst <= '0';

        wait for clk_period;

        output_expected := input_v * weight_v;

        output_v := to_real(output);

        assert abs(output_v - output_expected) < 0.01
            report "Output value is not correct"
            severity error;

        wait;

    end process;
        
    -- Clock process
    process
    begin
        wait for clk_period / 2;
        clk <= not clk;
    end process;

    DUT: mac
        port map (
            clk         => clk,
            rst         => rst,

            data_in     => input,
            weight_in   => weight,

            data_out    => output
        );

end architecture sim;