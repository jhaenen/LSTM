library ieee;
use ieee.std_logic_1164.all;

entity mem_manager is
    port (
        clk : in std_logic;
        rst : in std_logic;

        data_in : in std_logic_vector(63 downto 0);

        data_out_0 : out std_logic_vector(15 downto 0);
        data_out_1 : out std_logic_vector(15 downto 0);
        data_out_2 : out std_logic_vector(15 downto 0);
        data_out_3 : out std_logic_vector(15 downto 0);
        data_out_4 : out std_logic_vector(15 downto 0);
        data_out_5 : out std_logic_vector(15 downto 0);
        data_out_6 : out std_logic_vector(15 downto 0);
        data_out_7 : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of mem_manager is
    type weights_pe_arr_t is array (0 to 3) of std_logic_vector(15 downto 0);
    signal weights_pe1_array : weights_pe_arr_t;
    signal weights_pe2_array : weights_pe_arr_t;

    -- Create a state machine to handle the data loading of 2 states load_pe1 and load_pe2
    type state_t is (load_pe1, load_pe2);
    signal state : state_t := load_pe1;
begin
    process(clk, rst)
        
    begin
        if rst = '1' then
            weights_pe1_array(0) <= (others => '0');
            weights_pe1_array(1) <= (others => '0');
            weights_pe1_array(2) <= (others => '0');
            weights_pe1_array(3) <= (others => '0');
            weights_pe2_array(0) <= (others => '0');
            weights_pe2_array(1) <= (others => '0');
            weights_pe2_array(2) <= (others => '0');
            weights_pe2_array(3) <= (others => '0');

            state <= load_pe1;
        elsif rising_edge(clk) then
            case state is
                when load_pe1 =>
                    weights_pe1_array(0) <= data_in(15 downto 0);
                    weights_pe1_array(1) <= data_in(31 downto 16);
                    weights_pe1_array(2) <= data_in(47 downto 32);
                    weights_pe1_array(3) <= data_in(63 downto 48);
                    state <= load_pe2;
                when load_pe2 =>
                    weights_pe2_array(0) <= data_in(15 downto 0);
                    weights_pe2_array(1) <= data_in(31 downto 16);
                    weights_pe2_array(2) <= data_in(47 downto 32);
                    weights_pe2_array(3) <= data_in(63 downto 48);
                    state <= load_pe1;
            end case;
        end if;
    end process;

    data_out_0 <= weights_pe1_array(0);
    data_out_1 <= weights_pe1_array(1);
    data_out_2 <= weights_pe1_array(2);
    data_out_3 <= weights_pe1_array(3);
    data_out_4 <= weights_pe2_array(0);
    data_out_5 <= weights_pe2_array(1);
    data_out_6 <= weights_pe2_array(2);
    data_out_7 <= weights_pe2_array(3);

end architecture;