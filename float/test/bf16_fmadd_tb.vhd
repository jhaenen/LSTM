-- Testbench for fixed point MAC

library ieee;
use ieee.std_logic_1164.all;

library ieee_proposed;
use ieee_proposed.float_pkg.all;

use work.tb_pkg.all;

entity bf16_fmadd_tb is
end entity bf16_fmadd_tb;

architecture sim of bf16_fmadd_tb is

    constant clk_period : time := 10 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    signal mult1 : std_logic_vector(15 downto 0) := (others => '0');
    signal mult1_valid : std_logic := '0';

    signal mult2 : std_logic_vector(15 downto 0) := (others => '0');
    signal mult2_valid : std_logic := '0';

    signal additive : std_logic_vector(15 downto 0) := (others => '0');
    signal additive_valid : std_logic := '0';

    signal result : std_logic_vector(15 downto 0);
    signal result_valid : std_logic;

    component fmadd_bf16_wrapper is
        port (
            M_AXIS_RESULT_tdata : out STD_LOGIC_VECTOR ( 15 downto 0 );
            M_AXIS_RESULT_tvalid : out STD_LOGIC;

            S_AXIS_ADDITIVE_tdata : in STD_LOGIC_VECTOR ( 15 downto 0 );
            S_AXIS_ADDITIVE_tvalid : in STD_LOGIC;

            S_AXIS_MULT_1_tdata : in STD_LOGIC_VECTOR ( 15 downto 0 );
            S_AXIS_MULT_1_tvalid : in STD_LOGIC;

            S_AXIS_MULT_2_tdata : in STD_LOGIC_VECTOR ( 15 downto 0 );
            S_AXIS_MULT_2_tvalid : in STD_LOGIC;
            aclk : in STD_LOGIC
          );
    end component;

begin

    -- Test process
    process
        variable mult1_v : real := 0.0;
        variable mult2_v : real := 0.0;
        variable add_v : real := 0.0;
    begin
        

        wait for clk_period * 10;

        -- rst <= '1';
        -- wait for clk_period * 10;
        -- rst <= '0';

        mult1_v := 2.4;
        mult2_v := 10.3;
        add_v := 1.2;

        mult1 <= to_slv(to_float(mult1_v, bfloat16'high, -bfloat16'low));
        mult2 <= to_slv(to_float(mult2_v, bfloat16'high, -bfloat16'low));
        additive <= to_slv(to_float(add_v, bfloat16'high, -bfloat16'low));

        mult1_valid <= '1';
        mult2_valid <= '1';
        additive_valid <= '1';

        wait for clk_period;

        mult1_v := 1.4;
        mult2_v := 5.7;

        mult1 <= to_slv(to_float(mult1_v, bfloat16'high, -bfloat16'low));
        mult2 <= to_slv(to_float(mult2_v, bfloat16'high, -bfloat16'low));
        additive <= result;

        mult1_valid <= '1';
        mult2_valid <= '1';
        additive_valid <= '1';

        -- Wait for result to be valid
        wait for clk_period;

        mult1_valid <= '0';
        mult2_valid <= '0';
        additive_valid <= '0';

        wait for clk_period;

        wait;

    end process;
        
    -- Clock process
    process
    begin
        wait for clk_period / 2;
        clk <= not clk;
    end process;

    DUT: fmadd_bf16_wrapper
        port map (
            M_AXIS_RESULT_tdata => result,
            M_AXIS_RESULT_tvalid => result_valid,

            S_AXIS_ADDITIVE_tdata => additive,
            S_AXIS_ADDITIVE_tvalid => additive_valid,

            S_AXIS_MULT_1_tdata => mult1,
            S_AXIS_MULT_1_tvalid => mult1_valid,

            S_AXIS_MULT_2_tdata => mult2,
            S_AXIS_MULT_2_tvalid => mult2_valid,

            aclk => clk
        );
        
end architecture sim;