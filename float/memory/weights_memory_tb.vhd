library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity weights_memory_tb is
end entity weights_memory_tb;

architecture sim of weights_memory_tb is
    component weights_memory is
        port (
          clk : in STD_LOGIC;
          m_axis_f_hid_weight_data : out STD_LOGIC_VECTOR ( 6143 downto 0 );
          m_axis_f_in_weight_data : out STD_LOGIC_VECTOR ( 6143 downto 0 );
          m_axis_g_hid_weight_data : out STD_LOGIC_VECTOR ( 6143 downto 0 );
          m_axis_g_in_weight_data : out STD_LOGIC_VECTOR ( 6143 downto 0 );
          m_axis_i_hid_weight_data : out STD_LOGIC_VECTOR ( 6143 downto 0 );
          m_axis_i_in_weight_data : out STD_LOGIC_VECTOR ( 6143 downto 0 );
          m_axis_o_hid_weight_data : out STD_LOGIC_VECTOR ( 6143 downto 0 );
          m_axis_o_in_weight_data : out STD_LOGIC_VECTOR ( 6143 downto 0 );
          m_axis_pes_last : out STD_LOGIC;
          m_axis_pes_ready : in STD_LOGIC;
          m_axis_pes_valid : out STD_LOGIC;
          s_axis_counter_data : in STD_LOGIC_VECTOR ( 8 downto 0 );
          s_axis_counter_last : in STD_LOGIC_VECTOR ( 1 downto 0 );
          s_axis_counter_valid : in STD_LOGIC;
          s_axis_counter_ready : out STD_LOGIC;
          s_axis_write_bus_data : in STD_LOGIC_VECTOR ( 6143 downto 0 );
          s_axis_write_bus_dest : in STD_LOGIC_VECTOR ( 8 downto 0 );
          s_axis_write_bus_last : in STD_LOGIC;
          s_axis_write_bus_user : in STD_LOGIC_VECTOR ( 2 downto 0 );
          s_axis_write_bus_valid : in STD_LOGIC;
          s_axis_write_bus_ready : out STD_LOGIC
        );
    end component weights_memory;

    constant clk_period : time := 10 ns;

    signal clk : std_logic := '0';
    signal m_axis_f_hid_weight_data : std_logic_vector (6143 downto 0) := (others => '0');
    signal m_axis_f_in_weight_data : std_logic_vector (6143 downto 0) := (others => '0');
    signal m_axis_g_hid_weight_data : std_logic_vector (6143 downto 0) := (others => '0');
    signal m_axis_g_in_weight_data : std_logic_vector (6143 downto 0) := (others => '0');
    signal m_axis_i_hid_weight_data : std_logic_vector (6143 downto 0) := (others => '0');
    signal m_axis_i_in_weight_data : std_logic_vector (6143 downto 0) := (others => '0');
    signal m_axis_o_hid_weight_data : std_logic_vector (6143 downto 0) := (others => '0');
    signal m_axis_o_in_weight_data : std_logic_vector (6143 downto 0) := (others => '0');
    signal m_axis_pes_last : std_logic := '0';
    signal m_axis_pes_ready : std_logic := '1';
    signal m_axis_pes_valid : std_logic := '0';

    signal s_axis_counter_data : std_logic_vector (8 downto 0) := (others => '0');
    signal s_axis_counter_last : std_logic_vector (1 downto 0) := (others => '0');
    signal s_axis_counter_valid : std_logic := '0';
    signal s_axis_counter_ready : std_logic := '0';

    signal s_axis_write_bus_data : std_logic_vector (6143 downto 0) := (others => '0');
    signal s_axis_write_bus_dest : std_logic_vector (8 downto 0) := (others => '0');
    signal s_axis_write_bus_last : std_logic := '0';
    signal s_axis_write_bus_user : weight_dest_t := I_INPUT;
    signal s_axis_write_bus_valid : std_logic := '0';
    signal s_axis_write_bus_ready : std_logic := '0';

