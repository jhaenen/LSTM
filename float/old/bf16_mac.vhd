library ieee;
use ieee.std_logic_1164.all;

entity bf16_mac is
    port (
        clk         : in std_logic;
        rst         : in std_logic;

        S_AXIS_DATA_IN_tdata   : in std_logic_vector(15 downto 0);
        S_AXIS_DATA_IN_tvalid  : in std_logic;
        S_AXIS_DATA_IN_tready  : out std_logic;

        S_AXIS_WEIGHT_IN_tdata : in std_logic_vector(15 downto 0);
        S_AXIS_WEIGHT_IN_tvalid: in std_logic;
        S_AXIS_WEIGHT_IN_tready: out std_logic;

        M_AXIS_DATA_OUT_tdata  : out std_logic_vector(15 downto 0);
        M_AXIS_DATA_OUT_tvalid : out std_logic
        -- M_AXIS_DATA_OUT_tready : in std_logic
    );
end entity bf16_mac;

architecture behav of bf16_mac is
    signal data_in_buffer : std_logic_vector(15 downto 0) := (others => '0');
    signal data_in_buffer_valid : std_logic := '0';
    signal data_in_float_ready : std_logic;

    signal weight_in_buffer : std_logic_vector(15 downto 0) := (others => '0');
    signal weight_in_buffer_valid : std_logic := '0';
    signal weight_in_float_ready : std_logic;

    signal acc : std_logic_vector(15 downto 0) := (others => '0');
    signal acc_valid : std_logic := '0';
    signal acc_float_ready : std_logic;

    signal result : std_logic_vector(15 downto 0);
    signal result_float_valid : std_logic;
    signal result_ready : std_logic := '0';

    component fmadd_bf16_wrapper is
        port (
            M_AXIS_RESULT_tdata : out STD_LOGIC_VECTOR ( 15 downto 0 );
            M_AXIS_RESULT_tready : in STD_LOGIC;
            M_AXIS_RESULT_tvalid : out STD_LOGIC;

            S_AXIS_ADDITIVE_tdata : in STD_LOGIC_VECTOR ( 15 downto 0 );
            S_AXIS_ADDITIVE_tready : out STD_LOGIC;
            S_AXIS_ADDITIVE_tvalid : in STD_LOGIC;

            S_AXIS_MULT_1_tdata : in STD_LOGIC_VECTOR ( 15 downto 0 );
            S_AXIS_MULT_1_tready : out STD_LOGIC;
            S_AXIS_MULT_1_tvalid : in STD_LOGIC;

            S_AXIS_MULT_2_tdata : in STD_LOGIC_VECTOR ( 15 downto 0 );
            S_AXIS_MULT_2_tready : out STD_LOGIC;
            S_AXIS_MULT_2_tvalid : in STD_LOGIC;
            aclk : in STD_LOGIC
          );
    end component;

    -- State machine
    type state_type is (wait_float_ready, receive);
    signal state : state_type := receive;

begin
    -- Input process
    process (clk, rst)
        variable has_data : boolean := false;
    begin
        if rst = '1' then
            state <= receive;
            has_data := false;
            S_AXIS_DATA_IN_tready <= '1';
            S_AXIS_WEIGHT_IN_tready <= '1';

            data_in_buffer <= (others => '0');
            data_in_buffer_valid <= '0';

            weight_in_buffer <= (others => '0');
            weight_in_buffer_valid <= '0';
        elsif rising_edge(clk) then
            case state is
                when receive =>
                    if S_AXIS_DATA_IN_tvalid = '1' and S_AXIS_WEIGHT_IN_tvalid = '1'then 
                        data_in_buffer <= S_AXIS_DATA_IN_tdata;
                        weight_in_buffer <= S_AXIS_WEIGHT_IN_tdata;

                        -- The data is valid
                        data_in_buffer_valid <= '1';
                        weight_in_buffer_valid <= '1';

                        -- Check if the float is ready
                        if data_in_float_ready = '1' and weight_in_float_ready = '1' and acc_float_ready = '1' then
                            -- If it is ready, then we can receive immediately again
                            S_AXIS_DATA_IN_tready <= '1';
                            S_AXIS_WEIGHT_IN_tready <= '1';
                            state <= receive;
                        else
                            -- Else we have to wait
                            S_AXIS_DATA_IN_tready <= '0';
                            S_AXIS_WEIGHT_IN_tready <= '0';
                            state <= wait_float_ready;
                        end if;
                    else 
                        S_AXIS_DATA_IN_tready <= '1';
                        S_AXIS_WEIGHT_IN_tready <= '1';     
                        
                        -- The data is invalid
                        data_in_buffer_valid <= '0';
                        weight_in_buffer_valid <= '0';
                        state <= receive;
                    end if;
                when wait_float_ready =>
                    if data_in_float_ready = '1' and weight_in_float_ready = '1' and acc_float_ready = '1' then
                        -- If it is ready, then we can receive again
                        S_AXIS_DATA_IN_tready <= '1';
                        S_AXIS_WEIGHT_IN_tready <= '1';
                        state <= receive;
                    else
                        -- Else we have to wait
                        S_AXIS_DATA_IN_tready <= '0';
                        S_AXIS_WEIGHT_IN_tready <= '0';
                        state <= wait_float_ready;
                    end if;
            end case;
        end if;
    end process;

    -- Accumulator process
    process (clk, rst)
    begin
        if rst = '1' then
            acc <= (others => '0');
            result_ready <= '1';
            acc_valid <= '1';
        elsif rising_edge(clk) then
            if result_float_valid = '1' then
                acc <= result;
            end if;
        end if;
    end process;

    M_AXIS_DATA_OUT_tdata <= acc;
    M_AXIS_DATA_OUT_tvalid <= acc_valid;

    fmadd_bf16_wrapper_inst : fmadd_bf16_wrapper
        port map (
            M_AXIS_RESULT_tdata => result,
            M_AXIS_RESULT_tready => result_ready,
            M_AXIS_RESULT_tvalid => result_float_valid,

            S_AXIS_ADDITIVE_tdata => acc,
            S_AXIS_ADDITIVE_tready => acc_float_ready,
            S_AXIS_ADDITIVE_tvalid => acc_valid,

            S_AXIS_MULT_1_tdata => data_in_buffer,
            S_AXIS_MULT_1_tready => data_in_float_ready,
            S_AXIS_MULT_1_tvalid => data_in_buffer_valid,

            S_AXIS_MULT_2_tdata => weight_in_buffer,
            S_AXIS_MULT_2_tready => weight_in_float_ready,
            S_AXIS_MULT_2_tvalid => weight_in_buffer_valid,
            aclk => clk
        );
    
    
    
end architecture behav;