library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity pe_block is
    port (
        clk : in std_logic;

        s_axis_pe_ready : out std_logic;
        s_axis_pe_valid : in std_logic;
        s_axis_pe_last : in std_logic;

        post_allowed : in std_logic;

        s_axis_data_in_data : in std_logic_vector(15 downto 0);
        s_axis_hidden_in_data : in std_logic_vector(15 downto 0);

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
    end component;


    type data_signal_t is array(383 downto 0) of std_logic_vector(15 downto 0);
    type ready_signal_t is array(383 downto 0) of std_logic;
    type valid_signal_t is array(383 downto 0) of std_logic;
    signal pes_ready : ready_signal_t;

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
        variable write_corrected : natural range 0 to 11 := 0;
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
                                for i in 0 to 383 loop
                                    if i >= write_counter * 32 and i < (write_counter + 1) * 32 then
                                        if c_t_out_valid(i) = '0' then
                                            c_out_valid_check := false;
                                        end if;

                                        write_corrected := i - write_counter * 32;
                                        s_axis_c_and_bias_data(16 * write_corrected + 15 downto 16 * write_corrected) <= c_t_out_data(write_corrected);
                                    end if;
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
    -- gen_pe : for i in 0 to 383 generate
    --     lstm_pe_bf16_inst : lstm_pe_bf16
    --         port map (
    --             clk     => clk,
        
    --             -- input
    --             s_axis_pe_ready => pes_ready(i),
    --             s_axis_pe_valid => s_axis_pe_valid,
    --             s_axis_pe_last => s_axis_pe_last,

    --             post_allowed => post_allowed,

    --             s_axis_data_in => s_axis_data_in_data,
    --             s_axis_hidden_data => s_axis_hidden_in_data,

    --             -- weights
    --             s_axis_weight_i_input_data => s_axis_weight_i_input_data(16 * i + 15 downto 16 * i),
    --             s_axis_weight_i_hidden_data => s_axis_weight_i_hidden_data(16 * i + 15 downto 16 * i),

    --             s_axis_weight_f_input_data => s_axis_weight_f_input_data(16 * i + 15 downto 16 * i),
    --             s_axis_weight_f_hidden_data => s_axis_weight_f_hidden_data(16 * i + 15 downto 16 * i),

    --             s_axis_weight_g_input_data => s_axis_weight_g_input_data(16 * i + 15 downto 16 * i),
    --             s_axis_weight_g_hidden_data => s_axis_weight_g_hidden_data(16 * i + 15 downto 16 * i),

    --             s_axis_weight_o_input_data => s_axis_weight_o_input_data(16 * i + 15 downto 16 * i),
    --             s_axis_weight_o_hidden_data => s_axis_weight_o_hidden_data(16 * i + 15 downto 16 * i),

    --             -- output
    --             m_axis_hidden_out_data => m_axis_hidden_out_data(16 * i + 15 downto 16 * i),
    --             m_axis_hidden_out_valid => output_valid(i),
    --             m_axis_hidden_out_ready => m_axis_hidden_out_ready,

    --             -- c_t and bias update
    --             s_axis_c_in_and_bias_ready => c_and_bias_in_ready(i),
                
    --             s_axis_c_t_in_data => c_t_in_data(i),
    --             s_axis_c_t_in_valid => c_t_in_valid(i),

    --             s_axis_c_t_out_data => c_t_out_data(i),
    --             s_axis_c_t_out_valid => c_t_out_valid(i),
    --             s_axis_c_t_out_ready => c_t_out_ready(i),

    --             s_axis_i_bias_data => i_bias_data(i),
    --             s_axis_i_bias_valid => i_bias_valid(i),

    --             s_axis_f_bias_data => f_bias_data(i),
    --             s_axis_f_bias_valid => f_bias_valid(i),

    --             s_axis_g_bias_data => g_bias_data(i),
    --             s_axis_g_bias_valid => g_bias_valid(i),

    --             s_axis_o_bias_data => o_bias_data(i),
    --             s_axis_o_bias_valid => o_bias_valid(i)

    --         );
    -- end generate gen_pe;
    
    -- And reduce the ready signals
    process (pes_ready)
        variable temp : std_logic := '1';
    begin
        for i in 0 to 383 loop
            temp := temp and pes_ready(i);
        end loop;

        s_axis_pe_ready <= temp;
    end process;
    
    -- And reduce the valid signals
    process (output_valid)
        variable temp : std_logic := '1';
    begin
        for i in 0 to 383 loop
            temp := temp and output_valid(i);
        end loop;

        m_axis_hidden_out_valid <= temp;
    end process;
end architecture behav;