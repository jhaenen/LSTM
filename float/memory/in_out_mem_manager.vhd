library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;
use work.util_pkg.all;

entity in_out_mem_manager is
    generic (
        LATENCY : natural := 2;
        CHUNCK_SIZE : natural := 1000
    );
    port (
        clk : in std_logic;

        -- control
        s_axis_counter_data : in std_logic_vector(8 downto 0);
        s_axis_counter_valid : in std_logic;
        s_axis_counter_ready : out std_logic := '0';
        s_axis_counter_last : in std_logic_vector(1 downto 0);
        s_axis_counter_user : in std_logic_vector(3 downto 0);

        -- pe exchange
        m_axis_pes_ready : in std_logic;
        m_axis_pes_valid : out std_logic := '0';
        m_axis_pes_last : out std_logic := '0';

        m_axis_input_data : out std_logic_vector(15 downto 0);
        m_axis_hidden_data : out std_logic_vector(15 downto 0) := (others => '0');

        s_axis_pe_data : in std_logic_vector(384 * 16 - 1 downto 0);
        s_axis_pe_valid : in std_logic;
        s_axis_pe_ready : out std_logic := '0';

        -- BRAM reading Memory
        read_addr : out std_logic_vector(18 downto 0) := (others => '0');

        read_data_blk1 : in std_logic_vector(15 downto 0);
        read_en_blk1 : out std_logic := '0';

        read_data_blk2 : in std_logic_vector(15 downto 0);
        read_en_blk2 : out std_logic := '0';

        -- DRAM to BRAM signals
        s_axis_input_data : in std_logic_vector(15 downto 0);
        s_axis_input_valid : in std_logic;
        s_axis_input_ready : out std_logic := '0';
        s_axis_input_last : in std_logic;

        m_axis_output_data : out std_logic_vector(15 downto 0) := (others => '0');
        m_axis_output_valid : out std_logic := '0';
        m_axis_output_last : out std_logic := '0';

        -- Hidden swap memory
        read_addr_hidden : out std_logic_vector(8 downto 0) := (others => '0');
        read_data_hidden : in std_logic_vector(15 downto 0);
        read_en_hidden : out std_logic := '0';
        hidden_swap_valid : in std_logic;

        -- hidden to DRAM signals
        hidden_dram_data : out std_logic_vector(15 downto 0) := (others => '0');
        hidden_dram_valid : out std_logic := '0';
        hidden_dram_dest : out std_logic_vector(8 downto 0) := (others => '0');
        hidden_dram_ready : in std_logic;

        write_addr : out std_logic_vector(18 downto 0) := (others => '0');
        write_en_blk1 : out std_logic := '0';
        write_en_blk2 : out std_logic := '0';
        write_data : out std_logic_vector(15 downto 0) := (others => '0')
    );
end entity in_out_mem_manager;

architecture rtl of in_out_mem_manager is
    type hidden_arr_t is array (0 to 383) of std_logic_vector(15 downto 0);
    signal hidden_arr : hidden_arr_t := (others => (others => '0'));
    signal hidden_data_buffer_value : std_logic_vector(15 downto 0) := (others => '0');
    signal hidden_buffer_valid : valid_t := INVALID;

    type read_blk_t is (INPUT, BLOCK1, BLOCK2);
    signal read_blk : read_blk_t := INPUT;

    type read_mode_t is (NORMAL, REVERSED);
    signal read_mode : read_mode_t := NORMAL;

    signal read_chunk_index : natural range 0 to CHUNCK_SIZE - 1 := 0;
    signal write_chunk_index : natural range 0 to CHUNCK_SIZE - 1 := 0;
    signal reset_write_chunk_index : boolean := false;

    -- Make an object containing count data, valid, and last
    type counter_info_t is record
        data : std_logic_vector(8 downto 0);
        valid : valid_t;
        last : last_t;
    end record counter_info_t;

    -- Shift register to hold the counter info
    type counter_info_arr_t is array (0 to LATENCY - 1) of counter_info_t;
    signal counter_info_arr : counter_info_arr_t := (others => (data => (others => '0'), valid => INVALID, last => NOT_LAST));

    type write_out_type is (IDLE, WAITING, WRITING, FINISHED);
    signal write_out_state : write_out_type := IDLE;

    signal inference_data : inference_data_t := (layer_info => LAYER1, last_inf => false);
    signal current_layer : layer_info_t := LAYER1;
    signal last_inference : boolean := false;
