library ieee_proposed;
use ieee_proposed.float_pkg.all;

package tb_pkg is
    -- Create a bfloat16 type
    subtype UNRESOLVED_bfloat16 is UNRESOLVED_float (8 downto -7);
    alias U_float16 is UNRESOLVED_bfloat16;
    subtype bfloat16 is float (8 downto -7);

    -- Create a half type
    subtype UNRESOLVED_half is UNRESOLVED_float (5 downto -10);
    alias U_half is UNRESOLVED_half;
    subtype half is float (5 downto -10);

end package;