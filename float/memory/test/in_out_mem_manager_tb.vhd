library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.types.all;

entity in_out_mem_manager_tb is
end entity in_out_mem_manager_tb;

architecture sim of in_out_mem_manager_tb is
    component in_out_mem_manager is
        generic (
            LATENCY : natural := 2;
            CHUNCK_SIZE : natural := 1000
        );
        port (
            clk : in std_logic;
    
            -- control
            s_axis_counter_data : in std_logic_vector(8 downto 0);
            s_axis_counter_valid : in std_logic;
            s_axis_counter_ready : out std_logic;
            s_axis_counter_last : in std_logic_vector(1 downto 0);
            s_axis_counter_user : in std_logic_vector(3 downto 0);
    
            -- pe exchange
            m_axis_pes_ready : in std_logic;
            m_axis_pes_valid : out std_logic;
            m_axis_pes_last : out std_logic;
    
            m_axis_input_data : out std_logic_vector(15 downto 0);
            m_axis_hidden_data : out std_logic_vector(15 downto 0);
    
            s_axis_pe_data : in std_logic_vector(384 * 16 - 1 downto 0);
            s_axis_pe_valid : in std_logic;
            s_axis_pe_ready : out std_logic;
    
            -- BRAM reading Memory
            read_addr : out std_logic_vector(18 downto 0);
    
            read_data_blk1 : in std_logic_vector(15 downto 0);
            read_en_blk1 : out std_logic;
    
            read_data_blk2 : in std_logic_vector(15 downto 0);
            read_en_blk2 : out std_logic;
    
            -- DRAM to BRAM signals
            s_axis_input_data : in std_logic_vector(15 downto 0);
            s_axis_input_valid : in std_logic;
            s_axis_input_ready : out std_logic;
            s_axis_input_last : in std_logic;
    
            m_axis_output_data : out std_logic_vector(15 downto 0);
            m_axis_output_valid : out std_logic;
            m_axis_output_last : out std_logic;
    
            -- Hidden swap memory
            read_addr_hidden : out std_logic_vector(8 downto 0);
            read_data_hidden : in std_logic_vector(15 downto 0);
            read_en_hidden : out std_logic;
            hidden_swap_valid : in std_logic;
    
            -- hidden to DRAM signals
            hidden_dram_data : out std_logic_vector(15 downto 0);
            hidden_dram_valid : out std_logic;
            hidden_dram_dest : out std_logic_vector(8 downto 0);
            hidden_dram_ready : in std_logic;
    
            write_addr : out std_logic_vector(18 downto 0);
            write_en_blk1 : out std_logic;
            write_en_blk2 : out std_logic;
            write_data : out std_logic_vector(15 downto 0)
        );
    end component in_out_mem_manager;

    constant clk_period : time := 10 ns;

    signal clk : std_logic := '0';

    -- control
    signal s_axis_counter_data : std_logic_vector(8 downto 0) := (others => '0');
    signal s_axis_counter_valid : std_logic := '0';
    signal s_axis_counter_ready : std_logic;
    signal s_axis_counter_last : last_t := NOT_LAST;
    signal inference_data : inference_data_t := (layer_info => LAYER1, last_inf => false);

    -- pe exchange
    signal m_axis_pes_ready : std_logic := '0';
    signal m_axis_pes_valid : std_logic;
    signal m_axis_pes_last : std_logic;

    signal m_axis_input_data : std_logic_vector(15 downto 0);
    signal m_axis_hidden_data : std_logic_vector(15 downto 0);

    signal s_axis_pe_data : std_logic_vector(384 * 16 - 1 downto 0) := (others => '0');
    signal s_axis_pe_valid : std_logic := '0';
    signal s_axis_pe_ready : std_logic;

    -- BRAM reading Memory
    signal read_addr : std_logic_vector(18 downto 0);

    signal read_data_blk1 : std_logic_vector(15 downto 0) := (others => '0');
    signal read_en_blk1 : std_logic;

    signal read_data_blk2 : std_logic_vector(15 downto 0) := (others => '0');
    signal read_en_blk2 : std_logic;

    -- DRAM to BRAM signals
    signal s_axis_input_data : std_logic_vector(15 downto 0) := (others => '0');
    signal s_axis_input_valid : std_logic := '0';
    signal s_axis_input_ready : std_logic;
    signal s_axis_input_last : std_logic := '0';

    signal m_axis_output_data : std_logic_vector(15 downto 0);
    signal m_axis_output_valid : std_logic;
    signal m_axis_output_last : std_logic;

    -- Hidden swap memory
    signal read_addr_hidden : std_logic_vector(8 downto 0);
    signal read_data_hidden : std_logic_vector(15 downto 0) := (others => '0');
    signal read_en_hidden : std_logic;
    signal hidden_swap_valid : std_logic := '0';

    -- hidden to DRAM signals
    signal hidden_dram_data : std_logic_vector(15 downto 0) ;
    signal hidden_dram_valid : std_logic;
    signal hidden_dram_dest : std_logic_vector(8 downto 0);
    signal hidden_dram_ready : std_logic := '0';

    signal write_addr : std_logic_vector(18 downto 0);
    signal write_en_blk1 : std_logic;
    signal write_en_blk2 : std_logic;
    signal write_data : std_logic_vector(15 downto 0);