begin

    inference_data <= slv_to_inference_data(s_axis_counter_user);
    current_layer <= inference_data.layer_info;
    last_inference <= inference_data.last_inf;

    -- Read mode
    process(current_layer)
    begin
        case current_layer is
            when LAYER1 =>
                read_mode <= NORMAL;
            when LAYER2 =>
                read_mode <= REVERSED;
            when LAYER3 =>
                read_mode <= NORMAL;
            when LAYER4 =>
                read_mode <= REVERSED;
            when LAYER5 =>
                read_mode <= NORMAL;
            when others =>
                read_mode <= NORMAL;
        end case;
    end process;
    
    process(clk)
        variable write_counter : unsigned(8 downto 0) := (others => '0');
        variable prev_counter : std_logic_vector(8 downto 0) := (others => '0');
    begin
        if rising_edge(clk) then
            if (write_out_state = IDLE) then
                if hidden_buffer_valid = VALID then
                    s_axis_counter_ready <= m_axis_pes_ready;
                else
                    if hidden_swap_valid = '1' then
                        s_axis_counter_ready <= m_axis_pes_ready;
                    else
                        s_axis_counter_ready <= '0';
                    end if;
                end if;
            end if;

            -- PE output
            if (write_out_state = WAITING) then
                s_axis_counter_ready <= '0';
                s_axis_pe_ready <= '1';
                if (s_axis_pe_valid = '1') then
                    for i in 0 to 383 loop
                        write_out_state <= WRITING;
                        hidden_buffer_valid <= VALID;
                        hidden_arr(i) <= s_axis_pe_data(16 * i + 15 downto 16 * i);
                    end loop;
                end if;
            end if;

            if (write_out_state = WRITING) then
                s_axis_pe_ready <= '0';
                s_axis_counter_ready <= '1';

                if (not (last_inference and hidden_dram_ready = '0')) then
                    write_addr <= std_logic_vector(to_unsigned(write_chunk_index, clogb2(CHUNCK_SIZE))) & std_logic_vector(write_counter);
                    write_data <= hidden_arr(to_integer(unsigned(write_counter)));

                    if (current_layer = LAYER2 or current_layer = LAYER4) then
                        m_axis_output_data <= (others => '0');
                        m_axis_output_valid <= '0';
                        m_axis_output_last <= '0';

                        write_en_blk1 <= '0';
                        write_en_blk2 <= '1';
                    elsif (current_layer = LAYER1 or current_layer = LAYER3) then
                        m_axis_output_data <= (others => '0');
                        m_axis_output_valid <= '0';
                        m_axis_output_last <= '0';

                        write_en_blk1 <= '1';
                        write_en_blk2 <= '0';
                    elsif (current_layer = LAYER5) then
                        m_axis_output_data <= hidden_arr(to_integer(unsigned(write_counter)));
                        m_axis_output_valid <= '1';

                        if (last_inference) then
                            m_axis_output_last <= '1';
                        else
                            m_axis_output_last <= '0';
                        end if;

                        write_en_blk1 <= '0';
                        write_en_blk2 <= '0';
                    end if;

                    -- If it is the last inference, then send the hidden data to the DRAM
                    if (last_inference) then
                        hidden_dram_data <= hidden_arr(to_integer(unsigned(write_counter)));
                        hidden_dram_valid <= '1';
                        hidden_dram_dest <= std_logic_vector(write_counter);
                    else
                        hidden_dram_valid <= '0';
                        hidden_dram_data <= (others => '0');
                        hidden_dram_dest <= (others => '0');
                    end if;

                    if (current_layer = LAYER5) then
                        m_axis_output_data <= hidden_arr(to_integer(unsigned(write_counter)));
                        m_axis_output_valid <= '1';
                    else 
                        m_axis_output_data <= (others => '0');
                        m_axis_output_valid <= '0';
                    end if;

                    if (write_counter = 383) then
                        write_out_state <= IDLE;

                        if (last_inference) then
                            hidden_buffer_valid <= INVALID;
                        end if;

                        if (current_layer = LAYER5) then
                            m_axis_output_last <= '1';
                        else
                            m_axis_output_last <= '0';
                        end if;

                        if (reset_write_chunk_index = true) then
                            write_chunk_index <= 0;
                            reset_write_chunk_index <= false;
                        else 
                            write_chunk_index <= write_chunk_index + 1;
                        end if;

                        write_counter := (others => '0');
                    else
                        write_counter := write_counter + 1;
                        m_axis_output_last <= '0';
                    end if;
                end if;
            else 
                hidden_dram_valid <= '0';
                hidden_dram_data <= (others => '0');
                hidden_dram_dest <= (others => '0');

                s_axis_pe_ready <= '1';        

                m_axis_output_data <= (others => '0');
                m_axis_output_valid <= '0';
                m_axis_output_last <= '0';
                
                write_addr <= (others => '0');
                write_data <= (others => '0');
                write_en_blk1 <= '0';
                write_en_blk2 <= '0';
            end if;
            
            -- Counter info shift register
            counter_info_arr(0) <= (data => s_axis_counter_data, valid => sl_to_valid(s_axis_counter_valid), last => slv_to_last(s_axis_counter_last));
            for i in 1 to LATENCY - 1 loop
                counter_info_arr(i) <= counter_info_arr(i - 1);

                if (i = LATENCY - 1) then
                    if (counter_info_arr(i).valid = VALID) then
                        m_axis_pes_valid <= '1';

                        -- The hidden data can be sent
                        if (hidden_buffer_valid = VALID) then
                            hidden_data_buffer_value <= hidden_arr(to_integer(unsigned(counter_info_arr(i).data)));
                        else
                            hidden_data_buffer_value <= (others => '0');
                        end if;
                    else
                        hidden_data_buffer_value <= (others => '0');
                        m_axis_pes_valid <= '0';
                    end if;

                    if (counter_info_arr(i).last = LAYER_LAST) then
                        reset_write_chunk_index <= true;
                        read_chunk_index <= 0;
                        m_axis_pes_last <= '1';
                        write_out_state <= WAITING;
                    elsif (counter_info_arr(i).last = SEQ_LAST) then
                        read_chunk_index <= read_chunk_index + 1;
                        m_axis_pes_last <= '1';
                        write_out_state <= WAITING;
                    else
                        m_axis_pes_last <= '0';
                    end if;
                end if;
            end loop;


            -- Has to be placed here to avoid multiple drivers
            if (write_out_state = FINISHED and reset_write_chunk_index = true) then

            end if;

            -- Read process
            if (s_axis_counter_valid = '1') then
                if (read_mode = NORMAL) then
                    read_addr <= std_logic_vector(to_unsigned(read_chunk_index, clogb2(CHUNCK_SIZE))) & s_axis_counter_data;
                elsif (read_mode = REVERSED) then
                    read_addr <= std_logic_vector(to_unsigned(read_chunk_index, clogb2(CHUNCK_SIZE))) & std_logic_vector(to_unsigned(383 - to_integer(unsigned(s_axis_counter_data)), 9));
                end if;

                if (current_layer = LAYER3 or current_layer = LAYER5) then

                    read_blk <= BLOCK1;
                    read_en_blk1 <= '1';
                    read_en_blk2 <= '0';
                elsif (current_layer = LAYER2 or current_layer = LAYER4) then
                    read_blk <= BLOCK2;
                    read_en_blk1 <= '0';
                    read_en_blk2 <= '1';
                else
                    read_blk <= INPUT;

                    if prev_counter /= s_axis_counter_data then
                        s_axis_input_ready <= '1';
                        prev_counter := s_axis_counter_data;
                    else
                        s_axis_input_ready <= '0';
                    end if;

                    read_en_blk1 <= '0';
                    read_en_blk2 <= '0';
                end if;

                if (hidden_buffer_valid = INVALID) then
                    read_addr_hidden <= s_axis_counter_data;
                    read_en_hidden <= '1';
                else
                    read_en_hidden <= '0';
                    read_addr_hidden <= (others => '0');
                end if;
            else
                read_en_blk1 <= '0';
                read_en_blk2 <= '0';
                read_en_hidden <= '0';
                read_addr <= (others => '0');
                read_addr_hidden <= (others => '0');
                s_axis_input_ready <= '0';
            end if;
        end if;
    end process;

    -- Read mux
    process(read_blk, read_data_blk1, read_data_blk2, s_axis_input_data,
            hidden_buffer_valid, hidden_data_buffer_value, read_data_hidden)
    begin
        case read_blk is
            when BLOCK1 =>
                m_axis_input_data <= read_data_blk1;
            when BLOCK2 =>
                m_axis_input_data <= read_data_blk2;
            when INPUT =>
                m_axis_input_data <= s_axis_input_data;
            when others =>
                m_axis_input_data <= (others => '0');
        end case;

        if (hidden_buffer_valid = VALID) then
            m_axis_hidden_data <= hidden_data_buffer_value;
        else
            m_axis_hidden_data <= read_data_hidden;
        end if;
    end process;
end architecture rtl;