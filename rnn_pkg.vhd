-- Synthesis only
library ieee;
use ieee.fixed_pkg.all; 

-- Simulation only
-- library ieee_proposed;
-- use ieee_proposed.fixed_pkg.all;

package rnn_pkg is
    subtype data_t is sfixed(3 downto -12);
    subtype acc_t is sfixed(7 downto -24);
    subtype sigmoid_t is ufixed(0 downto -15);
    subtype tanh_t is sfixed(0 downto -15);
end;