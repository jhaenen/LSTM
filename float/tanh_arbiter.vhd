library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tanh_arbiter is
    port (
        aclk : in std_logic;

        -- input
        in_valid : in std_logic;
        in_data : in std_logic_vector(15 downto 0);

        -- output
        slope_out_valid : out std_logic := '0';
        slope_out_data : out std_logic_vector(15 downto 0) := (others => '0');

        offset_out_valid : out std_logic := '0';
        offset_out_data : out std_logic_vector(15 downto 0) := (others => '0');

        input_out_valid : out std_logic := '0';
        input_out_data : out std_logic_vector(15 downto 0) := (others => '0');

        value_out_valid : out std_logic := '0';
        value_out_data : out std_logic_vector(15 downto 0) := (others => '0')
    );
end tanh_arbiter;

architecture behav of tanh_arbiter is
begin 
    process (aclk) is
        variable sign : std_logic;
        variable exponent : unsigned(7 downto 0);
        variable fraction : unsigned(6 downto 0);

        variable temp_value : std_logic_vector(15 downto 0);

        variable slope_out_valid_v : std_logic := '0';
        variable slope_out_data_v : std_logic_vector(15 downto 0) := (others => '0');

        variable offset_out_valid_v : std_logic := '0';
        variable offset_out_data_v : std_logic_vector(15 downto 0) := (others => '0');

        variable input_out_valid_v : std_logic := '0';
        variable input_out_data_v : std_logic_vector(15 downto 0) := (others => '0');

        variable value_out_valid_v : std_logic := '0';
        variable value_out_data_v : std_logic_vector(15 downto 0) := (others => '0');
    begin
        -- If input is valid
        if in_valid = '1' then
            -- Get sign, exponent and fraction
            sign := in_data(15);
            exponent := unsigned(in_data(14 downto 7));
            fraction := unsigned(in_data(6 downto 0));

            if exponent >= x"81" then -- [-inf, -4.0]
                value_out_data(15) <= sign;
                temp_value := x"3F80"; -- 1.0
                value_out_data(14 downto 0) <= temp_value(14 downto 0);
                value_out_valid_v := '1';

                slope_out_data_v := (others => '0');
                slope_out_valid_v := '0';

                offset_out_data_v := (others => '0');
                offset_out_valid_v := '0';

                input_out_data_v := (others => '0');
                input_out_valid_v := '0';
            elsif exponent = x"80" then
                offset_out_data(15) <= sign;

                if fraction >= x"20" then -- [-4.0, -2.5]
                    slope_out_data_v := x"3BF2"; -- 0.00739
                    slope_out_valid_v := '1';

                    temp_value := x"3F78"; -- 0.97183
                    offset_out_data_v(14 downto 0) := temp_value(14 downto 0);
                    offset_out_valid_v := '1';
                else -- [-2.5, -1.75]
                    slope_out_data_v := x"3D66"; -- 0.05619
                    slope_out_valid_v := '1';

                    temp_value := x"3F59"; -- 0.84983
                    offset_out_data_v(14 downto 0) := temp_value(14 downto 0);
                    offset_out_valid_v := '1';
                end if;

                input_out_data_v := in_data;
                input_out_valid_v := '1';

                value_out_data_v := (others => '0');
                value_out_valid_v := '0';
            elsif exponent = x"7F" then
                offset_out_data(15) <= sign;

                if fraction >= x"60" then -- [-2.5, -1.75]
                    slope_out_data_v := x"3D66"; -- 0.05619
                    slope_out_valid_v := '1';

                    temp_value := x"3F59"; -- 0.84983
                    offset_out_data_v(14 downto 0) := temp_value(14 downto 0);
                    offset_out_valid_v := '1';
                elsif fraction >= x"20" then -- [-1.75, -1.25]
                    slope_out_data_v := x"3E40"; -- 0.18788
                    slope_out_valid_v := '1';

                    temp_value := x"3F1E"; -- 0.61937
                    offset_out_data_v(14 downto 0) := temp_value(14 downto 0);
                    offset_out_valid_v := '1';
                else -- [-1.25, -1.0]
                    slope_out_data_v := x"3EB8"; -- 0.36098
                    slope_out_valid_v := '1';

                    temp_value := x"3ECE"; -- 0.40300
                    offset_out_data_v(14 downto 0) := temp_value(14 downto 0);
                    offset_out_valid_v := '1';
                end if;

                input_out_data_v := in_data;
                input_out_valid_v := '1';

                value_out_data_v := (others => '0');
                value_out_valid_v := '0';
            elsif exponent = x"7E" then 
                offset_out_data(15) <= sign;

                if fraction >= x"40" then -- [-1.0, -0.75]
                    slope_out_data_v := x"3F00"; -- 0.5
                    slope_out_valid_v := '1';

                    temp_value := x"3E86"; -- 0.26316
                    offset_out_data_v(14 downto 0) := temp_value(14 downto 0);
                    offset_out_valid_v := '1';
                else -- [-0.75, -0.5]
                    slope_out_data_v := x"3F30"; -- 0.6875
                    slope_out_valid_v := '1';

                    temp_value := x"3DF6"; -- 0.12011
                    offset_out_data_v(14 downto 0) := temp_value(14 downto 0);
                    offset_out_valid_v := '1';
                end if;

                input_out_data_v := in_data;
                input_out_valid_v := '1';

                value_out_data_v := (others => '0');
                value_out_valid_v := '0';
            elsif exponent = x"7D" then -- [-0.5, -0.25]
                slope_out_data_v := x"3F5F"; -- 0.87109
                slope_out_valid_v := '1';

                offset_out_data(15) <= sign;
                temp_value := x"3CEE"; -- 0.02905
                offset_out_data_v(14 downto 0) := temp_value(14 downto 0);
                offset_out_valid_v := '1';

                input_out_data_v := in_data;
                input_out_valid_v := '1';

                value_out_data_v := (others => '0');
                value_out_valid_v := '0';
            else -- [-0.25, 0.25]
                slope_out_data_v := x"3F80"; -- 1.0
                slope_out_valid_v := '1';

                offset_out_data_v := (others => '0');
                offset_out_valid_v := '1';

                input_out_data_v := in_data;
                input_out_valid_v := '1';

                value_out_data_v := (others => '0');
                value_out_valid_v := '0';
            end if;
        else
            -- Set all outputs to invalid
            slope_out_valid_v := '0';
            offset_out_valid_v := '0';
            input_out_valid_v := '0';
            value_out_valid_v := '0';

            -- Set all outputs to zero
            slope_out_data_v := (others => '0');
            offset_out_data_v := (others => '0');
            input_out_data_v := (others => '0');
            value_out_data_v := (others => '0');
        end if;      

        -- Set outputs
        slope_out_valid <= slope_out_valid_v;
        slope_out_data <= slope_out_data_v;

        offset_out_valid <= offset_out_valid_v;
        offset_out_data <= offset_out_data_v;

        input_out_valid <= input_out_valid_v;
        input_out_data <= input_out_data_v;

        value_out_valid <= value_out_valid_v;
        value_out_data <= value_out_data_v;
    end process;

    
    
end architecture behav;