begin

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

        m_axis_pes_ready <= '1';
        hidden_swap_valid <= '1';
        hidden_dram_ready <= '1';
        
        for layer in 0 to 4 loop
            for inf_count in 0 to 2 loop 
                if s_axis_counter_ready = '0' then
                    wait until s_axis_counter_ready = '1';
                end if;
                wait for clk_period / 2;                

                s_axis_counter_valid <= '1';
                inference_data.layer_info <= slv_to_layer_info(std_logic_vector(to_unsigned(layer, 3)));

                for i in 0 to 383 loop
                    s_axis_counter_data <= std_logic_vector(to_unsigned(i, 9));
                    if inf_count = 2 then
                        inference_data.last_inf <= true;
                    else
                        inference_data.last_inf <= false;
                    end if;

                    if i = 383 then
                        if inf_count = 2 then
                            s_axis_counter_last <= LAYER_LAST;
                        else
                            s_axis_counter_last <= SEQ_LAST;
                        end if;
                    else
                        s_axis_counter_last <= NOT_LAST;
                    end if;

                    wait for clk_period;
                end loop;

                s_axis_counter_valid <= '0';
                s_axis_counter_last <= NOT_LAST;

                wait for clk_period * 20;

                s_axis_pe_data <= rand_slv(384 * 16);
                s_axis_pe_valid <= '1';

                wait for clk_period;

                s_axis_pe_data <= (others => '0');
                s_axis_pe_valid <= '0';
            end loop;

            wait until hidden_dram_valid = '1';
            wait for clk_period;
            wait until hidden_dram_valid = '0';
        end loop;

        wait;
    end process;

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
        wait until s_axis_counter_valid = '1' and m_axis_pes_valid = '1';

        while m_axis_pes_last = '0' loop
            s_axis_input_data <= rand_slv(16);
            s_axis_input_valid <= '1';
            read_data_hidden <= rand_slv(16);
            wait for clk_period;
        end loop;

        s_axis_input_valid <= '0';
        s_axis_input_data <= (others => '0');
        read_data_hidden <= (others => '0');
        
    end process;
    
    
    DUT: in_out_mem_manager
        generic map (
            LATENCY => 2,
            CHUNCK_SIZE => 1000
        )
        port map (
            clk => clk,
    
            -- control
            s_axis_counter_data => s_axis_counter_data,
            s_axis_counter_valid => s_axis_counter_valid,
            s_axis_counter_ready => s_axis_counter_ready,
            s_axis_counter_last => last_to_slv(s_axis_counter_last),
            s_axis_counter_user => inference_data_to_slv(inference_data),
    
            -- pe exchange
            m_axis_pes_ready => m_axis_pes_ready,
            m_axis_pes_valid => m_axis_pes_valid,
            m_axis_pes_last => m_axis_pes_last,
    
            m_axis_input_data => m_axis_input_data,
            m_axis_hidden_data => m_axis_hidden_data,
    
            s_axis_pe_data => s_axis_pe_data,
            s_axis_pe_valid => s_axis_pe_valid,
            s_axis_pe_ready => s_axis_pe_ready,
    
            -- BRAM reading Memory
            read_addr => read_addr,
    
            read_data_blk1 => read_data_blk1,
            read_en_blk1 => read_en_blk1,
    
            read_data_blk2 => read_data_blk2,
            read_en_blk2 => read_en_blk2,
    
            -- DRAM to BRAM signals
            s_axis_input_data => s_axis_input_data,
            s_axis_input_valid => s_axis_input_valid,
            s_axis_input_ready => s_axis_input_ready,
            s_axis_input_last => s_axis_input_last,
    
            m_axis_output_data => m_axis_output_data,
            m_axis_output_valid => m_axis_output_valid,
            m_axis_output_last => m_axis_output_last,
    
            -- Hidden swap memory
            read_addr_hidden => read_addr_hidden,
            read_data_hidden => read_data_hidden,
            read_en_hidden => read_en_hidden,
            hidden_swap_valid => hidden_swap_valid,
    
            -- hidden to DRAM signals
            hidden_dram_data => hidden_dram_data,
            hidden_dram_valid => hidden_dram_valid,
            hidden_dram_dest => hidden_dram_dest,
            hidden_dram_ready => hidden_dram_ready,
    
            write_addr => write_addr,
            write_en_blk1 => write_en_blk1,
            write_en_blk2 => write_en_blk2,
            write_data => write_data
        );

    -- Clock process
    process
    begin
        wait for clk_period / 2;
        clk <= not clk;
    end process;

end architecture sim;