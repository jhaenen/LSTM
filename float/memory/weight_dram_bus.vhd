library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity weight_dram_bus is
    port (
        clk : in std_logic;

        -- DRAM bus interface
        data_bus : in std_logic_vector(511 downto 0);
        data_bus_valid : in std_logic;
        data_bus_state : in std_logic_vector(4 downto 0);
        data_bus_state_valid : in std_logic;
        data_bus_dest : in std_logic_vector(18 downto 0);
        data_bus_last : in std_logic_vector(1 downto 0);

        data_bus_ready : out std_logic;

        -- Local interface
        m_axis_weight_data : out std_logic_vector(3071 downto 0);
        m_axis_weight_data_valid : out std_logic;
        m_axis_weight_data_ready : in std_logic;
        m_axis_weight_data_last : out std_logic;
        m_axis_weight_data_dest : out std_logic_vector(9 downto 0);
        m_axis_weight_data_user : out std_logic_vector(2 downto 0)
    );
end entity weight_dram_bus;

architecture rtl of weight_dram_bus is
    constant BUFFER_SIZE : natural := 6;

    type data_buffer_t is array (0 to BUFFER_SIZE-1) of std_logic_vector(511 downto 0);
    signal data_buffer : data_buffer_t := (others => (others => '0'));

    signal buffer_valid : valid_t := INVALID;
    signal layer_complete : boolean := false;
    signal layers_complete : boolean := false;

    signal buffer_dest : weight_dest_t := I_INPUT;
        
    signal bus_state : bus_states_t := IDLE;

    signal read_pointer : natural range 0 to BUFFER_SIZE-1 := 0;
    signal write_addr : unsigned(9 downto 0) := (others => '0');
    constant max_addr : natural := 768;
begin
    
    bus_state <= slv_to_bus_states(data_bus_state) when data_bus_state_valid = '1' else IDLE;

    process (clk)
    begin
        if rising_edge(clk) then
            if buffer_valid = INVALID then
                data_bus_ready <= '1';

                if data_bus_valid = '1' and data_bus_state_valid = '1' then
                    data_buffer(read_pointer) <= data_bus;

                    if data_bus_last(1) = '1' then
                        layers_complete <= true;
                    else
                        layers_complete <= false;
                    end if;

                    if data_bus_last(0) = '1' then
                        layer_complete <= true;
                    else
                        layer_complete <= false;
                    end if;

                    if read_pointer = BUFFER_SIZE-1 then
                        read_pointer <= 0;

                        buffer_valid <= VALID;
                        data_bus_ready <= '0';

                        case bus_state is
                            when READ_I_IN_W =>
                                buffer_dest <= I_INPUT;
                            when READ_I_HID_W =>
                                buffer_dest <= I_HIDDEN;
                            when READ_F_IN_W =>
                                buffer_dest <= F_INPUT;
                            when READ_F_HID_W =>
                                buffer_dest <= F_HIDDEN;
                            when READ_G_IN_W =>
                                buffer_dest <= G_INPUT;
                            when READ_G_HID_W =>
                                buffer_dest <= G_HIDDEN;
                            when READ_O_IN_W =>
                                buffer_dest <= O_INPUT;
                            when READ_O_HID_W =>
                                buffer_dest <= O_HIDDEN;
                            when others => 
                                buffer_dest <= I_INPUT;
                        end case;
                    else
                        read_pointer <= read_pointer + 1;
                    end if;
                end if;
            else
                data_bus_ready <= '0';
            end if;

            if m_axis_weight_data_ready = '1'and buffer_valid = VALID then
                for i in 0 to BUFFER_SIZE-1 loop
                    m_axis_weight_data(512*i + 511 downto 512*i) <= data_buffer(i);
                end loop;
                
                m_axis_weight_data_valid <= '1';
                if layers_complete then
                    m_axis_weight_data_last <= '1';
                else
                    m_axis_weight_data_last <= '0';
                end if;

                m_axis_weight_data_dest <= std_logic_vector(write_addr);
                m_axis_weight_data_user <= weight_dest_to_slv(buffer_dest);

                buffer_valid <= INVALID;

                if layer_complete then
                    write_addr <= (others => '0');
                else
                    write_addr <= write_addr + 1;
                end if;
            else
                m_axis_weight_data <= (others => '0');
                m_axis_weight_data_valid <= '0';
                m_axis_weight_data_last <= '0';
                m_axis_weight_data_dest <= (others => '0');
                m_axis_weight_data_user <= (others => '0');
            end if;
        end if;
    end process;
    
    
end architecture rtl;