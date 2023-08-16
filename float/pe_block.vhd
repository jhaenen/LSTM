library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

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
        m_axis_hidden_out_ready : in std_logic;

        s_axis_c_and_bias_data : inout std_logic_vector(511 downto 0) := (others => 'Z');
        s_axis_c_and_bias_valid : inout std_logic := 'Z';
        s_axis_c_and_bias_pe_ready : out std_logic;
        s_axis_c_and_bias_bus_ready : in std_logic;
        s_axis_c_and_bias_dest : inout std_logic_vector(18 downto 0) := (others => 'Z');
        s_axis_c_and_bias_last : inout std_logic_vector(1 downto 0) := (others => 'Z');
        s_axis_c_and_bias_bus_state : in std_logic_vector(4 downto 0)
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
    end component;


    type data_signal_t is array(383 downto 0) of std_logic_vector(15 downto 0);
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

    signal c_and_bias_in_ready : ready_signal_t;

    signal c_t_in_data : data_signal_t;
    signal c_t_in_valid : valid_signal_t;

    signal c_t_out_data : data_signal_t;
    signal c_t_out_valid : valid_signal_t;
    signal c_t_out_ready : ready_signal_t;

    signal i_bias_data : data_signal_t;
    signal i_bias_valid : valid_signal_t;

    signal f_bias_data : data_signal_t;
    signal f_bias_valid : valid_signal_t;

    signal g_bias_data : data_signal_t;
    signal g_bias_valid : valid_signal_t;

    signal o_bias_data : data_signal_t;
    signal o_bias_valid : valid_signal_t;

    signal bus_state : bus_states_t;
