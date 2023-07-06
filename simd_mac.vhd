library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity simd_mac is
    port (
        clk   : in std_logic;
        rst : in std_logic;
        en : in std_logic;
        
        data_in : in std_logic_vector(8 * 4 - 1 downto 0);
        weight_in : in std_logic_vector(8 * 4 - 1 downto 0);

        data_out : out std_logic_vector(16 * 4 - 1 downto 0)
    );
end entity;

architecture behav of simd_mac is

    type input_t is array (0 to 3) of signed(7 downto 0);
    signal data_in_arr : input_t;
    signal weight_in_arr : input_t;

    type output_t is array (0 to 3) of signed(15 downto 0);
    signal data_out_array : output_t;

    signal acc_arr : output_t;

    signal output_buffer : output_t;

begin

    process (data_in, weight_in)
    begin
        for i in 0 to 3 loop
            data_in_arr(i) <= signed(data_in(8 * (i + 1) - 1 downto 8 * i));
            weight_in_arr(i) <= signed(weight_in(8 * (i + 1) - 1 downto 8 * i));
        end loop;
    end process;

    process (clk, rst)
    begin

        if rst = '1' then
            acc_arr(0) <= (others => '0');
            acc_arr(1) <= (others => '0');
            acc_arr(2) <= (others => '0');
            acc_arr(3) <= (others => '0');
        elsif rising_edge(clk) then
            if en = '1' then                
                for i in 0 to 3 loop
                    acc_arr(i) <= resize(acc_arr(i) + (data_in_arr(i) * weight_in_arr(i)), acc_arr(i)'length);

                    output_buffer(i) <= acc_arr(i);
                end loop;
            end if;
        end if;

    end process;
    
    process (output_buffer)
    begin
        for i in 0 to 3 loop
            data_out_array(i) <= output_buffer(i);
            
            data_out(16 * (i + 1) - 1 downto 16 * i) <= std_logic_vector(data_out_array(i));
        end loop;
    end process;
end behav;
