library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fmadd_pe_bf16 is
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
end entity fmadd_pe_bf16;

architecture behav of fmadd_pe_bf16 is
    component fmadd_bf16 is
        port (
            S_AXIS_MULT_1_tdata : in STD_LOGIC_VECTOR ( 15 downto 0 );
            S_AXIS_MULT_1_tvalid : in STD_LOGIC;
            S_AXIS_MULT_2_tdata : in STD_LOGIC_VECTOR ( 15 downto 0 );
            S_AXIS_MULT_2_tvalid : in STD_LOGIC;
            S_AXIS_ADDITIVE_tdata : in STD_LOGIC_VECTOR ( 15 downto 0 );
            S_AXIS_ADDITIVE_tvalid : in STD_LOGIC;
            M_AXIS_RESULT_tdata : out STD_LOGIC_VECTOR ( 15 downto 0 );
            M_AXIS_RESULT_tvalid : out STD_LOGIC;
            aclk : in STD_LOGIC
        );
    end component fmadd_bf16;

    component sigmoid_arbiter is
        port (
            aclk : in std_logic;
    
            -- input
            in_valid : in std_logic;
            in_data : in std_logic_vector(15 downto 0);
    
            -- output
            slope_out_valid : out std_logic;
            slope_out_data : out std_logic_vector(15 downto 0);
    
            offset_out_valid : out std_logic;
            offset_out_data : out std_logic_vector(15 downto 0);
    
            input_out_valid : out std_logic;
            input_out_data : out std_logic_vector(15 downto 0);
    
            value_out_valid : out std_logic;
            value_out_data : out std_logic_vector(15 downto 0)
        );
    end component;

    component tanh_arbiter is
        port (
            aclk : in std_logic;
    
            -- input
            in_valid : in std_logic;
            in_data : in std_logic_vector(15 downto 0);
    
            -- output
            slope_out_valid : out std_logic;
            slope_out_data : out std_logic_vector(15 downto 0);
    
            offset_out_valid : out std_logic;
            offset_out_data : out std_logic_vector(15 downto 0);
    
            input_out_valid : out std_logic;
            input_out_data : out std_logic_vector(15 downto 0);
    
            value_out_valid : out std_logic;
            value_out_data : out std_logic_vector(15 downto 0)
        );
    end component;

    -- FMADD signals
    signal fma1_ii_mult_1_data : std_logic_vector(15 downto 0);
    signal fma1_ii_mult_1_valid : std_logic;
    signal fma1_ii_mult_2_data : std_logic_vector(15 downto 0);
    signal fma1_ii_mult_2_valid : std_logic;
    signal fma1_ii_add_data : std_logic_vector(15 downto 0);
    signal fma1_ii_add_valid : std_logic;
    signal fma1_ii_result_data : std_logic_vector(15 downto 0);
    signal fma1_ii_result_valid : std_logic;

    signal fma2_ih_mult_1_data : std_logic_vector(15 downto 0);
    signal fma2_ih_mult_1_valid : std_logic;
    signal fma2_ih_mult_2_data : std_logic_vector(15 downto 0);
    signal fma2_ih_mult_2_valid : std_logic;
    signal fma2_ih_add_data : std_logic_vector(15 downto 0);
    signal fma2_ih_add_valid : std_logic;
    signal fma2_ih_result_data : std_logic_vector(15 downto 0);
    signal fma2_ih_result_valid : std_logic;

    signal fma3_fi_mult_1_data : std_logic_vector(15 downto 0);
    signal fma3_fi_mult_1_valid : std_logic;
    signal fma3_fi_mult_2_data : std_logic_vector(15 downto 0);
    signal fma3_fi_mult_2_valid : std_logic;
    signal fma3_fi_add_data : std_logic_vector(15 downto 0);
    signal fma3_fi_add_valid : std_logic;
    signal fma3_fi_result_data : std_logic_vector(15 downto 0);
    signal fma3_fi_result_valid : std_logic;

    signal fma4_fh_mult_1_data : std_logic_vector(15 downto 0);
    signal fma4_fh_mult_1_valid : std_logic;
    signal fma4_fh_mult_2_data : std_logic_vector(15 downto 0);
    signal fma4_fh_mult_2_valid : std_logic;
    signal fma4_fh_add_data : std_logic_vector(15 downto 0);
    signal fma4_fh_add_valid : std_logic;
    signal fma4_fh_result_data : std_logic_vector(15 downto 0);
    signal fma4_fh_result_valid : std_logic;

    signal fma5_gi_mult_1_data : std_logic_vector(15 downto 0);
    signal fma5_gi_mult_1_valid : std_logic;
    signal fma5_gi_mult_2_data : std_logic_vector(15 downto 0);
    signal fma5_gi_mult_2_valid : std_logic;
    signal fma5_gi_add_data : std_logic_vector(15 downto 0);
    signal fma5_gi_add_valid : std_logic;
    signal fma5_gi_result_data : std_logic_vector(15 downto 0);
    signal fma5_gi_result_valid : std_logic;

    signal fma6_gh_mult_1_data : std_logic_vector(15 downto 0);
    signal fma6_gh_mult_1_valid : std_logic;
    signal fma6_gh_mult_2_data : std_logic_vector(15 downto 0);
    signal fma6_gh_mult_2_valid : std_logic;
    signal fma6_gh_add_data : std_logic_vector(15 downto 0);
    signal fma6_gh_add_valid : std_logic;
    signal fma6_gh_result_data : std_logic_vector(15 downto 0);
    signal fma6_gh_result_valid : std_logic;

    signal fma7_oi_mult_1_data : std_logic_vector(15 downto 0);
    signal fma7_oi_mult_1_valid : std_logic;
    signal fma7_oi_mult_2_data : std_logic_vector(15 downto 0);
    signal fma7_oi_mult_2_valid : std_logic;
    signal fma7_oi_add_data : std_logic_vector(15 downto 0);
    signal fma7_oi_add_valid : std_logic;
    signal fma7_oi_result_data : std_logic_vector(15 downto 0);
    signal fma7_oi_result_valid : std_logic;

    signal fma8_oh_mult_1_data : std_logic_vector(15 downto 0);
    signal fma8_oh_mult_1_valid : std_logic;
    signal fma8_oh_mult_2_data : std_logic_vector(15 downto 0);
    signal fma8_oh_mult_2_valid : std_logic;
    signal fma8_oh_add_data : std_logic_vector(15 downto 0);
    signal fma8_oh_add_valid : std_logic;
    signal fma8_oh_result_data : std_logic_vector(15 downto 0);
    signal fma8_oh_result_valid : std_logic;

    -- Tanh and Sigmoid signals
    signal sig_1_input_data : std_logic_vector(15 downto 0) := (others => '0');
    signal sig_1_input_valid : std_logic := '0';

    signal sig_1_slope_data : std_logic_vector(15 downto 0);
    signal sig_1_slope_valid : std_logic;

    signal sig_1_offset_data : std_logic_vector(15 downto 0);
    signal sig_1_offset_valid : std_logic;

    signal sig_1_input_out_data : std_logic_vector(15 downto 0);
    signal sig_1_input_out_valid : std_logic;

    signal sig_1_value_data : std_logic_vector(15 downto 0);
    signal sig_1_value_valid : std_logic;

    signal sig_2_input_data : std_logic_vector(15 downto 0) := (others => '0');
    signal sig_2_input_valid : std_logic := '0';

    signal sig_2_slope_data : std_logic_vector(15 downto 0);
    signal sig_2_slope_valid : std_logic;

    signal sig_2_offset_data : std_logic_vector(15 downto 0);
    signal sig_2_offset_valid : std_logic;

    signal sig_2_input_out_data : std_logic_vector(15 downto 0);
    signal sig_2_input_out_valid : std_logic;

    signal sig_2_value_data : std_logic_vector(15 downto 0);
    signal sig_2_value_valid : std_logic;

    signal tanh_input_data : std_logic_vector(15 downto 0) := (others => '0');
    signal tanh_input_valid : std_logic := '0';

    signal tanh_slope_data : std_logic_vector(15 downto 0);
    signal tanh_slope_valid : std_logic;

    signal tanh_offset_data : std_logic_vector(15 downto 0);
    signal tanh_offset_valid : std_logic;

    signal tanh_input_out_data : std_logic_vector(15 downto 0);
    signal tanh_input_out_valid : std_logic;

    signal tanh_value_data : std_logic_vector(15 downto 0);
    signal tanh_value_valid : std_logic;

    -- Signals specifying the activation function method
    type activation_t is (PWL, VALUE);
    signal sig_1_method : activation_t := PWL;
    signal sig_2_method : activation_t := PWL;
    signal tanh_method : activation_t := PWL;

    -- Signals to use for buffering in the post state
    type post_buffer_arr_t is array(1 to 10) of std_logic_vector(15 downto 0);
    signal post_buffer : post_buffer_arr_t := (others => (others => '0'));

    -- C buffer and biases
    signal c_t : std_logic_vector(15 downto 0) := (others => '0');
    signal i_bias : std_logic_vector(15 downto 0) := (others => '0');
    signal f_bias : std_logic_vector(15 downto 0) := (others => '0');
    signal g_bias : std_logic_vector(15 downto 0) := (others => '0');
    signal o_bias : std_logic_vector(15 downto 0) := (others => '0');

    -- State machine with accumulate and post states
    type pe_state_t is (ACCUMULATE, ACC_FINISHED, POST);
    signal pe_state : pe_state_t := ACCUMULATE;

    type pe_post_state_t is (S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11);
    signal pe_post_state : pe_post_state_t := S1;