begin

    bus_state <= slv_to_bus_states(s_axis_c_and_bias_bus_state);

    process(s_axis_c_and_bias_bus_ready)
    begin
        for i in 0 to 383 loop
            c_t_out_ready(i) <= s_axis_c_and_bias_bus_ready;
        end loop;
    end process;

    process(clk)
        variable write_counter : natural range 0 to 11 := 0;
        variable c_out_valid_check : boolean := true;
    begin
        if rising_edge(clk) then
            if s_axis_c_and_bias_valid = '1' then
                case bus_state is
                    when READ_C_T =>
                        for i in 0 to 11 loop
                            for j in 0 to 31 loop
                                if s_axis_c_and_bias_dest = std_logic_vector(to_unsigned(i, 19)) then
                                    c_t_in_data(32 * i + j) <= s_axis_c_and_bias_data(16 * i + j + 15 downto 16 * i + j);
                                    c_t_in_valid(32 * i + j) <= '1';
                                else
                                    c_t_in_data(32 * i + j) <= (others => '0');
                                    c_t_in_valid(32 * i + j) <= '0';
                                end if;
                            end loop;
                        end loop;

                        i_bias_data <= (others => (others => '0'));
                        i_bias_valid <= (others => '0');

                        f_bias_data <= (others => (others => '0'));
                        f_bias_valid <= (others => '0');

                        g_bias_data <= (others => (others => '0'));
                        g_bias_valid <= (others => '0');

                        o_bias_data <= (others => (others => '0'));
                        o_bias_valid <= (others => '0');
                    when READ_I_B =>
                        for i in 0 to 11 loop
                            for j in 0 to 31 loop
                                if s_axis_c_and_bias_dest = std_logic_vector(to_unsigned(i, 19)) then
                                    i_bias_data(32 * i + j) <= s_axis_c_and_bias_data(16 * i + j + 15 downto 16 * i + j);
                                    i_bias_valid(32 * i + j) <= '1';
                                else
                                    i_bias_data(32 * i + j) <= (others => '0');
                                    i_bias_valid(32 * i + j) <= '0';
                                end if;
                            end loop;
                        end loop;

                        c_t_in_data <= (others => (others => '0'));
                        c_t_in_valid <= (others => '0');

                        f_bias_data <= (others => (others => '0'));
                        f_bias_valid <= (others => '0');

                        g_bias_data <= (others => (others => '0'));
                        g_bias_valid <= (others => '0');

                        o_bias_data <= (others => (others => '0'));
                        o_bias_valid <= (others => '0');
                    when READ_F_B =>
                        for i in 0 to 11 loop
                            for j in 0 to 31 loop
                                if s_axis_c_and_bias_dest = std_logic_vector(to_unsigned(i, 19)) then
                                    f_bias_data(32 * i + j) <= s_axis_c_and_bias_data(16 * i + j + 15 downto 16 * i + j);
                                    f_bias_valid(32 * i + j) <= '1';
                                else
                                    f_bias_data(32 * i + j) <= (others => '0');
                                    f_bias_valid(32 * i + j) <= '0';
                                end if;
                            end loop;
                        end loop;

                        c_t_in_data <= (others => (others => '0'));
                        c_t_in_valid <= (others => '0');

                        i_bias_data <= (others => (others => '0'));
                        i_bias_valid <= (others => '0');

                        g_bias_data <= (others => (others => '0'));
                        g_bias_valid <= (others => '0');

                        o_bias_data <= (others => (others => '0'));
                        o_bias_valid <= (others => '0');
                    when READ_G_B =>
                        for i in 0 to 11 loop
                            for j in 0 to 31 loop
                                if s_axis_c_and_bias_dest = std_logic_vector(to_unsigned(i, 19)) then
                                    g_bias_data(32 * i + j) <= s_axis_c_and_bias_data(16 * i + j + 15 downto 16 * i + j);
                                    g_bias_valid(32 * i + j) <= '1';
                                else
                                    g_bias_data(32 * i + j) <= (others => '0');
                                    g_bias_valid(32 * i + j) <= '0';
                                end if;
                            end loop;
                        end loop;

                        c_t_in_data <= (others => (others => '0'));
                        c_t_in_valid <= (others => '0');

                        i_bias_data <= (others => (others => '0'));
                        i_bias_valid <= (others => '0');

                        f_bias_data <= (others => (others => '0'));
                        f_bias_valid <= (others => '0');

                        o_bias_data <= (others => (others => '0'));
                        o_bias_valid <= (others => '0');
                    when READ_O_B =>
                        for i in 0 to 11 loop
                            for j in 0 to 31 loop
                                if s_axis_c_and_bias_dest = std_logic_vector(to_unsigned(i, 19)) then
                                    o_bias_data(32 * i + j) <= s_axis_c_and_bias_data(16 * i + j + 15 downto 16 * i + j);
                                    o_bias_valid(32 * i + j) <= '1';
                                else
                                    o_bias_data(32 * i + j) <= (others => '0');
                                    o_bias_valid(32 * i + j) <= '0';
                                end if;
                            end loop;
                        end loop;

                        c_t_in_data <= (others => (others => '0'));
                        c_t_in_valid <= (others => '0');

                        i_bias_data <= (others => (others => '0'));
                        i_bias_valid <= (others => '0');

                        f_bias_data <= (others => (others => '0'));
                        f_bias_valid <= (others => '0');

                        g_bias_data <= (others => (others => '0'));
                        g_bias_valid <= (others => '0');
                    when WRITE_C_T =>
                            if s_axis_c_and_bias_bus_ready = '1' then
                                c_out_valid_check := true;
                                for i in write_counter to write_counter + 31 loop
                                    if c_t_out_valid(i) = '0' then
                                        c_out_valid_check := false;
                                    end if;
                                    
                                    s_axis_c_and_bias_data(16 * i + 15 downto 16 * i) <= c_t_out_data(i);
                                end loop;

                                if c_out_valid_check = true then
                                    s_axis_c_and_bias_valid <= '1';
                                    s_axis_c_and_bias_dest <= std_logic_vector(to_unsigned(write_counter, 19));

                                    if write_counter = 11 then
                                        s_axis_c_and_bias_last <= "01";
                                        write_counter := 0;
                                    else
                                        s_axis_c_and_bias_last <= "00";
                                        write_counter := write_counter + 1;
                                    end if;
                                else
                                    s_axis_c_and_bias_valid <= '0';
                                    s_axis_c_and_bias_dest <= (others => '0');
                                    s_axis_c_and_bias_last <= (others => '0');
                                end if;
                            else
                                s_axis_c_and_bias_data <= (others => 'Z');
                                s_axis_c_and_bias_valid <= 'Z';
                                s_axis_c_and_bias_dest <= (others => 'Z');
                                s_axis_c_and_bias_last <= (others => 'Z');
                            end if;

                            c_t_in_data <= (others => (others => '0'));
                            c_t_in_valid <= (others => '0');

                            i_bias_data <= (others => (others => '0'));
                            i_bias_valid <= (others => '0');

                            f_bias_data <= (others => (others => '0'));
                            f_bias_valid <= (others => '0');

                            g_bias_data <= (others => (others => '0'));
                            g_bias_valid <= (others => '0');

                            o_bias_data <= (others => (others => '0'));
                            o_bias_valid <= (others => '0');
                    when others =>
                        s_axis_c_and_bias_data <= (others => 'Z');
                        s_axis_c_and_bias_valid <= 'Z';
                        s_axis_c_and_bias_dest <= (others => 'Z');
                        s_axis_c_and_bias_last <= (others => 'Z');

                        c_t_in_data <= (others => (others => '0'));
                        c_t_in_valid <= (others => '0');

                        i_bias_data <= (others => (others => '0'));
                        i_bias_valid <= (others => '0');

                        f_bias_data <= (others => (others => '0'));
                        f_bias_valid <= (others => '0');

                        g_bias_data <= (others => (others => '0'));
                        g_bias_valid <= (others => '0');

                        o_bias_data <= (others => (others => '0'));
                        o_bias_valid <= (others => '0');
                end case;
            else 
                s_axis_c_and_bias_data <= (others => 'Z');
                s_axis_c_and_bias_valid <= 'Z';
                s_axis_c_and_bias_dest <= (others => 'Z');
                s_axis_c_and_bias_last <= (others => 'Z');

                c_t_in_data <= (others => (others => '0'));
                c_t_in_valid <= (others => '0');

                i_bias_data <= (others => (others => '0'));
                i_bias_valid <= (others => '0');

                f_bias_data <= (others => (others => '0'));
                f_bias_valid <= (others => '0');

                g_bias_data <= (others => (others => '0'));
                g_bias_valid <= (others => '0');

                o_bias_data <= (others => (others => '0'));
                o_bias_valid <= (others => '0');
            end if;
        end if;
    end process;

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
                M_AXIS_HIDDEN_OUT_tready => m_axis_hidden_out_ready,

                -- c_t and bias update
                S_AXIS_C_AND_BIAS_IN_tready => c_and_bias_in_ready(i),

                S_AXIS_C_T_in_tdata => c_t_in_data(i),
                S_AXIS_C_T_in_tvalid => c_t_in_valid(i),

                S_AXIS_C_T_out_tdata => c_t_out_data(i),
                S_AXIS_C_T_out_tvalid => c_t_out_valid(i),
                S_AXIS_C_T_out_tready => c_t_out_ready(i),

                S_AXIS_I_BIAS_tdata => i_bias_data(i),
                S_AXIS_I_BIAS_tvalid => i_bias_valid(i),

                S_AXIS_F_BIAS_tdata => f_bias_data(i),
                S_AXIS_F_BIAS_tvalid => f_bias_valid(i),

                S_AXIS_G_BIAS_tdata => g_bias_data(i),
                S_AXIS_G_BIAS_tvalid => g_bias_valid(i),

                S_AXIS_O_BIAS_tdata => o_bias_data(i),
                S_AXIS_O_BIAS_tvalid => o_bias_valid(i)
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