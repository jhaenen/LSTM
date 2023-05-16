package util_pkg is
    function clogb2(bit_depth : in natural ) return natural; 
    function flogb2(bit_depth : in natural ) return natural;   
end package util_pkg;

package body util_pkg is
    function flogb2(bit_depth : in natural ) return natural is
        variable result         : natural := 0;
        variable bit_depth_buff : natural := bit_depth;
    begin
        while bit_depth_buff>1 loop
            bit_depth_buff := bit_depth_buff/2;
            result         := result+1;
        end loop; 
        return result;
    end function flogb2;

    function clogb2 (bit_depth : in natural ) return natural is
        variable result : natural := 0;
    begin
        result := flogb2(bit_depth);
        if (bit_depth > (2**result)) then
            return(result + 1);
        else
            return result;
        end if;
    end function clogb2;
end package body;