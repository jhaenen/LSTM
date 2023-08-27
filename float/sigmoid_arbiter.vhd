library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sigmoid_arbiter is
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
end sigmoid_arbiter;

architecture behav of sigmoid_arbiter is
begin 
    process (aclk) is
        variable sign : std_logic;
        variable exponent : unsigned(7 downto 0);
        variable fraction : unsigned(6 downto 0);

        variable slope_out_valid_v : std_logic := '0';
        variable slope_out_data_v : std_logic_vector(15 downto 0) := (others => '0');
        
        variable offset_out_valid_v : std_logic := '0';
        variable offset_out_data_v : std_logic_vector(15 downto 0) := (others => '0');

        variable input_out_valid_v : std_logic := '0';
        variable input_out_data_v : std_logic_vector(15 downto 0) := (others => '0');

        variable value_out_valid_v : std_logic := '0';
        variable value_out_data_v : std_logic_vector(15 downto 0) := (others => '0');
    begin
        -- If input is valid and all outputs are ready
        if in_valid = '1' then
            -- Get sign, exponent and fraction
            sign := in_data(15);
            exponent := unsigned(in_data(14 downto 7));
            fraction := unsigned(in_data(6 downto 0));

            if exponent >= x"82" then -- (6)
                if sign = '0' then
                    value_out_data_v := x"3F80"; -- 1.0
                    value_out_valid_v := '1';
                else 
                    value_out_data_v := x"0000"; -- 0.0
                    value_out_valid_v := '1';
                end if;

                slope_out_data_v := (others => '0');
                slope_out_valid_v := '0';

                offset_out_data_v := (others => '0');
                offset_out_valid_v := '0';

                input_out_data_v := (others => '0');
                input_out_valid_v := '0';
            elsif exponent = x"81" then
                if fraction >= x"10" then -- (5)
                    slope_out_data_v := x"3B25"; -- 0.00252
                    slope_out_valid_v := '1';

                    if sign = '0' then
                        offset_out_data_v := x"3F7B"; -- 0.98125
                        offset_out_valid_v := '1';
                    else 
                        offset_out_data_v := x"3C99"; -- 0.01875
                        offset_out_valid_v := '1';
                    end if;
                else -- (4)
                    slope_out_data_v := x"3CC1"; -- 0.02367
                    slope_out_valid_v := '1';

                    if sign = '0' then
                        offset_out_data_v := x"3F62"; -- 0.88603
                        offset_out_valid_v := '1';
                    else 
                        offset_out_data_v := x"3DE9"; -- 0.11397
                        offset_out_valid_v := '1';
                    end if;
                end if;

                input_out_data_v := in_data;
                input_out_valid_v := '1';

                value_out_data_v := (others => '0');
                value_out_valid_v := '0';
            elsif exponent = x"80" then
                if fraction >= x"40" then -- (4)
                    slope_out_data_v := x"3CC1"; -- 0.02367
                    slope_out_valid_v := '1';

                    if sign = '0' then
                        offset_out_data_v := x"3F62"; -- 0.88603
                        offset_out_valid_v := '1';
                    else 
                        offset_out_data_v := x"3DE9"; -- 0.11397
                        offset_out_valid_v := '1';
                    end if;
                else -- (3)
                    slope_out_data_v := x"3D8E"; -- 0.06975
                    slope_out_valid_v := '1';

                    if sign = '0' then 
                        offset_out_data_v := x"3F3F"; -- 0.74781
                        offset_out_valid_v := '1';
                    else 
                        offset_out_data_v := x"3E81"; -- 0.25219
                        offset_out_valid_v := '1';
                    end if;
                end if;

                input_out_data_v := in_data;
                input_out_valid_v := '1';

                value_out_data_v := (others => '0');
                value_out_valid_v := '0';
            elsif exponent = x"7F" then -- (2)
                slope_out_data_v := x"3E17"; -- 0.14841
                slope_out_valid_v := '1';

                if sign = '0' then
                    offset_out_data_v := x"3F17"; -- 0.59049
                    offset_out_valid_v := '1';
                else 
                    offset_out_data_v := x"3ED1"; -- 0.40951
                    offset_out_valid_v := '1';
                end if;

                input_out_data_v := in_data;
                input_out_valid_v := '1';

                value_out_data_v := (others => '0');
                value_out_valid_v := '0';
            else -- (1)
                slope_out_data_v := x"3E74"; -- 0.2389
                slope_out_valid_v := '1';

                offset_out_data_v := x"3F00"; -- 0.5
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
        
        -- Assign outputs
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