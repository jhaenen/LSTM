library ieee_proposed;
use ieee_proposed.float_pkg.all;

package tb_pkg is
    -- Create a bfloat16 type
    subtype UNRESOLVED_bfloat16 is UNRESOLVED_float (8 downto -7);
    alias U_float16 is UNRESOLVED_bfloat16;
    subtype bfloat16 is float (8 downto -7);

end package;