-- Testbench for fixed point MAC

library ieee;
use ieee.std_logic_1164.all;

library ieee_proposed;
use ieee_proposed.float_pkg.all;

use work.tb_pkg.all;

entity mac_bf16_tb is
end entity mac_bf16_tb;

architecture sim of mac_bf16_tb is

    constant clk_period : time := 10 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    signal input : std_logic_vector(15 downto 0) := (others => '0');
    signal input_valid : std_logic := '0';
    signal input_ready : std_logic;

    signal weight : std_logic_vector(15 downto 0) := (others => '0');
    signal weight_valid : std_logic := '0';
    signal weight_ready : std_logic;

    signal output : std_logic_vector(15 downto 0);
    signal output_valid : std_logic;
    -- signal output_ready : std_logic;

    component bf16_mac is
        port (
            clk         : in std_logic;
            rst         : in std_logic;
    
            S_AXIS_DATA_IN_tdata   : in std_logic_vector(15 downto 0);
            S_AXIS_DATA_IN_tvalid  : in std_logic;
            S_AXIS_DATA_IN_tready  : out std_logic;
    
            S_AXIS_WEIGHT_IN_tdata : in std_logic_vector(15 downto 0);
            S_AXIS_WEIGHT_IN_tvalid: in std_logic;
            S_AXIS_WEIGHT_IN_tready: out std_logic;
    
            M_AXIS_DATA_OUT_tdata  : out std_logic_vector(15 downto 0);
            M_AXIS_DATA_OUT_tvalid : out std_logic
            -- M_AXIS_DATA_OUT_tready : in std_logic
        );
    end component;

begin

    -- Test process
    process
        variable input_v : real := 0.0;
        variable weight_v : real := 0.0;
        variable output_v : real := 0.0;
        variable output_expected : real := 0.0;
    begin
        

        wait for clk_period * 10;

        rst <= '1';
        wait for clk_period * 10;
        rst <= '0';

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

        -- wait for clk_period;

        -- input_valid <= '0';
        -- weight_valid <= '0';

        -- Wait for output to be valid
        wait until output_valid = '1';

        output_v := to_real(to_float(output, bfloat16'high, -bfloat16'low));

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

    DUT: bf16_mac
        port map (
            clk => clk,
            rst => rst,

            S_AXIS_DATA_IN_tdata => input,
            S_AXIS_DATA_IN_tvalid => input_valid,
            S_AXIS_DATA_IN_tready => input_ready,

            S_AXIS_WEIGHT_IN_tdata => weight,
            S_AXIS_WEIGHT_IN_tvalid => weight_valid,
            S_AXIS_WEIGHT_IN_tready => weight_ready,

            M_AXIS_DATA_OUT_tdata => output,
            M_AXIS_DATA_OUT_tvalid => output_valid
            -- M_AXIS_DATA_OUT_tready => output_ready
        );

end architecture sim;