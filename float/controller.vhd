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
    begin
        if rising_edge(clk) then
            if initial then
                layer <= LAYER1;

                if m_axis_dram_control_ready = '1' then
                    m_axis_dram_control_valid <= '1';
                    m_axis_dram_control_data <= dram_control_to_slv(dram_control_t'(layer, true));
                    initial := false;
                else
                    m_axis_dram_control_data <= (others => '0');
                    m_axis_dram_control_valid <= '0';
                end if;

                m_axis_counter_data <= (others => '0');
                last <= NOT_LAST;
                last_inference <= false;
                m_axis_counter_valid <= '0';
                m_axis_dram_control_valid <= '0';
                post_allowed <= '0';

                counter := 0;
            else
                if not ready then
                    if m_axis_weights_ready = '1' and m_axis_in_hid_ready = '1' and m_axis_dram_control_ready = '1' then
                        ready := true;
                        m_axis_dram_control_data <= dram_control_to_slv(dram_control_t'(layer, false));
                        m_axis_dram_control_valid <= '1';

                    else
                        m_axis_dram_control_data <= (others => '0');
                        m_axis_dram_control_valid <= '0';
                    end if;

                    m_axis_counter_data <= (others => '0');
                    last <= NOT_LAST;
                    last_inference <= false;
                    m_axis_counter_valid <= '0';
                    post_allowed <= '0';

                    counter := 0;
                else
                    m_axis_dram_control_valid <= '0';
                    post_allowed <= '1' when is_post_allowed(bus_state) else '0';
            
                    if m_axis_weights_ready = '1' and m_axis_in_hid_ready = '1' then
                        m_axis_counter_data <= std_logic_vector(to_unsigned(counter, 9));
                        m_axis_counter_valid <= '1';

                        if counter = 383 then
                            counter := 0;

                            if chunk_counter = CHUNK_SIZE - 1 then
                                chunk_counter := 0;

                                last <= LAYER_LAST;
                            else

                                last <= SEQ_LAST;
                                chunk_counter := chunk_counter + 1;
                            end if;
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
                        m_axis_counter_data <= (others => '0');
                        last <= NOT_LAST;
                        last_inference <= false;
                        m_axis_counter_valid <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    
end architecture behav;