begin
    
    process(clk)
        variable first_iter : boolean := true;

        type result_buffer_arr_t is array(0 to 7) of std_logic_vector(15 downto 0);
        variable result_buffer : result_buffer_arr_t := (others => (others => '0'));
        variable result_buffered : boolean := false;

        variable post_init : boolean := true;

        type operator_state_t is (IDLE, WAITING, DONE);
        variable fma1_state : operator_state_t := IDLE;
        variable fma2_state : operator_state_t := IDLE;
        variable fma3_state : operator_state_t := IDLE;
        variable fma4_state : operator_state_t := IDLE;
        variable fma5_state : operator_state_t := IDLE;
        variable fma6_state : operator_state_t := IDLE;
        variable fma7_state : operator_state_t := IDLE;
        variable fma8_state : operator_state_t := IDLE;
        variable sig_1_state : operator_state_t := IDLE;
        variable sig_2_state : operator_state_t := IDLE;
        variable tanh_state : operator_state_t := IDLE;
    begin
        if rising_edge(clk) then
            case pe_state is
                when ACCUMULATE =>
                    m_axis_hidden_out_data <= (others => '0');
                    m_axis_hidden_out_valid <= '0';

                    s_axis_c_t_out_valid <= '0';
                    s_axis_c_t_out_data <= (others => '0');

                    s_axis_c_in_and_bias_ready <= '1';

                    if s_axis_c_t_in_valid = '1' then
                        c_t <= s_axis_c_t_in_data;
                    end if;

                    if s_axis_i_bias_valid = '1' then
                        i_bias <= s_axis_i_bias_data;
                    end if;

                    if s_axis_f_bias_valid = '1' then
                        f_bias <= s_axis_f_bias_data;
                    end if;

                    if s_axis_g_bias_valid = '1' then
                        g_bias <= s_axis_g_bias_data;
                    end if;

                    if s_axis_o_bias_valid = '1' then
                        o_bias <= s_axis_o_bias_data;
                    end if;

                    if s_axis_pe_valid = '1' then
                        if s_axis_pe_last = '1' then
                            pe_state <= ACC_FINISHED;
                            s_axis_pe_ready <= '0';
                            post_init := true;
                        else
                            s_axis_pe_ready <= '1';
                        end if;

                        fma1_ii_mult_1_data <= s_axis_data_in;
                        fma1_ii_mult_1_valid <= '1';
                        fma1_ii_mult_2_data <= s_axis_weight_i_input_data;
                        fma1_ii_mult_2_valid <= '1';

                        fma2_ih_mult_1_data <= s_axis_hidden_data;
                        fma2_ih_mult_1_valid <= '1';
                        fma2_ih_mult_2_data <= s_axis_weight_i_hidden_data;
                        fma2_ih_mult_2_valid <= '1';

                        fma3_fi_mult_1_data <= s_axis_data_in;
                        fma3_fi_mult_1_valid <= '1';
                        fma3_fi_mult_2_data <= s_axis_weight_f_input_data;
                        fma3_fi_mult_2_valid <= '1';

                        fma4_fh_mult_1_data <= s_axis_hidden_data;
                        fma4_fh_mult_1_valid <= '1';
                        fma4_fh_mult_2_data <= s_axis_weight_f_hidden_data;
                        fma4_fh_mult_2_valid <= '1';

                        fma5_gi_mult_1_data <= s_axis_data_in;
                        fma5_gi_mult_1_valid <= '1';
                        fma5_gi_mult_2_data <= s_axis_weight_g_input_data;
                        fma5_gi_mult_2_valid <= '1';

                        fma6_gh_mult_1_data <= s_axis_hidden_data;
                        fma6_gh_mult_1_valid <= '1';
                        fma6_gh_mult_2_data <= s_axis_weight_g_hidden_data;
                        fma6_gh_mult_2_valid <= '1';

                        fma7_oi_mult_1_data <= s_axis_data_in;
                        fma7_oi_mult_1_valid <= '1';
                        fma7_oi_mult_2_data <= s_axis_weight_o_input_data;
                        fma7_oi_mult_2_valid <= '1';

                        fma8_oh_mult_1_data <= s_axis_hidden_data;
                        fma8_oh_mult_1_valid <= '1';
                        fma8_oh_mult_2_data <= s_axis_weight_o_hidden_data;
                        fma8_oh_mult_2_valid <= '1';

                        if first_iter then
                            fma1_ii_add_data <= (others => '0');
                            fma1_ii_add_valid <= '1';

                            fma2_ih_add_data <= (others => '0');
                            fma2_ih_add_valid <= '1';

                            fma3_fi_add_data <= (others => '0');
                            fma3_fi_add_valid <= '1';

                            fma4_fh_add_data <= (others => '0');
                            fma4_fh_add_valid <= '1';

                            fma5_gi_add_data <= (others => '0');
                            fma5_gi_add_valid <= '1';

                            fma6_gh_add_data <= (others => '0');
                            fma6_gh_add_valid <= '1';

                            fma7_oi_add_data <= (others => '0');
                            fma7_oi_add_valid <= '1';

                            fma8_oh_add_data <= (others => '0');
                            fma8_oh_add_valid <= '1';

                            first_iter := false;
                        else
                            if result_buffered then
                                fma1_ii_add_data <= result_buffer(0);
                                fma1_ii_add_valid <= '1';

                                fma2_ih_add_data <= result_buffer(1);
                                fma2_ih_add_valid <= '1';

                                fma3_fi_add_data <= result_buffer(2);
                                fma3_fi_add_valid <= '1';

                                fma4_fh_add_data <= result_buffer(3);
                                fma4_fh_add_valid <= '1';

                                fma5_gi_add_data <= result_buffer(4);
                                fma5_gi_add_valid <= '1';

                                fma6_gh_add_data <= result_buffer(5);
                                fma6_gh_add_valid <= '1';

                                fma7_oi_add_data <= result_buffer(6);
                                fma7_oi_add_valid <= '1';

                                fma8_oh_add_data <= result_buffer(7);
                                fma8_oh_add_valid <= '1';

                                result_buffered := false;
                            else
                                fma1_ii_add_data <= fma1_ii_result_data;
                                fma1_ii_add_valid <= '1';

                                fma2_ih_add_data <= fma2_ih_result_data;
                                fma2_ih_add_valid <= '1';

                                fma3_fi_add_data <= fma3_fi_result_data;
                                fma3_fi_add_valid <= '1';

                                fma4_fh_add_data <= fma4_fh_result_data;
                                fma4_fh_add_valid <= '1';

                                fma5_gi_add_data <= fma5_gi_result_data;
                                fma5_gi_add_valid <= '1';

                                fma6_gh_add_data <= fma6_gh_result_data;
                                fma6_gh_add_valid <= '1';

                                fma7_oi_add_data <= fma7_oi_result_data;
                                fma7_oi_add_valid <= '1';

                                fma8_oh_add_data <= fma8_oh_result_data;
                                fma8_oh_add_valid <= '1';
                            end if;
                        end if;
                    else
                        s_axis_pe_ready <= '1';

                        if not first_iter then
                            result_buffer(0) := fma1_ii_result_data;
                            result_buffer(1) := fma2_ih_result_data;
                            result_buffer(2) := fma3_fi_result_data;
                            result_buffer(3) := fma4_fh_result_data;
                            result_buffer(4) := fma5_gi_result_data;
                            result_buffer(5) := fma6_gh_result_data;
                            result_buffer(6) := fma7_oi_result_data;
                            result_buffer(7) := fma8_oh_result_data;
                            result_buffered := true;
                        end if;

                        fma1_ii_mult_1_data <= (others => '0');
                        fma1_ii_mult_1_valid <= '0';
                        fma1_ii_mult_2_data <= (others => '0');
                        fma1_ii_mult_2_valid <= '0';
                        fma1_ii_add_data <= (others => '0');
                        fma1_ii_add_valid <= '0';

                        fma2_ih_mult_1_data <= (others => '0');
                        fma2_ih_mult_1_valid <= '0';
                        fma2_ih_mult_2_data <= (others => '0');
                        fma2_ih_mult_2_valid <= '0';
                        fma2_ih_add_data <= (others => '0');
                        fma2_ih_add_valid <= '0';

                        fma3_fi_mult_1_data <= (others => '0');
                        fma3_fi_mult_1_valid <= '0';
                        fma3_fi_mult_2_data <= (others => '0');
                        fma3_fi_mult_2_valid <= '0';
                        fma3_fi_add_data <= (others => '0');
                        fma3_fi_add_valid <= '0';

                        fma4_fh_mult_1_data <= (others => '0');
                        fma4_fh_mult_1_valid <= '0';
                        fma4_fh_mult_2_data <= (others => '0');
                        fma4_fh_mult_2_valid <= '0';
                        fma4_fh_add_data <= (others => '0');
                        fma4_fh_add_valid <= '0';

                        fma5_gi_mult_1_data <= (others => '0');
                        fma5_gi_mult_1_valid <= '0';
                        fma5_gi_mult_2_data <= (others => '0');
                        fma5_gi_mult_2_valid <= '0';
                        fma5_gi_add_data <= (others => '0');
                        fma5_gi_add_valid <= '0';

                        fma6_gh_mult_1_data <= (others => '0');
                        fma6_gh_mult_1_valid <= '0';
                        fma6_gh_mult_2_data <= (others => '0');
                        fma6_gh_mult_2_valid <= '0';
                        fma6_gh_add_data <= (others => '0');
                        fma6_gh_add_valid <= '0';

                        fma7_oi_mult_1_data <= (others => '0');
                        fma7_oi_mult_1_valid <= '0';
                        fma7_oi_mult_2_data <= (others => '0');
                        fma7_oi_mult_2_valid <= '0';
                        fma7_oi_add_data <= (others => '0');
                        fma7_oi_add_valid <= '0';

                        fma8_oh_mult_1_data <= (others => '0');
                        fma8_oh_mult_1_valid <= '0';
                        fma8_oh_mult_2_data <= (others => '0');
                        fma8_oh_mult_2_valid <= '0';
                        fma8_oh_add_data <= (others => '0');
                        fma8_oh_add_valid <= '0';
                    end if;
                when ACC_FINISHED =>
                    s_axis_pe_ready <= '0';
                    s_axis_c_t_out_valid <= '0';
                    s_axis_c_t_out_data <= (others => '0');

                    s_axis_c_in_and_bias_ready <= '1';

                    if s_axis_c_t_in_valid = '1' then
                        c_t <= s_axis_c_t_in_data;
                    end if;

                    if s_axis_i_bias_valid = '1' then
                        i_bias <= s_axis_i_bias_data;
                    end if;

                    if s_axis_f_bias_valid = '1' then
                        f_bias <= s_axis_f_bias_data;
                    end if;

                    if s_axis_g_bias_valid = '1' then
                        g_bias <= s_axis_g_bias_data;
                    end if;

                    if s_axis_o_bias_valid = '1' then
                        o_bias <= s_axis_o_bias_data;
                    end if;

                    if post_allowed = '1' then
                        pe_state <= POST; 
                    end if;

                    -- Initialize the post state
                    pe_post_state <= S1;

                    if post_init then
                        post_buffer(1) <= fma1_ii_result_data;
                        post_buffer(2) <= fma2_ih_result_data;
                        post_buffer(3) <= fma3_fi_result_data;
                        post_buffer(4) <= fma4_fh_result_data;
                        post_buffer(5) <= fma5_gi_result_data;
                        post_buffer(6) <= fma6_gh_result_data;
                        post_buffer(7) <= fma7_oi_result_data;
                        post_buffer(8) <= fma8_oh_result_data;

                        post_init := false;
                    end if;

                    fma1_state := IDLE;
                    fma2_state := IDLE;
                    fma3_state := IDLE;
                    fma4_state := IDLE;
                    fma5_state := IDLE;
                    fma6_state := IDLE;
                    fma7_state := IDLE;
                    fma8_state := IDLE;

                    sig_1_state := IDLE;
                    sig_2_state := IDLE;
                    tanh_state := IDLE;

                    m_axis_hidden_out_data <= (others => '0');
                    m_axis_hidden_out_valid <= '0';

                    fma1_ii_mult_1_data <= (others => '0');
                    fma1_ii_mult_1_valid <= '0';
                    fma1_ii_mult_2_data <= (others => '0');
                    fma1_ii_mult_2_valid <= '0';
                    fma1_ii_add_data <= (others => '0');
                    fma1_ii_add_valid <= '0';

                    fma2_ih_mult_1_data <= (others => '0');
                    fma2_ih_mult_1_valid <= '0';
                    fma2_ih_mult_2_data <= (others => '0');
                    fma2_ih_mult_2_valid <= '0';
                    fma2_ih_add_data <= (others => '0');
                    fma2_ih_add_valid <= '0';

                    fma3_fi_mult_1_data <= (others => '0');
                    fma3_fi_mult_1_valid <= '0';
                    fma3_fi_mult_2_data <= (others => '0');
                    fma3_fi_mult_2_valid <= '0';
                    fma3_fi_add_data <= (others => '0');
                    fma3_fi_add_valid <= '0';

                    fma4_fh_mult_1_data <= (others => '0');
                    fma4_fh_mult_1_valid <= '0';
                    fma4_fh_mult_2_data <= (others => '0');
                    fma4_fh_mult_2_valid <= '0';
                    fma4_fh_add_data <= (others => '0');
                    fma4_fh_add_valid <= '0';

                    fma5_gi_mult_1_data <= (others => '0');
                    fma5_gi_mult_1_valid <= '0';
                    fma5_gi_mult_2_data <= (others => '0');
                    fma5_gi_mult_2_valid <= '0';
                    fma5_gi_add_data <= (others => '0');
                    fma5_gi_add_valid <= '0';

                    fma6_gh_mult_1_data <= (others => '0');
                    fma6_gh_mult_1_valid <= '0';
                    fma6_gh_mult_2_data <= (others => '0');
                    fma6_gh_mult_2_valid <= '0';
                    fma6_gh_add_data <= (others => '0');
                    fma6_gh_add_valid <= '0';

                    fma7_oi_mult_1_data <= (others => '0');
                    fma7_oi_mult_1_valid <= '0';
                    fma7_oi_mult_2_data <= (others => '0');
                    fma7_oi_mult_2_valid <= '0';
                    fma7_oi_add_data <= (others => '0');
                    fma7_oi_add_valid <= '0';

                    fma8_oh_mult_1_data <= (others => '0');
                    fma8_oh_mult_1_valid <= '0';
                    fma8_oh_mult_2_data <= (others => '0');
                    fma8_oh_mult_2_valid <= '0';
                    fma8_oh_add_data <= (others => '0');
                    fma8_oh_add_valid <= '0';
                when POST =>
                    s_axis_pe_ready <= '0';

                    s_axis_c_in_and_bias_ready <= '0';

                    case pe_post_state is
                        when S1 =>
                            -- Stage 1: The output of the i, g, f, and o macs are added together. So input + hidden
                            -- Buffers
                            -- 1: i_inp => i_inp + i_hid
                            -- 2: i_hid => f_inp + f_hid
                            -- 3: f_inp => g_inp + g_hid
                            -- 4: f_hid
                            -- 5: g_inp
                            -- 6: g_hid
                            -- 7: o_inp
                            -- 8: o_hid
                            -- 9: empty
                            -- 10: empty => o_inp + o_hid

                            if fma1_state = IDLE then
                                fma1_ii_mult_1_data <= post_buffer(1);
                                fma1_ii_mult_1_valid <= '1';
                                fma1_ii_mult_2_data <= x"3F80"; -- 1.0
                                fma1_ii_mult_2_valid <= '1';
                                fma1_ii_add_data <= post_buffer(2);
                                fma1_ii_add_valid <= '1';
                                fma1_state := WAITING;
                            elsif fma1_state = WAITING then
                                if fma1_ii_result_valid = '1' then
                                    post_buffer(1) <= fma1_ii_result_data;
                                    fma1_state := DONE;

                                    fma1_ii_mult_1_data <= (others => '0');
                                    fma1_ii_mult_1_valid <= '0';
                                    fma1_ii_mult_2_data <= (others => '0');
                                    fma1_ii_mult_2_valid <= '0';
                                    fma1_ii_add_data <= (others => '0');
                                    fma1_ii_add_valid <= '0';
                                end if;
                            end if;

                            if fma2_state = IDLE then
                                fma2_ih_mult_1_data <= post_buffer(3);
                                fma2_ih_mult_1_valid <= '1';
                                fma2_ih_mult_2_data <= x"3F80"; -- 1.0
                                fma2_ih_mult_2_valid <= '1';
                                fma2_ih_add_data <= post_buffer(4);
                                fma2_ih_add_valid <= '1';
                                fma2_state := WAITING;
                            elsif fma2_state = WAITING then
                                if fma2_ih_result_valid = '1' then
                                    post_buffer(2) <= fma2_ih_result_data;
                                    fma2_state := DONE;

                                    fma2_ih_mult_1_data <= (others => '0');
                                    fma2_ih_mult_1_valid <= '0';
                                    fma2_ih_mult_2_data <= (others => '0');
                                    fma2_ih_mult_2_valid <= '0';
                                    fma2_ih_add_data <= (others => '0');
                                    fma2_ih_add_valid <= '0';
                                end if;
                            end if;

                            if fma3_state = IDLE then
                                fma3_fi_mult_1_data <= post_buffer(5);
                                fma3_fi_mult_1_valid <= '1';
                                fma3_fi_mult_2_data <= x"3F80"; -- 1.0
                                fma3_fi_mult_2_valid <= '1';
                                fma3_fi_add_data <= post_buffer(6);
                                fma3_fi_add_valid <= '1';
                                fma3_state := WAITING;
                            elsif fma3_state = WAITING then
                                if fma3_fi_result_valid = '1' then
                                    post_buffer(3) <= fma3_fi_result_data;
                                    fma3_state := DONE;

                                    fma3_fi_mult_1_data <= (others => '0');
                                    fma3_fi_mult_1_valid <= '0';
                                    fma3_fi_mult_2_data <= (others => '0');
                                    fma3_fi_mult_2_valid <= '0';
                                    fma3_fi_add_data <= (others => '0');
                                    fma3_fi_add_valid <= '0';
                                end if;
                            end if;

                            if fma4_state = IDLE then
                                fma4_fh_mult_1_data <= post_buffer(7);
                                fma4_fh_mult_1_valid <= '1';
                                fma4_fh_mult_2_data <= x"3F80"; -- 1.0
                                fma4_fh_mult_2_valid <= '1';
                                fma4_fh_add_data <= post_buffer(8);
                                fma4_fh_add_valid <= '1';
                                fma4_state := WAITING;
                            elsif fma4_state = WAITING then
                                if fma4_fh_result_valid = '1' then
                                    post_buffer(10) <= fma4_fh_result_data;
                                    fma4_state := DONE;

                                    fma4_fh_mult_1_data <= (others => '0');
                                    fma4_fh_mult_1_valid <= '0';
                                    fma4_fh_mult_2_data <= (others => '0');
                                    fma4_fh_mult_2_valid <= '0';
                                    fma4_fh_add_data <= (others => '0');
                                    fma4_fh_add_valid <= '0';
                                end if;
                            end if;

                            if fma1_state = DONE and fma2_state = DONE and fma3_state = DONE and fma4_state = DONE then
                                pe_post_state <= S2;
                                fma1_state := IDLE;
                                fma2_state := IDLE;
                                fma3_state := IDLE;
                                fma4_state := IDLE;
                            end if;   
                        when S2 =>
                            -- Stage 2: The output of the i, g, and f of the previous stage are added with their corresponding biases

                            -- Buffers
                            -- 1: i_inp + i_hid => i_inp + i_hid + i_bias
                            -- 2: f_inp + f_hid => f_inp + f_hid + f_bias
                            -- 3: g_inp + g_hid => g_inp + g_hid + g_bias
                            -- 4: empty
                            -- 5: empty
                            -- 6: empty
                            -- 7: empty
                            -- 8: empty
                            -- 9: empty 
                            -- 10: o_inp + o_hid => o_inp + o_hid + o_bias    
                            
                            if fma1_state = IDLE then
                                fma1_ii_mult_1_data <= post_buffer(1);
                                fma1_ii_mult_1_valid <= '1';
                                fma1_ii_mult_2_data <= x"3F80"; -- 1.0
                                fma1_ii_mult_2_valid <= '1';
                                fma1_ii_add_data <= i_bias;
                                fma1_ii_add_valid <= '1';
                                fma1_state := WAITING;
                            elsif fma1_state = WAITING then
                                if fma1_ii_result_valid = '1' then
                                    post_buffer(1) <= fma1_ii_result_data;
                                    fma1_state := DONE;

                                    fma1_ii_mult_1_data <= (others => '0');
                                    fma1_ii_mult_1_valid <= '0';
                                    fma1_ii_mult_2_data <= (others => '0');
                                    fma1_ii_mult_2_valid <= '0';
                                    fma1_ii_add_data <= (others => '0');
                                    fma1_ii_add_valid <= '0';
                                end if;
                            end if;

                            if fma2_state = IDLE then
                                fma2_ih_mult_1_data <= post_buffer(2);
                                fma2_ih_mult_1_valid <= '1';
                                fma2_ih_mult_2_data <= x"3F80"; -- 1.0
                                fma2_ih_mult_2_valid <= '1';
                                fma2_ih_add_data <= f_bias;
                                fma2_ih_add_valid <= '1';
                                fma2_state := WAITING;
                            elsif fma2_state = WAITING then
                                if fma2_ih_result_valid = '1' then
                                    post_buffer(2) <= fma2_ih_result_data;
                                    fma2_state := DONE;

                                    fma2_ih_mult_1_data <= (others => '0');
                                    fma2_ih_mult_1_valid <= '0';
                                    fma2_ih_mult_2_data <= (others => '0');
                                    fma2_ih_mult_2_valid <= '0';
                                    fma2_ih_add_data <= (others => '0');
                                    fma2_ih_add_valid <= '0';
                                end if;
                            end if;

                            if fma3_state = IDLE then
                                fma3_fi_mult_1_data <= post_buffer(3);
                                fma3_fi_mult_1_valid <= '1';
                                fma3_fi_mult_2_data <= x"3F80"; -- 1.0
                                fma3_fi_mult_2_valid <= '1';
                                fma3_fi_add_data <= g_bias;
                                fma3_fi_add_valid <= '1';
                                fma3_state := WAITING;
                            elsif fma3_state = WAITING then
                                if fma3_fi_result_valid = '1' then
                                    post_buffer(3) <= fma3_fi_result_data;
                                    fma3_state := DONE;

                                    fma3_fi_mult_1_data <= (others => '0');
                                    fma3_fi_mult_1_valid <= '0';
                                    fma3_fi_mult_2_data <= (others => '0');
                                    fma3_fi_mult_2_valid <= '0';
                                    fma3_fi_add_data <= (others => '0');
                                    fma3_fi_add_valid <= '0';
                                end if;
                            end if;

                            if fma4_state = IDLE then
                                fma4_fh_mult_1_data <= post_buffer(10);
                                fma4_fh_mult_1_valid <= '1';
                                fma4_fh_mult_2_data <= x"3F80"; -- 1.0
                                fma4_fh_mult_2_valid <= '1';
                                fma4_fh_add_data <= o_bias;
                                fma4_fh_add_valid <= '1';
                                fma4_state := WAITING;
                            elsif fma4_state = WAITING then
                                if fma4_fh_result_valid = '1' then
                                    post_buffer(10) <= fma4_fh_result_data;
                                    fma4_state := DONE;

                                    fma4_fh_mult_1_data <= (others => '0');
                                    fma4_fh_mult_1_valid <= '0';
                                    fma4_fh_mult_2_data <= (others => '0');
                                    fma4_fh_mult_2_valid <= '0';
                                    fma4_fh_add_data <= (others => '0');
                                    fma4_fh_add_valid <= '0';
                                end if;
                            end if;

                            if fma1_state = DONE and fma2_state = DONE and fma3_state = DONE and fma4_state = DONE then
                                pe_post_state <= S3;
                                fma1_state := IDLE;
                                fma2_state := IDLE;
                                fma3_state := IDLE;
                                fma4_state := IDLE;
                            end if;
                        when S3 =>
                            -- Stage 3: The outputs are now activated with i and f being sigmoid and g being tanh
                            -- The first stage of the activation is arbiting the slope of the piecewise linear function approximation
                            
                            -- Buffers
                            -- 1: i + i_bias => i + i_bias | sig(i + i_bias)
                            -- 2: f + f_bias => i_sig slope | empty
                            -- 3: g + g_bias => i_sig offset | empty
                            -- 4: empty => f + f_bias | sig(f + f_bias)
                            -- 5: empty => f_sig slope | empty
                            -- 6: empty => f_sig offset | empty
                            -- 7: empty => g + g_bias | tanh(g + g_bias)
                            -- 8: empty => g_tanh slope | empty
                            -- 9: empty => g_tanh offset | empty
                            -- 10: o + o_bias

                            if sig_1_state = IDLE then
                                sig_1_input_data <= post_buffer(1);
                                sig_1_input_valid<= '1';
                                sig_1_state := WAITING;
                            elsif sig_1_state = WAITING then
                                if sig_1_value_valid = '1' then
                                    post_buffer(1) <= sig_1_value_data;
                                    sig_1_state := DONE;

                                    sig_1_method <= VALUE;

                                    sig_1_input_data <= (others => '0');
                                    sig_1_input_valid<= '0';
                                elsif sig_1_input_out_valid = '1' and sig_1_offset_valid = '1' and sig_1_slope_valid = '1' then
                                    post_buffer(1) <= sig_1_input_out_data;
                                    post_buffer(2) <= sig_1_slope_data;
                                    post_buffer(3) <= sig_1_offset_data;                                    
                                    sig_1_state := DONE;

                                    sig_1_method <= PWL;

                                    sig_1_input_data <= (others => '0');
                                    sig_1_input_valid<= '0';
                                end if;
                            end if;

                            if sig_2_state = IDLE then
                                sig_2_input_data <= post_buffer(2);
                                sig_2_input_valid<= '1';
                                sig_2_state := WAITING;
                            elsif sig_2_state = WAITING then
                                if sig_2_value_valid = '1' then
                                    post_buffer(2) <= sig_2_value_data;
                                    sig_2_state := DONE;

                                    sig_2_method <= VALUE;

                                    sig_2_input_data <= (others => '0');
                                    sig_2_input_valid<= '0';
                                elsif sig_2_input_out_valid = '1' and sig_2_offset_valid = '1' and sig_2_slope_valid = '1' then
                                    post_buffer(4) <= sig_2_input_out_data;
                                    post_buffer(5) <= sig_2_slope_data;
                                    post_buffer(6) <= sig_2_offset_data;                                    
                                    sig_2_state := DONE;

                                    sig_2_method <= PWL;

                                    sig_2_input_data <= (others => '0');
                                    sig_2_input_valid<= '0';
                                end if;
                            end if;

                            if tanh_state = IDLE then
                                tanh_input_data <= post_buffer(3);
                                tanh_input_valid<= '1';
                                tanh_state := WAITING;
                            elsif tanh_state = WAITING then
                                if tanh_value_valid = '1' then
                                    post_buffer(3) <= tanh_value_data;
                                    tanh_state := DONE;

                                    tanh_method <= VALUE;

                                    tanh_input_data <= (others => '0');
                                    tanh_input_valid<= '0';
                                elsif tanh_input_out_valid = '1' and tanh_offset_valid = '1' and tanh_slope_valid = '1' then
                                    post_buffer(7) <= tanh_input_out_data;
                                    post_buffer(8) <= tanh_slope_data;
                                    post_buffer(9) <= tanh_offset_data;                                    
                                    tanh_state := DONE;

                                    tanh_method <= PWL;

                                    tanh_input_data <= (others => '0');
                                    tanh_input_valid<= '0';
                                end if;
                            end if;

                            if sig_1_state = DONE and sig_2_state = DONE and tanh_state = DONE then
                                pe_post_state <= S4;
                                sig_1_state := IDLE;
                                sig_2_state := IDLE;
                                tanh_state := IDLE;
                            end if;
                        when S4 =>
                            -- Stage 4: Depending on the method, the outputs are fed to the fmadd (PWL) otherwise the value is passed through

                            -- Buffers
                            -- 1: i + i_bias | sig(i + i_bias) => sig(i)
                            -- 2: i_sig slope | empty
                            -- 3: i_sig offset | empty
                            -- 4: f + f_bias | sig(f + f_bias) => sig(f)
                            -- 5: f_sig slope | empty
                            -- 6: f_sig offset | empty
                            -- 7: g + g_bias | tanh(g + g_bias) => tanh(g)
                            -- 8: g_tanh slope | empty
                            -- 9: g_tanh offset | empty
                            -- 10: o

                            if sig_1_method = VALUE then
                                fma1_state := DONE;
                            else
                                if fma1_state = IDLE then
                                    fma1_ii_mult_1_data <= post_buffer(1);
                                    fma1_ii_mult_1_valid <= '1';
                                    fma1_ii_mult_2_data <= post_buffer(2);
                                    fma1_ii_mult_2_valid <= '1';
                                    fma1_ii_add_data <= post_buffer(3);
                                    fma1_ii_add_valid <= '1';
                                    fma1_state := WAITING;
                                elsif fma1_state = WAITING then
                                    if fma1_ii_result_valid = '1' then
                                        post_buffer(1) <= fma1_ii_result_data;
                                        fma1_state := DONE;

                                        fma1_ii_mult_1_data <= (others => '0');
                                        fma1_ii_mult_1_valid <= '0';
                                        fma1_ii_mult_2_data <= (others => '0');
                                        fma1_ii_mult_2_valid <= '0';
                                        fma1_ii_add_data <= (others => '0');
                                        fma1_ii_add_valid <= '0';
                                    end if;
                                end if;
                            end if;

                            if sig_2_method = VALUE then
                                fma2_state := DONE;
                            else
                                if fma2_state = IDLE then
                                    fma2_ih_mult_1_data <= post_buffer(4);
                                    fma2_ih_mult_1_valid <= '1';
                                    fma2_ih_mult_2_data <= post_buffer(5);
                                    fma2_ih_mult_2_valid <= '1';
                                    fma2_ih_add_data <= post_buffer(6);
                                    fma2_ih_add_valid <= '1';
                                    fma2_state := WAITING;
                                elsif fma2_state = WAITING then
                                    if fma2_ih_result_valid = '1' then
                                        post_buffer(4) <= fma2_ih_result_data;
                                        fma2_state := DONE;

                                        fma2_ih_mult_1_data <= (others => '0');
                                        fma2_ih_mult_1_valid <= '0';
                                        fma2_ih_mult_2_data <= (others => '0');
                                        fma2_ih_mult_2_valid <= '0';
                                        fma2_ih_add_data <= (others => '0');
                                        fma2_ih_add_valid <= '0';
                                    end if;
                                end if;
                            end if;

                            if tanh_method = VALUE then
                                fma3_state := DONE;
                            else
                                if fma3_state = IDLE then
                                    fma3_fi_mult_1_data <= post_buffer(7);
                                    fma3_fi_mult_1_valid <= '1';
                                    fma3_fi_mult_2_data <= post_buffer(8);
                                    fma3_fi_mult_2_valid <= '1';
                                    fma3_fi_add_data <= post_buffer(9);
                                    fma3_fi_add_valid <= '1';
                                    fma3_state := WAITING;
                                elsif fma3_state = WAITING then
                                    if fma3_fi_result_valid = '1' then
                                        post_buffer(7) <= fma3_fi_result_data;
                                        fma3_state := DONE;

                                        fma3_fi_mult_1_data <= (others => '0');
                                        fma3_fi_mult_1_valid <= '0';
                                        fma3_fi_mult_2_data <= (others => '0');
                                        fma3_fi_mult_2_valid <= '0';
                                        fma3_fi_add_data <= (others => '0');
                                        fma3_fi_add_valid <= '0';
                                    end if;
                                end if;
                            end if;

                            if fma1_state = DONE and fma2_state = DONE and fma3_state = DONE then
                                pe_post_state <= S5;
                                fma1_state := IDLE;
                                fma2_state := IDLE;
                                fma3_state := IDLE;
                            end if;
                        when S5 =>
                            -- Stage 5: Multiply the I and G results and multiply the F and C value

                            -- Buffers
                            -- 1: sig(i) => sig(i) * tanh(g)
                            -- 2: empty => sig(f) * c_t
                            -- 3: empty
                            -- 4: sig(f) => empty
                            -- 5: empty
                            -- 6: empty
                            -- 7: tanh(g) => empty
                            -- 8: empty
                            -- 9: empty
                            -- 10: o

                            if fma1_state = IDLE then
                                fma1_ii_mult_1_data <= post_buffer(1);
                                fma1_ii_mult_1_valid <= '1';
                                fma1_ii_mult_2_data <= post_buffer(7);
                                fma1_ii_mult_2_valid <= '1';
                                fma1_ii_add_data <= (others => '0');
                                fma1_ii_add_valid <= '1';
                                fma1_state := WAITING;
                            elsif fma1_state = WAITING then
                                if fma1_ii_result_valid = '1' then
                                    post_buffer(1) <= fma1_ii_result_data;
                                    fma1_state := DONE;

                                    fma1_ii_mult_1_data <= (others => '0');
                                    fma1_ii_mult_1_valid <= '0';
                                    fma1_ii_mult_2_data <= (others => '0');
                                    fma1_ii_mult_2_valid <= '0';
                                    fma1_ii_add_data <= (others => '0');
                                    fma1_ii_add_valid <= '0';
                                end if;
                            end if;

                            if fma2_state = IDLE then
                                fma2_ih_mult_1_data <= post_buffer(4);
                                fma2_ih_mult_1_valid <= '1';
                                fma2_ih_mult_2_data <= C_T;
                                fma2_ih_mult_2_valid <= '1';
                                fma2_ih_add_data <= (others => '0');
                                fma2_ih_add_valid <= '1';
                                fma2_state := WAITING;
                            elsif fma2_state = WAITING then
                                if fma2_ih_result_valid = '1' then
                                    post_buffer(2) <= fma2_ih_result_data;
                                    fma2_state := DONE;

                                    fma2_ih_mult_1_data <= (others => '0');
                                    fma2_ih_mult_1_valid <= '0';
                                    fma2_ih_mult_2_data <= (others => '0');
                                    fma2_ih_mult_2_valid <= '0';
                                    fma2_ih_add_data <= (others => '0');
                                    fma2_ih_add_valid <= '0';
                                end if;
                            end if;

                            if fma1_state = DONE and fma2_state = DONE then
                                pe_post_state <= S6;
                                fma1_state := IDLE;
                                fma2_state := IDLE;
                            end if;
                        when S6 =>
                            -- Stage 7: Add the results of the multiplications together
                            -- Additionally write c_t+1 to the memory

                            -- Buffers
                            -- 1: sig(i) * tanh(g) => sig(i) * tanh(g) + sig(f) * c_t (c_(t+1))
                            -- 2: sig(f) * c_t => empty
                            -- 3: empty
                            -- 4: empty
                            -- 5: empty
                            -- 6: empty
                            -- 7: empty
                            -- 8: empty
                            -- 9: empty
                            -- 10: o

                            if fma1_state = IDLE then
                                fma1_ii_mult_1_data <= post_buffer(1);
                                fma1_ii_mult_1_valid <= '1';
                                fma1_ii_mult_2_data <= x"3F80"; -- 1.0
                                fma1_ii_mult_2_valid <= '1';
                                fma1_ii_add_data <= post_buffer(2);
                                fma1_ii_add_valid <= '1';
                                fma1_state := WAITING;
                            elsif fma1_state = WAITING then
                                if fma1_ii_result_valid = '1' then
                                    post_buffer(1) <= fma1_ii_result_data;
                                    c_t <= fma1_ii_result_data;
                                    s_axis_c_t_out_valid <= '1';
                                    s_axis_c_t_out_data <= fma1_ii_result_data;
                                    fma1_state := DONE;

                                    fma1_ii_mult_1_data <= (others => '0');
                                    fma1_ii_mult_1_valid <= '0';
                                    fma1_ii_mult_2_data <= (others => '0');
                                    fma1_ii_mult_2_valid <= '0';
                                    fma1_ii_add_data <= (others => '0');
                                    fma1_ii_add_valid <= '0';
                                end if;
                            end if;

                            if fma1_state = DONE then
                                pe_post_state <= S7;
                                fma1_state := IDLE;
                            end if;
                        when S7 =>
                            -- Stage 8: the tanh function is applied on the c_(t+1); the o is put through a sigmoid function

                            -- Buffers
                            -- 1: c_(t+1) => c_(t+1) | tanh(c_(t+1))
                            -- 2: empty => tanh_slope | empty
                            -- 3: empty => tanh_offset | empty
                            -- 4: empty => o | sig(o)
                            -- 5: empty => sig_slope | empty
                            -- 6: empty => sig_offset | empty
                            -- 7: empty
                            -- 8: empty
                            -- 9: empty
                            -- 10: o => empty

                            if tanh_state = IDLE then
                                tanh_input_data <= post_buffer(1);
                                tanh_input_valid<= '1';
                                tanh_state := WAITING;
                            elsif tanh_state = WAITING then
                                if tanh_value_valid = '1' then
                                    post_buffer(1) <= tanh_value_data;
                                    tanh_state := DONE;

                                    tanh_method <= VALUE;

                                    tanh_input_data <= (others => '0');
                                    tanh_input_valid<= '0';
                                elsif tanh_input_out_valid = '1' and tanh_offset_valid = '1' and tanh_slope_valid = '1' then
                                    post_buffer(1) <= tanh_input_out_data;
                                    post_buffer(2) <= tanh_slope_data;
                                    post_buffer(3) <= tanh_offset_data;                                    
                                    tanh_state := DONE;

                                    tanh_method <= PWL;

                                    tanh_input_data <= (others => '0');
                                    tanh_input_valid<= '0';
                                end if;
                            end if;

                            if sig_1_state = IDLE then
                                sig_1_input_data <= post_buffer(10);
                                sig_1_input_valid<= '1';
                                sig_1_state := WAITING;
                            elsif sig_1_state = WAITING then
                                if sig_1_value_valid = '1' then
                                    post_buffer(4) <= sig_1_value_data;
                                    sig_1_state := DONE;

                                    sig_1_method <= VALUE;

                                    sig_1_input_data <= (others => '0');
                                    sig_1_input_valid<= '0';
                                elsif sig_1_input_out_valid = '1' and sig_1_offset_valid = '1' and sig_1_slope_valid = '1' then
                                    post_buffer(4) <= sig_1_input_out_data;
                                    post_buffer(5) <= sig_1_slope_data;
                                    post_buffer(6) <= sig_1_offset_data;                                    
                                    sig_1_state := DONE;

                                    sig_1_method <= PWL;

                                    sig_1_input_data <= (others => '0');
                                    sig_1_input_valid<= '0';
                                end if;
                            end if;

                            if tanh_state = DONE and sig_1_state = DONE then
                                pe_post_state <= S8;
                                tanh_state := IDLE;
                                sig_1_state := IDLE;
                            end if;
                        when S8 =>
                            -- Stage 9: the tanh and sigmoid functions are fed through the fmadds if PWL otherwise passed through

                            -- Buffers
                            -- 1: c_(t+1) | tanh(c_(t+1)) => tanh(c_(t+1))
                            -- 2: tanh_slope | empty => empty
                            -- 3: tanh_offset | empty => empty
                            -- 4: o | sig(o) => sig(o)
                            -- 5: sig_slope | empty => empty
                            -- 6: sig_offset | empty => empty
                            -- 7: empty
                            -- 8: empty
                            -- 9: empty
                            -- 10: empty

                            if tanh_method = VALUE then
                                tanh_state := DONE;
                            else
                                if fma1_state = IDLE then
                                    fma1_ii_mult_1_data <= post_buffer(1);
                                    fma1_ii_mult_1_valid <= '1';
                                    fma1_ii_mult_2_data <= post_buffer(2);
                                    fma1_ii_mult_2_valid <= '1';
                                    fma1_ii_add_data <= post_buffer(3);
                                    fma1_ii_add_valid <= '1';
                                    fma1_state := WAITING;
                                elsif fma1_state = WAITING then
                                    if fma1_ii_result_valid = '1' then
                                        post_buffer(1) <= fma1_ii_result_data;
                                        fma1_state := DONE;

                                        fma1_ii_mult_1_data <= (others => '0');
                                        fma1_ii_mult_1_valid <= '0';
                                        fma1_ii_mult_2_data <= (others => '0');
                                        fma1_ii_mult_2_valid <= '0';
                                        fma1_ii_add_data <= (others => '0');
                                        fma1_ii_add_valid <= '0';
                                    end if;
                                end if;
                            end if;

                            if sig_1_method = VALUE then
                                sig_1_state := DONE;
                            else
                                if fma2_state = IDLE then
                                    fma2_ih_mult_1_data <= post_buffer(4);
                                    fma2_ih_mult_1_valid <= '1';
                                    fma2_ih_mult_2_data <= post_buffer(5);
                                    fma2_ih_mult_2_valid <= '1';
                                    fma2_ih_add_data <= post_buffer(6);
                                    fma2_ih_add_valid <= '1';
                                    fma2_state := WAITING;
                                elsif fma2_state = WAITING then
                                    if fma2_ih_result_valid = '1' then
                                        post_buffer(4) <= fma2_ih_result_data;
                                        fma2_state := DONE;

                                        fma2_ih_mult_1_data <= (others => '0');
                                        fma2_ih_mult_1_valid <= '0';
                                        fma2_ih_mult_2_data <= (others => '0');
                                        fma2_ih_mult_2_valid <= '0';
                                        fma2_ih_add_data <= (others => '0');
                                        fma2_ih_add_valid <= '0';
                                    end if;
                                end if;
                            end if;

                            if fma1_state = DONE and fma2_state = DONE then
                                pe_post_state <= S9;
                                fma1_state := IDLE;
                                fma2_state := IDLE;
                            end if;

                        when S9 =>
                            -- Stage 9: Final stage; multiply the tanh and sigmoid values together to get the final hidden output

                            -- Buffers
                            -- 1: tanh(c_(t+1)) => tanh(c_(t+1)) * sig(o) (h_(t+1))
                            -- 2: empty
                            -- 3: empty
                            -- 4: sig (o) => empty
                            -- 5: empty
                            -- 6: empty
                            -- 7: empty
                            -- 8: empty
                            -- 9: empty
                            -- 10: empty

                            if fma1_state = IDLE then
                                fma1_ii_mult_1_data <= post_buffer(1);
                                fma1_ii_mult_1_valid <= '1';
                                fma1_ii_mult_2_data <= post_buffer(4);
                                fma1_ii_mult_2_valid <= '1';
                                fma1_ii_add_data <= (others => '0');
                                fma1_ii_add_valid <= '1';
                                fma1_state := WAITING;
                            elsif fma1_state = WAITING then
                                if fma1_ii_result_valid = '1' then
                                    post_buffer(1) <= fma1_ii_result_data;
                                    fma1_state := DONE;

                                    fma1_ii_mult_1_data <= (others => '0');
                                    fma1_ii_mult_1_valid <= '0';
                                    fma1_ii_mult_2_data <= (others => '0');
                                    fma1_ii_mult_2_valid <= '0';
                                    fma1_ii_add_data <= (others => '0');
                                    fma1_ii_add_valid <= '0';
                                end if;
                            end if;

                            if fma1_state = DONE and m_axis_hidden_out_ready = '1' then
                                m_axis_hidden_out_data <= post_buffer(1);
                                m_axis_hidden_out_valid <= '1';
                                pe_state <= ACCUMULATE;
                            end if;
                        when others =>
                            null;
                    end case;
                when others =>
                    s_axis_pe_ready <= '0';

                    fma1_ii_mult_1_data <= (others => '0');
                    fma1_ii_mult_1_valid <= '0';
                    fma1_ii_mult_2_data <= (others => '0');
                    fma1_ii_mult_2_valid <= '0';
                    fma1_ii_add_data <= (others => '0');
                    fma1_ii_add_valid <= '0';

                    fma2_ih_mult_1_data <= (others => '0');
                    fma2_ih_mult_1_valid <= '0';
                    fma2_ih_mult_2_data <= (others => '0');
                    fma2_ih_mult_2_valid <= '0';
                    fma2_ih_add_data <= (others => '0');
                    fma2_ih_add_valid <= '0';

                    fma3_fi_mult_1_data <= (others => '0');
                    fma3_fi_mult_1_valid <= '0';
                    fma3_fi_mult_2_data <= (others => '0');
                    fma3_fi_mult_2_valid <= '0';
                    fma3_fi_add_data <= (others => '0');
                    fma3_fi_add_valid <= '0';

                    fma4_fh_mult_1_data <= (others => '0');
                    fma4_fh_mult_1_valid <= '0';
                    fma4_fh_mult_2_data <= (others => '0');
                    fma4_fh_mult_2_valid <= '0';
                    fma4_fh_add_data <= (others => '0');
                    fma4_fh_add_valid <= '0';

                    fma5_gi_mult_1_data <= (others => '0');
                    fma5_gi_mult_1_valid <= '0';
                    fma5_gi_mult_2_data <= (others => '0');
                    fma5_gi_mult_2_valid <= '0';
                    fma5_gi_add_data <= (others => '0');
                    fma5_gi_add_valid <= '0';

                    fma6_gh_mult_1_data <= (others => '0');
                    fma6_gh_mult_1_valid <= '0';
                    fma6_gh_mult_2_data <= (others => '0');
                    fma6_gh_mult_2_valid <= '0';
                    fma6_gh_add_data <= (others => '0');
                    fma6_gh_add_valid <= '0';

                    fma7_oi_mult_1_data <= (others => '0');
                    fma7_oi_mult_1_valid <= '0';
                    fma7_oi_mult_2_data <= (others => '0');
                    fma7_oi_mult_2_valid <= '0';
                    fma7_oi_add_data <= (others => '0');
                    fma7_oi_add_valid <= '0';

                    fma8_oh_mult_1_data <= (others => '0');
                    fma8_oh_mult_1_valid <= '0';
                    fma8_oh_mult_2_data <= (others => '0');
                    fma8_oh_mult_2_valid <= '0';
                    fma8_oh_add_data <= (others => '0');
                    fma8_oh_add_valid <= '0';
            end case;
        end if;
    end process;
    
    fmadd_ii: fmadd_bf16
        port map (
            S_AXIS_MULT_1_tdata => fma1_ii_mult_1_data,
            S_AXIS_MULT_1_tvalid => fma1_ii_mult_1_valid,
            S_AXIS_MULT_2_tdata => fma1_ii_mult_2_data,
            S_AXIS_MULT_2_tvalid => fma1_ii_mult_2_valid,
            S_AXIS_ADDITIVE_tdata => fma1_ii_add_data,
            S_AXIS_ADDITIVE_tvalid => fma1_ii_add_valid,
            M_AXIS_RESULT_tdata => fma1_ii_result_data,
            M_AXIS_RESULT_tvalid => fma1_ii_result_valid,
            aclk => clk
        );

    fmadd_ih: fmadd_bf16
        port map (
            S_AXIS_MULT_1_tdata => fma2_ih_mult_1_data,
            S_AXIS_MULT_1_tvalid => fma2_ih_mult_1_valid,
            S_AXIS_MULT_2_tdata => fma2_ih_mult_2_data,
            S_AXIS_MULT_2_tvalid => fma2_ih_mult_2_valid,
            S_AXIS_ADDITIVE_tdata => fma2_ih_add_data,
            S_AXIS_ADDITIVE_tvalid => fma2_ih_add_valid,
            M_AXIS_RESULT_tdata => fma2_ih_result_data,
            M_AXIS_RESULT_tvalid => fma2_ih_result_valid,
            aclk => clk
        );

    fmadd_fi: fmadd_bf16
        port map (
            S_AXIS_MULT_1_tdata => fma3_fi_mult_1_data,
            S_AXIS_MULT_1_tvalid => fma3_fi_mult_1_valid,
            S_AXIS_MULT_2_tdata => fma3_fi_mult_2_data,
            S_AXIS_MULT_2_tvalid => fma3_fi_mult_2_valid,
            S_AXIS_ADDITIVE_tdata => fma3_fi_add_data,
            S_AXIS_ADDITIVE_tvalid => fma3_fi_add_valid,
            M_AXIS_RESULT_tdata => fma3_fi_result_data,
            M_AXIS_RESULT_tvalid => fma3_fi_result_valid,
            aclk => clk
        );

    fmadd_fh: fmadd_bf16
        port map (
            S_AXIS_MULT_1_tdata => fma4_fh_mult_1_data,
            S_AXIS_MULT_1_tvalid => fma4_fh_mult_1_valid,
            S_AXIS_MULT_2_tdata => fma4_fh_mult_2_data,
            S_AXIS_MULT_2_tvalid => fma4_fh_mult_2_valid,
            S_AXIS_ADDITIVE_tdata => fma4_fh_add_data,
            S_AXIS_ADDITIVE_tvalid => fma4_fh_add_valid,
            M_AXIS_RESULT_tdata => fma4_fh_result_data,
            M_AXIS_RESULT_tvalid => fma4_fh_result_valid,
            aclk => clk
        );

    fmadd_gi: fmadd_bf16
        port map (
            S_AXIS_MULT_1_tdata => fma5_gi_mult_1_data,
            S_AXIS_MULT_1_tvalid => fma5_gi_mult_1_valid,
            S_AXIS_MULT_2_tdata => fma5_gi_mult_2_data,
            S_AXIS_MULT_2_tvalid => fma5_gi_mult_2_valid,
            S_AXIS_ADDITIVE_tdata => fma5_gi_add_data,
            S_AXIS_ADDITIVE_tvalid => fma5_gi_add_valid,
            M_AXIS_RESULT_tdata => fma5_gi_result_data,
            M_AXIS_RESULT_tvalid => fma5_gi_result_valid,
            aclk => clk
        );

    fmadd_gh: fmadd_bf16
        port map (
            S_AXIS_MULT_1_tdata => fma6_gh_mult_1_data,
            S_AXIS_MULT_1_tvalid => fma6_gh_mult_1_valid,
            S_AXIS_MULT_2_tdata => fma6_gh_mult_2_data,
            S_AXIS_MULT_2_tvalid => fma6_gh_mult_2_valid,
            S_AXIS_ADDITIVE_tdata => fma6_gh_add_data,
            S_AXIS_ADDITIVE_tvalid => fma6_gh_add_valid,
            M_AXIS_RESULT_tdata => fma6_gh_result_data,
            M_AXIS_RESULT_tvalid => fma6_gh_result_valid,
            aclk => clk
        );

    fmadd_oi: fmadd_bf16
        port map (
            S_AXIS_MULT_1_tdata => fma7_oi_mult_1_data,
            S_AXIS_MULT_1_tvalid => fma7_oi_mult_1_valid,
            S_AXIS_MULT_2_tdata => fma7_oi_mult_2_data,
            S_AXIS_MULT_2_tvalid => fma7_oi_mult_2_valid,
            S_AXIS_ADDITIVE_tdata => fma7_oi_add_data,
            S_AXIS_ADDITIVE_tvalid => fma7_oi_add_valid,
            M_AXIS_RESULT_tdata => fma7_oi_result_data,
            M_AXIS_RESULT_tvalid => fma7_oi_result_valid,
            aclk => clk
        );

    fmadd_oh: fmadd_bf16
        port map (
            S_AXIS_MULT_1_tdata => fma8_oh_mult_1_data,
            S_AXIS_MULT_1_tvalid => fma8_oh_mult_1_valid,
            S_AXIS_MULT_2_tdata => fma8_oh_mult_2_data,
            S_AXIS_MULT_2_tvalid => fma8_oh_mult_2_valid,
            S_AXIS_ADDITIVE_tdata => fma8_oh_add_data,
            S_AXIS_ADDITIVE_tvalid => fma8_oh_add_valid,
            M_AXIS_RESULT_tdata => fma8_oh_result_data,
            M_AXIS_RESULT_tvalid => fma8_oh_result_valid,
            aclk => clk
        );

    -- Sigmoid and tanh functions
    sig_1: sigmoid_arbiter
        port map (
            aclk => clk,
            in_valid => sig_1_input_valid,
            in_data => sig_1_input_data,
            slope_out_valid => sig_1_slope_valid,
            slope_out_data => sig_1_slope_data,
            offset_out_valid => sig_1_offset_valid,
            offset_out_data => sig_1_offset_data,
            input_out_valid => sig_1_input_out_valid,
            input_out_data => sig_1_input_out_data,
            value_out_valid => sig_1_value_valid,
            value_out_data => sig_1_value_data
        );

    sig_2: sigmoid_arbiter
        port map (
            aclk => clk,
            in_valid => sig_2_input_valid,
            in_data => sig_2_input_data,
            slope_out_valid => sig_2_slope_valid,
            slope_out_data => sig_2_slope_data,
            offset_out_valid => sig_2_offset_valid,
            offset_out_data => sig_2_offset_data,
            input_out_valid => sig_2_input_out_valid,
            input_out_data => sig_2_input_out_data,
            value_out_valid => sig_2_value_valid,
            value_out_data => sig_2_value_data
        );

    tanh: tanh_arbiter
        port map (
            aclk => clk,
            in_valid => tanh_input_valid,
            in_data => tanh_input_data,
            slope_out_valid => tanh_slope_valid,
            slope_out_data => tanh_slope_data,
            offset_out_valid => tanh_offset_valid,
            offset_out_data => tanh_offset_data,
            input_out_valid => tanh_input_out_valid,
            input_out_data => tanh_input_out_data,
            value_out_valid => tanh_value_valid,
            value_out_data => tanh_value_data
        );
end architecture behav;