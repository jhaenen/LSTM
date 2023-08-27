library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sigmoid_arbiter_hp is
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
end sigmoid_arbiter_hp;

architecture behav of sigmoid_arbiter_hp is
begin 
    process (aclk) is
        variable sign : std_logic;
        variable exponent : unsigned(4 downto 0);
        variable fraction : unsigned(9 downto 0);

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
        -- If input is valid and all outputs are ready
        if in_valid = '1' then
            -- Get sign, exponent and fraction
            sign := in_data(15);
            exponent := unsigned(in_data(14 downto 10));
            fraction := unsigned(in_data(9 downto 0));

            if exponent >= to_unsigned(3 + bias_offset, 5) then -- (6) [8.0, inf]
                if sign = '0' then
                    value_out_data_v := x"3C00"; -- 1.0
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
            elsif exponent = to_unsigned(2 + bias_offset, 5) then -- (5) [4.0, 8.0)
                if fraction >= x"080" then -- (5) [4.5, 8.0)
                    slope_out_data_v := x"1929"; -- 0.00252
                    slope_out_valid_v := '1';

                    if sign = '0' then
                        offset_out_data_v := x"3BD9"; -- 0.98125
                        offset_out_valid_v := '1';
                    else 
                        offset_out_data_v := x"24CC"; -- 0.01875
                        offset_out_valid_v := '1';
                    end if;
                else -- (4) [4.0, 4.5)
                    slope_out_data_v := x"260F"; -- 0.02367
                    slope_out_valid_v := '1';

                    if sign = '0' then
                        offset_out_data_v := x"3B16"; -- 0.88603
                        offset_out_valid_v := '1';
                    else 
                        offset_out_data_v := x"2F4B"; -- 0.11397
                        offset_out_valid_v := '1';
                    end if;
                end if;

                input_out_data_v := in_data;
                input_out_valid_v := '1';

                value_out_data_v := (others => '0');
                value_out_valid_v := '0';
            elsif exponent = to_unsigned(1 + bias_offset, 5) then -- (3) [2.0, 4.0)
                if fraction >= x"200" then -- (4) [3.0, 4.0)
                    slope_out_data_v := x"260F"; -- 0.02367
                    slope_out_valid_v := '1';

                    if sign = '0' then
                        offset_out_data_v := x"3B16"; -- 0.88603
                        offset_out_valid_v := '1';
                    else 
                        offset_out_data_v := x"2F4B"; -- 0.11397
                        offset_out_valid_v := '1';
                    end if;
                else -- (3) [2.0, 3.0)
                    slope_out_data_v := x"2C76"; -- 0.06975
                    slope_out_valid_v := '1';

                    if sign = '0' then 
                        offset_out_data_v := x"39FB"; -- 0.74781
                        offset_out_valid_v := '1';
                    else 
                        offset_out_data_v := x"3408"; -- 0.25219
                        offset_out_valid_v := '1';
                    end if;
                end if;

                input_out_data_v := in_data;
                input_out_valid_v := '1';

                value_out_data_v := (others => '0');
                value_out_valid_v := '0';
            elsif exponent = to_unsigned(0 + bias_offset, 5) then -- (2) [1.0, 2.0)
                slope_out_data_v := x"30BF"; -- 0.14841
                slope_out_valid_v := '1';

                if sign = '0' then
                    offset_out_data_v := x"38B9"; -- 0.59049
                    offset_out_valid_v := '1';
                else 
                    offset_out_data_v := x"368D"; -- 0.40951
                    offset_out_valid_v := '1';
                end if;

                input_out_data_v := in_data;
                input_out_valid_v := '1';

                value_out_data_v := (others => '0');
                value_out_valid_v := '0';
            else -- (1) [0.0, 1.0)
                slope_out_data_v := x"33A5"; -- 0.2389
                slope_out_valid_v := '1';

                offset_out_data_v := x"3800"; -- 0.5
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