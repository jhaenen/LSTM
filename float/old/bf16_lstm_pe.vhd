library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.rnn_pkg.all;
use work.util_pkg.all;

entity bf16_lstm_pe is
    port (
        clk     : in std_logic;
        rst     : in std_logic;
        
        pe_state    : in pe_state_slv_t;

        -- input
        S_AXIS_DATA_IN_tdata     : in std_logic_vector(15 downto 0);
        S_AXIS_DATA_IN_tvalid    : in std_logic;
        S_AXIS_DATA_IN_tready    : out std_logic;

        S_AXIS_WEIGHT_I_IN_tdata : in std_logic_vector(15 downto 0);
        S_AXIS_WEIGHT_I_IN_tvalid: in std_logic;
        S_AXIS_WEIGHT_I_IN_tready: out std_logic;

        S_AXIS_WEIGHT_G_IN_tdata : in std_logic_vector(15 downto 0);
        S_AXIS_WEIGHT_G_IN_tvalid: in std_logic;
        S_AXIS_WEIGHT_G_IN_tready: out std_logic;

        S_AXIS_WEIGHT_F_IN_tdata : in std_logic_vector(15 downto 0);
        S_AXIS_WEIGHT_F_IN_tvalid: in std_logic;
        S_AXIS_WEIGHT_F_IN_tready: out std_logic;

        S_AXIS_WEIGHT_O_IN_tdata : in std_logic_vector(15 downto 0);
        S_AXIS_WEIGHT_O_IN_tvalid: in std_logic;
        S_AXIS_WEIGHT_O_IN_tready: out std_logic;

        -- output
        M_AXIS_HIDDEN_OUT_tdata    : out std_logic_vector(15 downto 0);
        M_AXIS_HIDDEN_OUT_tvalid   : out std_logic;
        M_AXIS_HIDDEN_OUT_tready   : in std_logic
    );
end entity;

architecture behav of bf16_lstm_pe is
    -- component sigmoid_pwl is
    --     generic (
    --         n : natural := acc_t'high;
    --         f : natural := acc_t'low
    --     );
    --     port (
    --         x : in sfixed(n downto -f);
    --         y : out sigmoid_t
    --     );
    -- end component sigmoid_pwl;

    -- component tanh_lut is
    --     port (
    --         x : in acc_t;
    --         y : out tanh_t
    --     );
    -- end component tanh_lut;
    
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

    signal f_out  : std_logic_vector(15 downto 0);
    signal f_out_valid : std_logic;
    signal f_out_ready : std_logic;

    signal i_out  : std_logic_vector(15 downto 0);
    signal i_out_valid : std_logic;
    signal i_out_ready : std_logic;

    signal o_out  : std_logic_vector(15 downto 0);
    signal o_out_valid : std_logic;
    signal o_out_ready : std_logic;

    signal g_out  : std_logic_vector(15 downto 0);
    signal g_out_valid : std_logic;
    signal g_out_ready : std_logic;

    signal c_t : data_t;
    signal c_t_tanh : tanh_t;

    signal mod_reset : std_logic;
    signal mod_en    : std_logic;

    signal pe_state_int : pe_state_t;
begin
    pe_state_int <= to_pe_state(pe_state);

    process (clk, rst)
    begin
        if rst = '1' then
            mod_reset <= '1';
            mod_en    <= '0';
        elsif rising_edge(clk) then
            case pe_state_int is
                when IDLE =>
                    mod_en    <= '0';
                    mod_reset <= '0';
                when ACCUMULATE =>
                    mod_reset <= '0';
                    mod_en    <= '1';
                when POST =>
                    mod_reset <= '1';
                    mod_en    <= '0';

                    c_t <= resize(to_sfixed(f_sig) * c_t + to_sfixed(i_sig) * g_tanh, c_t'high, c_t'low);

                    hidden_out <= resize(to_sfixed(o_sig) * c_t_tanh, hidden_out'high, hidden_out'low);
                when RESET =>
                    mod_reset <= '1';
                    mod_en    <= '0';
            end case;
        end if;
    end process;
    
    -- -- Sigmoid functions
    -- sigmoid_f : sigmoid_pwl
    --     generic map (
    --         n => acc_t'high,
    --         f => -acc_t'low
    --     )
    --     port map (
    --         x => f_out,
    --         y => f_sig
    --     );
    
    -- sigmoid_i : sigmoid_pwl
    --     generic map (
    --         n => acc_t'high,
    --         f => -acc_t'low
    --     )
    --     port map (
    --         x => i_out,
    --         y => i_sig
    --     );

    -- sigmoid_o : sigmoid_pwl
    --     generic map (
    --         n => acc_t'high,
    --         f => -acc_t'low
    --     )
    --     port map (
    --         x => o_out,
    --         y => o_sig
    --     );

    -- -- Tanh function
    -- tanh_g : tanh_lut
    --     port map (
    --         x => g_out,
    --         y => g_tanh
    --     );

    -- tanh_c : tanh_lut
    --     port map (
    --         x => resize(c_t, acc_t'high, acc_t'low),
    --         y => c_t_tanh
    --     );

    -- Input gate
    mac_i : 
    
    -- Cell input gate  
    mac_g : MAC
        port map (
            clk     => clk,
            rst     => mod_reset,
            en      => mod_en,
            
            -- input
            data_in     => data_in,
            weight_in   => weight_g_in,

            -- output
            data_out    => g_out
        );

    -- Forget gate
    mac_f : MAC
        port map (
            clk     => clk,
            rst     => mod_reset,
            en      => mod_en,
            
            -- input
            data_in     => data_in,
            weight_in   => weight_f_in,

            -- output
            data_out    => f_out
        );

    -- Output gate
    mac_o : MAC
        port map (
            clk     => clk,
            rst     => mod_reset,
            en      => mod_en,
            
            -- input
            data_in     => data_in,
            weight_in   => weight_o_in,

            -- output
            data_out    => o_out
        );
end architecture behav;