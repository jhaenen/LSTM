library ieee;
use ieee.std_logic_1164.all;

entity pe_block is
    port (
        clk : in std_logic;

        s_axis_data_in_data : in std_logic_vector(15 downto 0);
        s_axis_data_in_valid : in std_logic;
        s_axis_data_in_ready : out std_logic;
        s_axis_data_in_last : in std_logic;

        s_axis_hidden_in_data : in std_logic_vector(15 downto 0);
        s_axis_hidden_in_valid : in std_logic;
        s_axis_hidden_in_ready : out std_logic;
        s_axis_hidden_in_last : in std_logic;

        s_axis_weight_valid : in std_logic;
        s_axis_weight_ready : out std_logic;
        s_axis_weight_last : in std_logic;

        s_axis_weight_i_input_data : in std_logic_vector(384 * 16 - 1 downto 0);
        s_axis_weight_i_hidden_data  : in std_logic_vector(384 * 16 - 1 downto 0);
        
        s_axis_weight_f_input_data : in std_logic_vector(384 * 16 - 1 downto 0);
        s_axis_weight_f_hidden_data : in std_logic_vector(384 * 16 - 1 downto 0);

        s_axis_weight_g_input_data : in std_logic_vector(384 * 16 - 1 downto 0);
        s_axis_weight_g_hidden_data : in std_logic_vector(384 * 16 - 1 downto 0);

        s_axis_weight_o_input_data : in std_logic_vector(384 * 16 - 1 downto 0);
        s_axis_weight_o_hidden_data : in std_logic_vector(384 * 16 - 1 downto 0);

        m_axis_hidden_out_data : out std_logic_vector(384 * 16 -1 downto 0);
        m_axis_hidden_out_valid : out std_logic;
        m_axis_hidden_out_ready : in std_logic
    );
end entity pe_block;

architecture behav of pe_block is
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
    end component;

    type ready_signal_t is array(383 downto 0) of std_logic;
    type valid_signal_t is array(383 downto 0) of std_logic;
    signal data_input_ready : ready_signal_t;
    signal hidden_input_ready : ready_signal_t;
    signal weight_i_input_ready : ready_signal_t;
    signal weight_i_hidden_ready : ready_signal_t;
    signal weight_f_input_ready : ready_signal_t;
    signal weight_f_hidden_ready : ready_signal_t;
    signal weight_g_input_ready : ready_signal_t;
    signal weight_g_hidden_ready : ready_signal_t;
    signal weight_o_input_ready : ready_signal_t;
    signal weight_o_hidden_ready : ready_signal_t;

    signal output_valid : valid_signal_t;
