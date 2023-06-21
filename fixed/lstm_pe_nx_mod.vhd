library ieee;
use ieee.std_logic_1164.all;

use work.rnn_pkg.pe_state_slv_t;

entity lstm_pe_nx_mod is
    generic (
        NUM_PES : natural := 32;
        constant BIT_WIDTH : natural := 16
    );
    port (
        clk     : in std_logic;
        rst     : in std_logic;

        pe_state : in std_logic_vector(1 downto 0);

        -- input; These are signals that are fed to all PEs
        data_in     : in std_logic_vector(BIT_WIDTH*NUM_PES-1 downto 0);
        weight_i_in : in std_logic_vector(BIT_WIDTH*NUM_PES-1 downto 0);
        weight_g_in : in std_logic_vector(BIT_WIDTH*NUM_PES-1 downto 0);
        weight_f_in : in std_logic_vector(BIT_WIDTH*NUM_PES-1 downto 0);
        weight_o_in : in std_logic_vector(BIT_WIDTH*NUM_PES-1 downto 0);


        -- output
        hidden_out  : out std_logic_vector(BIT_WIDTH*NUM_PES-1 downto 0)
   );
end entity lstm_pe_nx_mod;

architecture behav of lstm_pe_nx_mod is
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
    -- Create array of weights
    type data_array_t is array (0 to NUM_PES-1) of std_logic_vector(BIT_WIDTH-1 downto 0);
    signal data_in_array : data_array_t;
    signal weights_i_array : data_array_t;
    signal weights_g_array : data_array_t;
    signal weights_f_array : data_array_t;
    signal weights_o_array : data_array_t;
    signal hidden_out_array : data_array_t;

begin
    process(data_in, weight_i_in, weight_g_in, weight_f_in, weight_o_in)
        begin
            for i in 0 to NUM_PES-1 loop 
                data_in_array(i) <= data_in(i*BIT_WIDTH+BIT_WIDTH-1 downto i*BIT_WIDTH);
                weights_i_array(i) <= weight_i_in(i*BIT_WIDTH+BIT_WIDTH-1 downto i*BIT_WIDTH);
                weights_g_array(i) <= weight_g_in(i*BIT_WIDTH+BIT_WIDTH-1 downto i*BIT_WIDTH);
                weights_f_array(i) <= weight_f_in(i*BIT_WIDTH+BIT_WIDTH-1 downto i*BIT_WIDTH);
                weights_o_array(i) <= weight_o_in(i*BIT_WIDTH+BIT_WIDTH-1 downto i*BIT_WIDTH);
            end loop;
    end process;


    -- Generate n PEs
    gen_pe : for i in 0 to NUM_PES-1 generate
        pe : lstm_pe_slv
            port map (
                clk     => clk,
                rst     => rst,

                pe_state => pe_state,
                
                -- input
                data_in     => data_in_array(i),
                weight_i_in => weights_i_array(i),
                weight_g_in => weights_g_array(i),
                weight_f_in => weights_f_array(i),
                weight_o_in => weights_o_array(i),
        
                -- output
                hidden_out  => hidden_out_array(i)
            );
    end generate;
    
end architecture behav;