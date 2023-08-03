library ieee;
use ieee.std_logic_1164.all;

use work.types.all;

entity weight_mem_manager is
    generic (
        DEPTH : positive := 384;
        LATENCY : natural := 2
    );
    port (
        clk : in std_logic;

        -- control
        s_axis_counter_data : in std_logic_vector(8 downto 0);
        s_axis_counter_valid : in std_logic;
        s_axis_counter_ready : out std_logic := '0';
        s_axis_counter_last : in std_logic_vector(1 downto 0);

        -- Write bus
        s_axis_write_bus_data : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        s_axis_write_bus_valid : in std_logic;
        s_axis_write_bus_ready : out std_logic := '1';
        s_axis_write_bus_last : in std_logic;
        s_axis_write_bus_dest : in std_logic_vector(9 downto 0);
        s_axis_write_bus_user : in std_logic_vector(2 downto 0);

        -- Writing blocks
        mem_write_addr : out std_logic_vector(8 downto 0) := (others => '0');
        mem_write_data : out std_logic_vector((16 * DEPTH / 2) - 1 downto 0) := (others => '0');

        mem_raddr : out std_logic_vector(8 downto 0) := (others => '0');
        -- data block 1
        -- Writing
        mem_i_in_write_we_A_blk1 : out std_logic_vector(0 downto 0) := (others => '0');
        mem_i_in_write_we_B_blk1 : out std_logic_vector(0 downto 0) := (others => '0');

        mem_i_hid_write_we_A_blk1 : out std_logic_vector(0 downto 0) := (others => '0');
        mem_i_hid_write_we_B_blk1 : out std_logic_vector(0 downto 0) := (others => '0');

        mem_f_in_write_we_A_blk1 : out std_logic_vector(0 downto 0) := (others => '0');
        mem_f_in_write_we_B_blk1 : out std_logic_vector(0 downto 0) := (others => '0');

        mem_f_hid_write_we_A_blk1 : out std_logic_vector(0 downto 0) := (others => '0');
        mem_f_hid_write_we_B_blk1 : out std_logic_vector(0 downto 0) := (others => '0');

        
        mem_g_in_write_we_A_blk1 : out std_logic_vector(0 downto 0) := (others => '0');
        mem_g_in_write_we_B_blk1 : out std_logic_vector(0 downto 0) := (others => '0');

        mem_g_hid_write_we_A_blk1 : out std_logic_vector(0 downto 0) := (others => '0');
        mem_g_hid_write_we_B_blk1 : out std_logic_vector(0 downto 0) := (others => '0');

        mem_o_in_write_we_A_blk1 : out std_logic_vector(0 downto 0) := (others => '0');
        mem_o_in_write_we_B_blk1 : out std_logic_vector(0 downto 0) := (others => '0');

        mem_o_hid_write_we_A_blk1 : out std_logic_vector(0 downto 0) := (others => '0');
        mem_o_hid_write_we_B_blk1 : out std_logic_vector(0 downto 0) := (others => '0');

        -- Reading
        mem_re_blk1 : out std_logic := '0';
        mem_i_in_read_data_A_blk1 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_i_hid_read_data_A_blk1 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_f_in_read_data_A_blk1 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_f_hid_read_data_A_blk1 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_g_in_read_data_A_blk1 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_g_hid_read_data_A_blk1 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_o_in_read_data_A_blk1 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_o_hid_read_data_A_blk1 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);

        mem_i_in_read_data_B_blk1 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_i_hid_read_data_B_blk1 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_f_in_read_data_B_blk1 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_f_hid_read_data_B_blk1 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_g_in_read_data_B_blk1 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_g_hid_read_data_B_blk1 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_o_in_read_data_B_blk1 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_o_hid_read_data_B_blk1 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);

        -- data block 2
        -- Writing
        mem_i_in_write_we_A_blk2 : out std_logic_vector(0 downto 0) := (others => '0');
        mem_i_in_write_we_B_blk2 : out std_logic_vector(0 downto 0) := (others => '0');

        mem_i_hid_write_we_A_blk2 : out std_logic_vector(0 downto 0) := (others => '0');
        mem_i_hid_write_we_B_blk2 : out std_logic_vector(0 downto 0) := (others => '0');

        mem_f_in_write_we_A_blk2 : out std_logic_vector(0 downto 0) := (others => '0');
        mem_f_in_write_we_B_blk2 : out std_logic_vector(0 downto 0) := (others => '0');

        mem_f_hid_write_we_A_blk2 : out std_logic_vector(0 downto 0) := (others => '0');
        mem_f_hid_write_we_B_blk2 : out std_logic_vector(0 downto 0) := (others => '0');

        mem_g_in_write_we_A_blk2 : out std_logic_vector(0 downto 0) := (others => '0');
        mem_g_in_write_we_B_blk2 : out std_logic_vector(0 downto 0) := (others => '0');

        mem_g_hid_write_we_A_blk2 : out std_logic_vector(0 downto 0) := (others => '0');
        mem_g_hid_write_we_B_blk2 : out std_logic_vector(0 downto 0) := (others => '0');

        mem_o_in_write_we_A_blk2 : out std_logic_vector(0 downto 0) := (others => '0');
        mem_o_in_write_we_B_blk2 : out std_logic_vector(0 downto 0) := (others => '0');

        mem_o_hid_write_we_A_blk2 : out std_logic_vector(0 downto 0) := (others => '0');
        mem_o_hid_write_we_B_blk2 : out std_logic_vector(0 downto 0) := (others => '0');

        -- Reading
        mem_re_blk2 : out std_logic := '0';
        mem_i_in_read_data_A_blk2 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_i_hid_read_data_A_blk2 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_f_in_read_data_A_blk2 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_f_hid_read_data_A_blk2 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_g_in_read_data_A_blk2 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_g_hid_read_data_A_blk2 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_o_in_read_data_A_blk2 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_o_hid_read_data_A_blk2 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);

        mem_i_in_read_data_B_blk2 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_i_hid_read_data_B_blk2 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_f_in_read_data_B_blk2 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_f_hid_read_data_B_blk2 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_g_in_read_data_B_blk2 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_g_hid_read_data_B_blk2 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_o_in_read_data_B_blk2 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);
        mem_o_hid_read_data_B_blk2 : in std_logic_vector((16 * DEPTH / 2) - 1 downto 0);

        -- output
        m_axis_pes_ready : in std_logic;
        m_axis_pes_valid : out std_logic := '0';
        m_axis_pes_last : out std_logic := '0';

        m_axis_i_in_weight_data : out std_logic_vector((16 * DEPTH) - 1 downto 0) := (others => '0');
        m_axis_i_hid_weight_data : out std_logic_vector((16 * DEPTH) - 1 downto 0) := (others => '0');
        m_axis_f_in_weight_data : out std_logic_vector((16 * DEPTH) - 1 downto 0) := (others => '0');
        m_axis_f_hid_weight_data : out std_logic_vector((16 * DEPTH) - 1 downto 0) := (others => '0');
        m_axis_g_in_weight_data : out std_logic_vector((16 * DEPTH) - 1 downto 0) := (others => '0');
        m_axis_g_hid_weight_data : out std_logic_vector((16 * DEPTH) - 1 downto 0) := (others => '0');
        m_axis_o_in_weight_data : out std_logic_vector((16 * DEPTH) - 1 downto 0) := (others => '0');
        m_axis_o_hid_weight_data : out std_logic_vector((16 * DEPTH) - 1 downto 0) := (others => '0')
    );
