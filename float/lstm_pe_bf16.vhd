library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lstm_pe_bf16 is
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
        M_AXIS_HIDDEN_OUT_tready : in std_logic;

        -- c_t and bias update
        S_AXIS_C_AND_BIAS_IN_tready : out std_logic := '0';

        S_AXIS_C_T_in_tdata : in std_logic_vector(15 downto 0);
        S_AXIS_C_T_in_tvalid : in std_logic;

        S_AXIS_C_T_out_tdata : out std_logic_vector(15 downto 0) := (others => '0');
        S_AXIS_C_T_out_tvalid : out std_logic := '0';
        S_AXIS_C_T_out_tready : in std_logic;

        S_AXIS_I_BIAS_tdata : in std_logic_vector(15 downto 0);
        S_AXIS_I_BIAS_tvalid : in std_logic;

        S_AXIS_F_BIAS_tdata : in std_logic_vector(15 downto 0);
        S_AXIS_F_BIAS_tvalid : in std_logic;

        S_AXIS_G_BIAS_tdata : in std_logic_vector(15 downto 0);
        S_AXIS_G_BIAS_tvalid : in std_logic;

        S_AXIS_O_BIAS_tdata : in std_logic_vector(15 downto 0);
        S_AXIS_O_BIAS_tvalid : in std_logic
    );
end entity;

architecture behav of lstm_pe_bf16 is
    component mac_bf16_mult is
        port (
            M_AXIS_ACC_RESULT_tdata : out STD_LOGIC_VECTOR ( 15 downto 0 );
            M_AXIS_ACC_RESULT_tlast : out STD_LOGIC;
            M_AXIS_ACC_RESULT_tready : in STD_LOGIC;
            M_AXIS_ACC_RESULT_tvalid : out STD_LOGIC;

            M_AXIS_MULT_RESULT_tdata : out STD_LOGIC_VECTOR ( 15 downto 0 );
            M_AXIS_MULT_RESULT_tvalid : out STD_LOGIC;
            M_AXIS_MULT_RESULT_tready : in STD_LOGIC;

            S_AXIS_WEIGHT_IN_tdata : in STD_LOGIC_VECTOR ( 15 downto 0 );
            S_AXIS_WEIGHT_IN_tlast : in STD_LOGIC;
            S_AXIS_WEIGHT_IN_tready : out STD_LOGIC;
            S_AXIS_WEIGHT_IN_tvalid : in STD_LOGIC;

            S_AXIS_DATA_IN_tdata : in STD_LOGIC_VECTOR ( 15 downto 0 );
            S_AXIS_DATA_IN_tlast : in STD_LOGIC;
            S_AXIS_DATA_IN_tready : out STD_LOGIC;
            S_AXIS_DATA_IN_tuser : in STD_LOGIC_VECTOR ( 0 to 0 );
            S_AXIS_DATA_IN_tvalid : in STD_LOGIC;
            aclk : in STD_LOGIC
          );
    end component mac_bf16_mult;

    component mac_bf16 is
        port (
            M_AXIS_ACC_RESULT_tdata : out STD_LOGIC_VECTOR ( 15 downto 0 );
            M_AXIS_ACC_RESULT_tlast : out STD_LOGIC;
            M_AXIS_ACC_RESULT_tready : in STD_LOGIC;
            M_AXIS_ACC_RESULT_tvalid : out STD_LOGIC;

            S_AXIS_DATA_IN_tdata : in STD_LOGIC_VECTOR ( 15 downto 0 );
            S_AXIS_DATA_IN_tlast : in STD_LOGIC;
            S_AXIS_DATA_IN_tready : out STD_LOGIC;
            S_AXIS_DATA_IN_tvalid : in STD_LOGIC;

            S_AXIS_WEIGHT_IN_tdata : in STD_LOGIC_VECTOR ( 15 downto 0 );
            S_AXIS_WEIGHT_IN_tlast : in STD_LOGIC;
            S_AXIS_WEIGHT_IN_tready : out STD_LOGIC;
            S_AXIS_WEIGHT_IN_tvalid : in STD_LOGIC;

            aclk : in STD_LOGIC
        );
    end component mac_bf16;

    component sigmoid_arbiter is
        port (
            aclk : in std_logic;
    
            -- input
            in_valid : in std_logic;
            in_data : in std_logic_vector(15 downto 0);
            in_ready : out std_logic;
    
            -- output
            slope_out_valid : out std_logic;
            slope_out_data : out std_logic_vector(15 downto 0);
            slope_out_ready : in std_logic;
    
            offset_out_valid : out std_logic;
            offset_out_data : out std_logic_vector(15 downto 0);
            offset_out_ready : in std_logic;
    
            input_out_valid : out std_logic;
            input_out_data : out std_logic_vector(15 downto 0);
            input_out_ready : in std_logic;
    
            value_out_valid : out std_logic;
            value_out_data : out std_logic_vector(15 downto 0);
            value_out_ready : in std_logic
        );
    end component;

    component tanh_arbiter is
        port (
            aclk : in std_logic;
    
            -- input
            in_valid : in std_logic;
            in_data : in std_logic_vector(15 downto 0);
            in_ready : out std_logic;
    
            -- output
            slope_out_valid : out std_logic;
            slope_out_data : out std_logic_vector(15 downto 0);
            slope_out_ready : in std_logic;
    
            offset_out_valid : out std_logic;
            offset_out_data : out std_logic_vector(15 downto 0);
            offset_out_ready : in std_logic;
    
            input_out_valid : out std_logic;
            input_out_data : out std_logic_vector(15 downto 0);
            input_out_ready : in std_logic;
    
            value_out_valid : out std_logic;
            value_out_data : out std_logic_vector(15 downto 0);
            value_out_ready : in std_logic
        );
    end component;

    component adder is
        port (
          S_AXIS_A_tdata : in STD_LOGIC_VECTOR ( 15 downto 0 );
          S_AXIS_A_tready : out STD_LOGIC;
          S_AXIS_A_tvalid : in STD_LOGIC;
          S_AXIS_B_tdata : in STD_LOGIC_VECTOR ( 15 downto 0 );
          S_AXIS_B_tready : out STD_LOGIC;
          S_AXIS_B_tvalid : in STD_LOGIC;
          aclk : in STD_LOGIC;
          M_AXIS_RESULT_tdata : out STD_LOGIC_VECTOR ( 15 downto 0 );
          M_AXIS_RESULT_tready : in STD_LOGIC;
          M_AXIS_RESULT_tvalid : out STD_LOGIC
        );
    end component adder;

    -- Input ready signals

    signal i_in_mac_data_ready : std_logic;
    signal i_in_mac_weight_ready : std_logic;

    signal i_hid_mac_data_ready : std_logic;
    signal i_hid_mac_weight_ready : std_logic;

    signal f_in_mac_data_ready : std_logic;
    signal f_in_mac_weight_ready : std_logic;

    signal f_hid_mac_data_ready : std_logic;
    signal f_hid_mac_weight_ready : std_logic;

    signal o_in_mac_data_ready : std_logic;
    signal o_in_mac_weight_ready : std_logic;

    signal o_hid_mac_data_ready : std_logic;
    signal o_hid_mac_weight_ready : std_logic;

    signal g_in_mac_data_ready : std_logic;
    signal g_in_mac_weight_ready : std_logic;

    signal g_hid_mac_data_ready : std_logic;
    signal g_hid_mac_weight_ready : std_logic;

    -- Output signals from the MACs

    signal i_in_out_data : std_logic_vector(15 downto 0);
    signal i_in_out_data_buffer : std_logic_vector(15 downto 0) := (others => '0');
    signal i_in_out_valid : std_logic;
    signal i_in_out_ready : std_logic := '1';
    signal i_in_out_last : std_logic;

    signal i_hid_out_data : std_logic_vector(15 downto 0);
    signal i_hid_out_data_buffer : std_logic_vector(15 downto 0) := (others => '0');
    signal i_hid_out_valid : std_logic;
    signal i_hid_out_ready : std_logic := '1';
    signal i_hid_out_last : std_logic;

    signal f_in_out_data : std_logic_vector(15 downto 0);
    signal f_in_out_data_buffer : std_logic_vector(15 downto 0) := (others => '0');
    signal f_in_out_valid : std_logic;
    signal f_in_out_ready : std_logic := '1';
    signal f_in_out_last : std_logic;

    signal f_hid_out_data : std_logic_vector(15 downto 0);
    signal f_hid_out_data_buffer : std_logic_vector(15 downto 0) := (others => '0');
    signal f_hid_out_valid : std_logic;
    signal f_hid_out_ready : std_logic := '1';
    signal f_hid_out_last : std_logic;

    signal o_in_out_data : std_logic_vector(15 downto 0);
    signal o_in_out_data_buffer : std_logic_vector(15 downto 0) := (others => '0');
    signal o_in_out_valid : std_logic;
    signal o_in_out_ready : std_logic := '1';
    signal o_in_out_last : std_logic;

    signal o_hid_out_data : std_logic_vector(15 downto 0);
    signal o_hid_out_data_buffer : std_logic_vector(15 downto 0) := (others => '0');
    signal o_hid_out_valid : std_logic;
    signal o_hid_out_ready : std_logic := '1';
    signal o_hid_out_last : std_logic;

    signal g_in_out_data : std_logic_vector(15 downto 0);
    signal g_in_out_data_buffer : std_logic_vector(15 downto 0) := (others => '0');
    signal g_in_out_valid : std_logic;
    signal g_in_out_ready : std_logic := '1';
    signal g_in_out_last : std_logic;

    signal g_hid_out_data : std_logic_vector(15 downto 0);
    signal g_hid_out_data_buffer : std_logic_vector(15 downto 0) := (others => '0');
    signal g_hid_out_valid : std_logic;
    signal g_hid_out_ready : std_logic := '1';
    signal g_hid_out_last : std_logic;

    -- Signals for the adders

    signal adder_1_A_tdata : std_logic_vector(15 downto 0) := (others => '0');
    signal adder_1_A_tready : std_logic;
    signal adder_1_A_tvalid : std_logic := '0';

    signal adder_1_B_tdata : std_logic_vector(15 downto 0) := (others => '0');
    signal adder_1_B_tready : std_logic;
    signal adder_1_B_tvalid : std_logic := '0';

    signal adder_1_RESULT_tdata : std_logic_vector(15 downto 0) := (others => '0');
    signal adder_1_RESULT_tready : std_logic := '0';
    signal adder_1_RESULT_tvalid : std_logic;

    signal adder_2_A_tdata : std_logic_vector(15 downto 0) := (others => '0');
    signal adder_2_A_tready : std_logic;
    signal adder_2_A_tvalid : std_logic := '0';

    signal adder_2_B_tdata : std_logic_vector(15 downto 0) := (others => '0');
    signal adder_2_B_tready : std_logic;
    signal adder_2_B_tvalid : std_logic := '0';

    signal adder_2_RESULT_tdata : std_logic_vector(15 downto 0) := (others => '0');
    signal adder_2_RESULT_tready : std_logic := '0';
    signal adder_2_RESULT_tvalid : std_logic;

    signal adder_3_A_tdata : std_logic_vector(15 downto 0) := (others => '0');
    signal adder_3_A_tready : std_logic;
    signal adder_3_A_tvalid : std_logic := '0';

    signal adder_3_B_tdata : std_logic_vector(15 downto 0) := (others => '0');
    signal adder_3_B_tready : std_logic;
    signal adder_3_B_tvalid : std_logic := '0';

    signal adder_3_RESULT_tdata : std_logic_vector(15 downto 0) := (others => '0');
    signal adder_3_RESULT_tready : std_logic := '0';
    signal adder_3_RESULT_tvalid : std_logic;

    -- Signals for the multipliers
    signal mult_1_A_tdata : std_logic_vector(15 downto 0) := (others => '0');
    signal mult_1_A_tready : std_logic;
    signal mult_1_A_tvalid : std_logic := '0';
    signal mult_1_A_tlast : std_logic := '0';

    signal mult_1_B_tdata : std_logic_vector(15 downto 0) := (others => '0');
    signal mult_1_B_tready : std_logic;
    signal mult_1_B_tvalid : std_logic := '0';
    signal mult_1_B_tlast : std_logic := '0';

    signal mult_1_RESULT_tdata : std_logic_vector(15 downto 0) := (others => '0');
    signal mult_1_RESULT_tready : std_logic := '0';
    signal mult_1_RESULT_tvalid : std_logic;

    signal mult_1_tdest : std_logic_vector(0 downto 0) := (others => '0');

    signal mult_2_A_tdata : std_logic_vector(15 downto 0) := (others => '0');
    signal mult_2_A_tready : std_logic;
    signal mult_2_A_tvalid : std_logic := '0';
    signal mult_2_A_tlast : std_logic := '0';

    signal mult_2_B_tdata : std_logic_vector(15 downto 0) := (others => '0');
    signal mult_2_B_tready : std_logic;
    signal mult_2_B_tvalid : std_logic := '0';
    signal mult_2_B_tlast : std_logic := '0';

    signal mult_2_RESULT_tdata : std_logic_vector(15 downto 0) := (others => '0');
    signal mult_2_RESULT_tready : std_logic := '0';
    signal mult_2_RESULT_tvalid : std_logic;

    signal mult_2_tdest : std_logic_vector(0 downto 0) := (others => '0');

    signal mult_3_A_tdata : std_logic_vector(15 downto 0) := (others => '0');
    signal mult_3_A_tready : std_logic;
    signal mult_3_A_tvalid : std_logic := '0';
    signal mult_3_A_tlast : std_logic := '0';

    signal mult_3_B_tdata : std_logic_vector(15 downto 0) := (others => '0');
    signal mult_3_B_tready : std_logic;
    signal mult_3_B_tvalid : std_logic := '0';
    signal mult_3_B_tlast : std_logic := '0';

    signal mult_3_RESULT_tdata : std_logic_vector(15 downto 0) := (others => '0');
    signal mult_3_RESULT_tready : std_logic := '0';
    signal mult_3_RESULT_tvalid : std_logic;

    signal mult_3_tdest : std_logic_vector(0 downto 0) := (others => '0');

    -- Signals for the arbiters

    signal sig_1_input_tdata : std_logic_vector(15 downto 0) := (others => '0');
    signal sig_1_input_tready : std_logic;
    signal sig_1_input_tvalid : std_logic := '0';

    signal sig_1_slope_tdata : std_logic_vector(15 downto 0);
    signal sig_1_slope_tready : std_logic := '0';
    signal sig_1_slope_tvalid : std_logic;

    signal sig_1_offset_tdata : std_logic_vector(15 downto 0);
    signal sig_1_offset_tready : std_logic := '0';
    signal sig_1_offset_tvalid : std_logic;

    signal sig_1_input_out_tdata : std_logic_vector(15 downto 0);
    signal sig_1_input_out_tready : std_logic := '0';
    signal sig_1_input_out_tvalid : std_logic;

    signal sig_1_value_tdata : std_logic_vector(15 downto 0);
    signal sig_1_value_tready : std_logic := '0';
    signal sig_1_value_tvalid : std_logic;

    signal sig_2_input_tdata : std_logic_vector(15 downto 0) := (others => '0');
    signal sig_2_input_tready : std_logic;
    signal sig_2_input_tvalid : std_logic := '0';

    signal sig_2_slope_tdata : std_logic_vector(15 downto 0);
    signal sig_2_slope_tready : std_logic := '0';
    signal sig_2_slope_tvalid : std_logic;

    signal sig_2_offset_tdata : std_logic_vector(15 downto 0);
    signal sig_2_offset_tready : std_logic := '0';
    signal sig_2_offset_tvalid : std_logic;

    signal sig_2_input_out_tdata : std_logic_vector(15 downto 0);
    signal sig_2_input_out_tready : std_logic := '0';
    signal sig_2_input_out_tvalid : std_logic;

    signal sig_2_value_tdata : std_logic_vector(15 downto 0);
    signal sig_2_value_tready : std_logic := '0';
    signal sig_2_value_tvalid : std_logic;

    signal tanh_input_tdata : std_logic_vector(15 downto 0) := (others => '0');
    signal tanh_input_tready : std_logic;
    signal tanh_input_tvalid : std_logic := '0';

    signal tanh_slope_tdata : std_logic_vector(15 downto 0);
    signal tanh_slope_tready : std_logic := '0';
    signal tanh_slope_tvalid : std_logic;

    signal tanh_offset_tdata : std_logic_vector(15 downto 0);
    signal tanh_offset_tready : std_logic := '0';
    signal tanh_offset_tvalid : std_logic;

    signal tanh_input_out_tdata : std_logic_vector(15 downto 0);
    signal tanh_input_out_tready : std_logic := '0';
    signal tanh_input_out_tvalid : std_logic;

    signal tanh_value_tdata : std_logic_vector(15 downto 0);
    signal tanh_value_tready : std_logic := '0';
    signal tanh_value_tvalid : std_logic;

    -- Signals to use for buffering in the post state
    signal post_buffer_1 : std_logic_vector(15 downto 0) := (others => '0');
    signal post_buffer_2 : std_logic_vector(15 downto 0) := (others => '0');
    signal post_buffer_3 : std_logic_vector(15 downto 0) := (others => '0');
    signal post_buffer_4 : std_logic_vector(15 downto 0) := (others => '0');
    signal post_buffer_5 : std_logic_vector(15 downto 0) := (others => '0');
    signal post_buffer_6 : std_logic_vector(15 downto 0) := (others => '0');
    signal post_buffer_7 : std_logic_vector(15 downto 0) := (others => '0');
    signal post_buffer_8 : std_logic_vector(15 downto 0) := (others => '0');
    signal post_buffer_9 : std_logic_vector(15 downto 0) := (others => '0');

    type post_buffer_t is (NONE, PB1, PB2, PB3, PB4, PB5, PB6, PB7, PB8, PB9, CT);
    signal mult_1_A_pb : post_buffer_t := NONE;
    signal mult_1_B_pb : post_buffer_t := NONE;
    signal mult_2_A_pb : post_buffer_t := NONE;
    signal mult_2_B_pb : post_buffer_t := NONE;
    signal mult_3_A_pb : post_buffer_t := NONE;
    signal mult_3_B_pb : post_buffer_t := NONE;


    -- Signals specifying the activation function method
    type activation_t is (PWL, VALUE);
    signal sig_1_method : activation_t := PWL;
    signal sig_2_method : activation_t := PWL;
    signal tanh_method : activation_t := PWL;

    -- C buffer
    signal c_t : std_logic_vector(15 downto 0) := (others => '0');
    signal i_bias : std_logic_vector(15 downto 0) := (others => '0');
    signal f_bias : std_logic_vector(15 downto 0) := (others => '0');
    signal g_bias : std_logic_vector(15 downto 0) := (others => '0');
    signal o_bias : std_logic_vector(15 downto 0) := (others => '0');

    -- State machine with accumulate and post states
    type pe_state_t is (READY, RECEIVE, ACCUMULATE, POST);
    signal pe_state : pe_state_t := READY;

    type pe_post_state_t is (S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11);
    signal pe_post_state : pe_post_state_t := S1;
  
    type operator_state_t is (IDLE, WAITING, DONE);
    signal adder_1_state : operator_state_t := IDLE;
    signal adder_2_state : operator_state_t := IDLE;
    signal adder_3_state : operator_state_t := IDLE;
    signal mult_1_state : operator_state_t := IDLE;
    signal mult_2_state : operator_state_t := IDLE;
    signal mult_3_state : operator_state_t := IDLE;
    signal sig_1_state : operator_state_t := IDLE;
    signal sig_2_state : operator_state_t := IDLE;
    signal tanh_state : operator_state_t := IDLE;

    type latency_blocker_t is (BLOCKED, UNBLOCKED);
    signal adder_1_lat_block : latency_blocker_t := UNBLOCKED;
    signal adder_2_lat_block : latency_blocker_t := UNBLOCKED;
    signal adder_3_lat_block : latency_blocker_t := UNBLOCKED;
