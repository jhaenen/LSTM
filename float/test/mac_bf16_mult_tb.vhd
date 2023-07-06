-- Testbench for fixed point MAC

library ieee;
use ieee.std_logic_1164.all;

library ieee_proposed;
use ieee_proposed.float_pkg.all;

use work.tb_pkg.all;

entity mac_bf16_mult_tb is
end entity mac_bf16_mult_tb;

architecture sim of mac_bf16_mult_tb is

    constant clk_period : time := 10 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    signal mode_select : std_logic_vector(0 downto 0) := "0";

    signal input : std_logic_vector(15 downto 0) := (others => '0');
    signal input_valid : std_logic := '0';
    signal input_ready : std_logic;
    signal input_last : std_logic := '0';

    signal weight : std_logic_vector(15 downto 0) := (others => '0');
    signal weight_valid : std_logic := '0';
    signal weight_ready : std_logic;
    signal weight_last : std_logic := '0';

    signal output_acc : std_logic_vector(15 downto 0);
    signal output_acc_valid : std_logic;
    signal output_acc_ready : std_logic := '0';
    signal output_acc_last : std_logic;

    signal output_mult : std_logic_vector(15 downto 0);
    signal output_mult_valid : std_logic;
    signal output_mult_ready : std_logic := '0';

    component mac_bf16_mult is
        port (
            M_AXIS_ACC_RESULT_tdata : out STD_LOGIC_VECTOR ( 15 downto 0 );
            M_AXIS_ACC_RESULT_tlast : out STD_LOGIC;
            M_AXIS_ACC_RESULT_tready : in STD_LOGIC;
            M_AXIS_ACC_RESULT_tvalid : out STD_LOGIC;

            M_AXIS_MULT_RESULT_tdata : out STD_LOGIC_VECTOR ( 15 downto 0 );
            M_AXIS_MULT_RESULT_tready : in STD_LOGIC;
            M_AXIS_MULT_RESULT_tvalid : out STD_LOGIC;

            S_AXIS_DATA_IN_tdata : in STD_LOGIC_VECTOR ( 15 downto 0 );
            S_AXIS_DATA_IN_tlast : in STD_LOGIC;
            S_AXIS_DATA_IN_tready : out STD_LOGIC;
            S_AXIS_DATA_IN_tuser : in STD_LOGIC_VECTOR ( 0 to 0 );
            S_AXIS_DATA_IN_tvalid : in STD_LOGIC;

            S_AXIS_WEIGHT_IN_tdata : in STD_LOGIC_VECTOR ( 15 downto 0 );
            S_AXIS_WEIGHT_IN_tlast : in STD_LOGIC;
            S_AXIS_WEIGHT_IN_tready : out STD_LOGIC;
            S_AXIS_WEIGHT_IN_tvalid : in STD_LOGIC;

            aclk : in STD_LOGIC
        );
    end component mac_bf16_mult;

begin

    -- Test process
    process
        variable input_v : real := 0.0;
        variable weight_v : real := 0.0;
        variable output_v : real := 0.0;
        variable output_expected : real := 0.0;
    begin
        

        wait for clk_period * 10;

        -- Wait for input readies to be asserted
        if input_ready = '0' then
            wait until input_ready = '1';
        end if;

        if weight_ready = '0' then
            wait until weight_ready = '1';
        end if;

        input_v := 2.4;
        weight_v := 10.3;

        output_expected := input_v * weight_v;

        input <= to_slv(to_float(input_v, bfloat16'high, -bfloat16'low));
        weight <= to_slv(to_float(weight_v, bfloat16'high, -bfloat16'low));

        -- Make inputs valid
        input_valid <= '1';
        weight_valid <= '1';

        mode_select <= "0";

        output_acc_ready <= '1';
        output_mult_ready <= '1';

        wait for clk_period * 6;

        input_v := 0.15;
        weight_v := 13.4;

        input <= to_slv(to_float(input_v, bfloat16'high, -bfloat16'low));
        weight <= to_slv(to_float(weight_v, bfloat16'high, -bfloat16'low));

        mode_select <= "1";

        wait for clk_period;

        input_v := 2.4;
        weight_v := 10.3;

        input <= to_slv(to_float(input_v, bfloat16'high, -bfloat16'low));
        weight <= to_slv(to_float(weight_v, bfloat16'high, -bfloat16'low));

        mode_select <= "0";

        wait for clk_period * 3;

        -- set last signals
        input_last <= '1';
        weight_last <= '1';

        wait for clk_period;

        -- Make inputs invalid
        input_valid <= '0';
        weight_valid <= '0';

        -- Set last signals
        input_last <= '0';
        weight_last <= '0';

        -- Wait for output to be valid
        wait until output_acc_last = '1';

        output_v := to_real(to_float(output_acc, bfloat16'high, -bfloat16'low));

        assert abs(output_v - output_expected) < 0.01
            report "Output value is not correct"
            severity error;

        wait;

    end process;
        
    -- Clock process
    process
    begin
        wait for clk_period / 2;
        clk <= not clk;
    end process;

    DUT: mac_bf16_mult
        port map (
            M_AXIS_ACC_RESULT_tdata => output_acc,
            M_AXIS_ACC_RESULT_tlast => output_acc_last,
            M_AXIS_ACC_RESULT_tready => output_acc_ready,
            M_AXIS_ACC_RESULT_tvalid => output_acc_valid,

            M_AXIS_MULT_RESULT_tdata => output_mult,
            M_AXIS_MULT_RESULT_tready => output_mult_ready,
            M_AXIS_MULT_RESULT_tvalid => output_mult_valid,

            S_AXIS_DATA_IN_tdata => input,
            S_AXIS_DATA_IN_tready => input_ready,
            S_AXIS_DATA_IN_tvalid => input_valid,
            S_AXIS_DATA_IN_tlast => input_last,
            S_AXIS_DATA_IN_tuser => mode_select,

            S_AXIS_WEIGHT_IN_tdata => weight,
            S_AXIS_WEIGHT_IN_tready => weight_ready,
            S_AXIS_WEIGHT_IN_tvalid => weight_valid,
            S_AXIS_WEIGHT_IN_tlast => weight_last,

            aclk => clk
        );
        

end architecture sim;