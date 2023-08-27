library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tanh_arbiter_hp is
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
end tanh_arbiter_hp;

architecture behav of tanh_arbiter_hp is
begin 
    process (aclk) is
        variable sign : std_logic;
        variable exponent : unsigned(4 downto 0);
        variable fraction : unsigned(9 downto 0);

        variable temp_value : std_logic_vector(15 downto 0);

        constant bias_offset : natural := 15; -- 15

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
            exponent := unsigned(in_data(14 downto 10));
            fraction := unsigned(in_data(9 downto 0));

            if exponent >= to_unsigned(2 + bias_offset, 5) then -- [-inf, -4.0]
                value_out_data(15) <= sign;
                temp_value := x"3C00"; -- 1.0
                value_out_data(14 downto 0) <= temp_value(14 downto 0);
                value_out_valid_v := '1';

                slope_out_data_v := (others => '0');
                slope_out_valid_v := '0';

                offset_out_data_v := (others => '0');
                offset_out_valid_v := '0';

                input_out_data_v := (others => '0');
                input_out_valid_v := '0';
            elsif exponent = to_unsigned(1 + bias_offset, 5) then -- [-4.0, -2.0]
                offset_out_data(15) <= sign;

                if fraction >= x"200" then -- [-4.0, -2.5]
                    slope_out_data_v := x"1F92"; -- 0.007393
                    slope_out_valid_v := '1';

                    temp_value := x"3BC6"; -- 0.97183
                    offset_out_data_v(14 downto 0) := temp_value(14 downto 0);
                    offset_out_valid_v := '1';
                else -- [-2.5, -1.75]
                    slope_out_data_v := x"2B31"; -- 0.05619
                    slope_out_valid_v := '1';

                    temp_value := x"3ACC"; -- 0.84983
                    offset_out_data_v(14 downto 0) := temp_value(14 downto 0);
                    offset_out_valid_v := '1';
                end if;

                input_out_data_v := in_data;
                input_out_valid_v := '1';

                value_out_data_v := (others => '0');
                value_out_valid_v := '0';
            elsif exponent = to_unsigned(0 + bias_offset, 5) then -- [-2.0, -1.0]
                offset_out_data(15) <= sign;

                if fraction >= x"400" then -- [-2.5, -1.75]
                    slope_out_data_v := x"2B31"; -- 0.05619
                    slope_out_valid_v := '1';

                    temp_value := x"3ACC"; -- 0.84983
                    offset_out_data_v(14 downto 0) := temp_value(14 downto 0);
                    offset_out_valid_v := '1';
                elsif fraction >= x"100" then -- [-1.75, -1.25]
                    slope_out_data_v := x"3203"; -- 0.18788
                    slope_out_valid_v := '1';

                    temp_value := x"38F4"; -- 0.61937
                    offset_out_data_v(14 downto 0) := temp_value(14 downto 0);
                    offset_out_valid_v := '1';
                else -- [-1.25, -1.0]
                    slope_out_data_v := x"35C6"; -- 0.36098
                    slope_out_valid_v := '1';

                    temp_value := x"3672"; -- 0.40300
                    offset_out_data_v(14 downto 0) := temp_value(14 downto 0);
                    offset_out_valid_v := '1';
                end if;

                input_out_data_v := in_data;
                input_out_valid_v := '1';

                value_out_data_v := (others => '0');
                value_out_valid_v := '0';
            elsif exponent = to_unsigned(-1 + bias_offset, 5) then  -- [-1.0, -0.5]
                offset_out_data(15) <= sign;

                if fraction >= x"200" then -- [-1.0, -0.75]
                    slope_out_data_v := x"3801"; -- 0.5
                    slope_out_valid_v := '1';

                    temp_value := x"3435"; -- 0.26316
                    offset_out_data_v(14 downto 0) := temp_value(14 downto 0);
                    offset_out_valid_v := '1';
                else -- [-0.75, -0.5]
                    slope_out_data_v := x"3987"; -- 0.6875
                    slope_out_valid_v := '1';

                    temp_value := x"2FB2"; -- 0.12011
                    offset_out_data_v(14 downto 0) := temp_value(14 downto 0);
                    offset_out_valid_v := '1';
                end if;

                input_out_data_v := in_data;
                input_out_valid_v := '1';

                value_out_data_v := (others => '0');
                value_out_valid_v := '0';
            elsif exponent = to_unsigned(-2 + bias_offset, 5) then -- [-0.5, -0.25]
                slope_out_data_v := x"3AFD"; -- 0.87109
                slope_out_valid_v := '1';

                offset_out_data(15) <= sign;
                temp_value := x"2772"; -- 0.02905
                offset_out_data_v(14 downto 0) := temp_value(14 downto 0);
                offset_out_valid_v := '1';

                input_out_data_v := in_data;
                input_out_valid_v := '1';

                value_out_data_v := (others => '0');
                value_out_valid_v := '0';
            else -- [-0.25, 0.25]
                slope_out_data_v := x"3C00"; -- 1.0
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