begin
    i_in_mac_data_ready <= mult_1_A_tready;
    i_in_mac_weight_ready <= mult_1_B_tready;

    i_hid_mac_data_ready <= mult_2_A_tready;
    i_hid_mac_weight_ready <= mult_2_B_tready;

    f_in_mac_data_ready <= mult_3_A_tready;
    f_in_mac_weight_ready <= mult_3_B_tready;

    process (pe_state, mult_1_A_pb, mult_1_B_pb, mult_2_A_pb, mult_2_B_pb, mult_3_A_pb, mult_3_B_pb, 
        S_AXIS_DATA_IN_tdata, S_AXIS_DATA_IN_tvalid, S_AXIS_DATA_IN_tlast, 
        S_AXIS_WEIGHT_I_input_tdata, S_AXIS_WEIGHT_I_input_tvalid, S_AXIS_WEIGHT_I_input_tlast, 
        S_AXIS_WEIGHT_I_hidden_tdata, S_AXIS_WEIGHT_I_hidden_tvalid, S_AXIS_WEIGHT_I_hidden_tlast, 
        S_AXIS_WEIGHT_F_input_tdata, S_AXIS_WEIGHT_F_input_tvalid, S_AXIS_WEIGHT_F_input_tlast, 
        S_AXIS_WEIGHT_F_hidden_tdata, S_AXIS_WEIGHT_F_hidden_tvalid, S_AXIS_WEIGHT_F_hidden_tlast, 
        S_AXIS_WEIGHT_O_input_tdata, S_AXIS_WEIGHT_O_input_tvalid, S_AXIS_WEIGHT_O_input_tlast, 
        S_AXIS_WEIGHT_O_hidden_tdata, S_AXIS_WEIGHT_O_hidden_tvalid, S_AXIS_WEIGHT_O_hidden_tlast, 
        S_AXIS_WEIGHT_G_input_tdata, S_AXIS_WEIGHT_G_input_tvalid, S_AXIS_WEIGHT_G_input_tlast, 
        S_AXIS_WEIGHT_G_hidden_tdata, S_AXIS_WEIGHT_G_hidden_tvalid, S_AXIS_WEIGHT_G_hidden_tlast,
        post_buffer_1, post_buffer_2, post_buffer_3, 
        post_buffer_4, post_buffer_5, post_buffer_6, 
        post_buffer_7, post_buffer_8, post_buffer_9, 
        c_t
        )
    begin
        case pe_state is
            when READY =>
                -- Route the inputs of the multipliers to the correct mac inputs
                mult_1_A_tdata <= S_AXIS_DATA_IN_tdata;
                mult_1_A_tvalid <= S_AXIS_DATA_IN_tvalid;
                mult_1_A_tlast <= S_AXIS_DATA_IN_tlast;

                mult_1_B_tdata <= S_AXIS_WEIGHT_I_input_tdata;
                mult_1_B_tvalid <= S_AXIS_WEIGHT_I_input_tvalid;
                mult_1_B_tlast <= S_AXIS_WEIGHT_I_input_tlast;

                mult_1_tdest <= "0";

                mult_2_A_tdata <= S_AXIS_DATA_IN_tdata;
                mult_2_A_tvalid <= S_AXIS_DATA_IN_tvalid;
                mult_2_A_tlast <= S_AXIS_DATA_IN_tlast;

                mult_2_B_tdata <= S_AXIS_WEIGHT_I_hidden_tdata;
                mult_2_B_tvalid <= S_AXIS_WEIGHT_I_hidden_tvalid;
                mult_2_B_tlast <= S_AXIS_WEIGHT_I_hidden_tlast;

                mult_2_tdest <= "0";

                mult_3_A_tdata <= S_AXIS_DATA_IN_tdata;
                mult_3_A_tvalid <= S_AXIS_DATA_IN_tvalid;
                mult_3_A_tlast <= S_AXIS_DATA_IN_tlast;

                mult_3_B_tdata <= S_AXIS_WEIGHT_F_input_tdata;
                mult_3_B_tvalid <= S_AXIS_WEIGHT_F_input_tvalid;
                mult_3_B_tlast <= S_AXIS_WEIGHT_F_input_tlast;

                mult_3_tdest <= "0";
            when RECEIVE =>
                -- Route the inputs of the multipliers to the correct mac inputs
                mult_1_A_tdata <= S_AXIS_DATA_IN_tdata;
                mult_1_A_tvalid <= S_AXIS_DATA_IN_tvalid;
                mult_1_A_tlast <= S_AXIS_DATA_IN_tlast;

                mult_1_B_tdata <= S_AXIS_WEIGHT_I_input_tdata;
                mult_1_B_tvalid <= S_AXIS_WEIGHT_I_input_tvalid;
                mult_1_B_tlast <= S_AXIS_WEIGHT_I_input_tlast;

                mult_1_tdest <= "0";

                mult_2_A_tdata <= S_AXIS_DATA_IN_tdata;
                mult_2_A_tvalid <= S_AXIS_DATA_IN_tvalid;
                mult_2_A_tlast <= S_AXIS_DATA_IN_tlast;

                mult_2_B_tdata <= S_AXIS_WEIGHT_I_hidden_tdata;
                mult_2_B_tvalid <= S_AXIS_WEIGHT_I_hidden_tvalid;
                mult_2_B_tlast <= S_AXIS_WEIGHT_I_hidden_tlast;

                mult_2_tdest <= "0";

                mult_3_A_tdata <= S_AXIS_DATA_IN_tdata;
                mult_3_A_tvalid <= S_AXIS_DATA_IN_tvalid;
                mult_3_A_tlast <= S_AXIS_DATA_IN_tlast;

                mult_3_B_tdata <= S_AXIS_WEIGHT_F_input_tdata;
                mult_3_B_tvalid <= S_AXIS_WEIGHT_F_input_tvalid;
                mult_3_B_tlast <= S_AXIS_WEIGHT_F_input_tlast;

                mult_3_tdest <= "0";
            when ACCUMULATE =>
                -- Route the inputs of the multipliers to the correct mac inputs
                mult_1_A_tdata <= S_AXIS_DATA_IN_tdata;
                mult_1_A_tvalid <= S_AXIS_DATA_IN_tvalid;
                mult_1_A_tlast <= S_AXIS_DATA_IN_tlast;

                mult_1_B_tdata <= S_AXIS_WEIGHT_I_input_tdata;
                mult_1_B_tvalid <= S_AXIS_WEIGHT_I_input_tvalid;
                mult_1_B_tlast <= S_AXIS_WEIGHT_I_input_tlast;

                mult_1_tdest <= "0";

                mult_2_A_tdata <= S_AXIS_DATA_IN_tdata;
                mult_2_A_tvalid <= S_AXIS_DATA_IN_tvalid;
                mult_2_A_tlast <= S_AXIS_DATA_IN_tlast;

                mult_2_B_tdata <= S_AXIS_WEIGHT_I_hidden_tdata;
                mult_2_B_tvalid <= S_AXIS_WEIGHT_I_hidden_tvalid;
                mult_2_B_tlast <= S_AXIS_WEIGHT_I_hidden_tlast;

                mult_2_tdest <= "0";

                mult_3_A_tdata <= S_AXIS_DATA_IN_tdata;
                mult_3_A_tvalid <= S_AXIS_DATA_IN_tvalid;
                mult_3_A_tlast <= S_AXIS_DATA_IN_tlast;

                mult_3_B_tdata <= S_AXIS_WEIGHT_F_input_tdata;
                mult_3_B_tvalid <= S_AXIS_WEIGHT_F_input_tvalid;
                mult_3_B_tlast <= S_AXIS_WEIGHT_F_input_tlast;

                mult_3_tdest <= "0";
            when POST =>
                case mult_1_A_pb is
                    when PB1 =>
                        mult_1_A_tdata <= post_buffer_1;
                        mult_1_A_tvalid <= '1';
                    when PB2 =>
                        mult_1_A_tdata <= post_buffer_2;
                        mult_1_A_tvalid <= '1';
                    when PB3 =>
                        mult_1_A_tdata <= post_buffer_3;
                        mult_1_A_tvalid <= '1';
                    when PB4 =>
                        mult_1_A_tdata <= post_buffer_4;
                        mult_1_A_tvalid <= '1';
                    when PB5 =>
                        mult_1_A_tdata <= post_buffer_5;
                        mult_1_A_tvalid <= '1';
                    when PB6 =>
                        mult_1_A_tdata <= post_buffer_6;
                        mult_1_A_tvalid <= '1';
                    when PB7 =>
                        mult_1_A_tdata <= post_buffer_7;
                        mult_1_A_tvalid <= '1';
                    when PB8 =>
                        mult_1_A_tdata <= post_buffer_8;
                        mult_1_A_tvalid <= '1';
                    when PB9 =>
                        mult_1_A_tdata <= post_buffer_9;
                        mult_1_A_tvalid <= '1';
                    when CT =>
                        mult_1_A_tdata <= c_t;
                        mult_1_A_tvalid <= '1';
                    when others =>
                        mult_1_A_tdata <= (others => '0');
                        mult_1_A_tvalid <= '0';
                end case;
                mult_1_A_tlast <= '0';

                case mult_1_B_pb is
                    when PB1 =>
                        mult_1_B_tdata <= post_buffer_1;
                        mult_1_B_tvalid <= '1';
                    when PB2 =>
                        mult_1_B_tdata <= post_buffer_2;
                        mult_1_B_tvalid <= '1';
                    when PB3 =>
                        mult_1_B_tdata <= post_buffer_3;
                        mult_1_B_tvalid <= '1';
                    when PB4 =>
                        mult_1_B_tdata <= post_buffer_4;
                        mult_1_B_tvalid <= '1';
                    when PB5 =>
                        mult_1_B_tdata <= post_buffer_5;
                        mult_1_B_tvalid <= '1';
                    when PB6 =>
                        mult_1_B_tdata <= post_buffer_6;
                        mult_1_B_tvalid <= '1';
                    when PB7 =>
                        mult_1_B_tdata <= post_buffer_7;
                        mult_1_B_tvalid <= '1';
                    when PB8 =>
                        mult_1_B_tdata <= post_buffer_8;
                        mult_1_B_tvalid <= '1';
                    when PB9 =>
                        mult_1_B_tdata <= post_buffer_9;
                        mult_1_B_tvalid <= '1';
                    when CT =>
                        mult_1_B_tdata <= c_t;
                        mult_1_B_tvalid <= '1';
                    when others =>
                        mult_1_B_tdata <= (others => '0');
                        mult_1_B_tvalid <= '0';
                end case;
                mult_1_B_tlast <= '0';
                mult_1_tdest <= "1";

                case mult_2_A_pb is
                    when PB1 =>
                        mult_2_A_tdata <= post_buffer_1;
                        mult_2_A_tvalid <= '1';
                    when PB2 =>
                        mult_2_A_tdata <= post_buffer_2;
                        mult_2_A_tvalid <= '1';
                    when PB3 =>
                        mult_2_A_tdata <= post_buffer_3;
                        mult_2_A_tvalid <= '1';
                    when PB4 =>
                        mult_2_A_tdata <= post_buffer_4;
                        mult_2_A_tvalid <= '1';
                    when PB5 =>
                        mult_2_A_tdata <= post_buffer_5;
                        mult_2_A_tvalid <= '1';
                    when PB6 =>
                        mult_2_A_tdata <= post_buffer_6;
                        mult_2_A_tvalid <= '1';
                    when PB7 =>
                        mult_2_A_tdata <= post_buffer_7;
                        mult_2_A_tvalid <= '1';
                    when PB8 =>
                        mult_2_A_tdata <= post_buffer_8;
                        mult_2_A_tvalid <= '1';
                    when PB9 =>
                        mult_2_A_tdata <= post_buffer_9;
                        mult_2_A_tvalid <= '1';
                    when CT =>
                        mult_2_A_tdata <= c_t;
                        mult_2_A_tvalid <= '1';
                    when others =>
                        mult_2_A_tdata <= (others => '0');
                        mult_2_A_tvalid <= '0';
                end case;
                mult_2_A_tlast <= '0';   
                
                case mult_2_B_pb is
                    when PB1 =>
                        mult_2_B_tdata <= post_buffer_1;
                        mult_2_B_tvalid <= '1';
                    when PB2 =>
                        mult_2_B_tdata <= post_buffer_2;
                        mult_2_B_tvalid <= '1';
                    when PB3 =>
                        mult_2_B_tdata <= post_buffer_3;
                        mult_2_B_tvalid <= '1';
                    when PB4 =>
                        mult_2_B_tdata <= post_buffer_4;
                        mult_2_B_tvalid <= '1';
                    when PB5 =>
                        mult_2_B_tdata <= post_buffer_5;
                        mult_2_B_tvalid <= '1';
                    when PB6 =>
                        mult_2_B_tdata <= post_buffer_6;
                        mult_2_B_tvalid <= '1';
                    when PB7 =>
                        mult_2_B_tdata <= post_buffer_7;
                        mult_2_B_tvalid <= '1';
                    when PB8 =>
                        mult_2_B_tdata <= post_buffer_8;
                        mult_2_B_tvalid <= '1';
                    when PB9 =>
                        mult_2_B_tdata <= post_buffer_9;
                        mult_2_B_tvalid <= '1';
                    when CT =>
                        mult_2_B_tdata <= c_t;
                        mult_2_B_tvalid <= '1';
                    when others =>
                        mult_2_B_tdata <= (others => '0');
                        mult_2_B_tvalid <= '0';
                end case;
                mult_2_B_tlast <= '0';
                mult_2_tdest <= "1";

                case mult_3_A_pb is
                    when PB1 =>
                        mult_3_A_tdata <= post_buffer_1;
                        mult_3_A_tvalid <= '1';
                    when PB2 =>
                        mult_3_A_tdata <= post_buffer_2;
                        mult_3_A_tvalid <= '1';
                    when PB3 =>
                        mult_3_A_tdata <= post_buffer_3;
                        mult_3_A_tvalid <= '1';
                    when PB4 =>
                        mult_3_A_tdata <= post_buffer_4;
                        mult_3_A_tvalid <= '1';
                    when PB5 =>
                        mult_3_A_tdata <= post_buffer_5;
                        mult_3_A_tvalid <= '1';
                    when PB6 =>
                        mult_3_A_tdata <= post_buffer_6;
                        mult_3_A_tvalid <= '1';
                    when PB7 =>
                        mult_3_A_tdata <= post_buffer_7;
                        mult_3_A_tvalid <= '1';
                    when PB8 =>
                        mult_3_A_tdata <= post_buffer_8;
                        mult_3_A_tvalid <= '1';
                    when PB9 =>
                        mult_3_A_tdata <= post_buffer_9;
                        mult_3_A_tvalid <= '1';
                    when CT =>
                        mult_3_A_tdata <= c_t;
                        mult_3_A_tvalid <= '1';
                    when others =>
                        mult_3_A_tdata <= (others => '0');
                        mult_3_A_tvalid <= '0';
                end case;
                mult_3_A_tlast <= '0';

                case mult_3_B_pb is
                    when PB1 =>
                        mult_3_B_tdata <= post_buffer_1;
                        mult_3_B_tvalid <= '1';
                    when PB2 =>
                        mult_3_B_tdata <= post_buffer_2;
                        mult_3_B_tvalid <= '1';
                    when PB3 =>
                        mult_3_B_tdata <= post_buffer_3;
                        mult_3_B_tvalid <= '1';
                    when PB4 =>
                        mult_3_B_tdata <= post_buffer_4;
                        mult_3_B_tvalid <= '1';
                    when PB5 =>
                        mult_3_B_tdata <= post_buffer_5;
                        mult_3_B_tvalid <= '1';
                    when PB6 =>
                        mult_3_B_tdata <= post_buffer_6;
                        mult_3_B_tvalid <= '1';
                    when PB7 =>
                        mult_3_B_tdata <= post_buffer_7;
                        mult_3_B_tvalid <= '1';
                    when PB8 =>
                        mult_3_B_tdata <= post_buffer_8;
                        mult_3_B_tvalid <= '1';
                    when PB9 =>
                        mult_3_B_tdata <= post_buffer_9;
                        mult_3_B_tvalid <= '1';
                    when CT =>
                        mult_3_B_tdata <= c_t;
                        mult_3_B_tvalid <= '1';
                    when others =>
                        mult_3_B_tdata <= (others => '0');
                        mult_3_B_tvalid <= '0';
                end case;
                mult_3_B_tlast <= '0';
                mult_3_tdest <= "1";
            when others =>
                null;
        end case;
    end process;

    -- C_T output process
    process (clk)
    begin
        if S_AXIS_C_T_out_tready = '1' then
            S_AXIS_C_T_out_tdata <= c_t;
            S_AXIS_C_T_out_tvalid <= '1';
        else
            S_AXIS_C_T_out_tvalid <= '0';
        end if;
    end process;

    -- Accumulation process
    process (clk)
        variable pe_state_next: pe_state_t;

        variable i_in_done : boolean := false;
        variable i_hid_done : boolean := false;
        variable f_in_done : boolean := false;
        variable f_hid_done : boolean := false;
        variable o_in_done : boolean := false;
        variable o_hid_done : boolean := false;
        variable g_in_done : boolean := false;
        variable g_hid_done : boolean := false;
    begin
        if rising_edge(clk) then
            case pe_state is
                when READY =>
                    -- Check if MACs are ready to receive data
                    if (i_in_mac_data_ready = '1' and i_in_mac_weight_ready = '1' and i_hid_mac_data_ready = '1' and i_hid_mac_weight_ready = '1' and
                        f_in_mac_data_ready = '1' and f_in_mac_weight_ready = '1' and f_hid_mac_data_ready = '1' and f_hid_mac_weight_ready = '1' and
                        o_in_mac_data_ready = '1' and o_in_mac_weight_ready = '1' and o_hid_mac_data_ready = '1' and o_hid_mac_weight_ready = '1' and
                        g_in_mac_data_ready = '1' and g_in_mac_weight_ready = '1' and g_hid_mac_data_ready = '1' and g_hid_mac_weight_ready = '1') 
                    then
                        pe_state_next := RECEIVE;

                        -- Set all the ready signals to 1
                        S_AXIS_DATA_IN_tready <= '1';
                        S_AXIS_HIDDEN_IN_tready <= '1';

                        S_AXIS_WEIGHT_I_input_tready <= '1';
                        S_AXIS_WEIGHT_I_hidden_tready <= '1';

                        S_AXIS_WEIGHT_F_INPUT_tready <= '1';
                        S_AXIS_WEIGHT_F_HIDDEN_tready <= '1';

                        S_AXIS_WEIGHT_O_INPUT_tready <= '1';
                        S_AXIS_WEIGHT_O_HIDDEN_tready <= '1';

                        S_AXIS_WEIGHT_G_INPUT_tready <= '1';
                        S_AXIS_WEIGHT_G_HIDDEN_tready <= '1';
                    else
                        pe_state_next := READY;
                        
                        -- Set all the ready signals to 0
                        S_AXIS_DATA_IN_tready <= '0';
                        S_AXIS_HIDDEN_IN_tready <= '0';

                        S_AXIS_WEIGHT_I_input_tready <= '0';
                        S_AXIS_WEIGHT_I_hidden_tready <= '0';

                        S_AXIS_WEIGHT_F_INPUT_tready <= '0';
                        S_AXIS_WEIGHT_F_HIDDEN_tready <= '0';

                        S_AXIS_WEIGHT_O_INPUT_tready <= '0';
                        S_AXIS_WEIGHT_O_HIDDEN_tready <= '0';

                        S_AXIS_WEIGHT_G_INPUT_tready <= '0';
                        S_AXIS_WEIGHT_G_HIDDEN_tready <= '0';
                    end if;

                    -- C_T and bias are ready to be received
                    S_AXIS_C_AND_BIAS_IN_tready <= '1';

                    if S_AXIS_C_T_in_tvalid = '1' then
                        c_t <= S_AXIS_C_T_in_tdata;
                    end if;

                    if S_AXIS_I_BIAS_tvalid = '1' then
                        i_bias <= S_AXIS_I_BIAS_tdata;
                    end if;

                    if S_AXIS_F_BIAS_tvalid = '1' then
                        f_bias <= S_AXIS_F_BIAS_tdata;
                    end if;

                    if S_AXIS_O_BIAS_tvalid = '1' then
                        o_bias <= S_AXIS_O_BIAS_tdata;
                    end if;

                    if S_AXIS_G_BIAS_tvalid = '1' then
                        g_bias <= S_AXIS_G_BIAS_tdata;
                    end if;
                when RECEIVE =>
                    -- Check if none of the last signals are raised
                    if (S_AXIS_DATA_IN_tlast = '0' and S_AXIS_HIDDEN_IN_tlast = '0' and
                        S_AXIS_WEIGHT_I_input_tlast = '0' and S_AXIS_WEIGHT_I_hidden_tlast = '0' and
                        S_AXIS_WEIGHT_F_input_tlast = '0' and S_AXIS_WEIGHT_F_hidden_tlast = '0' and
                        S_AXIS_WEIGHT_O_input_tlast = '0' and S_AXIS_WEIGHT_O_hidden_tlast = '0' and
                        S_AXIS_WEIGHT_G_input_tlast = '0' and S_AXIS_WEIGHT_G_hidden_tlast = '0') 
                    then
                        -- Keep ready signals high
                        S_AXIS_DATA_IN_tready <= '1';
                        S_AXIS_HIDDEN_IN_tready <= '1';

                        S_AXIS_WEIGHT_I_INPUT_tready <= '1';
                        S_AXIS_WEIGHT_I_HIDDEN_tready <= '1';

                        S_AXIS_WEIGHT_F_INPUT_tready <= '1';
                        S_AXIS_WEIGHT_F_HIDDEN_tready <= '1';

                        S_AXIS_WEIGHT_O_INPUT_tready <= '1';
                        S_AXIS_WEIGHT_O_HIDDEN_tready <= '1';

                        S_AXIS_WEIGHT_G_INPUT_tready <= '1';
                        S_AXIS_WEIGHT_G_HIDDEN_tready <= '1';
                    else
                        -- The last element has been received, cannot accept any more data
                        S_AXIS_DATA_IN_tready <= '0';
                        S_AXIS_HIDDEN_IN_tready <= '0';

                        S_AXIS_WEIGHT_I_INPUT_tready <= '0';
                        S_AXIS_WEIGHT_I_HIDDEN_tready <= '0';

                        S_AXIS_WEIGHT_F_INPUT_tready <= '0';
                        S_AXIS_WEIGHT_F_HIDDEN_tready <= '0';

                        S_AXIS_WEIGHT_O_INPUT_tready <= '0';
                        S_AXIS_WEIGHT_O_HIDDEN_tready <= '0';

                        S_AXIS_WEIGHT_G_INPUT_tready <= '0';
                        S_AXIS_WEIGHT_G_HIDDEN_tready <= '0';

                        -- Set the next state to accumulate
                        pe_state_next := ACCUMULATE;
                    end if;

                     -- C_T and bias are ready to be received
                    S_AXIS_C_AND_BIAS_IN_tready <= '1';

                    if S_AXIS_C_T_in_tvalid = '1' then
                        c_t <= S_AXIS_C_T_in_tdata;
                    end if;
 
                     if S_AXIS_I_BIAS_tvalid = '1' then
                         i_bias <= S_AXIS_I_BIAS_tdata;
                     end if;
 
                     if S_AXIS_F_BIAS_tvalid = '1' then
                         f_bias <= S_AXIS_F_BIAS_tdata;
                     end if;
 
                     if S_AXIS_O_BIAS_tvalid = '1' then
                         o_bias <= S_AXIS_O_BIAS_tdata;
                     end if;
 
                     if S_AXIS_G_BIAS_tvalid = '1' then
                         g_bias <= S_AXIS_G_BIAS_tdata;
                     end if;
                when ACCUMULATE =>
                    -- We are waiting for all the MACs to be finished so we cannot accept any more data
                    S_AXIS_DATA_IN_tready <= '0';
                    S_AXIS_HIDDEN_IN_tready <= '0';

                    S_AXIS_WEIGHT_I_INPUT_tready <= '0';
                    S_AXIS_WEIGHT_I_HIDDEN_tready <= '0';

                    S_AXIS_WEIGHT_F_INPUT_tready <= '0';
                    S_AXIS_WEIGHT_F_HIDDEN_tready <= '0';

                    S_AXIS_WEIGHT_O_INPUT_tready <= '0';
                    S_AXIS_WEIGHT_O_HIDDEN_tready <= '0';

                    S_AXIS_WEIGHT_G_INPUT_tready <= '0';
                    S_AXIS_WEIGHT_G_HIDDEN_tready <= '0';

                    if not i_in_done and i_in_out_valid = '1' and i_in_out_last = '1' then
                        i_in_done := true;
                        i_in_out_ready <= '0';
                        i_in_out_data_buffer <= i_in_out_data;
                    end if;

                    if not i_hid_done and i_hid_out_valid = '1' and i_hid_out_last = '1' then
                        i_hid_done := true;
                        i_hid_out_ready <= '0';
                        i_hid_out_data_buffer <= i_hid_out_data;
                    end if;

                    if not f_in_done and f_in_out_valid = '1' and f_in_out_last = '1' then
                        f_in_done := true;
                        f_in_out_ready <= '0';
                        f_in_out_data_buffer <= f_in_out_data;
                    end if;

                    if not f_hid_done and f_hid_out_valid = '1' and f_hid_out_last = '1' then
                        f_hid_done := true;
                        f_hid_out_ready <= '0';
                        f_hid_out_data_buffer <= f_hid_out_data;
                    end if;

                    if not o_in_done and o_in_out_valid = '1' and o_in_out_last = '1' then
                        o_in_done := true;
                        o_in_out_ready <= '0';
                        o_in_out_data_buffer <= o_in_out_data;
                    end if;

                    if not o_hid_done and o_hid_out_valid = '1' and o_hid_out_last = '1' then
                        o_hid_done := true;
                        o_hid_out_ready <= '0';
                        o_hid_out_data_buffer <= o_hid_out_data;
                    end if;

                    if not g_in_done and g_in_out_valid = '1' and g_in_out_last = '1' then
                        g_in_done := true;
                        g_in_out_ready <= '0';
                        g_in_out_data_buffer <= g_in_out_data;
                    end if;

                    if not g_hid_done and g_hid_out_valid = '1' and g_hid_out_last = '1' then
                        g_hid_done := true;
                        g_hid_out_ready <= '0';
                        g_hid_out_data_buffer <= g_hid_out_data;
                    end if;

                    if i_in_done and i_hid_done and f_in_done and f_hid_done and o_in_done and o_hid_done and g_in_done and g_hid_done then
                        -- Set the next state to post
                        pe_state_next := POST;

                        -- Reset the valid flags
                        i_in_done := false;
                        i_hid_done := false;

                        f_in_done := false;
                        f_hid_done := false;

                        o_in_done := false;
                        o_hid_done := false;

                        g_in_done := false;
                        g_hid_done := false;
                    end if;

                     -- C_T and bias are ready to be received
                    S_AXIS_C_AND_BIAS_IN_tready <= '1';

                    if S_AXIS_C_T_in_tvalid = '1' then
                        c_t <= S_AXIS_C_T_in_tdata;
                    end if;
 
                     if S_AXIS_I_BIAS_tvalid = '1' then
                         i_bias <= S_AXIS_I_BIAS_tdata;
                     end if;
 
                     if S_AXIS_F_BIAS_tvalid = '1' then
                         f_bias <= S_AXIS_F_BIAS_tdata;
                     end if;
 
                     if S_AXIS_O_BIAS_tvalid = '1' then
                         o_bias <= S_AXIS_O_BIAS_tdata;
                     end if;
 
                     if S_AXIS_G_BIAS_tvalid = '1' then
                         g_bias <= S_AXIS_G_BIAS_tdata;
                     end if;
                when POST =>
                    S_AXIS_C_AND_BIAS_IN_tready <= '0';

                    case pe_post_state is
                        when S1 =>
                            -- Stage 1: The output of the i, g, and f macs are added together. So input + hidden
                            
                            -- I MAC
                            -- Wait for the adder to be ready
                            if (adder_1_A_tready = '1' and adder_1_B_tready = '1' and adder_1_state = IDLE) then
                                -- Set the inputs to the adder
                                adder_1_A_tdata <= i_in_out_data_buffer;
                                adder_1_A_tvalid <= '1';
                                adder_1_B_tdata <= i_hid_out_data_buffer;
                                adder_1_B_tvalid <= '1';

                                adder_1_RESULT_tready <= '1';
                                adder_1_state <= WAITING;
                                adder_1_lat_block <= BLOCKED;
                            end if;

                            if (adder_1_lat_block = BLOCKED) then
                                adder_1_lat_block <= UNBLOCKED;
                            end if;

                            -- Wait for the adder to be done
                            if (adder_1_state = WAITING and adder_1_RESULT_tvalid = '1' and adder_1_lat_block = UNBLOCKED) then
                                -- Reset the adder
                                adder_1_A_tvalid <= '0';
                                adder_1_B_tvalid <= '0';
                                adder_1_RESULT_tready <= '0';
                                post_buffer_1 <= adder_1_RESULT_tdata;
                                adder_1_state <= DONE;
                            end if;

                            -- F MAC
                            -- Wait for the adder to be ready
                            if (adder_2_A_tready = '1' and adder_2_B_tready = '1' and adder_2_state = IDLE) then
                                -- Set the inputs to the adder
                                adder_2_A_tdata <= f_in_out_data_buffer;
                                adder_2_A_tvalid <= '1';
                                adder_2_B_tdata <= f_hid_out_data_buffer;
                                adder_2_B_tvalid <= '1';

                                adder_2_RESULT_tready <= '1';
                                adder_2_state <= WAITING;
                                adder_2_lat_block <= BLOCKED;
                            end if;

                            if (adder_2_lat_block = BLOCKED) then
                                adder_2_lat_block <= UNBLOCKED;
                            end if;

                            -- Wait for the adder to be done
                            if (adder_2_RESULT_tvalid = '1' and adder_2_state = WAITING and adder_2_lat_block = UNBLOCKED) then
                                -- Reset the adder
                                adder_2_A_tvalid <= '0';
                                adder_2_B_tvalid <= '0';
                                adder_2_RESULT_tready <= '0';
                                post_buffer_2 <= adder_2_RESULT_tdata;
                                adder_2_state <= DONE;
                            end if;

                            -- G MAC
                            -- Wait for the adder to be ready
                            if (adder_3_A_tready = '1' and adder_3_B_tready = '1' and adder_3_state = IDLE) then
                                -- Set the inputs to the adder
                                adder_3_A_tdata <= g_in_out_data_buffer;
                                adder_3_A_tvalid <= '1';
                                adder_3_B_tdata <= g_hid_out_data_buffer;
                                adder_3_B_tvalid <= '1';

                                adder_3_RESULT_tready <= '1';
                                adder_3_state <= WAITING;

                                adder_3_lat_block <= BLOCKED;
                            end if;

                            if (adder_3_lat_block = BLOCKED) then
                                adder_3_lat_block <= UNBLOCKED;
                            end if;

                            -- Wait for the adder to be done
                            if (adder_3_RESULT_tvalid = '1' and adder_3_state = WAITING and adder_3_lat_block = UNBLOCKED) then
                                -- Reset the adder
                                adder_3_A_tvalid <= '0';
                                adder_3_B_tvalid <= '0';
                                adder_3_RESULT_tready <= '0';
                                post_buffer_3 <= adder_3_RESULT_tdata;
                                adder_3_state <= DONE;
                            end if;

                            -- Wait for all the adders to be done
                            if (adder_1_state = DONE and adder_2_state = DONE and adder_3_state = DONE) then
                                -- Set the next state to post
                                pe_post_state <= S2;

                                -- Reset the states to idle
                                adder_1_state <= IDLE;
                                adder_2_state <= IDLE;
                                adder_3_state <= IDLE;
                            end if;
                        when S2 =>
                            -- Stage 2: The output of the i, g, and f of the previous stage are added with their corresponding biases

                            -- Buffers
                            -- 1: i_inp + i_hid
                            -- 2: f_inp + f_hid
                            -- 3: g_inp + g_hid
                            -- 4: empty
                            -- 5: empty
                            -- 6: empty
                            -- 7: empty
                            -- 8: empty
                            -- 9: empty

                            -- I MAC
                            -- Wait for the adder to be ready
                            if (adder_1_A_tready = '1' and adder_1_B_tready = '1' and adder_1_state = IDLE) then
                                -- Set the inputs to the adder
                                adder_1_A_tdata <= post_buffer_1;
                                adder_1_A_tvalid <= '1';
                                adder_1_B_tdata <= i_bias;
                                adder_1_B_tvalid <= '1';

                                adder_1_RESULT_tready <= '1';
                                adder_1_state <= WAITING;

                                adder_1_lat_block <= BLOCKED;
                            end if;

                            if (adder_1_lat_block = BLOCKED) then
                                adder_1_lat_block <= UNBLOCKED;
                            end if;

                            -- Wait for the adder to be done
                            if (adder_1_RESULT_tvalid = '1' and adder_1_state = WAITING and adder_1_lat_block = UNBLOCKED) then
                                -- Reset the adder
                                adder_1_A_tvalid <= '0';
                                adder_1_B_tvalid <= '0';
                                adder_1_RESULT_tready <= '0';
                                post_buffer_1 <= adder_1_RESULT_tdata;
                                adder_1_state <= DONE;
                            end if;

                            -- G MAC
                            -- Wait for the adder to be ready
                            if (adder_2_A_tready = '1' and adder_2_B_tready = '1' and adder_2_state = IDLE) then
                                -- Set the inputs to the adder
                                adder_2_A_tdata <= post_buffer_2;
                                adder_2_A_tvalid <= '1';
                                adder_2_B_tdata <= g_bias;
                                adder_2_B_tvalid <= '1';

                                adder_2_RESULT_tready <= '1';
                                adder_2_state <= WAITING;

                                adder_2_lat_block <= BLOCKED;
                            end if;

                            if (adder_2_lat_block = BLOCKED) then
                                adder_2_lat_block <= UNBLOCKED;
                            end if;

                            -- Wait for the adder to be done
                            if (adder_2_RESULT_tvalid = '1' and adder_2_state = WAITING and adder_2_lat_block = UNBLOCKED) then
                                -- Reset the adder
                                adder_2_A_tvalid <= '0';
                                adder_2_B_tvalid <= '0';
                                adder_2_RESULT_tready <= '0';
                                post_buffer_2 <= adder_2_RESULT_tdata;
                                adder_2_state <= DONE;
                            end if;

                            -- F MAC
                            -- Wait for the adder to be ready
                            if (adder_3_A_tready = '1' and adder_3_B_tready = '1' and adder_3_state = IDLE) then
                                -- Set the inputs to the adder
                                adder_3_A_tdata <= post_buffer_3;
                                adder_3_A_tvalid <= '1';
                                adder_3_B_tdata <= f_bias;
                                adder_3_B_tvalid <= '1';

                                adder_3_RESULT_tready <= '1';
                                adder_3_state <= WAITING;

                                adder_3_lat_block <= BLOCKED;
                            end if;

                            if (adder_3_lat_block = BLOCKED) then
                                adder_3_lat_block <= UNBLOCKED;
                            end if;

                            -- Wait for the adder to be done
                            if (adder_3_RESULT_tvalid = '1' and adder_3_state = WAITING and adder_3_lat_block = UNBLOCKED) then
                                -- Reset the adder
                                adder_3_A_tvalid <= '0';
                                adder_3_B_tvalid <= '0';
                                adder_3_RESULT_tready <= '0';
                                post_buffer_3 <= adder_3_RESULT_tdata;
                                adder_3_state <= DONE;
                            end if;

                            -- Wait for all the adders to be done
                            if (adder_1_state = DONE and adder_2_state = DONE and adder_3_state = DONE) then
                                -- Set the next state to post
                                pe_post_state <= S3;

                                -- Reset the states to idle
                                adder_1_state <= IDLE;
                                adder_2_state <= IDLE;
                                adder_3_state <= IDLE;

                                sig_1_slope_tready <= '1';
                                sig_1_offset_tready <= '1';
                                sig_1_input_out_tready <= '1';
                                sig_1_value_tready <= '1';

                                sig_2_slope_tready <= '1';
                                sig_2_offset_tready <= '1';
                                sig_2_input_out_tready <= '1';
                                sig_2_value_tready <= '1';

                                tanh_slope_tready <= '1';
                                tanh_offset_tready <= '1';
                                tanh_input_out_tready <= '1';
                                tanh_value_tready <= '1';
                            end if;
                        when S3 =>
                            -- Stage 3: The outputs are now activated with i and f being sigmoid and g being tanh
                            -- The first stage of the activation is arbiting the slope of the piecewise linear function approximation
                            
                            -- Buffers
                            -- 1: i + i_bias
                            -- 2: f + f_bias
                            -- 3: g + g_bias
                            -- 4: empty
                            -- 5: empty
                            -- 6: empty
                            -- 7: empty
                            -- 8: empty
                            -- 9: empty

                            -- I MAC
                            -- Wait for arbiter to be ready
                            if (sig_1_input_tready = '1' and sig_1_state = IDLE) then
                                -- Set the inputs to the arbiter
                                sig_1_input_tdata <= post_buffer_1;
                                sig_1_input_tvalid <= '1';

                                sig_1_slope_tready <= '1';
                                sig_1_offset_tready <= '1';
                                sig_1_input_out_tready <= '1';
                                sig_1_value_tready <= '1';
                                sig_1_state <= WAITING;
                            end if;

                            -- Wait for the arbiter to be done
                            if (sig_1_state = WAITING) then
                                if (sig_1_value_tvalid = '1') then
                                    post_buffer_1 <= sig_1_value_tdata;
                                    post_buffer_2 <= (others => '0');
                                    post_buffer_3 <= (others => '0');
                                    sig_1_method <= VALUE;

                                    sig_1_slope_tready <= '0';
                                    sig_1_offset_tready <= '0';
                                    sig_1_input_out_tready <= '0';
                                    sig_1_value_tready <= '0';
                                    
                                    sig_1_state <= DONE;
                                elsif (sig_1_input_out_tvalid = '1' and sig_1_offset_tvalid = '1' and sig_1_slope_tvalid = '1') then
                                    post_buffer_1 <= sig_1_slope_tdata;
                                    post_buffer_2 <= sig_1_offset_tdata;
                                    post_buffer_3 <= sig_1_input_out_tdata;

                                    sig_1_method <= PWL;

                                    sig_1_slope_tready <= '0';
                                    sig_1_offset_tready <= '0';
                                    sig_1_input_out_tready <= '0';
                                    sig_1_value_tready <= '0';
                                    
                                    sig_1_state <= DONE;
                                end if;

                                -- Reset the arbiter
                                sig_1_input_tvalid <= '0';
                            end if;

                            -- F MAC
                            -- Wait for arbiter to be ready
                            if (sig_2_input_tready = '1' and sig_2_state = IDLE) then
                                -- Set the inputs to the arbiter
                                sig_2_input_tdata <= post_buffer_2;
                                sig_2_input_tvalid <= '1';

                                sig_2_slope_tready <= '1';
                                sig_2_offset_tready <= '1';
                                sig_2_input_out_tready <= '1';
                                sig_2_value_tready <= '1';
                                sig_2_state <= WAITING;
                            end if;

                            -- Wait for the arbiter to be done
                            if (sig_2_state = WAITING) then
                                if (sig_2_value_tvalid = '1') then
                                    post_buffer_4 <= sig_2_value_tdata;
                                    post_buffer_5 <= (others => '0');
                                    post_buffer_6 <= (others => '0');
                                    sig_2_method <= VALUE;

                                    sig_2_slope_tready <= '0';
                                    sig_2_offset_tready <= '0';
                                    sig_2_input_out_tready <= '0';
                                    sig_2_value_tready <= '0';
                                    sig_2_state <= DONE;
                                elsif (sig_2_input_out_tvalid = '1' and sig_2_offset_tvalid = '1' and sig_2_slope_tvalid = '1') then
                                    post_buffer_4 <= sig_2_slope_tdata;
                                    post_buffer_5 <= sig_2_offset_tdata;
                                    post_buffer_6 <= sig_2_input_out_tdata;

                                    sig_2_method <= PWL;

                                    sig_2_slope_tready <= '0';
                                    sig_2_offset_tready <= '0';
                                    sig_2_input_out_tready <= '0';
                                    sig_2_value_tready <= '0';
                                    sig_2_state <= DONE;
                                end if;

                                -- Reset the arbiter
                                sig_2_input_tvalid <= '0';
                            end if;

                            -- G MAC
                            -- Wait for arbiter to be ready
                            if (tanh_input_tready = '1' and tanh_state = IDLE) then
                                -- Set the inputs to the arbiter
                                tanh_input_tdata <= post_buffer_3;
                                tanh_input_tvalid <= '1';

                                tanh_slope_tready <= '1';
                                tanh_offset_tready <= '1';
                                tanh_input_out_tready <= '1';
                                tanh_value_tready <= '1';
                                tanh_state <= WAITING;
                            end if;

                            -- Wait for the arbiter to be done
                            if (tanh_state = WAITING) then
                                if (tanh_value_tvalid = '1') then
                                    post_buffer_7 <= tanh_value_tdata;
                                    post_buffer_8 <= (others => '0');
                                    post_buffer_9 <= (others => '0');
                                    tanh_method <= VALUE;

                                    tanh_slope_tready <= '0';
                                    tanh_offset_tready <= '0';
                                    tanh_input_out_tready <= '0';
                                    tanh_value_tready <= '0';
                                    
                                    tanh_state <= DONE;
                                elsif (tanh_input_out_tvalid = '1' and tanh_offset_tvalid = '1' and tanh_slope_tvalid = '1') then
                                    post_buffer_7 <= tanh_slope_tdata;
                                    post_buffer_8 <= tanh_offset_tdata;
                                    post_buffer_9 <= tanh_input_out_tdata;

                                    tanh_method <= PWL;

                                    tanh_slope_tready <= '0';
                                    tanh_offset_tready <= '0';
                                    tanh_input_out_tready <= '0';
                                    tanh_value_tready <= '0';
                                    
                                    tanh_state <= DONE;
                                end if;

                                -- Reset the arbiter
                                tanh_input_tvalid <= '0';
                            end if;

                            -- Wait for all arbiters to be done
                            if (sig_1_state = DONE and sig_2_state = DONE and tanh_state = DONE) then
                                -- Reset the arbiter states
                                sig_1_state <= IDLE;
                                sig_2_state <= IDLE;
                                tanh_state <= IDLE;

                                pe_post_state <= S4;
                            end if;

                        when S4 =>
                            -- Stage 4: Depending on the method, the outputs are fed to the multiplier (PWL) otherwise the value is passed through

                            -- Buffers
                            -- 1: i_sig Slope | Value
                            -- 2: i_sig Offset | Empty
                            -- 3: i_sig Input | Empty
                            -- 4: f_sig Slope | Value
                            -- 5: f_sig Offset | Empty
                            -- 6: f_sig Input | Empty
                            -- 7: g_tanh Slope | Value
                            -- 8: g_tanh Offset | Empty
                            -- 9: g_tanh Input | Empty

                            -- i_sig
                            -- Wait for the multiplier to be ready
                            if (mult_1_A_tready = '1' and mult_1_B_tready = '1' and mult_1_state = IDLE) then
                                if (sig_1_method = PWL) then
                                    mult_1_A_pb <= PB1;
                                    mult_1_B_pb <= PB3;

                                    mult_1_RESULT_tready <= '1';

                                    mult_1_state <= WAITING;
                                else
                                    mult_1_state <= DONE;
                                end if;
                            end if;

                            -- Wait for the multiplier to be done
                            if (mult_1_RESULT_tvalid = '1' and mult_1_state = WAITING) then
                                    post_buffer_1 <= mult_1_RESULT_tdata;
                                    post_buffer_3 <= (others => '0');
                                    
                                    mult_1_state <= DONE;

                                     -- Reset the multiplier
                                     mult_1_A_pb <= NONE;
                                     mult_1_B_pb <= NONE;
                                    mult_1_RESULT_tready <= '0';
                            end if;

                            -- f_sig
                            -- Wait for the multiplier to be ready
                            if (mult_2_A_tready = '1' and mult_2_B_tready = '1' and mult_2_state = IDLE) then
                                if (sig_2_method = PWL) then
                                    mult_2_A_pb <= PB4;
                                    mult_2_B_pb <= PB6;

                                    mult_2_RESULT_tready <= '1';

                                    mult_2_state <= WAITING;
                                else
                                    mult_2_state <= DONE;
                                end if;
                            end if;

                            -- Wait for the multiplier to be done
                            if (mult_2_RESULT_tvalid = '1' and mult_2_state = WAITING) then
                                    post_buffer_4 <= mult_2_RESULT_tdata;
                                    post_buffer_6 <= (others => '0');
                                    mult_2_state <= DONE;

                                     -- Reset the multiplier
                                    mult_2_A_pb <= NONE;
                                    mult_2_B_pb <= NONE;
                                    mult_2_RESULT_tready <= '0';
                            end if;

                            -- g_tanh
                            -- Wait for the multiplier to be ready
                            if (mult_3_A_tready = '1' and mult_3_B_tready = '1' and mult_3_state = IDLE) then
                                if (tanh_method = PWL) then
                                    mult_3_A_pb <= PB7;
                                    mult_3_B_pb <= PB9;

                                    mult_3_RESULT_tready <= '1';

                                    mult_3_state <= WAITING;
                                else
                                    mult_3_state <= DONE;
                                end if;
                            end if;

                            -- Wait for the multiplier to be done
                            if (mult_3_RESULT_tvalid = '1' and mult_3_state = WAITING) then
                                    post_buffer_7 <= mult_3_RESULT_tdata;
                                    post_buffer_9 <= (others => '0');
                                    mult_3_state <= DONE;

                                     -- Reset the multiplier
                                    mult_3_A_pb <= NONE;
                                    mult_3_B_pb <= NONE;
                                    mult_3_RESULT_tready <= '0';
                            end if;

                            -- Wait for all the multipliers to be done
                            if (mult_1_state = DONE and mult_2_state = DONE and mult_3_state = DONE) then
                                -- Reset the multipliers
                                mult_1_state <= IDLE;
                                mult_2_state <= IDLE;
                                mult_3_state <= IDLE;

                                pe_post_state <= S5;
                            end if;
                        when S5 =>
                            -- Stage 5: Add the offset to the multiplier results

                            -- Buffers
                            -- 1: i_sig Mult | Value
                            -- 2: i_sig Offset | Empty
                            -- 3: Empty
                            -- 4: f_sig Mult | Value
                            -- 5: f_sig Offset | Empty
                            -- 6: Empty
                            -- 7: g_tanh Mult | Value
                            -- 8: g_tanh Offset | Empty
                            -- 9: Empty

                            -- i_sig
                            -- Wait for the adder to be ready
                            if (adder_1_A_tready = '1' and adder_1_B_tready = '1' and adder_1_state = IDLE) then
                                if (sig_1_method = PWL) then
                                    adder_1_A_tdata <= post_buffer_1;
                                    adder_1_A_tvalid <= '1';

                                    adder_1_B_tdata <= post_buffer_2;
                                    adder_1_B_tvalid <= '1';

                                    adder_1_RESULT_tready <= '1';

                                    adder_1_state <= WAITING;

                                    adder_1_lat_block <= BLOCKED;
                                else
                                    adder_1_state <= DONE;
                                end if;
                            end if;

                            if (adder_1_lat_block = BLOCKED) then
                                adder_1_lat_block <= UNBLOCKED;
                            end if;

                            -- Wait for the adder to be done
                            if (adder_1_RESULT_tvalid = '1' and adder_1_state = WAITING and adder_1_lat_block = UNBLOCKED) then
                                    post_buffer_1 <= adder_1_RESULT_tdata;
                                    post_buffer_2 <= (others => '0');
                                    adder_1_state <= DONE;

                                     -- Reset the adder
                                    adder_1_A_tvalid <= '0';
                                    adder_1_B_tvalid <= '0';
                                    adder_1_RESULT_tready <= '0';
                            end if;

                            -- f_sig
                            -- Wait for the adder to be ready
                            if (adder_2_A_tready = '1' and adder_2_B_tready = '1' and adder_2_state = IDLE) then
                                if (sig_2_method = PWL) then
                                    adder_2_A_tdata <= post_buffer_4;
                                    adder_2_A_tvalid <= '1';

                                    adder_2_B_tdata <= post_buffer_5;
                                    adder_2_B_tvalid <= '1';

                                    adder_2_RESULT_tready <= '1';

                                    adder_2_state <= WAITING;

                                    adder_2_lat_block <= BLOCKED;
                                else
                                    adder_2_state <= DONE;
                                end if;
                            end if;

                            if (adder_2_lat_block = BLOCKED) then
                                adder_2_lat_block <= UNBLOCKED;
                            end if;

                            -- Wait for the adder to be done
                            if (adder_2_RESULT_tvalid = '1' and adder_2_state = WAITING and adder_2_lat_block = UNBLOCKED) then
                                    post_buffer_4 <= adder_2_RESULT_tdata;
                                    post_buffer_5 <= (others => '0');
                                    adder_2_state <= DONE;

                                     -- Reset the adder
                                    adder_2_A_tvalid <= '0';
                                    adder_2_B_tvalid <= '0';
                                    adder_2_RESULT_tready <= '0';
                            end if;

                            -- g_tanh
                            -- Wait for the adder to be ready
                            if (adder_3_A_tready = '1' and adder_3_B_tready = '1' and adder_3_state = IDLE) then
                                if (tanh_method = PWL) then
                                    adder_3_A_tdata <= post_buffer_7;
                                    adder_3_A_tvalid <= '1';

                                    adder_3_B_tdata <= post_buffer_8;
                                    adder_3_B_tvalid <= '1';

                                    adder_3_RESULT_tready <= '1';

                                    adder_3_state <= WAITING;

                                    adder_3_lat_block <= BLOCKED;
                                else
                                    adder_3_state <= DONE;
                                end if;
                            end if;

                            if (adder_3_lat_block = BLOCKED) then
                                adder_3_lat_block <= UNBLOCKED;
                            end if;

                            -- Wait for the adder to be done
                            if (adder_3_RESULT_tvalid = '1' and adder_3_state = WAITING and adder_3_lat_block = UNBLOCKED) then
                                    post_buffer_7 <= adder_3_RESULT_tdata;
                                    post_buffer_8 <= (others => '0');
                                    adder_3_state <= DONE;

                                     -- Reset the adder
                                    adder_3_A_tvalid <= '0';
                                    adder_3_B_tvalid <= '0';
                                    adder_3_RESULT_tready <= '0';
                            end if;

                            -- Wait for all the adders to be done
                            if (adder_1_state = DONE and adder_2_state = DONE and adder_3_state = DONE) then
                                -- Reset the adders
                                adder_1_state <= IDLE;
                                adder_2_state <= IDLE;
                                adder_3_state <= IDLE;

                                pe_post_state <= S6;
                            end if;
                        when S6 =>
                            -- Stage 6: Multiply the I and G results and multiply the F and C value
                            -- Additionally the O_input and O_hidden are added to each other

                            -- Buffers
                            -- 1: i_sig Value
                            -- 2: Empty
                            -- 3: Empty
                            -- 4: f_sig Value
                            -- 5: Empty
                            -- 6: Empty
                            -- 7: g_tanh Value
                            -- 8: Empty
                            -- 9: Empty

                            -- i_sig * g_tanh
                            -- Wait for the multiplier to be ready
                            if (mult_1_A_tready = '1' and mult_1_B_tready = '1' and mult_1_state = IDLE) then
                                mult_1_A_pb <= PB1;
                                mult_1_B_pb <= PB7;

                                mult_1_RESULT_tready <= '1';

                                mult_1_state <= WAITING;
                            end if;

                            -- Wait for the multiplier to be done
                            if (mult_1_RESULT_tvalid = '1' and mult_1_state = WAITING) then
                                    post_buffer_1 <= mult_1_RESULT_tdata;
                                    post_buffer_7 <= (others => '0');
                                    mult_1_state <= DONE;

                                     -- Reset the multiplier
                                    mult_1_A_pb <= NONE;
                                    mult_1_B_pb <= NONE;
                                    mult_1_RESULT_tready <= '0';
                            end if;

                            -- f_sig * c
                            -- Wait for the multiplier to be ready
                            if (mult_2_A_tready = '1' and mult_2_B_tready = '1' and mult_2_state = IDLE) then
                                mult_2_A_pb <= PB4;
                                mult_2_B_pb <= CT;

                                mult_2_RESULT_tready <= '1';
                                
                                mult_2_state <= WAITING;
                            end if;

                            -- Wait for the multiplier to be done
                            if (mult_2_RESULT_tvalid = '1' and mult_2_state = WAITING) then
                                    post_buffer_2 <= mult_2_RESULT_tdata;
                                    post_buffer_4 <= (others => '0');
                                    mult_2_state <= DONE;

                                     -- Reset the multiplier
                                    mult_2_A_pb <= NONE;
                                    mult_2_B_pb <= NONE;
                                    mult_2_RESULT_tready <= '0';
                            end if;

                            -- o_input + o_hidden
                            -- Wait for the adder to be ready
                            if (adder_1_A_tready = '1' and adder_1_B_tready = '1' and adder_1_state = IDLE) then
                                adder_1_A_tdata <= o_in_out_data_buffer;
                                adder_1_A_tvalid <= '1';

                                adder_1_B_tdata <= o_hid_out_data_buffer;
                                adder_1_B_tvalid <= '1';

                                adder_1_RESULT_tready <= '1';

                                adder_1_state <= WAITING;

                                adder_1_lat_block <= BLOCKED;
                            end if;

                            if (adder_1_lat_block = BLOCKED) then
                                adder_1_lat_block <= UNBLOCKED;
                            end if;

                            -- Wait for the adder to be done
                            if (adder_1_RESULT_tvalid = '1' and adder_1_state = WAITING and adder_1_lat_block = UNBLOCKED) then
                                    post_buffer_4 <= adder_1_RESULT_tdata;
                                    o_in_out_data_buffer <= (others => '0');
                                    o_hid_out_data_buffer <= (others => '0');
                                    adder_1_state <= DONE;

                                     -- Reset the adder
                                    adder_1_A_tvalid <= '0';
                                    adder_1_B_tvalid <= '0';
                                    adder_1_RESULT_tready <= '0';
                            end if;

                            -- Wait for all the multipliers and adders to be done
                            if (mult_1_state = DONE and mult_2_state = DONE and adder_1_state = DONE) then
                                -- Reset the multipliers and adders
                                mult_1_state <= IDLE;
                                mult_2_state <= IDLE;
                                adder_1_state <= IDLE;

                                pe_post_state <= S7;
                            end if;

                        when S7 =>
                            -- Stage 7: Add the results of the multiplications together
                            -- Additionally the O and O_bias are added to each other

                            -- Buffers
                            -- 1: i_sig * g_tanh
                            -- 2: f_sig * c
                            -- 3: Empty
                            -- 4: o_input + o_hidden
                            -- 5: Empty
                            -- 6: Empty
                            -- 7: Empty
                            -- 8: Empty
                            -- 9: Empty

                            -- (i_sig * g_tanh) + (f_sig * c)
                            -- Wait for the adder to be ready
                            if (adder_1_A_tready = '1' and adder_1_B_tready = '1' and adder_1_state = IDLE) then
                                adder_1_A_tdata <= post_buffer_1;
                                adder_1_A_tvalid <= '1';

                                adder_1_B_tdata <= post_buffer_2;
                                adder_1_B_tvalid <= '1';

                                adder_1_RESULT_tready <= '1';

                                adder_1_state <= WAITING;

                                adder_1_lat_block <= BLOCKED;
                            end if;

                            if (adder_1_lat_block = BLOCKED) then
                                adder_1_lat_block <= UNBLOCKED;
                            end if;

                            -- Wait for the adder to be done
                            if (adder_1_RESULT_tvalid = '1' and adder_1_state = WAITING and adder_1_lat_block = UNBLOCKED) then
                                    post_buffer_1 <= adder_1_RESULT_tdata;
                                    c_t <= adder_1_RESULT_tdata;
                                    post_buffer_2 <= (others => '0');
                                    adder_1_state <= DONE;

                                     -- Reset the adder
                                    adder_1_A_tvalid <= '0';
                                    adder_1_B_tvalid <= '0';
                                    adder_1_RESULT_tready <= '0';
                            end if;

                            -- O + O_bias
                            -- Wait for the adder to be ready
                            if (adder_2_A_tready = '1' and adder_2_B_tready = '1' and adder_2_state = IDLE) then
                                adder_2_A_tdata <= post_buffer_4;
                                adder_2_A_tvalid <= '1';

                                adder_2_B_tdata <= o_bias;
                                adder_2_B_tvalid <= '1';

                                adder_2_RESULT_tready <= '1';

                                adder_2_state <= WAITING;

                                adder_2_lat_block <= BLOCKED;
                            end if;

                            if (adder_2_lat_block = BLOCKED) then
                                adder_2_lat_block <= UNBLOCKED;
                            end if;

                            -- Wait for the adder to be done
                            if (adder_2_RESULT_tvalid = '1' and adder_2_state = WAITING and adder_2_lat_block = UNBLOCKED) then
                                    post_buffer_4 <= adder_2_RESULT_tdata;
                                    adder_2_state <= DONE;

                                     -- Reset the adder
                                    adder_2_A_tvalid <= '0';
                                    adder_2_B_tvalid <= '0';
                                    adder_2_RESULT_tready <= '0';
                            end if;

                            -- Wait for all the adders to be done
                            if (adder_1_state = DONE and adder_2_state = DONE) then
                                -- Reset the adders
                                adder_1_state <= IDLE;
                                adder_2_state <= IDLE;

                                pe_post_state <= S8;

                                -- Prepare ready signals for arbiters in stage 8
                                tanh_slope_tready <= '1';
                                tanh_offset_tready <= '1';
                                tanh_input_out_tready <= '1';
                                tanh_value_tready <= '1';

                                sig_1_slope_tready <= '1';
                                sig_1_offset_tready <= '1';
                                sig_1_input_out_tready <= '1';
                                sig_1_value_tready <= '1';
                            end if;
                        when S8 =>
                            -- Stage 8: the tanh function is applied on the combination of i, g, f and c; the o is put through a sigmoid function

                            -- Buffers
                            -- 1: i_sig * g_tanh + f_sig * c
                            -- 2: Empty
                            -- 3: Empty
                            -- 4: o + o_bias
                            -- 5: Empty
                            -- 6: Empty
                            -- 7: Empty
                            -- 8: Empty
                            -- 9: Empty

                            -- tanh arbiter
                            -- Wait for the arbiter to be ready
                            if (tanh_input_tready = '1' and tanh_state = IDLE) then
                                -- Set the inputs to the arbiter
                                tanh_input_tdata <= post_buffer_1;
                                tanh_input_tvalid <= '1';

                                tanh_slope_tready <= '1';
                                tanh_offset_tready <= '1';
                                tanh_input_out_tready <= '1';
                                tanh_value_tready <= '1';
                                
                                tanh_state <= WAITING;
                            end if;

                            -- Wait for the arbiter to be done
                            if (tanh_state = WAITING) then
                                if (tanh_value_tvalid = '1') then
                                    post_buffer_1 <= tanh_value_tdata;
                                    post_buffer_2 <= (others => '0');
                                    post_buffer_3 <= (others => '0');

                                    tanh_method <= VALUE;

                                    tanh_slope_tready <= '0';
                                    tanh_offset_tready <= '0';
                                    tanh_input_out_tready <= '0';
                                    tanh_value_tready <= '0';
                                    
                                    tanh_state <= DONE;
                                elsif (tanh_input_out_tvalid = '1' and tanh_offset_tvalid = '1' and tanh_slope_tvalid = '1') then
                                    post_buffer_1 <= tanh_slope_tdata;
                                    post_buffer_2 <= tanh_offset_tdata;
                                    post_buffer_3 <= tanh_input_out_tdata;

                                    tanh_method <= PWL;

                                    tanh_slope_tready <= '0';
                                    tanh_offset_tready <= '0';
                                    tanh_input_out_tready <= '0';
                                    tanh_value_tready <= '0';
                                    
                                    tanh_state <= DONE;
                                end if;

                                -- Reset the arbiter
                                tanh_input_tvalid <= '0';
                            end if;

                            -- Sig arbiter
                            -- Wait for the arbiter to be ready
                            if (sig_1_input_tready = '1' and sig_1_state = IDLE) then
                                -- Set the inputs to the arbiter
                                sig_1_input_tdata <= post_buffer_4;
                                sig_1_input_tvalid <= '1';

                                sig_1_slope_tready <= '1';
                                sig_1_offset_tready <= '1';
                                sig_1_input_out_tready <= '1';
                                sig_1_value_tready <= '1';
                                sig_1_state <= WAITING;
                            end if;

                            -- Wait for the arbiter to be done
                            if (sig_1_state = WAITING) then
                                if (sig_1_value_tvalid = '1') then
                                    post_buffer_4 <= sig_1_value_tdata;
                                    post_buffer_5 <= (others => '0');
                                    post_buffer_6 <= (others => '0');

                                    sig_1_method <= VALUE;

                                    sig_1_slope_tready <= '0';
                                    sig_1_offset_tready <= '0';
                                    sig_1_input_out_tready <= '0';
                                    sig_1_value_tready <= '0';
                                    
                                    sig_1_state <= DONE;
                                elsif (sig_1_input_out_tvalid = '1' and sig_1_offset_tvalid = '1' and sig_1_slope_tvalid = '1') then
                                    post_buffer_4 <= sig_1_slope_tdata;
                                    post_buffer_5 <= sig_1_offset_tdata;
                                    post_buffer_6 <= sig_1_input_out_tdata;

                                    sig_1_method <= PWL;

                                    sig_1_slope_tready <= '0';
                                    sig_1_offset_tready <= '0';
                                    sig_1_input_out_tready <= '0';
                                    sig_1_value_tready <= '0';
                                    
                                    sig_1_state <= DONE;
                                end if;

                                -- Reset the arbiter
                                sig_1_input_tvalid <= '0';
                            end if;

                            -- Wait for all the arbiters to be done
                            if (tanh_state = DONE and sig_1_state = DONE) then
                                -- Reset the arbiters
                                tanh_state <= IDLE;
                                sig_1_state <= IDLE;

                                pe_post_state <= S9;
                            end if;
                        when S9 =>
                            -- Stage 9: the tanh and sigmoid functions are fed through the multiplier if PWL otherwise passed through

                            -- Buffers
                            -- 1: tanh Slope | Value
                            -- 2: tanh Offset | Empty
                            -- 3: tanh Input | Empty
                            -- 4: sig_1 Slope | Value
                            -- 5: sig_1 Offset | Empty
                            -- 6: sig_1 Input | Empty
                            -- 7: Empty
                            -- 8: Empty
                            -- 9: Empty

                            -- tanh multiplier
                            -- Wait for the multiplier to be ready
                            if (mult_1_A_tready = '1' and mult_1_B_tready = '1' and mult_1_state = IDLE) then
                                if (tanh_method = PWL) then
                                    -- Set the inputs to the multiplier
                                    mult_1_A_pb <= PB1;
                                    mult_1_B_pb <= PB3;

                                    mult_1_RESULT_tready <= '1';
                                    mult_1_state <= WAITING;
                                else
                                    mult_1_state <= DONE;
                                end if;
                            end if;

                            -- Wait for the multiplier to be done
                            if (mult_1_RESULT_tvalid = '1' and mult_1_state = WAITING) then
                                post_buffer_1 <= mult_1_RESULT_tdata;
                                post_buffer_3 <= (others => '0');

                                -- Reset the multiplier
                                mult_1_A_pb <= NONE;
                                mult_1_B_pb <= NONE;
                                mult_1_RESULT_tready <= '0';
                                
                                mult_1_state <= DONE;
                            end if;

                            -- sig_1 multiplier
                            -- Wait for the multiplier to be ready
                            if (mult_2_A_tready = '1' and mult_2_B_tready = '1' and mult_2_state = IDLE) then
                                if (sig_1_method = PWL) then
                                    -- Set the inputs to the multiplier
                                    mult_2_A_pb <= PB4;
                                    mult_2_B_pb <= PB6;

                                    mult_2_RESULT_tready <= '1';
                                    mult_2_state <= WAITING;
                                else
                                    mult_2_state <= DONE;
                                end if;
                            end if;

                            -- Wait for the multiplier to be done
                            if (mult_2_RESULT_tvalid = '1' and mult_2_state = WAITING) then
                                post_buffer_4 <= mult_2_RESULT_tdata;
                                post_buffer_6 <= (others => '0');

                                -- Reset the multiplier
                                mult_2_A_pb <= NONE;
                                mult_2_B_pb <= NONE;
                                mult_2_RESULT_tready <= '0';
                                
                                mult_2_state <= DONE;
                            end if;

                            -- Wait for all the multipliers to be done
                            if (mult_1_state = DONE and mult_2_state = DONE) then
                                -- Reset the multipliers
                                mult_1_state <= IDLE;
                                mult_2_state <= IDLE;

                                pe_post_state <= S10;
                            end if;

                        when S10 =>
                            -- Stage 10: the mult and offset of the tanh and sigmoid functions are added together

                            -- Buffers
                            -- 1: tanh Mult | Value
                            -- 2: tanh Offset | Empty
                            -- 3: Empty
                            -- 4: sig_1 Mult | Value
                            -- 5: sig_1 Offset | Empty
                            -- 6: Empty
                            -- 7: Empty
                            -- 8: Empty
                            -- 9: Empty

                            -- tanh adder
                            -- Wait for the adder to be ready
                            if (adder_1_A_tready = '1' and adder_1_B_tready = '1' and adder_1_state = IDLE) then
                                if (tanh_method = PWL) then
                                    -- Set the inputs to the adder
                                    adder_1_A_tdata <= post_buffer_1;
                                    adder_1_A_tvalid <= '1';

                                    adder_1_B_tdata <= post_buffer_2;
                                    adder_1_B_tvalid <= '1';

                                    adder_1_RESULT_tready <= '1';
                                    adder_1_state <= WAITING;

                                    adder_1_lat_block <= BLOCKED;
                                else
                                    adder_1_state <= DONE;
                                end if;
                            end if;

                            if (adder_1_lat_block = BLOCKED) then
                                adder_1_lat_block <= UNBLOCKED;
                            end if;

                            -- Wait for the adder to be done
                            if (adder_1_RESULT_tvalid = '1' and adder_1_state = WAITING and adder_1_lat_block = UNBLOCKED) then
                                post_buffer_1 <= adder_1_RESULT_tdata;
                                post_buffer_2 <= (others => '0');

                                -- Reset the adder
                                adder_1_A_tvalid <= '0';
                                adder_1_B_tvalid <= '0';
                                adder_1_RESULT_tready <= '0';
                                
                                adder_1_state <= DONE;
                            end if;

                            -- sig_1 adder
                            -- Wait for the adder to be ready
                            if (adder_2_A_tready = '1' and adder_2_B_tready = '1' and adder_2_state = IDLE) then
                                if (sig_1_method = PWL) then
                                    -- Set the inputs to the adder
                                    adder_2_A_tdata <= post_buffer_4;
                                    adder_2_A_tvalid <= '1';

                                    adder_2_B_tdata <= post_buffer_5;
                                    adder_2_B_tvalid <= '1';

                                    adder_2_RESULT_tready <= '1';
                                    adder_2_state <= WAITING;

                                    adder_2_lat_block <= BLOCKED;
                                else
                                    adder_2_state <= DONE;
                                end if;
                            end if;

                            if (adder_2_lat_block = BLOCKED) then
                                adder_2_lat_block <= UNBLOCKED;
                            end if;

                            -- Wait for the adder to be done
                            if (adder_2_RESULT_tvalid = '1' and adder_2_state = WAITING and adder_2_lat_block = UNBLOCKED) then
                                post_buffer_4 <= adder_2_RESULT_tdata;
                                post_buffer_5 <= (others => '0');

                                -- Reset the adder
                                adder_2_A_tvalid <= '0';
                                adder_2_B_tvalid <= '0';
                                adder_2_RESULT_tready <= '0';
                                
                                adder_2_state <= DONE;
                            end if;

                            -- Wait for all the adders to be done
                            if (adder_1_state = DONE and adder_2_state = DONE) then
                                -- Reset the adders
                                adder_1_state <= IDLE;
                                adder_2_state <= IDLE;

                                pe_post_state <= S11;
                            end if;

                        when S11 =>
                            -- Stage 11: Final stage; multiply the tanh and sigmoid values together to get the final hidden output

                            -- Buffers
                            -- 1: tanh Value
                            -- 2: Empty
                            -- 3: Empty
                            -- 4: sig_1 Value
                            -- 5: Empty
                            -- 6: Empty
                            -- 7: Empty
                            -- 8: Empty
                            -- 9: Empty

                            -- Wait for the multiplier to be ready
                            if (mult_1_A_tready = '1' and mult_1_B_tready = '1' and mult_1_state = IDLE) then
                                -- Set the inputs to the multiplier
                                mult_1_A_pb <= PB1;
                                mult_1_B_pb <= PB4;

                                mult_1_RESULT_tready <= '1';
                                mult_1_state <= WAITING;
                            end if;

                            -- Wait for the multiplier to be done
                            if (mult_1_RESULT_tvalid = '1' and mult_1_state = WAITING) then
                                M_AXIS_HIDDEN_OUT_tdata <= mult_1_RESULT_tdata;
                                M_AXIS_HIDDEN_OUT_tvalid <= '1';
                                
                                post_buffer_1 <= (others => '0');
                                post_buffer_4 <= (others => '0');

                                -- Reset the multiplier
                                mult_1_A_pb <= NONE;
                                mult_1_B_pb <= NONE;
                                mult_1_RESULT_tready <= '0';
                                
                                mult_1_state <= DONE;
                            end if;

                            -- Wait for all the multipliers to be done
                            if (mult_1_state = DONE) then
                                -- Reset the multipliers
                                mult_1_state <= IDLE;

                                pe_post_state <= S1;
                                pe_state_next := RECEIVE;
                            end if;
                    end case;
            end case;


            pe_state <= pe_state_next;
        end if;
    end process;
        
    add_1 : adder
        port map (
            S_AXIS_A_tdata => adder_1_A_tdata,
            S_AXIS_A_tready => adder_1_A_tready,
            S_AXIS_A_tvalid => adder_1_A_tvalid,

            S_AXIS_B_tdata => adder_1_B_tdata,
            S_AXIS_B_tready => adder_1_B_tready,
            S_AXIS_B_tvalid => adder_1_B_tvalid,

            M_AXIS_RESULT_tdata => adder_1_RESULT_tdata,
            M_AXIS_RESULT_tready => adder_1_RESULT_tready,
            M_AXIS_RESULT_tvalid => adder_1_RESULT_tvalid,

            aclk => clk
        );

    add_2 : adder
        port map (
            S_AXIS_A_tdata => adder_2_A_tdata,
            S_AXIS_A_tready => adder_2_A_tready,
            S_AXIS_A_tvalid => adder_2_A_tvalid,

            S_AXIS_B_tdata => adder_2_B_tdata,
            S_AXIS_B_tready => adder_2_B_tready,
            S_AXIS_B_tvalid => adder_2_B_tvalid,

            M_AXIS_RESULT_tdata => adder_2_RESULT_tdata,
            M_AXIS_RESULT_tready => adder_2_RESULT_tready,
            M_AXIS_RESULT_tvalid => adder_2_RESULT_tvalid,

            aclk => clk
        );

    add_3 : adder
        port map (
            S_AXIS_A_tdata => adder_3_A_tdata,
            S_AXIS_A_tready => adder_3_A_tready,
            S_AXIS_A_tvalid => adder_3_A_tvalid,

            S_AXIS_B_tdata => adder_3_B_tdata,
            S_AXIS_B_tready => adder_3_B_tready,
            S_AXIS_B_tvalid => adder_3_B_tvalid,

            M_AXIS_RESULT_tdata => adder_3_RESULT_tdata,
            M_AXIS_RESULT_tready => adder_3_RESULT_tready,
            M_AXIS_RESULT_tvalid => adder_3_RESULT_tvalid,

            aclk => clk
        );
    
    -- Arbiters
    sig_1 : sigmoid_arbiter
        port map (
            in_data => sig_1_input_tdata,
            in_valid => sig_1_input_tvalid,
            in_ready => sig_1_input_tready,

            slope_out_valid => sig_1_slope_tvalid,
            slope_out_data => sig_1_slope_tdata,
            slope_out_ready => sig_1_slope_tready,

            offset_out_valid => sig_1_offset_tvalid,
            offset_out_data => sig_1_offset_tdata,
            offset_out_ready => sig_1_offset_tready,

            input_out_valid => sig_1_input_out_tvalid,
            input_out_data => sig_1_input_out_tdata,
            input_out_ready => sig_1_input_out_tready,

            value_out_valid => sig_1_value_tvalid,
            value_out_data => sig_1_value_tdata,
            value_out_ready => sig_1_value_tready,

            aclk => clk
        );

    sig_2 : sigmoid_arbiter
        port map (
            in_data => sig_2_input_tdata,
            in_ready => sig_2_input_tready,
            in_valid => sig_2_input_tvalid,

            slope_out_valid => sig_2_slope_tvalid,
            slope_out_data => sig_2_slope_tdata,
            slope_out_ready => sig_2_slope_tready,

            offset_out_valid => sig_2_offset_tvalid,
            offset_out_data => sig_2_offset_tdata,
            offset_out_ready => sig_2_offset_tready,

            input_out_valid => sig_2_input_out_tvalid,
            input_out_data => sig_2_input_out_tdata,
            input_out_ready => sig_2_input_out_tready,

            value_out_valid => sig_2_value_tvalid,
            value_out_data => sig_2_value_tdata,
            value_out_ready => sig_2_value_tready,

            aclk => clk
        );

    tanh : tanh_arbiter
        port map (
            in_data => tanh_input_tdata,
            in_ready => tanh_input_tready,
            in_valid => tanh_input_tvalid,

            slope_out_valid => tanh_slope_tvalid,
            slope_out_data => tanh_slope_tdata,
            slope_out_ready => tanh_slope_tready,

            offset_out_valid => tanh_offset_tvalid,
            offset_out_data => tanh_offset_tdata,
            offset_out_ready => tanh_offset_tready,

            input_out_valid => tanh_input_out_tvalid,
            input_out_data => tanh_input_out_tdata,
            input_out_ready => tanh_input_out_tready,

            value_out_valid => tanh_value_tvalid,
            value_out_data => tanh_value_tdata,
            value_out_ready => tanh_value_tready,

            aclk => clk
        );

    -- Input gate (input)
    mac_i : mac_bf16_mult
        port map (
            M_AXIS_ACC_RESULT_tdata => i_in_out_data,
            M_AXIS_ACC_RESULT_tlast => i_in_out_last,
            M_AXIS_ACC_RESULT_tready => i_in_out_ready,
            M_AXIS_ACC_RESULT_tvalid => i_in_out_valid,

            M_AXIS_MULT_RESULT_tdata => mult_1_RESULT_tdata,
            M_AXIS_MULT_RESULT_tready => mult_1_RESULT_tready,
            M_AXIS_MULT_RESULT_tvalid => mult_1_RESULT_tvalid,

            S_AXIS_DATA_IN_tdata => mult_1_A_tdata,
            S_AXIS_DATA_IN_tlast => mult_1_A_tlast,
            S_AXIS_DATA_IN_tready => mult_1_A_tready,
            S_AXIS_DATA_IN_tvalid => mult_1_A_tvalid,
            S_AXIS_DATA_IN_tuser => mult_1_tdest,

            S_AXIS_WEIGHT_IN_tdata => mult_1_B_tdata,
            S_AXIS_WEIGHT_IN_tlast => mult_1_B_tlast,
            S_AXIS_WEIGHT_IN_tready => mult_1_B_tready,
            S_AXIS_WEIGHT_IN_tvalid => mult_1_B_tvalid,

            aclk => clk
        );

    -- Input gate (hidden)
    mac_i_h : mac_bf16_mult
        port map (
            M_AXIS_ACC_RESULT_tdata => i_hid_out_data,
            M_AXIS_ACC_RESULT_tlast => i_hid_out_last,
            M_AXIS_ACC_RESULT_tready => i_hid_out_ready,
            M_AXIS_ACC_RESULT_tvalid => i_hid_out_valid,

            M_AXIS_MULT_RESULT_tdata => mult_2_RESULT_tdata,
            M_AXIS_MULT_RESULT_tready => mult_2_RESULT_tready,
            M_AXIS_MULT_RESULT_tvalid => mult_2_RESULT_tvalid,

            S_AXIS_DATA_IN_tdata => mult_2_A_tdata,
            S_AXIS_DATA_IN_tlast => mult_2_A_tlast,
            S_AXIS_DATA_IN_tready => mult_2_A_tready,
            S_AXIS_DATA_IN_tvalid => mult_2_A_tvalid,
            S_AXIS_DATA_IN_tuser => mult_2_tdest,

            S_AXIS_WEIGHT_IN_tdata => mult_2_B_tdata,
            S_AXIS_WEIGHT_IN_tlast => mult_2_B_tlast,
            S_AXIS_WEIGHT_IN_tready => mult_2_B_tready,
            S_AXIS_WEIGHT_IN_tvalid => mult_2_B_tvalid,

            aclk => clk
        );

    -- Forget gate (input)
    mac_f : mac_bf16_mult
        port map (
            M_AXIS_ACC_RESULT_tdata => f_in_out_data,
            M_AXIS_ACC_RESULT_tlast => f_in_out_last,
            M_AXIS_ACC_RESULT_tready => f_in_out_ready,
            M_AXIS_ACC_RESULT_tvalid => f_in_out_valid,

            M_AXIS_MULT_RESULT_tdata => mult_3_RESULT_tdata,
            M_AXIS_MULT_RESULT_tready => mult_3_RESULT_tready,
            M_AXIS_MULT_RESULT_tvalid => mult_3_RESULT_tvalid,

            S_AXIS_DATA_IN_tdata => mult_3_A_tdata,
            S_AXIS_DATA_IN_tlast => mult_3_A_tlast,
            S_AXIS_DATA_IN_tready => mult_3_A_tready,
            S_AXIS_DATA_IN_tvalid => mult_3_A_tvalid,
            S_AXIS_DATA_IN_tuser => mult_3_tdest,

            S_AXIS_WEIGHT_IN_tdata => mult_3_B_tdata,
            S_AXIS_WEIGHT_IN_tlast => mult_3_B_tlast,
            S_AXIS_WEIGHT_IN_tready => mult_3_B_tready,
            S_AXIS_WEIGHT_IN_tvalid => mult_3_B_tvalid,

            aclk => clk
        );

    -- Forget gate (hidden)
    mac_f_h : mac_bf16
        port map (
            M_AXIS_ACC_RESULT_tdata => f_hid_out_data,
            M_AXIS_ACC_RESULT_tlast => f_hid_out_last,
            M_AXIS_ACC_RESULT_tready => f_hid_out_ready,
            M_AXIS_ACC_RESULT_tvalid => f_hid_out_valid,

            S_AXIS_DATA_IN_tdata => S_AXIS_HIDDEN_IN_tdata,
            S_AXIS_DATA_IN_tlast => S_AXIS_HIDDEN_IN_tlast,
            S_AXIS_DATA_IN_tready => f_hid_mac_data_ready,
            S_AXIS_DATA_IN_tvalid => S_AXIS_HIDDEN_IN_tvalid,

            S_AXIS_WEIGHT_IN_tdata => S_AXIS_WEIGHT_F_hidden_tdata,
            S_AXIS_WEIGHT_IN_tlast => S_AXIS_WEIGHT_F_hidden_tlast,
            S_AXIS_WEIGHT_IN_tready => f_hid_mac_weight_ready,
            S_AXIS_WEIGHT_IN_tvalid => S_AXIS_WEIGHT_F_hidden_tvalid,

            aclk => clk
        );

    -- Output gate (input)
    mac_o : mac_bf16
        port map (
            M_AXIS_ACC_RESULT_tdata => o_in_out_data,
            M_AXIS_ACC_RESULT_tlast => o_in_out_last,
            M_AXIS_ACC_RESULT_tready => o_in_out_ready,
            M_AXIS_ACC_RESULT_tvalid => o_in_out_valid,

            S_AXIS_DATA_IN_tdata => S_AXIS_DATA_IN_tdata,
            S_AXIS_DATA_IN_tlast => S_AXIS_DATA_IN_tlast,
            S_AXIS_DATA_IN_tready => o_in_mac_data_ready,
            S_AXIS_DATA_IN_tvalid => S_AXIS_DATA_IN_tvalid,

            S_AXIS_WEIGHT_IN_tdata => S_AXIS_WEIGHT_O_input_tdata,
            S_AXIS_WEIGHT_IN_tlast => S_AXIS_WEIGHT_O_input_tlast,
            S_AXIS_WEIGHT_IN_tready => o_in_mac_weight_ready,
            S_AXIS_WEIGHT_IN_tvalid => S_AXIS_WEIGHT_O_input_tvalid,

            aclk => clk
        );

    -- Output gate (hidden)
    mac_o_h : mac_bf16
        port map (
            M_AXIS_ACC_RESULT_tdata => o_hid_out_data,
            M_AXIS_ACC_RESULT_tlast => o_hid_out_last,
            M_AXIS_ACC_RESULT_tready => o_hid_out_ready,
            M_AXIS_ACC_RESULT_tvalid => o_hid_out_valid,

            S_AXIS_DATA_IN_tdata => S_AXIS_HIDDEN_IN_tdata,
            S_AXIS_DATA_IN_tlast => S_AXIS_HIDDEN_IN_tlast,
            S_AXIS_DATA_IN_tready => o_hid_mac_data_ready,
            S_AXIS_DATA_IN_tvalid => S_AXIS_HIDDEN_IN_tvalid,

            S_AXIS_WEIGHT_IN_tdata => S_AXIS_WEIGHT_O_hidden_tdata,
            S_AXIS_WEIGHT_IN_tlast => S_AXIS_WEIGHT_O_hidden_tlast,
            S_AXIS_WEIGHT_IN_tready => o_hid_mac_weight_ready,
            S_AXIS_WEIGHT_IN_tvalid => S_AXIS_WEIGHT_O_hidden_tvalid,

            aclk => clk
        );

    -- Cell state (input)
    mac_c : mac_bf16
        port map (
            M_AXIS_ACC_RESULT_tdata => g_in_out_data,
            M_AXIS_ACC_RESULT_tlast => g_in_out_last,
            M_AXIS_ACC_RESULT_tready => g_in_out_ready,
            M_AXIS_ACC_RESULT_tvalid => g_in_out_valid,

            S_AXIS_DATA_IN_tdata => S_AXIS_DATA_IN_tdata,
            S_AXIS_DATA_IN_tlast => S_AXIS_DATA_IN_tlast,
            S_AXIS_DATA_IN_tready => g_in_mac_data_ready,
            S_AXIS_DATA_IN_tvalid => S_AXIS_DATA_IN_tvalid,

            S_AXIS_WEIGHT_IN_tdata => S_AXIS_WEIGHT_G_input_tdata,
            S_AXIS_WEIGHT_IN_tlast => S_AXIS_WEIGHT_G_input_tlast,
            S_AXIS_WEIGHT_IN_tready => g_in_mac_weight_ready,
            S_AXIS_WEIGHT_IN_tvalid => S_AXIS_WEIGHT_G_input_tvalid,

            aclk => clk
        );

    -- Cell state (hidden)
    mac_c_h : mac_bf16
    port map (
            M_AXIS_ACC_RESULT_tdata => g_hid_out_data,
            M_AXIS_ACC_RESULT_tlast => g_hid_out_last,
            M_AXIS_ACC_RESULT_tready => g_hid_out_ready,
            M_AXIS_ACC_RESULT_tvalid => g_hid_out_valid,

            S_AXIS_DATA_IN_tdata => S_AXIS_HIDDEN_IN_tdata,
            S_AXIS_DATA_IN_tlast => S_AXIS_HIDDEN_IN_tlast,
            S_AXIS_DATA_IN_tready => g_hid_mac_data_ready,
            S_AXIS_DATA_IN_tvalid => S_AXIS_HIDDEN_IN_tvalid,

            S_AXIS_WEIGHT_IN_tdata => S_AXIS_WEIGHT_G_hidden_tdata,
            S_AXIS_WEIGHT_IN_tlast => S_AXIS_WEIGHT_G_hidden_tlast,
            S_AXIS_WEIGHT_IN_tready => g_hid_mac_weight_ready,
            S_AXIS_WEIGHT_IN_tvalid => S_AXIS_WEIGHT_G_hidden_tvalid,

            aclk => clk
        );
        

end architecture behav;