library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.rnn_pkg.all;

entity pe_nx_controller is
    generic (
        INPUT_SIZE : natural := 4;
        HIDDEN_SIZE : natural := 4;
        BIT_WIDTH : natural := 16;
        ADDR_WIDTH : natural := 6;
        NUM_PES : natural := 2
    );
    port (
        clk : in std_logic;
        mem_clk : in std_logic;
        rst : in std_logic;
        mem_rst : in std_logic;

        data_in : in std_logic_vector(4*BIT_WIDTH*NUM_PES/2-1 downto 0);

        pe_state : out std_logic_vector(1 downto 0);

        weights_addr : out std_logic_vector(ADDR_WIDTH - 1 downto 0);

        weights_i : out std_logic_vector(BIT_WIDTH*NUM_PES-1 downto 0);
        weights_g : out std_logic_vector(BIT_WIDTH*NUM_PES-1 downto 0);
        weights_f : out std_logic_vector(BIT_WIDTH*NUM_PES-1 downto 0);
        weights_o : out std_logic_vector(BIT_WIDTH*NUM_PES-1 downto 0)
    );
end entity;

architecture rtl of pe_nx_controller is
    type weights_pe_arr_t is array (0 to 3) of std_logic_vector(15 downto 0);
    signal weights_pe1_array : weights_pe_arr_t;
    signal weights_pe2_array : weights_pe_arr_t;

    -- Create a state machine to handle the data loading of 2 states LOAD_PE1 and LOAD_PE2
    type load_state_t is (IDLE, LOADING);
    signal next_load_state : load_state_t;

    signal next_pe_state_int : pe_state_t;

    signal mem_counter : natural;
begin

    process (clk, rst)
        variable counter : natural := 0;

        variable pe_state_int : pe_state_t;
        variable load_state : load_state_t;
    begin
        pe_state_int := next_pe_state_int;
        load_state := next_load_state;

        if rst = '1' then
            next_pe_state_int <= IDLE;
            next_load_state <= IDLE;
        elsif rising_edge(clk) then
            case pe_state_int is
                when IDLE =>
                    -- if we were not loading yet, we have to wait for the next clock cycle to start accumulating
                    if load_state = IDLE then
                        next_pe_state_int <= RESET;

                        mem_counter <= 0;
                    else
                        next_pe_state_int <= ACCUMULATE;

                        mem_counter <= mem_counter + 2;
                    end if;

                    next_load_state <= LOADING;
                when RESET =>
                    -- if we were not loading yet, we have to wait for the next clock cycle to start accumulating
                    if load_state = IDLE then
                        next_pe_state_int <= IDLE;

                        mem_counter <= 0;
                    else
                        next_pe_state_int <= ACCUMULATE;

                        mem_counter <= mem_counter + 2;
                    end if;

                    next_load_state <= LOADING;
                when ACCUMULATE =>
                    -- If we are in the one before last cycle, stop loading
                    if counter = INPUT_SIZE + HIDDEN_SIZE - 2 then
                        counter := counter + 1;

                        -- Reset the memory counter
                        mem_counter <= 0;

                        next_load_state <= IDLE;
                        next_pe_state_int <= ACCUMULATE;
                    elsif counter = INPUT_SIZE + HIDDEN_SIZE - 1 then
                        -- Reset the pe counter
                        counter := 0;
                        mem_counter <= 0;

                        -- Switch to POST state
                        next_pe_state_int <= POST;
                        next_load_state <= IDLE;
                    else
                        -- Increment counters and continue accumulating
                        counter := counter + 1;
                        mem_counter <= mem_counter + 2;

                        next_pe_state_int <= ACCUMULATE;
                        next_load_state <= LOADING;
                    end if;
                when POST =>
                    counter := 0;
                    mem_counter <= 0;

                    next_pe_state_int <= RESET;
                    next_load_state <= LOADING;
            end case;
        end if;
    end process;

    pe_state <= to_slv(next_pe_state_int);

    -- Weight loading process
    process(mem_clk, rst)
        type load_phase_t is (LOAD_PE1, LOAD_PE2);
        variable load_phase : load_phase_t := LOAD_PE1;  
        variable load_state : load_state_t; 
    begin
        load_state := next_load_state;

        if rst = '1' then
            weights_pe1_array(0) <= (others => '0');
            weights_pe1_array(1) <= (others => '0');
            weights_pe1_array(2) <= (others => '0');
            weights_pe1_array(3) <= (others => '0');
            weights_pe2_array(0) <= (others => '0');
            weights_pe2_array(1) <= (others => '0');
            weights_pe2_array(2) <= (others => '0');
            weights_pe2_array(3) <= (others => '0');

            load_phase := LOAD_PE1;

            weights_addr <= (others => '0');
        elsif rising_edge(mem_clk) then
            if load_state = LOADING then
                case load_phase is
                    when LOAD_PE1 =>
                        weights_pe1_array(0) <= data_in(15 downto 0);
                        weights_pe1_array(1) <= data_in(31 downto 16);
                        weights_pe1_array(2) <= data_in(47 downto 32);
                        weights_pe1_array(3) <= data_in(63 downto 48);

                        -- Set the address to the next weight (with an offset of 1)
                        load_phase := LOAD_PE2;
                        weights_addr <= std_logic_vector(to_unsigned(mem_counter + 1, weights_addr'length));
                    when LOAD_PE2 =>
                        weights_pe2_array(0) <= data_in(15 downto 0);
                        weights_pe2_array(1) <= data_in(31 downto 16);
                        weights_pe2_array(2) <= data_in(47 downto 32);
                        weights_pe2_array(3) <= data_in(63 downto 48);

                        -- Set the address to the next weight (without an offset)
                        load_phase := LOAD_PE1;
                        weights_addr <= std_logic_vector(to_unsigned(mem_counter, weights_addr'length));
                end case;
            elsif load_state = IDLE then
                weights_pe1_array(0) <= (others => '0');
                weights_pe1_array(1) <= (others => '0');
                weights_pe1_array(2) <= (others => '0');
                weights_pe1_array(3) <= (others => '0');
                weights_pe2_array(0) <= (others => '0');
                weights_pe2_array(1) <= (others => '0');
                weights_pe2_array(2) <= (others => '0');
                weights_pe2_array(3) <= (others => '0');

                load_phase := LOAD_PE1;
                weights_addr <= std_logic_vector(to_unsigned(mem_counter, weights_addr'length));
            end if;
        end if;
    end process;

    pe1_weight_i <= weights_pe1_array(0);
    pe1_weight_g <= weights_pe1_array(1);
    pe1_weight_f <= weights_pe1_array(2);
    pe1_weight_o <= weights_pe1_array(3);
    pe2_weight_i <= weights_pe2_array(0);
    pe2_weight_g <= weights_pe2_array(1);
    pe2_weight_f <= weights_pe2_array(2);
    pe2_weight_o <= weights_pe2_array(3);

end architecture;