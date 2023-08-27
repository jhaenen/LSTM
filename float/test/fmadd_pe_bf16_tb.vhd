library ieee;
use ieee.std_logic_1164.all;

library ieee_proposed;
use ieee_proposed.float_pkg.all;

use work.tb_pkg.all;

entity fmadd_pe_bf16_tb is
end entity fmadd_pe_bf16_tb;

architecture sim of fmadd_pe_bf16_tb is
    component fmadd_pe_bf16
        port (
            clk     : in std_logic;
    
            s_axis_pe_ready : out std_logic := '0';
            s_axis_pe_valid : in std_logic;
            s_axis_pe_last : in std_logic;
    
            post_allowed : in std_logic;
    
            -- input
            s_axis_data_in : in std_logic_vector(15 downto 0);
            s_axis_hidden_data : in std_logic_vector(15 downto 0);
    
            -- weights
            s_axis_weight_i_input_data : in std_logic_vector(15 downto 0);
            s_axis_weight_i_hidden_data : in std_logic_vector(15 downto 0);
    
            s_axis_weight_f_input_data : in std_logic_vector(15 downto 0);
            s_axis_weight_f_hidden_data : in std_logic_vector(15 downto 0);
    
            s_axis_weight_g_input_data : in std_logic_vector(15 downto 0);
            s_axis_weight_g_hidden_data : in std_logic_vector(15 downto 0);
    
            s_axis_weight_o_input_data : in std_logic_vector(15 downto 0);
            s_axis_weight_o_hidden_data : in std_logic_vector(15 downto 0);
    
            -- output
            m_axis_hidden_out_data : out std_logic_vector(15 downto 0) := (others => '0');
            m_axis_hidden_out_valid : out std_logic := '0';
            m_axis_hidden_out_ready : in std_logic;
    
            -- c_t and bias update
            s_axis_c_in_and_bias_ready : out std_logic := '0';
    
            s_axis_c_t_in_data : in std_logic_vector(15 downto 0);
            s_axis_c_t_in_valid : in std_logic;
    
            s_axis_c_t_out_data : out std_logic_vector(15 downto 0) := (others => '0');
            s_axis_c_t_out_valid : out std_logic := '0';
            s_axis_c_t_out_ready : in std_logic;
    
            s_axis_i_bias_data : in std_logic_vector(15 downto 0);
            s_axis_i_bias_valid : in std_logic;
    
            s_axis_f_bias_data : in std_logic_vector(15 downto 0);
            s_axis_f_bias_valid : in std_logic;
    
            s_axis_g_bias_data : in std_logic_vector(15 downto 0);
            s_axis_g_bias_valid : in std_logic;
    
            s_axis_o_bias_data : in std_logic_vector(15 downto 0);
            s_axis_o_bias_valid : in std_logic
        );
    end component fmadd_pe_bf16;

    constant clk_period : time := 10 ns;

    signal clk : std_logic := '0';

    signal s_axis_pe_ready : std_logic;
    signal s_axis_pe_valid : std_logic := '0';
    signal s_axis_pe_last : std_logic := '0';

    signal post_allowed : std_logic := '0';

    signal data_in : real := 0.0;
    signal hidden_in : real := 0.0;

    signal weight_ii : real := 0.0;
    signal weight_ih : real := 0.0;
    signal weight_fi : real := 0.0;
    signal weight_fh : real := 0.0;
    signal weight_gi : real := 0.0;
    signal weight_gh : real := 0.0;
    signal weight_oi : real := 0.0;
    signal weight_oh : real := 0.0;

    signal hidden_out : real := 0.0;
    signal slv_hidden_out : std_logic_vector(15 downto 0) := (others => '0');
    signal hidden_out_valid : std_logic;
    signal hidden_out_ready : std_logic := '0';

    signal s_axis_c_in_and_bias_ready : std_logic;

    signal c_t_in : real := 0.0;
    signal c_t_in_valid : std_logic := '0';

    signal c_t_out : real := 0.0;
    signal slv_c_t_out : std_logic_vector(15 downto 0) := (others => '0');
    signal c_t_out_valid : std_logic;
    signal c_t_out_ready : std_logic := '0';

    signal i_bias : real := 0.0;
    signal i_bias_valid : std_logic := '0';

    signal f_bias : real := 0.0;
    signal f_bias_valid : std_logic := '0';

    signal g_bias : real := 0.0;
    signal g_bias_valid : std_logic := '0';

    signal o_bias : real := 0.0;
    signal o_bias_valid : std_logic := '0';
