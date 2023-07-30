-- Testbench for fixed point MAC

library ieee;
use ieee.std_logic_1164.all;

library ieee_proposed;
use ieee_proposed.float_pkg.all;

use work.tb_pkg.all;

entity lstm_pe_bf16_tb is
end entity lstm_pe_bf16_tb;

architecture sim of lstm_pe_bf16_tb is

    constant clk_period : time := 10 ns;

    signal clk : std_logic := '0';

    signal input : std_logic_vector(15 downto 0) := (others => '0');
    signal input_valid : std_logic := '0';
    signal input_ready : std_logic;
    signal input_last : std_logic := '0';

    signal input_hidden : std_logic_vector(15 downto 0) := (others => '0');
    signal input_hidden_valid : std_logic := '0';
    signal input_hidden_ready : std_logic;
    signal input_hidden_last : std_logic := '0';

    signal weight_i_in : std_logic_vector(15 downto 0) := (others => '0');
    signal weight_i_in_valid : std_logic := '0';
    signal weight_i_in_ready : std_logic;
    signal weight_i_in_last : std_logic := '0';

    signal weight_i_hid : std_logic_vector(15 downto 0) := (others => '0');
    signal weight_i_hid_valid : std_logic := '0';
    signal weight_i_hid_ready : std_logic;
    signal weight_i_hid_last : std_logic := '0';

    signal weight_g_in : std_logic_vector(15 downto 0) := (others => '0');
    signal weight_g_in_valid : std_logic := '0';
    signal weight_g_in_ready : std_logic;
    signal weight_g_in_last : std_logic := '0';

    signal weight_g_hid : std_logic_vector(15 downto 0) := (others => '0');
    signal weight_g_hid_valid : std_logic := '0';
    signal weight_g_hid_ready : std_logic;
    signal weight_g_hid_last : std_logic := '0';

    signal weight_f_in : std_logic_vector(15 downto 0) := (others => '0');
    signal weight_f_in_valid : std_logic := '0';
    signal weight_f_in_ready : std_logic;
    signal weight_f_in_last : std_logic := '0';

    signal weight_f_hid : std_logic_vector(15 downto 0) := (others => '0');
    signal weight_f_hid_valid : std_logic := '0';
    signal weight_f_hid_ready : std_logic;
    signal weight_f_hid_last : std_logic := '0';

    signal weight_o_in : std_logic_vector(15 downto 0) := (others => '0');
    signal weight_o_in_valid : std_logic := '0';
    signal weight_o_in_ready : std_logic;
    signal weight_o_in_last : std_logic := '0';

    signal weight_o_hid : std_logic_vector(15 downto 0) := (others => '0');
    signal weight_o_hid_valid : std_logic := '0';
    signal weight_o_hid_ready : std_logic;
    signal weight_o_hid_last : std_logic := '0';

    signal output_hidden : std_logic_vector(15 downto 0) := (others => '0');
    signal output_hidden_valid : std_logic;
    signal output_hidden_ready : std_logic := '0';

    component lstm_pe_bf16 is
        port (
            clk     : in std_logic;

            -- input
            S_AXIS_DATA_IN_tdata : in std_logic_vector(15 downto 0);
            S_AXIS_DATA_IN_tvalid : in std_logic;
            S_AXIS_DATA_IN_tready : out std_logic := '0';
            S_AXIS_DATA_IN_tlast : in std_logic;

            S_AXIS_HIDDEN_IN_tdata : in std_logic_vector(15 downto 0);
            S_AXIS_HIDDEN_IN_tvalid : in std_logic;
            S_AXIS_HIDDEN_IN_tready : out std_logic := '0';
            S_AXIS_HIDDEN_IN_tlast : in std_logic;

            -- weights
            S_AXIS_WEIGHT_I_input_tdata : in std_logic_vector(15 downto 0);
            S_AXIS_WEIGHT_I_input_tvalid : in std_logic;
            S_AXIS_WEIGHT_I_input_tready : out std_logic := '0';
            S_AXIS_WEIGHT_I_input_tlast : in std_logic;

            S_AXIS_WEIGHT_I_hidden_tdata : in std_logic_vector(15 downto 0);
            S_AXIS_WEIGHT_I_hidden_tvalid : in std_logic;
            S_AXIS_WEIGHT_I_hidden_tready : out std_logic := '0';
            S_AXIS_WEIGHT_I_hidden_tlast : in std_logic;

            S_AXIS_WEIGHT_G_input_tdata : in std_logic_vector(15 downto 0);
            S_AXIS_WEIGHT_G_input_tvalid : in std_logic;
            S_AXIS_WEIGHT_G_input_tready : out std_logic := '0'; 
            S_AXIS_WEIGHT_G_input_tlast : in std_logic;

            S_AXIS_WEIGHT_G_hidden_tdata : in std_logic_vector(15 downto 0);
            S_AXIS_WEIGHT_G_hidden_tvalid : in std_logic;
            S_AXIS_WEIGHT_G_hidden_tready : out std_logic := '0';
            S_AXIS_WEIGHT_G_hidden_tlast : in std_logic;

            S_AXIS_WEIGHT_F_input_tdata : in std_logic_vector(15 downto 0);
            S_AXIS_WEIGHT_F_input_tvalid : in std_logic;
            S_AXIS_WEIGHT_F_input_tready : out std_logic := '0';
            S_AXIS_WEIGHT_F_input_tlast : in std_logic;

            S_AXIS_WEIGHT_F_hidden_tdata : in std_logic_vector(15 downto 0);
            S_AXIS_WEIGHT_F_hidden_tvalid : in std_logic;
            S_AXIS_WEIGHT_F_hidden_tready : out std_logic := '0';
            S_AXIS_WEIGHT_F_hidden_tlast : in std_logic;

            S_AXIS_WEIGHT_O_input_tdata : in std_logic_vector(15 downto 0);
            S_AXIS_WEIGHT_O_input_tvalid : in std_logic;
            S_AXIS_WEIGHT_O_input_tready : out std_logic := '0';
            S_AXIS_WEIGHT_O_input_tlast : in std_logic;

            S_AXIS_WEIGHT_O_hidden_tdata : in std_logic_vector(15 downto 0);
            S_AXIS_WEIGHT_O_hidden_tvalid : in std_logic;
            S_AXIS_WEIGHT_O_hidden_tready : out std_logic := '0';
            S_AXIS_WEIGHT_O_hidden_tlast : in std_logic;

            -- output
            M_AXIS_HIDDEN_OUT_tdata : out std_logic_vector(15 downto 0) := (others => '0');
            M_AXIS_HIDDEN_OUT_tvalid : out std_logic := '0';
            M_AXIS_HIDDEN_OUT_tready : in std_logic
        );
    end component lstm_pe_bf16;

