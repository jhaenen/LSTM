-- Synthesis only
-- library ieee;
-- use ieee.fixed_pkg.all; 

-- Simulation only
library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

package rrn_pkg is
    subtype data_t is sfixed(9 downto -6);
    subtype mult_t is sfixed(19 downto -12);
end;