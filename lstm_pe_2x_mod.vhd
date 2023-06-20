library ieee;
use ieee.std_logic_1164.all;

use work.rnn_pkg.pe_state_slv_t;

entity lstm_pe_2x_mod is
    port (
        clk     : in std_logic;
        rst     : in std_logic;

        pe_state : in std_logic_vector(1 downto 0);

        -- input pe1
        pe1_data_in     : in std_logic_vector(15 downto 0);
        pe1_weight_i_in : in std_logic_vector(15 downto 0);
        pe1_weight_g_in : in std_logic_vector(15 downto 0);
        pe1_weight_f_in : in std_logic_vector(15 downto 0);
        pe1_weight_o_in : in std_logic_vector(15 downto 0);

        -- output pe1
        pe1_hidden_out  : out std_logic_vector(15 downto 0);

        -- input pe2
        pe2_data_in     : in std_logic_vector(15 downto 0);
        pe2_weight_i_in : in std_logic_vector(15 downto 0);
        pe2_weight_g_in : in std_logic_vector(15 downto 0);
        pe2_weight_f_in : in std_logic_vector(15 downto 0);
        pe2_weight_o_in : in std_logic_vector(15 downto 0);

        -- output pe2
        pe2_hidden_out  : out std_logic_vector(15 downto 0)
    );
end entity lstm_pe_2x_mod;

architecture behav of lstm_pe_2x_mod is
    constant NUM_PES : natural := 2;

    component lstm_pe_slv is
        port (
            clk     : in std_logic;
            rst     : in std_logic;

            pe_state : in pe_state_slv_t;
            
            -- input
            data_in     : in std_logic_vector(15 downto 0);
            weight_i_in : in std_logic_vector(15 downto 0);
            weight_g_in : in std_logic_vector(15 downto 0);
            weight_f_in : in std_logic_vector(15 downto 0);
            weight_o_in : in std_logic_vector(15 downto 0);
    
            -- output
            hidden_out  : out std_logic_vector(15 downto 0)
        );
    end component;

begin

    pe1 : lstm_pe_slv
        port map (
            clk     => clk,
            rst     => rst,

            pe_state => pe_state,
            
            -- input
            data_in     => pe1_data_in,
            weight_i_in => pe1_weight_i_in,
            weight_g_in => pe1_weight_g_in,
            weight_f_in => pe1_weight_f_in,
            weight_o_in => pe1_weight_o_in,
    
            -- output
            hidden_out  => pe1_hidden_out
        );

    pe2 : lstm_pe_slv
        port map (
            clk     => clk,
            rst     => rst,

            pe_state => pe_state,
            
            -- input
            data_in     => pe2_data_in,
            weight_i_in => pe2_weight_i_in,
            weight_g_in => pe2_weight_g_in,
            weight_f_in => pe2_weight_f_in,
            weight_o_in => pe2_weight_o_in,
    
            -- output
            hidden_out  => pe2_hidden_out
        );
    
end architecture behav;