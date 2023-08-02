library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.util_pkg.all;

entity in_out_mem_manager is
    generic (
        LATENCY : natural := 2
    );
    port (
        clk : in std_logic;

        -- control
        s_axis_counter_data : in std_logic_vector(8 downto 0);
        s_axis_counter_valid : in std_logic;
        s_axis_counter_ready : out std_logic := '1';
        s_axis_counter_last : in std_logic_vector(1 downto 0);
        s_axis_counter_user : in std_logic_vector(2 downto 0);

        -- data out
        m_axis_pes_ready : in std_logic;
        m_axis_pes_valid : out std_logic;
        m_axis_pes_last : out std_logic;

        m_axis_input_data : out std_logic_vector(15 downto 0);
        m_axis_hidden_data : out std_logic_vector(15 downto 0);

        -- Memory
        read_addr : out std_logic_vector(18 downto 0);
        read_en_blk1 : out std_logic;
        read_en_blk2 : out std_logic;
        read_data : in std_logic_vector(15 downto 0);

        write_addr : out std_logic_vector(18 downto 0);
        write_en_blk1 : out std_logic;
        write_en_blk2 : out std_logic;
        write_data : out std_logic_vector(15 downto 0)
    );
end entity in_out_mem_manager;

architecture rtl of in_out_mem_manager is
    type hidden_arr_t is array (0 to 383) of std_logic_vector(15 downto 0);
    signal hidden_arr : hidden_arr_t := (others => (others => '0'));

    type read_blk_t is (INPUT_BLOCK, BLOCK1, BLOCK2);
    signal read_blk : read_blk_t := INPUT_BLOCK;

    signal chunk_index : unsigned(9 downto 0) := (others => '0');

    -- Make an object containing count data, valid, and last
    type valid_t is (INVALID, VALID);
    type last_t is (NOT_LAST, SEQ_LAST, LAYER_LAST);
    type counter_info_t is record
        data : std_logic_vector(8 downto 0);
        valid : valid_t;
        last : last_t;
    end record counter_info_t;

    -- Shift register to hold the counter info
    type counter_info_arr_t is array (0 to LATENCY - 1) of counter_info_t;
    signal counter_info_arr : counter_info_arr_t := (others => (data => (others => '0'), valid => INVALID, last => NOT_LAST));
begin
    -- Counter info shift register
    process(clk)
    begin
        if rising_edge(clk) then
            counter_info_arr(0) <= (data => s_axis_counter_data, valid => VALID, last => slv_to_last(s_axis_counter_last));
            for i in 1 to LATENCY - 1 loop
                counter_info_arr(i) <= counter_info_arr(i - 1);
            end loop;
        end if;
    end process;

    -- Read process
    process(clk)
        variable current_layer : layer_info_t;
    begin
        if rising_edge(clk) then
            if (s_axis_counter_valid = '1') then
                current_layer := slv_to_layer_info(s_axis_counter_user);

                read_addr <= std_logic_vector(chunk_index) & s_axis_counter_data;

                if (current_layer = LAYER2 or current_layer = LAYER4) then
                    read_en_blk1 <= '1';
                    read_en_blk2 <= '0';
                elsif (current_layer = LAYER3 or current_layer = LAYER5) then
                    read_en_blk1 <= '0';
                    read_en_blk2 <= '1';
                else
                    read_en_blk1 <= '0';
                    read_en_blk2 <= '0';
                end if;
            end if;
        end if;
    end process;
end architecture rtl;