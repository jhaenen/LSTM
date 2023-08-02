library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity in_out_db_test is
end entity in_out_db_test;

architecture sim of in_out_db_test is
    component in_out_dram_bus is
        port (
            clk : in std_logic;
    
            -- DRAM bus interface
            data_bus : inout std_logic_vector(511 downto 0);
            data_bus_valid : inout std_logic;
            data_bus_state : in std_logic_vector(3 downto 0);
            data_bus_state_valid : in std_logic;
            data_bus_dest : inout std_logic_vector(18 downto 0);
            data_bus_last : inout std_logic;
    
                -- input
            db_hid_in_data_ready : out std_logic;
    
                -- output
            db_hid_out_data_ready : in std_logic;
    
            -- local memory interface
            hidden_in_buffer_addr : out std_logic_vector(8 downto 0);
            hidden_in_buffer_data : out std_logic_vector(15 downto 0);
            hidden_in_buffer_write_en : out std_logic;
            hidden_in_buffer_valid : out std_logic;
    
            hidden_out_data : in std_logic_vector(15 downto 0);
            hidden_out_data_valid : in std_logic;
            hidden_out_data_ready : out std_logic;
            hidden_out_data_dest : in std_logic_vector(8 downto 0)
    
        );
    end component;

    constant clk_period : time := 10 ns;

    signal clk : std_logic := '0';

    signal data_bus : std_logic_vector(511 downto 0) := (others => 'Z');
    signal data_bus_valid : std_logic := 'Z';
    signal data_bus_state : bus_states_t := IDLE;
    signal data_bus_state_valid : std_logic := '0';
    signal data_bus_dest : std_logic_vector(18 downto 0) := (others => 'Z');
    signal data_bus_last : std_logic := 'Z';

    signal db_hid_in_data_ready : std_logic;

    signal db_hid_out_data_ready : std_logic := '0';

    signal hidden_in_buffer_addr : std_logic_vector(8 downto 0);
    signal hidden_in_buffer_data : std_logic_vector(15 downto 0);
    signal hidden_in_buffer_write_en : std_logic;
    signal hidden_in_buffer_valid : std_logic;

    signal hidden_out_data : std_logic_vector(15 downto 0) := (others => '0');
    signal hidden_out_data_valid : std_logic := '0';
    signal hidden_out_data_ready : std_logic;
    signal hidden_out_data_dest : std_logic_vector(8 downto 0) := (others => '0');
begin

    -- test process
    process
    begin
        wait for clk_period * 10;

        if db_hid_in_data_ready = '0' then
            wait until db_hid_in_data_ready = '1';
        end if;

        data_bus_state <= READ_NEXT_H;
        data_bus_state_valid <= '1';
        data_bus_valid <= '1';
        
        for i in 0 to 11 loop
            -- Set each nibble of data bus to i
            for j in 0 to 127 loop
                data_bus(j * 4 + 3 downto j * 4) <= std_logic_vector(to_unsigned(i, 4));
            end loop;

            -- Set destination to i
            data_bus_dest <= std_logic_vector(to_unsigned(i, 19));

            if i = 11 then
                data_bus_last <= '1';
            else
                data_bus_last <= '0';
            end if;
            
            wait for clk_period;
        end loop;

        data_bus_state <= IDLE;
        data_bus_state_valid <= '1';
        data_bus_valid <= 'Z';
        data_bus_last <= 'Z';
        data_bus_dest <= (others => 'Z');
        data_bus <= (others => 'Z');

        wait until hidden_out_data_ready = '1';
        wait for clk_period;
        
        hidden_out_data_valid <= '1';

        data_bus_state <= WRITE_PREV_H;
        data_bus_state_valid <= '1';
        db_hid_out_data_ready <= '1';

        for i in 0 to 11 loop
            for j in 0 to 31 loop
                if j = 0 then
                    hidden_out_data <= std_logic_vector(to_unsigned(i, 16));
                else
                    hidden_out_data <= std_logic_vector(to_unsigned(j - 1, 16));
                end if;

                hidden_out_data_dest <= std_logic_vector(to_unsigned(i, 4)) & std_logic_vector(to_unsigned(j, 5));
                wait for clk_period;
            end loop;
        end loop;

        hidden_out_data_valid <= '0';
        hidden_out_data <= (others => '0');
        hidden_out_data_dest <= (others => '0');
                
        wait until data_bus_last = '1';
        wait for clk_period;

        data_bus_state <= IDLE;
        data_bus_state_valid <= '1';
        data_bus_valid <= 'Z';
        data_bus_last <= 'Z';
        data_bus_dest <= (others => 'Z');
        data_bus <= (others => 'Z');

        wait;
    end process;


    -- Clock process
    process
    begin
        wait for clk_period / 2;
        clk <= not clk;
    end process;


    DUT: in_out_dram_bus
        port map (
            clk => clk,

            -- DRAM bus interface
            data_bus => data_bus,
            data_bus_valid => data_bus_valid,
            data_bus_state => bus_states_to_slv(data_bus_state),
            data_bus_state_valid => data_bus_state_valid,
            data_bus_dest => data_bus_dest,
            data_bus_last => data_bus_last,

            -- input
            db_hid_in_data_ready => db_hid_in_data_ready,

            -- output
            db_hid_out_data_ready => db_hid_out_data_ready,

            -- local memory interface
            hidden_in_buffer_addr => hidden_in_buffer_addr,
            hidden_in_buffer_data => hidden_in_buffer_data,
            hidden_in_buffer_write_en => hidden_in_buffer_write_en,
            hidden_in_buffer_valid => hidden_in_buffer_valid,

            hidden_out_data => hidden_out_data,
            hidden_out_data_valid => hidden_out_data_valid,
            hidden_out_data_ready => hidden_out_data_ready,
            hidden_out_data_dest => hidden_out_data_dest
        );
    
    
    
end architecture sim;
