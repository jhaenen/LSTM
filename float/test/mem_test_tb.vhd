library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity mem_test_tb is
end entity;

architecture behav of mem_test_tb is
    component weight_mem_test is
        port (
          i_in_waddr : in STD_LOGIC_VECTOR ( 8 downto 0 );
          clk : in STD_LOGIC;
          i_in_data_in : in STD_LOGIC_VECTOR ( 3071 downto 0 );
          i_in_we : in STD_LOGIC_VECTOR ( 0 to 0 );
          i_in_raddr : in STD_LOGIC_VECTOR ( 8 downto 0 );
          i_in_data_out : out STD_LOGIC_VECTOR ( 3071 downto 0 );
          i_in_re : in STD_LOGIC
        );
    end component weight_mem_test;

    

    constant clk_period : time := 10 ns;

    signal i_in_waddr : STD_LOGIC_VECTOR ( 8 downto 0 ) := (others => '0');
    signal clk : STD_LOGIC := '0';
    signal i_in_data_in : STD_LOGIC_VECTOR ( 3071 downto 0 ) := (others => '0');
    signal i_in_we : STD_LOGIC_VECTOR ( 0 to 0 ) := (others => '0');
    signal i_in_raddr : STD_LOGIC_VECTOR ( 8 downto 0 ) := (others => '0');
    signal i_in_data_out : STD_LOGIC_VECTOR ( 3071 downto 0 );
    signal i_in_re : STD_LOGIC := '0';

    type explain_t is (NOTHING, WRITING, READING);
    signal explain : explain_t := NOTHING;
begin
    

    -- Test process
    process
        variable seed1, seed2 : integer := 999;

        impure function rand_slv(len : integer) return std_logic_vector is
            variable r : real;
            variable slv : std_logic_vector(len - 1 downto 0);
        begin
            for i in slv'range loop
            uniform(seed1, seed2, r);
            if r > 0.5 then
                slv(i) := '1';
            else
                slv(i) := '0';
            end if;
            end loop;
            return slv;
        end function;

    begin
        wait for clk_period * 10;

        explain <= WRITING;

        -- Set write address to 0
        i_in_waddr <= std_logic_vector(to_unsigned(0, 9));
        -- Set write enable to 1
        i_in_we <= "1";
        -- Set read address to 0
        i_in_raddr <= std_logic_vector(to_unsigned(0, 9));
        -- Set read enable to 0
        i_in_re <= '0';
        -- Set data in to random
        i_in_data_in <= rand_slv(3072);

        -- Wait for 1 clock cycle
        wait for clk_period;


        -- Set write address to 10
        i_in_waddr <= std_logic_vector(to_unsigned(10, 9));
        -- Set write enable to 1
        i_in_we <= "1";
        -- Set data in to random
        i_in_data_in <= rand_slv(3072);

        -- Wait for 1 clock cycle
        wait for clk_period;

        explain <= READING;

        -- Set write address to 0
        i_in_waddr <= std_logic_vector(to_unsigned(0, 9));
        -- Set write enable to 0
        i_in_we <= "0";
        -- Set data to 0
        i_in_data_in <= (others => '0');
        
        -- Set read address to 0
        i_in_raddr <= std_logic_vector(to_unsigned(0, 9));
        -- Set read enable to 1
        i_in_re <= '1';

        -- Wait for 1 clock cycle
        wait for clk_period * 1;

        -- Set read address to 10
        i_in_raddr <= std_logic_vector(to_unsigned(10, 9));
        -- Set read enable to 1
        i_in_re <= '1';

        -- Wait for 1 clock cycle
        wait for clk_period * 2;

        explain <= NOTHING;

        -- Set read address to 0
        i_in_raddr <= std_logic_vector(to_unsigned(0, 9));
        -- Set read enable to 0
        i_in_re <= '0';

        wait;

    end process;
    

    -- Clock process
    process
    begin
        wait for clk_period / 2;
        clk <= not clk;
    end process;

    -- Instantiate the Device Under Test (DUT)
    dut: weight_mem_test port map (
          i_in_waddr => i_in_waddr,
          clk => clk,
          i_in_data_in => i_in_data_in,
          i_in_we => i_in_we,
          i_in_raddr => i_in_raddr,
          i_in_data_out => i_in_data_out,
          i_in_re => i_in_re
        );

end architecture behav;