begin
        -- Testbench process
    process
    begin
        wait for clk_period * 10;

        -- First we write 8 weights to each weight memory
        -- First byte we write is corresponding to the first the weight memory the rest are incremented by 1 each write
        s_axis_write_bus_user <= I_INPUT;
        s_axis_write_bus_valid <= '1';
        s_axis_write_bus_last <= '0';
        -- Loop 8 times
        for i in 0 to 7 loop 
            -- Set the uppper nibble to 0x0
            s_axis_write_bus_data(6143 downto 6140) <= std_logic_vector(to_unsigned(0, 4));

            -- loop over every remaining nibble and set it to the current loop index
            for j in (6140/4) - 1 downto 0 loop
                s_axis_write_bus_data(j*4+3 downto j*4) <= std_logic_vector(to_unsigned(i, 4));
            end loop;

            -- Set the destination to the current loop index
            s_axis_write_bus_dest <= std_logic_vector(to_unsigned(i, 9));
            
            wait for clk_period;
        end loop;

        s_axis_write_bus_user <= I_HIDDEN;
        s_axis_write_bus_valid <= '1';
        s_axis_write_bus_last <= '0';
        -- Loop 8 times
        for i in 0 to 7 loop 
            -- Set the uppper nibble to 0x0
            s_axis_write_bus_data(6143 downto 6140) <= std_logic_vector(to_unsigned(1, 4));

            -- loop over every remaining nibble and set it to the current loop index
            for j in (6140/4) - 1 downto 0 loop
                s_axis_write_bus_data(j*4+3 downto j*4) <= std_logic_vector(to_unsigned(i, 4));
            end loop;

            -- Set the destination to the current loop index
            s_axis_write_bus_dest <= std_logic_vector(to_unsigned(i, 9));
            
            wait for clk_period;
        end loop;

        s_axis_write_bus_user <= F_INPUT;
        s_axis_write_bus_valid <= '1';
        s_axis_write_bus_last <= '0';
        -- Loop 8 times
        for i in 0 to 7 loop 
            -- Set the uppper nibble to 0x0
            s_axis_write_bus_data(6143 downto 6140) <= std_logic_vector(to_unsigned(2, 4));

            -- loop over every remaining nibble and set it to the current loop index
            for j in (6140/4) - 1 downto 0 loop
                s_axis_write_bus_data(j*4+3 downto j*4) <= std_logic_vector(to_unsigned(i, 4));
            end loop;

            -- Set the destination to the current loop index
            s_axis_write_bus_dest <= std_logic_vector(to_unsigned(i, 9));
            
            wait for clk_period;
        end loop;

        s_axis_write_bus_user <= F_HIDDEN;
        s_axis_write_bus_valid <= '1';
        s_axis_write_bus_last <= '0';
        -- Loop 8 times
        for i in 0 to 7 loop 
            -- Set the uppper nibble to 0x0
            s_axis_write_bus_data(6143 downto 6140) <= std_logic_vector(to_unsigned(3, 4));

            -- loop over every remaining nibble and set it to the current loop index
            for j in (6140/4) - 1 downto 0 loop
                s_axis_write_bus_data(j*4+3 downto j*4) <= std_logic_vector(to_unsigned(i, 4));
            end loop;

            -- Set the destination to the current loop index
            s_axis_write_bus_dest <= std_logic_vector(to_unsigned(i, 9));
            
            wait for clk_period;
        end loop;

        s_axis_write_bus_user <= G_INPUT;
        s_axis_write_bus_valid <= '1';
        s_axis_write_bus_last <= '0';
        -- Loop 8 times
        for i in 0 to 7 loop 
            -- Set the uppper nibble to 0x0
            s_axis_write_bus_data(6143 downto 6140) <= std_logic_vector(to_unsigned(4, 4));

            -- loop over every remaining nibble and set it to the current loop index
            for j in (6140/4) - 1 downto 0 loop
                s_axis_write_bus_data(j*4+3 downto j*4) <= std_logic_vector(to_unsigned(i, 4));
            end loop;

            -- Set the destination to the current loop index
            s_axis_write_bus_dest <= std_logic_vector(to_unsigned(i, 9));
            
            wait for clk_period;
        end loop;

        s_axis_write_bus_user <= G_HIDDEN;
        s_axis_write_bus_valid <= '1';
        s_axis_write_bus_last <= '0';
        -- Loop 8 times
        for i in 0 to 7 loop 
            -- Set the uppper nibble to 0x0
            s_axis_write_bus_data(6143 downto 6140) <= std_logic_vector(to_unsigned(5, 4));

            -- loop over every remaining nibble and set it to the current loop index
            for j in (6140/4) - 1 downto 0 loop
                s_axis_write_bus_data(j*4+3 downto j*4) <= std_logic_vector(to_unsigned(i, 4));
            end loop;

            -- Set the destination to the current loop index
            s_axis_write_bus_dest <= std_logic_vector(to_unsigned(i, 9));
            
            wait for clk_period;
        end loop;

        s_axis_write_bus_user <= O_INPUT;
        s_axis_write_bus_valid <= '1';
        s_axis_write_bus_last <= '0';
        -- Loop 8 times
        for i in 0 to 7 loop 
            -- Set the uppper nibble to 0x0
            s_axis_write_bus_data(6143 downto 6140) <= std_logic_vector(to_unsigned(6, 4));

            -- loop over every remaining nibble and set it to the current loop index
            for j in (6140/4) - 1 downto 0 loop
                s_axis_write_bus_data(j*4+3 downto j*4) <= std_logic_vector(to_unsigned(i, 4));
            end loop;

            -- Set the destination to the current loop index
            s_axis_write_bus_dest <= std_logic_vector(to_unsigned(i, 9));
            
            wait for clk_period;
        end loop;

        s_axis_write_bus_user <= O_HIDDEN;
        s_axis_write_bus_valid <= '1';
        s_axis_write_bus_last <= '0';
        -- Loop 8 times
        for i in 0 to 7 loop 
            -- Set the uppper nibble to 0x0
            s_axis_write_bus_data(6143 downto 6140) <= std_logic_vector(to_unsigned(7, 4));

            -- loop over every remaining nibble and set it to the current loop index
            for j in (6140/4) - 1 downto 0 loop
                s_axis_write_bus_data(j*4+3 downto j*4) <= std_logic_vector(to_unsigned(i, 4));
            end loop;

            -- Set the destination to the current loop index
            s_axis_write_bus_dest <= std_logic_vector(to_unsigned(i, 9));

            if i = 7 then
                s_axis_write_bus_last <= '1';
            end if;
            
            wait for clk_period;
        end loop;

        -- Reset the write bus
        s_axis_write_bus_user <= I_INPUT;
        s_axis_write_bus_valid <= '0';
        s_axis_write_bus_last <= '0';
        s_axis_write_bus_data <= (others => '0');
        s_axis_write_bus_dest <= (others => '0');
        
        wait for clk_period;

        s_axis_counter_valid <= '1';
        s_axis_counter_last <= "00";

        for i in 0 to 7 loop
            s_axis_counter_data <= std_logic_vector(to_unsigned(i, 9));

            if i = 7 then
                s_axis_counter_last <= "01";
            end if;
            wait for clk_period;
        end loop;

        s_axis_counter_data <= (others => '0');
        s_axis_counter_valid <= '0';
        s_axis_counter_last <= "00";

        -- First we write 8 weights to each weight memory
        -- First byte we write is corresponding to the first the weight memory the rest are incremented by 1 each write
        s_axis_write_bus_user <= I_INPUT;
        s_axis_write_bus_valid <= '1';
        s_axis_write_bus_last <= '0';
        -- Loop 8 times
        for i in 0 to 7 loop 
            -- Set the uppper nibble to 0x0
            s_axis_write_bus_data(6143 downto 6140) <= std_logic_vector(to_unsigned(8, 4));

            -- loop over every remaining nibble and set it to the current loop index
            for j in (6140/4) - 1 downto 0 loop
                s_axis_write_bus_data(j*4+3 downto j*4) <= std_logic_vector(to_unsigned(i, 4));
            end loop;

            -- Set the destination to the current loop index
            s_axis_write_bus_dest <= std_logic_vector(to_unsigned(i, 9));
            
            wait for clk_period;
        end loop;

        s_axis_write_bus_user <= I_HIDDEN;
        s_axis_write_bus_valid <= '1';
        s_axis_write_bus_last <= '0';
        -- Loop 8 times
        for i in 0 to 7 loop 
            -- Set the uppper nibble to 0x0
            s_axis_write_bus_data(6143 downto 6140) <= std_logic_vector(to_unsigned(9, 4));

            -- loop over every remaining nibble and set it to the current loop index
            for j in (6140/4) - 1 downto 0 loop
                s_axis_write_bus_data(j*4+3 downto j*4) <= std_logic_vector(to_unsigned(i, 4));
            end loop;

            -- Set the destination to the current loop index
            s_axis_write_bus_dest <= std_logic_vector(to_unsigned(i, 9));
            
            wait for clk_period;
        end loop;

        s_axis_write_bus_user <= F_INPUT;
        s_axis_write_bus_valid <= '1';
        s_axis_write_bus_last <= '0';
        -- Loop 8 times
        for i in 0 to 7 loop 
            -- Set the uppper nibble to 0x0
            s_axis_write_bus_data(6143 downto 6140) <= std_logic_vector(to_unsigned(10, 4));

            -- loop over every remaining nibble and set it to the current loop index
            for j in (6140/4) - 1 downto 0 loop
                s_axis_write_bus_data(j*4+3 downto j*4) <= std_logic_vector(to_unsigned(i, 4));
            end loop;

            -- Set the destination to the current loop index
            s_axis_write_bus_dest <= std_logic_vector(to_unsigned(i, 9));
            
            wait for clk_period;
        end loop;

        s_axis_write_bus_user <= F_HIDDEN;
        s_axis_write_bus_valid <= '1';
        s_axis_write_bus_last <= '0';
        -- Loop 8 times
        for i in 0 to 7 loop 
            -- Set the uppper nibble to 0x0
            s_axis_write_bus_data(6143 downto 6140) <= std_logic_vector(to_unsigned(11, 4));

            -- loop over every remaining nibble and set it to the current loop index
            for j in (6140/4) - 1 downto 0 loop
                s_axis_write_bus_data(j*4+3 downto j*4) <= std_logic_vector(to_unsigned(i, 4));
            end loop;

            -- Set the destination to the current loop index
            s_axis_write_bus_dest <= std_logic_vector(to_unsigned(i, 9));
            
            wait for clk_period;
        end loop;

        s_axis_write_bus_user <= G_INPUT;
        s_axis_write_bus_valid <= '1';
        s_axis_write_bus_last <= '0';
        -- Loop 8 times
        for i in 0 to 7 loop 
            -- Set the uppper nibble to 0x0
            s_axis_write_bus_data(6143 downto 6140) <= std_logic_vector(to_unsigned(12, 4));

            -- loop over every remaining nibble and set it to the current loop index
            for j in (6140/4) - 1 downto 0 loop
                s_axis_write_bus_data(j*4+3 downto j*4) <= std_logic_vector(to_unsigned(i, 4));
            end loop;

            -- Set the destination to the current loop index
            s_axis_write_bus_dest <= std_logic_vector(to_unsigned(i, 9));
            
            wait for clk_period;
        end loop;

        s_axis_write_bus_user <= G_HIDDEN;
        s_axis_write_bus_valid <= '1';
        s_axis_write_bus_last <= '0';
        -- Loop 8 times
        for i in 0 to 7 loop 
            -- Set the uppper nibble to 0x0
            s_axis_write_bus_data(6143 downto 6140) <= std_logic_vector(to_unsigned(13, 4));

            -- loop over every remaining nibble and set it to the current loop index
            for j in (6140/4) - 1 downto 0 loop
                s_axis_write_bus_data(j*4+3 downto j*4) <= std_logic_vector(to_unsigned(i, 4));
            end loop;

            -- Set the destination to the current loop index
            s_axis_write_bus_dest <= std_logic_vector(to_unsigned(i, 9));
            
            wait for clk_period;
        end loop;

        s_axis_write_bus_user <= O_INPUT;
        s_axis_write_bus_valid <= '1';
        s_axis_write_bus_last <= '0';
        -- Loop 8 times
        for i in 0 to 7 loop 
            -- Set the uppper nibble to 0x0
            s_axis_write_bus_data(6143 downto 6140) <= std_logic_vector(to_unsigned(14, 4));

            -- loop over every remaining nibble and set it to the current loop index
            for j in (6140/4) - 1 downto 0 loop
                s_axis_write_bus_data(j*4+3 downto j*4) <= std_logic_vector(to_unsigned(i, 4));
            end loop;

            -- Set the destination to the current loop index
            s_axis_write_bus_dest <= std_logic_vector(to_unsigned(i, 9));
            
            wait for clk_period;
        end loop;

        s_axis_write_bus_user <= O_HIDDEN;
        s_axis_write_bus_valid <= '1';
        s_axis_write_bus_last <= '0';
        -- Loop 8 times
        for i in 0 to 7 loop 
            -- Set the uppper nibble to 0x0
            s_axis_write_bus_data(6143 downto 6140) <= std_logic_vector(to_unsigned(15, 4));

            -- loop over every remaining nibble and set it to the current loop index
            for j in (6140/4) - 1 downto 0 loop
                s_axis_write_bus_data(j*4+3 downto j*4) <= std_logic_vector(to_unsigned(i, 4));
            end loop;

            -- Set the destination to the current loop index
            s_axis_write_bus_dest <= std_logic_vector(to_unsigned(i, 9));

            if i = 7 then
                s_axis_write_bus_last <= '1';
            end if;
            
            wait for clk_period;
        end loop;

        -- Reset the write bus
        s_axis_write_bus_user <= I_INPUT;
        s_axis_write_bus_valid <= '0';
        s_axis_write_bus_last <= '0';
        s_axis_write_bus_data <= (others => '0');
        s_axis_write_bus_dest <= (others => '0');

        wait for clk_period;


        s_axis_counter_valid <= '1';
        s_axis_counter_last <= "00";

        for i in 0 to 7 loop
            s_axis_counter_data <= std_logic_vector(to_unsigned(i, 9));

            if i = 7 then
                s_axis_counter_last <= "11";
            end if;
            wait for clk_period;
        end loop;

        s_axis_counter_data <= (others => '0');
        s_axis_counter_valid <= '0';
        s_axis_counter_last <= "00";

        wait for clk_period * 10;

        s_axis_counter_valid <= '1';
        s_axis_counter_last <= "00";

        for i in 0 to 7 loop
            s_axis_counter_data <= std_logic_vector(to_unsigned(i, 9));

            if i = 7 then
                s_axis_counter_last <= "11";
            end if;
            wait for clk_period;
        end loop;

        s_axis_counter_data <= (others => '0');
        s_axis_counter_valid <= '0';
        s_axis_counter_last <= "00";

        wait;
    end process;

    -- Clock process
    process
    begin
        wait for clk_period / 2;
        clk <= not clk;
    end process;
    
    uut: weights_memory port map (
        clk => clk,
        m_axis_f_hid_weight_data => m_axis_f_hid_weight_data,
        m_axis_f_in_weight_data => m_axis_f_in_weight_data,
        m_axis_g_hid_weight_data => m_axis_g_hid_weight_data,
        m_axis_g_in_weight_data => m_axis_g_in_weight_data,
        m_axis_i_hid_weight_data => m_axis_i_hid_weight_data,
        m_axis_i_in_weight_data => m_axis_i_in_weight_data,
        m_axis_o_hid_weight_data => m_axis_o_hid_weight_data,
        m_axis_o_in_weight_data => m_axis_o_in_weight_data,
        m_axis_pes_last => m_axis_pes_last,
        m_axis_pes_ready => m_axis_pes_ready,
        m_axis_pes_valid => m_axis_pes_valid,
        s_axis_counter_data => s_axis_counter_data,
        s_axis_counter_last => s_axis_counter_last,
        s_axis_counter_valid => s_axis_counter_valid,
        s_axis_counter_ready => s_axis_counter_ready,
        s_axis_write_bus_data => s_axis_write_bus_data,
        s_axis_write_bus_dest => s_axis_write_bus_dest,
        s_axis_write_bus_last => s_axis_write_bus_last,
        s_axis_write_bus_user => weight_dest_to_slv(s_axis_write_bus_user),
        s_axis_write_bus_valid => s_axis_write_bus_valid,
        s_axis_write_bus_ready => s_axis_write_bus_ready
    );   
    
end architecture sim;