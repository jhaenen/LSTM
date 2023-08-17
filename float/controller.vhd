library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity controller is
    generic (
        CHUNK_SIZE : natural := 1000
    );
    port (
        clk : in std_logic;

        m_axis_counter_data : out std_logic_vector(8 downto 0);
        m_axis_counter_last : out std_logic_vector(1 downto 0);
        m_axis_counter_valid : out std_logic;
        m_axis_counter_user : out std_logic_vector(3 downto 0);
        m_axis_weights_ready : in std_logic;
        m_axis_in_hid_ready : in std_logic;

        m_axis_dram_control_data : out std_logic_vector(3 downto 0);
        m_axis_dram_control_valid : out std_logic;
        m_axis_dram_control_ready : in std_logic;

        post_allowed : out std_logic;

        data_bus_state : in std_logic_vector(4 downto 0)
    );
end entity controller;

architecture behav of controller is
    signal layer : layer_info_t := LAYER1;

    signal last : last_t := NOT_LAST;
    signal last_inference : boolean := false;

    signal bus_state : bus_states_t := IDLE;

    signal dbg_counter : natural range 0 to 383 := 0;
    signal dbg_chunk_counter : natural range 0 to CHUNK_SIZE - 1 := 0;

    function is_post_allowed (state : bus_states_t) return boolean is
    begin
        case state is
            when READ_C_T | READ_I_B | READ_F_B | READ_G_B | READ_O_B =>
                return false;
            when others =>
                return true;
        end case;
    end function;
begin
    m_axis_counter_last <= last_to_slv(last);
    m_axis_counter_user <= inference_data_to_slv(inference_data_t'(layer, last_inference));

    bus_state <= slv_to_bus_states(data_bus_state);

    process(clk)
        variable counter : natural range 0 to 383 := 0;
        variable chunk_counter : natural range 0 to CHUNK_SIZE - 1 := 0;
        variable ready : boolean := false;
        variable initial : boolean := true;
        variable wait_for_dram_manager : boolean := false;
        variable wait_for_pes : boolean := false;
    begin
        if rising_edge(clk) then
            if initial then
                layer <= LAYER1;

                if not wait_for_dram_manager then
                    if m_axis_dram_control_ready = '1' then
                        m_axis_dram_control_valid <= '1';
                        m_axis_dram_control_data <= dram_control_to_slv(dram_control_t'(layer, true));
                        wait_for_dram_manager := true;
                    else
                        m_axis_dram_control_data <= (others => '0');
                        m_axis_dram_control_valid <= '0';
                    end if;
                else
                    if m_axis_dram_control_ready = '0' then
                        m_axis_dram_control_valid <= '0';
                        m_axis_dram_control_data <= (others => '0');
                        wait_for_dram_manager := false;
                        initial := false;
                    else
                        m_axis_dram_control_valid <= '1';
                        m_axis_dram_control_data <= dram_control_to_slv(dram_control_t'(layer, true));
                    end if;
                end if;

                m_axis_counter_data <= (others => '0');
                last <= NOT_LAST;
                last_inference <= false;
                m_axis_counter_valid <= '0';
                post_allowed <= '0';

                counter := 0;
            else
                if not ready then
                    if not wait_for_dram_manager then
                        if m_axis_weights_ready = '1' and m_axis_in_hid_ready = '1' and m_axis_dram_control_ready = '1' then
                            wait_for_dram_manager := true;
                            m_axis_dram_control_data <= dram_control_to_slv(dram_control_t'(layer, false));
                            m_axis_dram_control_valid <= '1';

                        else
                            m_axis_dram_control_data <= (others => '0');
                            m_axis_dram_control_valid <= '0';
                        end if;
                    else
                        if m_axis_dram_control_ready = '0' then
                            m_axis_dram_control_data <= (others => '0');
                            m_axis_dram_control_valid <= '0';
                            wait_for_dram_manager := false;
                            ready := true;
                        else
                            m_axis_dram_control_data <= dram_control_to_slv(dram_control_t'(layer, false));
                            m_axis_dram_control_valid <= '1';
                        end if;
                    end if;

                    m_axis_counter_data <= (others => '0');
                    last <= NOT_LAST;
                    last_inference <= false;
                    m_axis_counter_valid <= '0';
                    post_allowed <= '0';

                    counter := 0;
                else
                    m_axis_dram_control_valid <= '0';
                    if is_post_allowed(bus_state) then
                        post_allowed <= '1';
                    else
                        post_allowed <= '0';
                    end if;
            
                    if m_axis_weights_ready = '1' and m_axis_in_hid_ready = '1' then
                        if not wait_for_pes then
                            m_axis_counter_data <= std_logic_vector(to_unsigned(counter, 9));
                            m_axis_counter_valid <= '1';

                            if counter = 383 then
                                counter := 0;

                                if chunk_counter = CHUNK_SIZE - 1 then
                                    chunk_counter := 0;

                                    last <= LAYER_LAST;
                                    layer <= get_next_layer(layer);
                                    ready := false;
                                else

                                    last <= SEQ_LAST;
                                    chunk_counter := chunk_counter + 1;
                                end if;

                                wait_for_pes := true;
                            else
                                last <= NOT_LAST;
                                counter := counter + 1;
                            end if;

                            if chunk_counter = CHUNK_SIZE - 1 then
                                last_inference <= true;
                            else
                                last_inference <= false;
                            end if;
                        else
                            wait_for_pes := false;
                        end if;
                    else
                        m_axis_counter_data <= (others => '0');
                        last <= NOT_LAST;
                        last_inference <= false;
                        m_axis_counter_valid <= '0';
                    end if;
                end if;
            end if;
        end if;

        dbg_counter <= counter;
        dbg_chunk_counter <= chunk_counter;
    end process;
    
    
end architecture behav;