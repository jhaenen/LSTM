-- Synthesis only
library ieee;
use ieee.fixed_pkg.all; 

use work.rnn_pkg.all;

entity sigmoid_pwl is
    generic (
        n : natural := 8;
        f : natural := 8
    );
    port (
        x : in sfixed(n downto -f);
        y : out sigmoid_t
    );
end entity sigmoid_pwl;

architecture behav of sigmoid_pwl is
    signal x_abs : ufixed(n downto -f);
begin
    x_abs <= to_ufixed(to_slv(x), x_abs'high, x_abs'low);
    
    process (x_abs)
    begin
        if x_abs >= 5.0 then
            y <= to_ufixed(1.0, y'high, y'low);
        elsif x_abs >= 2.375 then
            y <= resize(shift_right(x_abs, 5) + 0.84375, y'high, y'low);
        elsif x_abs >= 1.0 then
            y <= resize(shift_right(x_abs, 3) + 0.625, y'high, y'low);
        else 
            y <= resize(shift_right(x_abs, 2) + 0.5, y'high, y'low);
        end if;
    end process;
    
end architecture behav;