begin

    -- Generate 384 components
    gen_pe : for i in 0 to 383 generate
        lstm_pe_bf16_inst : lstm_pe_bf16
            port map (
                clk     => clk,
        
                -- input
                S_AXIS_DATA_IN_tdata => s_axis_data_in_data,
                S_AXIS_DATA_IN_tvalid => s_axis_data_in_valid,
                S_AXIS_DATA_IN_tready => data_input_ready(i),
                S_AXIS_DATA_IN_tlast => s_axis_data_in_last,
        
                S_AXIS_HIDDEN_IN_tdata => s_axis_hidden_in_data,
                S_AXIS_HIDDEN_IN_tvalid => s_axis_hidden_in_valid,
                S_AXIS_HIDDEN_IN_tready => hidden_input_ready(i),
                S_AXIS_HIDDEN_IN_tlast => s_axis_hidden_in_last,
        
                -- weights
                S_AXIS_WEIGHT_I_input_tdata => s_axis_weight_i_input_data(16 * i + 15 downto 16 * i),
                S_AXIS_WEIGHT_I_input_tvalid => s_axis_weight_valid,
                S_AXIS_WEIGHT_I_input_tready => weight_i_input_ready(i),
                S_AXIS_WEIGHT_I_input_tlast => s_axis_weight_last,
        
                S_AXIS_WEIGHT_I_hidden_tdata => s_axis_weight_i_hidden_data(16 * i + 15 downto 16 * i),
                S_AXIS_WEIGHT_I_hidden_tvalid => s_axis_weight_valid,
                S_AXIS_WEIGHT_I_hidden_tready => weight_i_hidden_ready(i),
                S_AXIS_WEIGHT_I_hidden_tlast => s_axis_weight_last,
        
                S_AXIS_WEIGHT_G_input_tdata => s_axis_weight_g_input_data(16 * i + 15 downto 16 * i),
                S_AXIS_WEIGHT_G_input_tvalid => s_axis_weight_valid,
                S_AXIS_WEIGHT_G_input_tready => weight_g_input_ready(i),
                S_AXIS_WEIGHT_G_input_tlast => s_axis_weight_last,
        
                S_AXIS_WEIGHT_G_hidden_tdata => s_axis_weight_g_hidden_data(16 * i + 15 downto 16 * i),
                S_AXIS_WEIGHT_G_hidden_tvalid => s_axis_weight_valid,
                S_AXIS_WEIGHT_G_hidden_tready => weight_g_hidden_ready(i),
                S_AXIS_WEIGHT_G_hidden_tlast => s_axis_weight_last,
        
                S_AXIS_WEIGHT_F_input_tdata => s_axis_weight_f_input_data(16 * i + 15 downto 16 * i),
                S_AXIS_WEIGHT_F_input_tvalid => s_axis_weight_valid,
                S_AXIS_WEIGHT_F_input_tready => weight_f_input_ready(i),
                S_AXIS_WEIGHT_F_input_tlast => s_axis_weight_last,
        
                S_AXIS_WEIGHT_F_hidden_tdata => s_axis_weight_f_hidden_data(16 * i + 15 downto 16 * i),
                S_AXIS_WEIGHT_F_hidden_tvalid => s_axis_weight_valid,
                S_AXIS_WEIGHT_F_hidden_tready => weight_f_hidden_ready(i),
                S_AXIS_WEIGHT_F_hidden_tlast => s_axis_weight_last,
        
                S_AXIS_WEIGHT_O_input_tdata => s_axis_weight_o_input_data(16 * i + 15 downto 16 * i),
                S_AXIS_WEIGHT_O_input_tvalid => s_axis_weight_valid,
                S_AXIS_WEIGHT_O_input_tready => weight_o_input_ready(i),
                S_AXIS_WEIGHT_O_input_tlast => s_axis_weight_last,
        
                S_AXIS_WEIGHT_O_hidden_tdata => s_axis_weight_o_hidden_data(16 * i + 15 downto 16 * i),
                S_AXIS_WEIGHT_O_hidden_tvalid => s_axis_weight_valid,
                S_AXIS_WEIGHT_O_hidden_tready => weight_o_hidden_ready(i),
                S_AXIS_WEIGHT_O_hidden_tlast => s_axis_weight_last,
        
                -- output
                M_AXIS_HIDDEN_OUT_tdata => m_axis_hidden_out_data(16 * i + 15 downto 16 * i),
                M_AXIS_HIDDEN_OUT_tvalid => output_valid(i),
                M_AXIS_HIDDEN_OUT_tready => m_axis_hidden_out_ready
            );
    end generate gen_pe;
    
    -- And reduce the ready signals
    s_axis_data_in_ready <= '1' when data_input_ready = (others => '1') else '0';
    s_axis_hidden_in_ready <= '1' when hidden_input_ready = (others => '1') else '0';
    s_axis_weight_ready <= '1' when weight_i_input_ready = (others => '1') and
                                    weight_i_hidden_ready = (others => '1') and
                                    weight_f_input_ready = (others => '1') and
                                    weight_f_hidden_ready = (others => '1') and
                                    weight_g_input_ready = (others => '1') and
                                    weight_g_hidden_ready = (others => '1') and
                                    weight_o_input_ready = (others => '1') and
                                    weight_o_hidden_ready = (others => '1') else '0';
    
    -- And reduce the valid signals
    m_axis_hidden_out_valid <= '1' when output_valid = (others => '1') else '0';
end architecture behav;