end entity weight_mem_manager;

architecture behav of weight_mem_manager is
    -- block select (Means which block is currently being read from)
    type block_sel_t is (NONE, BLOCK1, BLOCK2);
    signal block_sel : block_sel_t := NONE;

    -- Shift register for valid signal of size LATENCY
    type valid_sr_t is array (0 to LATENCY-1) of valid_t;
    signal valid_sr : valid_sr_t := (others => INVALID);

    -- Shift register for last signal of size LATENCY
    type last_sr_t is array (0 to LATENCY-1) of last_t;
    signal last_sr : last_sr_t := (others => NOT_LAST);

    -- This signals the 
    signal last_input : boolean := false;
    signal layer_last_flag : boolean := false;
begin
    -- Ready process
    process(m_axis_pes_ready, block_sel)
    begin
        if m_axis_pes_ready = '1' then
            case block_sel is
                when NONE =>
                    s_axis_counter_ready <= '0';
                when BLOCK1 =>
                    s_axis_counter_ready <= '1';
                when BLOCK2 =>
                    s_axis_counter_ready <= '1';
            end case;
        else 
            s_axis_counter_ready <= '0';
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if s_axis_counter_valid = '1' or last_input = true then
                 case block_sel is
                    when NONE =>
                        mem_raddr <= (others => '0');

                        mem_re_blk1 <= '0';
                        mem_re_blk2 <= '0';
                    when BLOCK1 =>
                        mem_raddr <= s_axis_counter_data;

                        mem_re_blk1 <= '1';
                        mem_re_blk2 <= '0';
                    when BLOCK2 =>
                        mem_raddr <= s_axis_counter_data;

                        mem_re_blk1 <= '0';
                        mem_re_blk2 <= '1';
                end case;
            else
                mem_raddr <= (others => '0');

                mem_re_blk1 <= '0';
                mem_re_blk2 <= '0';
            end if;
        end if;
    end process;

    -- Shift register for valid signal of size LATENCY
    process(clk)
    begin
        if rising_edge(clk) then
            if s_axis_counter_valid = '1' then
                valid_sr(0) <= VALID;
            else
                valid_sr(0) <= INVALID;
            end if;

            for i in 1 to LATENCY-1 loop
                valid_sr(i) <= valid_sr(i-1);
            end loop;

            if valid_sr(LATENCY-1) = VALID then
                m_axis_pes_valid <= '1';
            else
                m_axis_pes_valid <= '0';
            end if;
        end if;
    end process;


    -- block select process
    process(clk)
    begin 
        if rising_edge(clk) then
            if (block_sel = NONE) then
                if (s_axis_write_bus_last = '1') then
                    block_sel <= BLOCK1;
                end if;
            else
                if (layer_last_flag = true) then
                    if (block_sel = BLOCK1) then
                        block_sel <= BLOCK2;
                    else
                        block_sel <= BLOCK1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Last signals handler
    process(clk)
    begin
        if rising_edge(clk) then
            if (block_sel = BLOCK1 or block_sel = BLOCK2) then
                if s_axis_counter_valid = '1' then
                    if s_axis_counter_last(1) = '1' then
                        last_sr(0) <= LAYER_LAST;
                        -- The read enable signal is held for LATENCY cycles
                        last_input <= true;
                    elsif s_axis_counter_last(0) = '1' then
                        last_sr(0) <= SEQ_LAST;
                        -- The read enable signal is held for LATENCY cycles
                        last_input <= true;
                    else
                        last_sr(0) <= NOT_LAST;
                        last_input <= false;
                    end if;
                else
                    last_sr(0) <= NOT_LAST;
                    last_input <= false;
                end if;

                for i in 1 to LATENCY-1 loop
                    last_sr(i) <= last_sr(i-1);
                end loop;

                if last_sr(LATENCY-1) = LAYER_LAST then
                    layer_last_flag <= true;
                    m_axis_pes_last <= '1';
                elsif last_sr(LATENCY-1) = SEQ_LAST then
                    m_axis_pes_last <= '1';
                    layer_last_flag <= false;
                else
                    m_axis_pes_last <= '0';
                    layer_last_flag <= false;
                end if;
                
            else
                m_axis_pes_last <= '0';
                layer_last_flag <= false;
            end if;
        end if;
    end process;

    -- merge memory data into one vector for each weight
    process(block_sel, mem_i_in_read_data_A_blk1, mem_i_in_read_data_B_blk1, mem_i_in_read_data_A_blk2, mem_i_in_read_data_B_blk2,
            mem_i_hid_read_data_A_blk1, mem_i_hid_read_data_B_blk1, mem_i_hid_read_data_A_blk2, mem_i_hid_read_data_B_blk2,
            mem_f_in_read_data_A_blk1, mem_f_in_read_data_B_blk1, mem_f_in_read_data_A_blk2, mem_f_in_read_data_B_blk2,
            mem_f_hid_read_data_A_blk1, mem_f_hid_read_data_B_blk1, mem_f_hid_read_data_A_blk2, mem_f_hid_read_data_B_blk2,
            mem_g_in_read_data_A_blk1, mem_g_in_read_data_B_blk1, mem_g_in_read_data_A_blk2, mem_g_in_read_data_B_blk2,
            mem_g_hid_read_data_A_blk1, mem_g_hid_read_data_B_blk1, mem_g_hid_read_data_A_blk2, mem_g_hid_read_data_B_blk2,
            mem_o_in_read_data_A_blk1, mem_o_in_read_data_B_blk1, mem_o_in_read_data_A_blk2, mem_o_in_read_data_B_blk2,
            mem_o_hid_read_data_A_blk1, mem_o_hid_read_data_B_blk1, mem_o_hid_read_data_A_blk2, mem_o_hid_read_data_B_blk2)
    begin
        case block_sel is
            when NONE =>
                m_axis_i_in_weight_data <= (others => '0');
                m_axis_i_hid_weight_data <= (others => '0');
                m_axis_f_in_weight_data <= (others => '0');
                m_axis_f_hid_weight_data <= (others => '0');
                m_axis_g_in_weight_data <= (others => '0');
                m_axis_g_hid_weight_data <= (others => '0');
                m_axis_o_in_weight_data <= (others => '0');
                m_axis_o_hid_weight_data <= (others => '0');
            when BLOCK1 =>
                m_axis_i_in_weight_data <= mem_i_in_read_data_A_blk1 & mem_i_in_read_data_B_blk1;
                m_axis_i_hid_weight_data <= mem_i_hid_read_data_A_blk1 & mem_i_hid_read_data_B_blk1;
                m_axis_f_in_weight_data <= mem_f_in_read_data_A_blk1 & mem_f_in_read_data_B_blk1;
                m_axis_f_hid_weight_data <= mem_f_hid_read_data_A_blk1 & mem_f_hid_read_data_B_blk1;
                m_axis_g_in_weight_data <= mem_g_in_read_data_A_blk1 & mem_g_in_read_data_B_blk1;
                m_axis_g_hid_weight_data <= mem_g_hid_read_data_A_blk1 & mem_g_hid_read_data_B_blk1;
                m_axis_o_in_weight_data <= mem_o_in_read_data_A_blk1 & mem_o_in_read_data_B_blk1;
                m_axis_o_hid_weight_data <= mem_o_hid_read_data_A_blk1 & mem_o_hid_read_data_B_blk1;
            when BLOCK2 =>
                m_axis_i_in_weight_data <= mem_i_in_read_data_A_blk2 & mem_i_in_read_data_B_blk2;
                m_axis_i_hid_weight_data <= mem_i_hid_read_data_A_blk2 & mem_i_hid_read_data_B_blk2;
                m_axis_f_in_weight_data <= mem_f_in_read_data_A_blk2 & mem_f_in_read_data_B_blk2;
                m_axis_f_hid_weight_data <= mem_f_hid_read_data_A_blk2 & mem_f_hid_read_data_B_blk2;
                m_axis_g_in_weight_data <= mem_g_in_read_data_A_blk2 & mem_g_in_read_data_B_blk2;
                m_axis_g_hid_weight_data <= mem_g_hid_read_data_A_blk2 & mem_g_hid_read_data_B_blk2;
                m_axis_o_in_weight_data <= mem_o_in_read_data_A_blk2 & mem_o_in_read_data_B_blk2;
                m_axis_o_hid_weight_data <= mem_o_hid_read_data_A_blk2 & mem_o_hid_read_data_B_blk2;
        end case;
    end process;

    -- Write process
    process(clk)
        variable weight_dest : weight_dest_t;            
    begin
        if rising_edge(clk) then
            -- Check if write bus is valid
            if (s_axis_write_bus_valid = '1') then
                -- Convert the user signal to a weight_dest_t
                weight_dest := slv_to_weight_dest(s_axis_write_bus_user);

                -- Split the data into two parts
                mem_write_data <= s_axis_write_bus_data;

                mem_write_addr <= s_axis_write_bus_dest(9 downto 1);

                -- The following code is a multiplexer to write the data to the correct memory
                if (weight_dest = I_INPUT) then
                    -- If there is no data in memory or we're reading from block 2, write to block 1
                    if (block_sel = BLOCK2 or block_sel = NONE) then 
                        if s_axis_write_bus_dest(0) = '0' then
                            mem_i_in_write_we_A_blk1 <= "0";
                            mem_i_in_write_we_B_blk1 <= "1";
                        else
                            mem_i_in_write_we_A_blk1 <= "1";
                            mem_i_in_write_we_B_blk1 <= "0";
                        end if;

                        mem_i_in_write_we_A_blk2 <= "0";
                        mem_i_in_write_we_B_blk2 <= "0";
                    -- else write to block 2
                    else
                        mem_i_in_write_we_A_blk1 <= "0";
                        mem_i_in_write_we_B_blk1 <= "0";

                        if s_axis_write_bus_dest(0) = '0' then
                            mem_i_in_write_we_A_blk2 <= "0";
                            mem_i_in_write_we_B_blk2 <= "1";
                        else
                            mem_i_in_write_we_A_blk2 <= "1";
                            mem_i_in_write_we_B_blk2 <= "0";
                        end if;
                    end if;
                else -- We're not writing for this weight, so set the everything to 0
                    mem_i_in_write_we_A_blk1 <= "0";
                    mem_i_in_write_we_B_blk1 <= "0";

                    mem_i_in_write_we_A_blk2 <= "0";
                    mem_i_in_write_we_B_blk2 <= "0";
                end if;

                if (weight_dest = I_HIDDEN) then
                    -- If there is no data in memory or we're reading from block 2, write to block 1
                    if (block_sel = BLOCK2 or block_sel = NONE) then 
                        if s_axis_write_bus_dest(0) = '0' then
                            mem_i_hid_write_we_A_blk1 <= "0";
                            mem_i_hid_write_we_B_blk1 <= "1";
                        else
                            mem_i_hid_write_we_A_blk1 <= "1";
                            mem_i_hid_write_we_B_blk1 <= "0";
                        end if;

                        mem_i_hid_write_we_A_blk2 <= "0";
                        mem_i_hid_write_we_B_blk2 <= "0";
                    -- else write to block 2
                    else 
                        mem_i_hid_write_we_A_blk1 <= "0";
                        mem_i_hid_write_we_B_blk1 <= "0";

                        if s_axis_write_bus_dest(0) = '0' then
                            mem_i_hid_write_we_A_blk2 <= "0";
                            mem_i_hid_write_we_B_blk2 <= "1";
                        else
                            mem_i_hid_write_we_A_blk2 <= "1";
                            mem_i_hid_write_we_B_blk2 <= "0";
                        end if;
                    end if;
                else -- We're not writing for this weight, so set the everything to 0
                    mem_i_hid_write_we_A_blk1 <= "0";
                    mem_i_hid_write_we_B_blk1 <= "0";

                    mem_i_hid_write_we_A_blk2 <= "0";
                    mem_i_hid_write_we_B_blk2 <= "0";
                end if;

                if (weight_dest = F_INPUT) then
                    -- If there is no data in memory or we're reading from block 2, write to block 1
                    if (block_sel = BLOCK2 or block_sel = NONE) then 
                        if s_axis_write_bus_dest(0) = '0' then
                            mem_f_in_write_we_A_blk1 <= "0";
                            mem_f_in_write_we_B_blk1 <= "1";
                        else
                            mem_f_in_write_we_A_blk1 <= "1";
                            mem_f_in_write_we_B_blk1 <= "0";
                        end if;

                        mem_f_in_write_we_A_blk2 <= "0";
                        mem_f_in_write_we_B_blk2 <= "0";
                    -- else write to block 2
                    else 
                        mem_f_in_write_we_A_blk1 <= "0";
                        mem_f_in_write_we_B_blk1 <= "0";

                        if s_axis_write_bus_dest(0) = '0' then
                            mem_f_in_write_we_A_blk2 <= "0";
                            mem_f_in_write_we_B_blk2 <= "1";
                        else
                            mem_f_in_write_we_A_blk2 <= "1";
                            mem_f_in_write_we_B_blk2 <= "0";
                        end if;
                    end if;
                else -- We're not writing for this weight, so set the everything to 0
                    mem_f_in_write_we_A_blk1 <= "0";
                    mem_f_in_write_we_B_blk1 <= "0";

                    mem_f_in_write_we_A_blk2 <= "0";
                    mem_f_in_write_we_B_blk2 <= "0";
                end if;

                if (weight_dest = F_HIDDEN) then
                    -- If there is no data in memory or we're reading from block 2, write to block 1
                    if (block_sel = BLOCK2 or block_sel = NONE) then 
                        if s_axis_write_bus_dest(0) = '0' then
                            mem_f_hid_write_we_A_blk1 <= "0";
                            mem_f_hid_write_we_B_blk1 <= "1";
                        else
                            mem_f_hid_write_we_A_blk1 <= "1";
                            mem_f_hid_write_we_B_blk1 <= "0";
                        end if;

                        mem_f_hid_write_we_A_blk2 <= "0";
                        mem_f_hid_write_we_B_blk2 <= "0";
                    -- else write to block 2
                    else 
                        mem_f_hid_write_we_A_blk1 <= "0";
                        mem_f_hid_write_we_B_blk1 <= "0";

                        if s_axis_write_bus_dest(0) = '0' then
                            mem_f_hid_write_we_A_blk2 <= "0";
                            mem_f_hid_write_we_B_blk2 <= "1";
                        else
                            mem_f_hid_write_we_A_blk2 <= "1";
                            mem_f_hid_write_we_B_blk2 <= "0";
                        end if;
                    end if;
                else -- We're not writing for this weight, so set the everything to 0
                    mem_f_hid_write_we_A_blk1 <= "0";
                    mem_f_hid_write_we_B_blk1 <= "0";

                    mem_f_hid_write_we_A_blk2 <= "0";
                    mem_f_hid_write_we_B_blk2 <= "0";
                end if;

                if (weight_dest = G_INPUT) then
                    -- If there is no data in memory or we're reading from block 2, write to block 1
                    if (block_sel = BLOCK2 or block_sel = NONE) then 
                        if s_axis_write_bus_dest(0) = '0' then
                            mem_g_in_write_we_A_blk1 <= "0";
                            mem_g_in_write_we_B_blk1 <= "1";
                        else
                            mem_g_in_write_we_A_blk1 <= "1";
                            mem_g_in_write_we_B_blk1 <= "0";
                        end if;

                        mem_g_in_write_we_A_blk2 <= "0";
                        mem_g_in_write_we_B_blk2 <= "0";
                    -- else write to block 2
                    else 
                        mem_g_in_write_we_A_blk1 <= "0";
                        mem_g_in_write_we_B_blk1 <= "0";

                        if s_axis_write_bus_dest(0) = '0' then
                            mem_g_in_write_we_A_blk2 <= "0";
                            mem_g_in_write_we_B_blk2 <= "1";
                        else
                            mem_g_in_write_we_A_blk2 <= "1";
                            mem_g_in_write_we_B_blk2 <= "0";
                        end if;
                    end if;

                else -- We're not writing for this weight, so set the everything to 0
                    mem_g_in_write_we_A_blk1 <= "0";
                    mem_g_in_write_we_B_blk1 <= "0";

                    mem_g_in_write_we_A_blk2 <= "0";
                    mem_g_in_write_we_B_blk2 <= "0";
                end if;

                if (weight_dest = G_HIDDEN) then
                    -- If there is no data in memory or we're reading from block 2, write to block 1
                    if (block_sel = BLOCK2 or block_sel = NONE) then 
                        if s_axis_write_bus_dest(0) = '0' then
                            mem_g_hid_write_we_A_blk1 <= "0";
                            mem_g_hid_write_we_B_blk1 <= "1";
                        else
                            mem_g_hid_write_we_A_blk1 <= "1";
                            mem_g_hid_write_we_B_blk1 <= "0";
                        end if;

                        mem_g_hid_write_we_A_blk2 <= "0";
                        mem_g_hid_write_we_B_blk2 <= "0";
                    -- else write to block 2
                    else 
                        mem_g_hid_write_we_A_blk1 <= "0";
                        mem_g_hid_write_we_B_blk1 <= "0";

                        if s_axis_write_bus_dest(0) = '0' then
                            mem_g_hid_write_we_A_blk2 <= "0";
                            mem_g_hid_write_we_B_blk2 <= "1";
                        else
                            mem_g_hid_write_we_A_blk2 <= "1";
                            mem_g_hid_write_we_B_blk2 <= "0";
                        end if;
                    end if;
                else -- We're not writing for this weight, so set the everything to 0
                    mem_g_hid_write_we_A_blk1 <= "0";
                    mem_g_hid_write_we_B_blk1 <= "0";

                    mem_g_hid_write_we_A_blk2 <= "0";
                    mem_g_hid_write_we_B_blk2 <= "0";
                end if;

                if (weight_dest = O_INPUT) then
                    -- If there is no data in memory or we're reading from block 2, write to block 1
                    if (block_sel = BLOCK2 or block_sel = NONE) then 
                        if s_axis_write_bus_dest(0) = '0' then
                            mem_o_in_write_we_A_blk1 <= "0";
                            mem_o_in_write_we_B_blk1 <= "1";
                        else
                            mem_o_in_write_we_A_blk1 <= "1";
                            mem_o_in_write_we_B_blk1 <= "0";
                        end if;

                        mem_o_in_write_we_A_blk2 <= "0";
                        mem_o_in_write_we_B_blk2 <= "0";
                                            -- else write to block 2
                    else 
                        mem_o_in_write_we_A_blk1 <= "0";
                        mem_o_in_write_we_B_blk1 <= "0";

                        if s_axis_write_bus_dest(0) = '0' then
                            mem_o_in_write_we_A_blk2 <= "0";
                            mem_o_in_write_we_B_blk2 <= "1";
                        else
                            mem_o_in_write_we_A_blk2 <= "1";
                            mem_o_in_write_we_B_blk2 <= "0";
                        end if;
                    end if;
                else -- We're not writing for this weight, so set the everything to 0
                    mem_o_in_write_we_A_blk1 <= "0";
                    mem_o_in_write_we_B_blk1 <= "0";

                    mem_o_in_write_we_A_blk2 <= "0";
                    mem_o_in_write_we_B_blk2 <= "0";
                end if;

                if (weight_dest = O_HIDDEN) then
                    -- If there is no data in memory or we're reading from block 2, write to block 1
                    if (block_sel = BLOCK2 or block_sel = NONE) then 
                        if s_axis_write_bus_dest(0) = '0' then
                            mem_o_hid_write_we_A_blk1 <= "0";
                            mem_o_hid_write_we_B_blk1 <= "1";
                        else
                            mem_o_hid_write_we_A_blk1 <= "1";
                            mem_o_hid_write_we_B_blk1 <= "0";
                        end if;

                        mem_o_hid_write_we_A_blk2 <= "0";
                        mem_o_hid_write_we_B_blk2 <= "0";
                    -- else write to block 2
                    else 
                        mem_o_hid_write_we_A_blk1 <= "0";
                        mem_o_hid_write_we_B_blk1 <= "0";

                        if s_axis_write_bus_dest(0) = '0' then
                            mem_o_hid_write_we_A_blk2 <= "0";
                            mem_o_hid_write_we_B_blk2 <= "1";
                        else
                            mem_o_hid_write_we_A_blk2 <= "1";
                            mem_o_hid_write_we_B_blk2 <= "0";
                        end if;
                    end if;
                else -- We're not writing for this weight, so set the everything to 0
                    mem_o_hid_write_we_A_blk1 <= "0";
                    mem_o_hid_write_we_B_blk1 <= "0";

                    mem_o_hid_write_we_A_blk2 <= "0";
                    mem_o_hid_write_we_B_blk2 <= "0";
                end if;
            end if;
        end if;
    end process;    
end architecture behav;