begin
    process
    begin
        if s_axis_pe_ready /= '1' then
            wait until s_axis_pe_ready = '1';
        end if;

        wait for clk_period;
        s_axis_pe_valid <= '1';

        data_in <= 0.01;
        hidden_in <= 0.02;

        weight_ii <= 0.03;
        weight_ih <= 0.04;
        weight_fi <= 0.05;
        weight_fh <= 0.06;
        weight_gi <= 0.07;
        weight_gh <= 0.08;
        weight_oi <= 0.09;
        weight_oh <= 0.10;

        wait for clk_period;

        data_in <= 0.11;
        hidden_in <= 0.12;

        weight_ii <= 0.13;
        weight_ih <= 0.14;
        weight_fi <= 0.15;
        weight_fh <= 0.16;
        weight_gi <= 0.17;
        weight_gh <= 0.18;
        weight_oi <= 0.19;
        weight_oh <= 0.20;

        wait for clk_period;

        s_axis_pe_valid <= '0';

        data_in <= 0.21;
        hidden_in <= 0.22;

        weight_ii <= 0.23;
        weight_ih <= 0.24;
        weight_fi <= 0.25;
        weight_fh <= 0.26;
        weight_gi <= 0.27;
        weight_gh <= 0.28;
        weight_oi <= 0.29;
        weight_oh <= 0.30;

        wait for clk_period;

        s_axis_pe_valid <= '1';
        s_axis_pe_last <= '1';

        data_in <= 0.31;
        hidden_in <= 0.32;

        weight_ii <= 0.33;
        weight_ih <= 0.34;
        weight_fi <= 0.35;
        weight_fh <= 0.36;
        weight_gi <= 0.37;
        weight_gh <= 0.38;
        weight_oi <= 0.39;
        weight_oh <= 0.40;

        wait for clk_period;

        s_axis_pe_last <= '0';

        s_axis_pe_valid <= '0';

        hidden_out_ready <= '1';

        wait for clk_period;

    end process;

    -- c_t and bias update
    process
    begin
        c_t_in <= 0.0;
        c_t_in_valid <= '0';
        i_bias <= 0.0;
        i_bias_valid <= '0';
        f_bias <= 0.0;
        f_bias_valid <= '0';
        g_bias <= 0.0;
        g_bias_valid <= '0';
        o_bias <= 0.0;
        o_bias_valid <= '0';

        post_allowed <= '0';

        if s_axis_c_in_and_bias_ready /= '1' then
            wait until s_axis_c_in_and_bias_ready = '1';
        end if;

        c_t_in <= 0.41;
        c_t_in_valid <= '1';

        wait for clk_period;

        c_t_in <= 0.0;
        c_t_in_valid <= '0';

        if s_axis_c_in_and_bias_ready /= '1' then
            wait until s_axis_c_in_and_bias_ready = '1';
        end if;

        i_bias <= 0.42;
        i_bias_valid <= '1';

        wait for clk_period;

        i_bias <= 0.0;
        i_bias_valid <= '0';

        wait for clk_period * 2;

        if s_axis_c_in_and_bias_ready /= '1' then
            wait until s_axis_c_in_and_bias_ready = '1';
        end if;

        f_bias <= 0.43;
        f_bias_valid <= '1';

        wait for clk_period;

        f_bias <= 0.0;
        f_bias_valid <= '0';

        if s_axis_c_in_and_bias_ready /= '1' then
            wait until s_axis_c_in_and_bias_ready = '1';
        end if;

        g_bias <= 0.44;
        g_bias_valid <= '1';

        wait for clk_period;

        g_bias <= 0.0;
        g_bias_valid <= '0';

        wait for clk_period * 2;

        if s_axis_c_in_and_bias_ready /= '1' then
            wait until s_axis_c_in_and_bias_ready = '1';
        end if;

        o_bias <= 0.45;
        o_bias_valid <= '1';

        wait for clk_period;

        o_bias <= 0.0;
        o_bias_valid <= '0';

        post_allowed <= '1';

        wait;
    end process;


    hidden_out <= to_real(to_float(slv_hidden_out, bfloat16'high, -bfloat16'low));
    c_t_out <= to_real(to_float(slv_c_t_out, bfloat16'high, -bfloat16'low));
    clk <= not clk after clk_period / 2;
    
    DUT: fmadd_pe_bf16
        port map (
            clk => clk,

            s_axis_pe_ready => s_axis_pe_ready,
            s_axis_pe_valid => s_axis_pe_valid,
            s_axis_pe_last => s_axis_pe_last,

            post_allowed => post_allowed,

            s_axis_data_in => to_slv(to_float(data_in, bfloat16'high, -bfloat16'low)),
            s_axis_hidden_data => to_slv(to_float(hidden_in, bfloat16'high, -bfloat16'low)),

            s_axis_weight_i_input_data => to_slv(to_float(weight_ii, bfloat16'high, -bfloat16'low)),
            s_axis_weight_i_hidden_data => to_slv(to_float(weight_ih, bfloat16'high, -bfloat16'low)),

            s_axis_weight_f_input_data => to_slv(to_float(weight_fi, bfloat16'high, -bfloat16'low)),
            s_axis_weight_f_hidden_data => to_slv(to_float(weight_fh, bfloat16'high, -bfloat16'low)),

            s_axis_weight_g_input_data => to_slv(to_float(weight_gi, bfloat16'high, -bfloat16'low)),
            s_axis_weight_g_hidden_data => to_slv(to_float(weight_gh, bfloat16'high, -bfloat16'low)),

            s_axis_weight_o_input_data => to_slv(to_float(weight_oi, bfloat16'high, -bfloat16'low)),
            s_axis_weight_o_hidden_data => to_slv(to_float(weight_oh, bfloat16'high, -bfloat16'low)),

            m_axis_hidden_out_data => slv_hidden_out,
            m_axis_hidden_out_valid => hidden_out_valid,
            m_axis_hidden_out_ready => hidden_out_ready,

            s_axis_c_in_and_bias_ready => s_axis_c_in_and_bias_ready,

            s_axis_c_t_in_data => to_slv(to_float(c_t_in, bfloat16'high, -bfloat16'low)),
            s_axis_c_t_in_valid => c_t_in_valid,

            s_axis_c_t_out_data => slv_c_t_out,
            s_axis_c_t_out_valid => c_t_out_valid,
            s_axis_c_t_out_ready => c_t_out_ready,

            s_axis_i_bias_data => to_slv(to_float(i_bias, bfloat16'high, -bfloat16'low)),
            s_axis_i_bias_valid => i_bias_valid,

            s_axis_f_bias_data => to_slv(to_float(f_bias, bfloat16'high, -bfloat16'low)),
            s_axis_f_bias_valid => f_bias_valid,

            s_axis_g_bias_data => to_slv(to_float(g_bias, bfloat16'high, -bfloat16'low)),
            s_axis_g_bias_valid => g_bias_valid,

            s_axis_o_bias_data => to_slv(to_float(o_bias, bfloat16'high, -bfloat16'low)),
            s_axis_o_bias_valid => o_bias_valid
        );
    
end architecture sim;