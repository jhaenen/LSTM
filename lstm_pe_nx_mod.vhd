library ieee;
use ieee.std_logic_1164.all;

entity lstm_pe_nx_mod is
    generic (
        NUM_PES : natural := 32;
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
end entity lstm_pe_nx_mod;

architecture behav of lstm_pe_nx_mod is
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

    -- Create hidden output array
    type hidden_out_array_t is array (0 to NUM_PES-1) of std_logic_vector(15 downto 0);
    signal hidden_out_array : hidden_out_array_t;
begin
    -- Generate 128 PEs
    gen_pe : for i in 0 to NUM_PES-1 generate
        pe : lstm_pe_slv
            generic map (
                ADDR_WIDTH => ADDR_WIDTH
            )
            port map (
                clk     => clk,
                rst     => rst,
                
                -- input
                data_in     => data_in,
                weight_i_in => weight_i_in,
                weight_g_in => weight_g_in,
                weight_f_in => weight_f_in,
                weight_o_in => weight_o_in,

                weights_addr => weights_addr_array(i),
        
                -- output
                hidden_out  => hidden_out_array(i)
            );
    end generate;
    
    weights_addr <= weights_addr_array(0);
    hidden_out <= hidden_out_array(0);

    -- uut : lstm_pe_slv
    --     port map (
    --         clk     => clk,
    --         rst     => rst,
            
    --         -- input
    --         data_in     => data_in,
    --         weight_i_in => weight_i_in,
    --         weight_g_in => weight_g_in,
    --         weight_f_in => weight_f_in,
    --         weight_o_in => weight_o_in,

    --         weights_addr => weights_addr,
    
    --         -- output
    --         hidden_out  => hidden_out
    --     );
    
    
end architecture behav;