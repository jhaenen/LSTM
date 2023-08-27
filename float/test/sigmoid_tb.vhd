library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library ieee_proposed;
use ieee_proposed.float_pkg.all;

use work.tb_pkg.all;

entity sigmoid_tb is
end entity sigmoid_tb;

architecture sim of sigmoid_tb is
    component sigmoid_arbiter_hp is
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
    end component;

    component fmadd_hp is
        port (
            S_AXIS_MULT_1_tdata : in STD_LOGIC_VECTOR ( 15 downto 0 );
            S_AXIS_MULT_1_tvalid : in STD_LOGIC;
            S_AXIS_MULT_2_tdata : in STD_LOGIC_VECTOR ( 15 downto 0 );
            S_AXIS_MULT_2_tvalid : in STD_LOGIC;
            S_AXIS_ADDITIVE_tdata : in STD_LOGIC_VECTOR ( 15 downto 0 );
            S_AXIS_ADDITIVE_tvalid : in STD_LOGIC;
            M_AXIS_RESULT_tdata : out STD_LOGIC_VECTOR ( 15 downto 0 );
            M_AXIS_RESULT_tvalid : out STD_LOGIC
        );
    end component fmadd_hp;

    constant clk_period : time := 10 ns;

    signal aclk : std_logic := '0';

    signal in_valid : std_logic := '0';
    signal in_data : real := 0.0;

    signal slope_out_valid : std_logic := '0';
    signal slope_out_data : std_logic_vector(15 downto 0);

    signal offset_out_valid : std_logic := '0';
    signal offset_out_data : std_logic_vector(15 downto 0);

    signal input_out_valid : std_logic;
    signal input_out_data : std_logic_vector(15 downto 0);

    signal value_out_valid : std_logic;
    signal value_out_data : real;
    signal slv_value_out_data : std_logic_vector(15 downto 0);

    signal result_data : real;
    signal slv_result_data : std_logic_vector(15 downto 0);
    signal result_valid : std_logic;

    file input_file : text;
    file output_file : text;
begin
    process
        variable input_line : line;
        variable read_data : real;
        variable output_line : line;
    begin
        file_open(input_file, "/home/jhaenen/Documenten/Vivado/RNN/RNN.srcs/sources_1/rtl/float/test/act_test/sig.txt", read_mode);
        file_open(output_file, "/home/jhaenen/Documenten/Vivado/RNN/RNN.srcs/sources_1/rtl/float/test/act_test/sig_out.txt", write_mode);
        wait for clk_period * 3;

        -- read input line by line
        while not(endfile(input_file)) loop
            readline(input_file, input_line);
            read(input_line, read_data);

            in_valid <= '1';  
            in_data <= read_data;          

            wait for clk_period / 2;

            if result_valid = '1' then
                write(output_line, to_hex_string(to_bitvector(slv_result_data)));
                writeline(output_file, output_line);
            end if;

            if value_out_valid = '1' then
                write(output_line, to_hex_string(to_bitvector(slv_value_out_data)));
                writeline(output_file, output_line); 
            end if;

            wait for clk_period / 2;
        end loop;

        in_valid <= '0';  
        in_data <= 0.0;

        file_close(input_file);

        -- Flush output
        file_close(output_file);


        wait;
    end process;


    result_data <= to_real(to_float(slv_result_data, half'high, -half'low));
    value_out_data <= to_real(to_float(slv_value_out_data, half'high, -half'low));
    
    aclk <= not aclk after clk_period / 2;

    DUT: sigmoid_arbiter_hp 
        port map (
            aclk => aclk,
            in_valid => in_valid,
            in_data => to_slv(to_float(in_data, half'high, -half'low)),
            slope_out_valid => slope_out_valid,
            slope_out_data => slope_out_data,
            offset_out_valid => offset_out_valid,
            offset_out_data => offset_out_data,
            input_out_valid => input_out_valid,
            input_out_data => input_out_data,
            value_out_valid => value_out_valid,
            value_out_data => slv_value_out_data
        );
    
    FMADD: fmadd_hp
        port map (
            S_AXIS_MULT_1_tdata => slope_out_data,
            S_AXIS_MULT_1_tvalid => slope_out_valid,
            S_AXIS_MULT_2_tdata => input_out_data,
            S_AXIS_MULT_2_tvalid => input_out_valid,
            S_AXIS_ADDITIVE_tdata => offset_out_data,
            S_AXIS_ADDITIVE_tvalid => offset_out_valid,
            M_AXIS_RESULT_tdata => slv_result_data,
            M_AXIS_RESULT_tvalid => result_valid
        );

    
    
end architecture sim;