library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Synthesis only
use ieee.fixed_pkg.all; 

-- -- Simulation only
-- library ieee_proposed;
-- use ieee_proposed.float_pkg.all;

use work.rnn_pkg.all;
use work.util_pkg.all;

entity lstm_pe is
    generic (
        INPUT_SIZE : natural := 5;
        HIDDEN_SIZE : natural := 5;
        ADDR_WIDTH : natural := 14
    );
    port (
        clk     : in std_logic;
        rst     : in std_logic;
        
        -- input
        data_in     : in data_t;
        weight_i_in : in data_t;
        weight_g_in : in data_t;
        weight_f_in : in data_t;
        weight_o_in : in data_t;

        weights_addr : out std_logic_vector(ADDR_WIDTH-1 downto 0);

        -- output
        hidden_out  : out data_t
    );
end entity;

architecture behav of lstm_pe is
    component sigmoid_pwl is
        generic (
            n : natural := acc_t'high;
            f : natural := acc_t'low
        );
        port (
            x : in sfixed(n downto -f);
            y : out sigmoid_t
        );
    end component sigmoid_pwl;

    component tanh_lut is
        port (
            x : in acc_t;
            y : out tanh_t
        );
    end component tanh_lut;
    
    component MAC is
        port (
            clk         : in std_logic;
            rst         : in std_logic;
            en          : in std_logic;
            
            -- input
            data_in     : in data_t;
            weight_in   : in data_t;

            -- output
            data_out    : out acc_t
        );
    end component;

    signal f_out  : acc_t;
    signal i_out  : acc_t;
    signal o_out  : acc_t;
    signal g_out  : acc_t;

    signal f_sig  : sigmoid_t;
    signal i_sig  : sigmoid_t;
    signal o_sig  : sigmoid_t;
    signal g_tanh : tanh_t;

    signal c_t : data_t;
    signal c_t_tanh : tanh_t;

    signal mod_reset : std_logic;
    signal mod_en    : std_logic;

begin

    process (clk, rst)
        variable counter : natural := 0;
    begin
        if rst = '1' then
            mod_reset <= '1';
            mod_en <= '0';
        elsif rising_edge(clk) then
            if counter = INPUT_SIZE + HIDDEN_SIZE - 1 then
                counter := 0;

                c_t <= resize(to_sfixed(f_sig) * c_t + to_sfixed(i_sig) * g_tanh, c_t'high, c_t'low);

                hidden_out <= resize(to_sfixed(o_sig) * c_t_tanh, hidden_out'high, hidden_out'low);

                mod_reset <= '1';
                mod_en <= '0';
            else
                counter := counter + 1;

                -- Set address to the current counter value
                weights_addr <= std_logic_vector(to_unsigned(counter, weights_addr'length));

                mod_reset <= '0';
                mod_en <= '1';
            end if;
        end if;
    end process;
    
    -- Sigmoid functions
    sigmoid_f : sigmoid_pwl
        generic map (
            n => acc_t'high,
            f => -acc_t'low
        )
        port map (
            x => f_out,
            y => f_sig
        );
    
    sigmoid_i : sigmoid_pwl
        generic map (
            n => acc_t'high,
            f => -acc_t'low
        )
        port map (
            x => i_out,
            y => i_sig
        );

    sigmoid_o : sigmoid_pwl
        generic map (
            n => acc_t'high,
            f => -acc_t'low
        )
        port map (
            x => o_out,
            y => o_sig
        );

    -- Tanh function
    tanh_g : tanh_lut
        port map (
            x => g_out,
            y => g_tanh
        );

    tanh_c : tanh_lut
        port map (
            x => resize(c_t, acc_t'high, acc_t'low),
            y => c_t_tanh
        );

    -- Input gate
    mac_i : MAC
        port map (
            clk     => clk,
            rst     => mod_reset,
            en      => mod_en,
            
            -- input
            data_in     => data_in,
            weight_in   => weight_i_in,

            -- output
            data_out    => i_out
        );
    
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