begin

    -- Test process
    process
        variable input_v : real := 0.0;
        variable hidden_v : real := 0.0;

        variable weight_i_in_v : real := 0.0;
        variable weight_i_hid_v : real := 0.0;

        variable weight_g_in_v : real := 0.0;
        variable weight_g_hid_v : real := 0.0;

        variable weight_f_in_v : real := 0.0;
        variable weight_f_hid_v : real := 0.0;

        variable weight_o_in_v : real := 0.0;
        variable weight_o_hid_v : real := 0.0;
    begin
        wait for clk_period * 10;

        output_hidden_ready <= '1';

        -- Wait for input readies to be asserted
        if input_ready = '0' or input_hidden_ready = '0' then
            wait until input_ready = '1' and input_hidden_ready = '1';
        end if;

        if weight_i_in_ready = '0' or weight_i_hid_ready = '0' or weight_g_in_ready = '0' or weight_g_hid_ready = '0' or weight_f_in_ready = '0' or weight_f_hid_ready = '0' or weight_o_in_ready = '0' or weight_o_hid_ready = '0' then
            wait until weight_i_in_ready = '1' and weight_i_hid_ready = '1' and weight_g_in_ready = '1' and weight_g_hid_ready = '1' and weight_f_in_ready = '1' and weight_f_hid_ready = '1' and weight_o_in_ready = '1' and weight_o_hid_ready = '1';
        end if;

        input_v := 2.4;
        hidden_v := 0.3;

        weight_i_in_v := 0.1;
        weight_i_hid_v := 0.2;

        weight_g_in_v := 0.15;
        weight_g_hid_v := 0.25;

        weight_f_in_v := 0.2;
        weight_f_hid_v := 0.3;

        weight_o_in_v := 0.3;
        weight_o_hid_v := 0.4;

        input <= to_slv(to_float(input_v, bfloat16'high, -bfloat16'low));
        input_hidden <= to_slv(to_float(hidden_v, bfloat16'high, -bfloat16'low));

        weight_i_in <= to_slv(to_float(weight_i_in_v, bfloat16'high, -bfloat16'low));
        weight_i_hid <= to_slv(to_float(weight_i_hid_v, bfloat16'high, -bfloat16'low));

        weight_g_in <= to_slv(to_float(weight_g_in_v, bfloat16'high, -bfloat16'low));
        weight_g_hid <= to_slv(to_float(weight_g_hid_v, bfloat16'high, -bfloat16'low));

        weight_f_in <= to_slv(to_float(weight_f_in_v, bfloat16'high, -bfloat16'low));
        weight_f_hid <= to_slv(to_float(weight_f_hid_v, bfloat16'high, -bfloat16'low));

        weight_o_in <= to_slv(to_float(weight_o_in_v, bfloat16'high, -bfloat16'low));
        weight_o_hid <= to_slv(to_float(weight_o_hid_v, bfloat16'high, -bfloat16'low));

        -- Make inputs valid
        input_valid <= '1';
        input_hidden_valid <= '1';

        weight_i_in_valid <= '1';
        weight_i_hid_valid <= '1';

        weight_g_in_valid <= '1';
        weight_g_hid_valid <= '1';

        weight_f_in_valid <= '1';
        weight_f_hid_valid <= '1';

        weight_o_in_valid <= '1';
        weight_o_hid_valid <= '1';

        wait for clk_period;

        input_v := 0.6;
        hidden_v := 0.4;

        weight_i_in_v := 0.001;
        weight_i_hid_v := 0.002;

        weight_g_in_v := 0.0015;
        weight_g_hid_v := 0.0025;

        weight_f_in_v := 0.002;
        weight_f_hid_v := 0.03;

        weight_o_in_v := 0.03;
        weight_o_hid_v := 0.0004;

        input <= to_slv(to_float(input_v, bfloat16'high, -bfloat16'low));
        input_hidden <= to_slv(to_float(hidden_v, bfloat16'high, -bfloat16'low));

        weight_i_in <= to_slv(to_float(weight_i_in_v, bfloat16'high, -bfloat16'low));
        weight_i_hid <= to_slv(to_float(weight_i_hid_v, bfloat16'high, -bfloat16'low));

        weight_g_in <= to_slv(to_float(weight_g_in_v, bfloat16'high, -bfloat16'low));
        weight_g_hid <= to_slv(to_float(weight_g_hid_v, bfloat16'high, -bfloat16'low));

        weight_f_in <= to_slv(to_float(weight_f_in_v, bfloat16'high, -bfloat16'low));
        weight_f_hid <= to_slv(to_float(weight_f_hid_v, bfloat16'high, -bfloat16'low));

        weight_o_in <= to_slv(to_float(weight_o_in_v, bfloat16'high, -bfloat16'low));
        weight_o_hid <= to_slv(to_float(weight_o_hid_v, bfloat16'high, -bfloat16'low));

        wait for clk_period;

        input_v := 0.56;
        hidden_v := 0.44;

        weight_i_in_v := 0.201;
        weight_i_hid_v := 0.202;

        weight_g_in_v := 0.0415;
        weight_g_hid_v := 0.3025;

        weight_f_in_v := 0.602;
        weight_f_hid_v := 0.33;

        weight_o_in_v := 0.43;
        weight_o_hid_v := 0.5004;

        input <= to_slv(to_float(input_v, bfloat16'high, -bfloat16'low));
        input_hidden <= to_slv(to_float(hidden_v, bfloat16'high, -bfloat16'low));

        weight_i_in <= to_slv(to_float(weight_i_in_v, bfloat16'high, -bfloat16'low));
        weight_i_hid <= to_slv(to_float(weight_i_hid_v, bfloat16'high, -bfloat16'low));

        weight_g_in <= to_slv(to_float(weight_g_in_v, bfloat16'high, -bfloat16'low));
        weight_g_hid <= to_slv(to_float(weight_g_hid_v, bfloat16'high, -bfloat16'low));

        weight_f_in <= to_slv(to_float(weight_f_in_v, bfloat16'high, -bfloat16'low));
        weight_f_hid <= to_slv(to_float(weight_f_hid_v, bfloat16'high, -bfloat16'low));

        weight_o_in <= to_slv(to_float(weight_o_in_v, bfloat16'high, -bfloat16'low));
        weight_o_hid <= to_slv(to_float(weight_o_hid_v, bfloat16'high, -bfloat16'low));

        -- Set last signals
        input_last <= '1';
        input_hidden_last <= '1';

        weight_i_in_last <= '1';
        weight_i_hid_last <= '1';

        weight_g_in_last <= '1';
        weight_g_hid_last <= '1';

        weight_f_in_last <= '1';
        weight_f_hid_last <= '1';

        weight_o_in_last <= '1';
        weight_o_hid_last <= '1';

        wait for clk_period;

        -- Make inputs invalid
        input_valid <= '0';
        input_hidden_valid <= '0';

        weight_i_in_valid <= '0';
        weight_i_hid_valid <= '0';

        weight_g_in_valid <= '0';
        weight_g_hid_valid <= '0';

        weight_f_in_valid <= '0';
        weight_f_hid_valid <= '0';

        weight_o_in_valid <= '0';
        weight_o_hid_valid <= '0';

        -- Wait for output to be valid
        wait until output_hidden_valid = '1';

        wait;

    end process;
        
    -- Clock process
    process
    begin
        wait for clk_period / 2;
        clk <= not clk;
    end process;

    DUT: lstm_pe_bf16
        port map (
            clk => clk,

            -- input
            S_AXIS_DATA_IN_tdata => input,
            S_AXIS_DATA_IN_tvalid => input_valid,
            S_AXIS_DATA_IN_tready => input_ready,
            S_AXIS_DATA_IN_tlast => input_last,

            S_AXIS_HIDDEN_IN_tdata => input_hidden,
            S_AXIS_HIDDEN_IN_tvalid => input_hidden_valid,
            S_AXIS_HIDDEN_IN_tready => input_hidden_ready,
            S_AXIS_HIDDEN_IN_tlast => input_hidden_last,

            -- weights
            S_AXIS_WEIGHT_I_input_tdata => weight_i_in,
            S_AXIS_WEIGHT_I_input_tvalid => weight_i_in_valid,
            S_AXIS_WEIGHT_I_input_tready => weight_i_in_ready,
            S_AXIS_WEIGHT_I_input_tlast => weight_i_in_last,

            S_AXIS_WEIGHT_I_hidden_tdata => weight_i_hid,
            S_AXIS_WEIGHT_I_hidden_tvalid => weight_i_hid_valid,
            S_AXIS_WEIGHT_I_hidden_tready => weight_i_hid_ready,
            S_AXIS_WEIGHT_I_hidden_tlast => weight_i_hid_last,

            S_AXIS_WEIGHT_G_input_tdata => weight_g_in,
            S_AXIS_WEIGHT_G_input_tvalid => weight_g_in_valid,
            S_AXIS_WEIGHT_G_input_tready => weight_g_in_ready,
            S_AXIS_WEIGHT_G_input_tlast => weight_g_in_last,

            S_AXIS_WEIGHT_G_hidden_tdata => weight_g_hid,
            S_AXIS_WEIGHT_G_hidden_tvalid => weight_g_hid_valid,
            S_AXIS_WEIGHT_G_hidden_tready => weight_g_hid_ready,
            S_AXIS_WEIGHT_G_hidden_tlast => weight_g_hid_last,

            S_AXIS_WEIGHT_F_input_tdata => weight_f_in,
            S_AXIS_WEIGHT_F_input_tvalid => weight_f_in_valid,
            S_AXIS_WEIGHT_F_input_tready => weight_f_in_ready,
            S_AXIS_WEIGHT_F_input_tlast => weight_f_in_last,

            S_AXIS_WEIGHT_F_hidden_tdata => weight_f_hid,
            S_AXIS_WEIGHT_F_hidden_tvalid => weight_f_hid_valid,
            S_AXIS_WEIGHT_F_hidden_tready => weight_f_hid_ready,
            S_AXIS_WEIGHT_F_hidden_tlast => weight_f_hid_last,

            S_AXIS_WEIGHT_O_input_tdata => weight_o_in,
            S_AXIS_WEIGHT_O_input_tvalid => weight_o_in_valid,
            S_AXIS_WEIGHT_O_input_tready => weight_o_in_ready,
            S_AXIS_WEIGHT_O_input_tlast => weight_o_in_last,

            S_AXIS_WEIGHT_O_hidden_tdata => weight_o_hid,
            S_AXIS_WEIGHT_O_hidden_tvalid => weight_o_hid_valid,
            S_AXIS_WEIGHT_O_hidden_tready => weight_o_hid_ready,
            S_AXIS_WEIGHT_O_hidden_tlast => weight_o_hid_last,

            -- output
            M_AXIS_HIDDEN_OUT_tdata => output_hidden,
            M_AXIS_HIDDEN_OUT_tvalid => output_hidden_valid,
            M_AXIS_HIDDEN_OUT_tready => output_hidden_ready
        );
        

end architecture sim;