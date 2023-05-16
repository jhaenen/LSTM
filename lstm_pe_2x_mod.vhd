library ieee;
use ieee.std_logic_1164.all;

entity lstm_pe_2x_mod is
    generic (
        ADDR_WIDTH : natural := 14
    );
    port (
        clk     : in std_logic;
        rst     : in std_logic;

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
        pe2_hidden_out  : out std_logic_vector(15 downto 0);

        weights_addr : out std_logic_vector(ADDR_WIDTH-1 downto 0)
    );
end entity lstm_pe_2x_mod;

architecture behav of lstm_pe_2x_mod is
    constant NUM_PES : natural := 2;

    component lstm_pe_slv is
        generic (
            ADDR_WIDTH : natural := 14
        );
        port (
            clk     : in std_logic;
            rst     : in std_logic;
            
            -- input
            data_in     : in std_logic_vector(15 downto 0);
            weight_i_in : in std_logic_vector(15 downto 0);
            weight_g_in : in std_logic_vector(15 downto 0);
            weight_f_in : in std_logic_vector(15 downto 0);
            weight_o_in : in std_logic_vector(15 downto 0);

            weights_addr : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    
            -- output
            hidden_out  : out std_logic_vector(15 downto 0)
        );
    end component;

    -- Create weights address array
    type weights_addr_array_t is array (0 to NUM_PES-1) of std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal weights_addr_array : weights_addr_array_t;
begin

    pe1 : lstm_pe_slv
        generic map (
            ADDR_WIDTH => ADDR_WIDTH
        )
        port map (
            clk     => clk,
            rst     => rst,
            
            -- input
            data_in     => pe1_data_in,
            weight_i_in => pe1_weight_i_in,
            weight_g_in => pe1_weight_g_in,
            weight_f_in => pe1_weight_f_in,
            weight_o_in => pe1_weight_o_in,

            weights_addr => weights_addr_array(0),
    
            -- output
            hidden_out  => pe1_hidden_out
        );

    pe2 : lstm_pe_slv
        generic map (
            ADDR_WIDTH => ADDR_WIDTH
        )
        port map (
            clk     => clk,
            rst     => rst,
            
            -- input
            data_in     => pe2_data_in,
            weight_i_in => pe2_weight_i_in,
            weight_g_in => pe2_weight_g_in,
            weight_f_in => pe2_weight_f_in,
            weight_o_in => pe2_weight_o_in,

            weights_addr => weights_addr_array(1),
    
            -- output
            hidden_out  => pe2_hidden_out
        );
    
    weights_addr <= weights_addr_array(0);   
    
end architecture behav;