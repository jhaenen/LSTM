library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity in_out_dram_bus is
    port (
        clk : in std_logic;

        -- DRAM bus interface
        data_bus : inout std_logic_vector(511 downto 0) := (others => 'Z');
        data_bus_valid : inout std_logic := 'Z';
        data_bus_state : in std_logic_vector(4 downto 0);
        data_bus_state_valid : in std_logic;
        data_bus_dest : inout std_logic_vector(18 downto 0) := (others => 'Z');
        data_bus_last : inout std_logic_vector(1 downto 0) := (others => 'Z');

            -- input
        db_hid_in_data_ready : out std_logic := '0';

            -- output
        db_hid_out_data_ready : in std_logic;

        -- local memory interface
        hidden_in_buffer_addr : out std_logic_vector(8 downto 0) := (others => '0');
        hidden_in_buffer_data : out std_logic_vector(15 downto 0) := (others => '0');
        hidden_in_buffer_write_en : out std_logic := '0';
        hidden_in_buffer_valid : out std_logic := '0';

        hidden_out_data : in std_logic_vector(15 downto 0);
        hidden_out_data_valid : in std_logic;
        hidden_out_data_ready : out std_logic := '0';
        hidden_out_data_dest : in std_logic_vector(8 downto 0)

    );
end entity in_out_dram_bus;

architecture rtl of in_out_dram_bus is
    type data_buffer_t is array (0 to 11) of std_logic_vector(511 downto 0);
    signal data_buffer : data_buffer_t := (others => (others => '0'));

    type state_machine_t is (IDLE, WRITING_PREV_H, READING_NEXT_H);

    type buffer_state_t is (invalid, prev_h, next_h);
    type buffer_state_array_t is array (0 to 11) of buffer_state_t;
    signal buffer_state : buffer_state_array_t := (others => invalid);

    signal hidden_buffer_valid : valid_t := invalid;

    signal ph_read_pointer : natural range 0 to 11 := 0;
    
    signal current_db_state : bus_states_t;
begin
    current_db_state <= slv_to_bus_states(data_bus_state);

    process(clk)
        variable current_state : state_machine_t := IDLE;

        variable ph_write_offset : natural range 0 to 31 := 0;
        variable ph_write_pointer : natural range 0 to 11 := 0;

        variable nh_read_offset : natural range 0 to 31 := 0;
        variable nh_read_pointer : natural range 0 to 11 := 0;
    begin
        if rising_edge(clk) then
            if (current_state = IDLE) then
                db_hid_in_data_ready <= '1';
                hidden_out_data_ready <= '1';

                if hidden_out_data_valid = '1' then
                    current_state := WRITING_PREV_H;
                end if;

                if buffer_state(nh_read_pointer) = next_h then
                    current_state := READING_NEXT_H;
                    hidden_buffer_valid <= invalid;
                else
                    hidden_in_buffer_addr <= (others => '0');
                    hidden_in_buffer_data <= (others => '0');
                    hidden_in_buffer_write_en <= '0';
                end if;
            end if;

            if hidden_buffer_valid = valid then
                hidden_in_buffer_valid <= '1';
            else
                hidden_in_buffer_valid <= '0';
            end if;

            -- Local memory handling
            if (current_state = WRITING_PREV_H) then
                db_hid_in_data_ready <= '0';
                hidden_out_data_ready <= '1';
                if hidden_out_data_valid = '1' then
                    ph_write_offset := to_integer(unsigned(hidden_out_data_dest(4 downto 0)));
                    ph_write_pointer := to_integer(unsigned(hidden_out_data_dest(8 downto 5)));
                    
                    data_buffer(ph_write_pointer)(ph_write_offset * 16 + 15 downto ph_write_offset * 16) <= hidden_out_data;
                    if ph_write_offset = 31 then
                        buffer_state(ph_write_pointer) <= prev_h;
                        if ph_write_pointer = 11 then
                            current_state := IDLE;
                        end if;
                    end if;
                end if;
            end if;

            if current_state = READING_NEXT_H then
                if buffer_state(11) /= invalid then
                    db_hid_in_data_ready <= '0';
                else 
                    db_hid_in_data_ready <= '1';
                end if;

                hidden_out_data_ready <= '0';
                if buffer_state(nh_read_pointer) = next_h then
                    hidden_in_buffer_data <= data_buffer(nh_read_pointer)(nh_read_offset * 16 + 15 downto nh_read_offset * 16);
                    hidden_in_buffer_addr <= std_logic_vector(to_unsigned(nh_read_pointer, 4)) & std_logic_vector(to_unsigned(nh_read_offset, 5));
                    hidden_in_buffer_write_en <= '1';

                    nh_read_offset := nh_read_offset + 1;
                    if nh_read_offset = 32 then
                        nh_read_offset := 0;
                        buffer_state(nh_read_pointer) <= invalid;
                        nh_read_pointer := nh_read_pointer + 1;
                        if nh_read_pointer = 12 then
                            nh_read_pointer := 0;
                            current_state := IDLE;
                            hidden_buffer_valid <= valid;
                        end if;
                    end if;
                else 
                    hidden_in_buffer_write_en <= '0';
                end if;
            end if;

            -- DRAM bus handling
            if data_bus_state_valid = '1' then
                case current_db_state is
                    when WRITE_PREV_H =>
                        if buffer_state(ph_read_pointer) = prev_h and db_hid_out_data_ready = '1' then
                            data_bus_valid <= '1';
                            data_bus <= data_buffer(ph_read_pointer);
                            data_bus_dest <= std_logic_vector(to_unsigned(ph_read_pointer, 19));

                            if ph_read_pointer = 11 then
                                data_bus_last <= "01";
                                -- reset read pointer
                                ph_read_pointer <= 0;
                            else
                                data_bus_last <= "00";
                                -- increment read pointer
                                ph_read_pointer <= ph_read_pointer + 1;
                            end if;

                            
                            buffer_state(ph_read_pointer) <= invalid;
                        else 
                            data_bus_valid <= 'Z';
                            data_bus <= (others => 'Z');
                            data_bus_dest <= (others => 'Z');
                            data_bus_last <= (others => 'Z');
                        end if;
                    when READ_NEXT_H =>
                        db_hid_in_data_ready <= '1';

                        if data_bus_valid = '1' then
                            buffer_state(to_integer(unsigned(data_bus_dest))) <= next_h;
                            data_buffer(to_integer(unsigned(data_bus_dest))) <= data_bus;
                        else 
                            data_bus_last <= (others => 'Z');
                            data_bus_valid <= 'Z';
                            data_bus <= (others => 'Z');
                            data_bus_dest <= (others => 'Z');
                        end if;
                    when others =>
                        data_bus_last <= (others => 'Z');
                        data_bus_valid <= 'Z';
                        data_bus <= (others => 'Z');
                        data_bus_dest <= (others => 'Z');
                end case;
            end if;
        end if;
    end process;
    
    
end architecture rtl;