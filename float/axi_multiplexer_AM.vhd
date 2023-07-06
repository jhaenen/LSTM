library ieee;
use ieee.std_logic_1164.all;

entity axi_multiplexer_am is
    port (
        aclk : in std_logic;

        S_AXIS_INPUT_tdata : in std_logic_vector(15 downto 0);
        S_AXIS_INPUT_tvalid : in std_logic;
        S_AXIS_INPUT_tready : out std_logic := '0';
        S_AXIS_INPUT_tlast : in std_logic;
        S_AXIS_INPUT_tdest : in std_logic;


        M_AXIS_OUTPUT_ACC_tdata : out std_logic_vector(15 downto 0) := (others => '0');
        M_AXIS_OUTPUT_ACC_tvalid : out std_logic := '0';
        M_AXIS_OUTPUT_ACC_tready : in std_logic;
        M_AXIS_OUTPUT_ACC_tlast : out std_logic := '0';

        M_AXIS_OUTPUT_MULT_tdata : out std_logic_vector(15 downto 0) := (others => '0');
        M_AXIS_OUTPUT_MULT_tvalid : out std_logic := '0';
        M_AXIS_OUTPUT_MULT_tready : in std_logic
    );
end entity axi_multiplexer_am;

architecture behav of axi_multiplexer_am is
    
begin
    process (aclk)
    begin
        if rising_edge(aclk) then
            if S_AXIS_INPUT_tdest = '0' then
                M_AXIS_OUTPUT_ACC_tdata <= S_AXIS_INPUT_tdata;
                M_AXIS_OUTPUT_ACC_tvalid <= S_AXIS_INPUT_tvalid;
                M_AXIS_OUTPUT_ACC_tlast <= S_AXIS_INPUT_tlast;
                S_AXIS_INPUT_tready <= M_AXIS_OUTPUT_ACC_tready;
    
                -- Set the other outputs to zero
                M_AXIS_OUTPUT_MULT_tdata <= (others => '0');
                M_AXIS_OUTPUT_MULT_tvalid <= '0';          
            else
                M_AXIS_OUTPUT_MULT_tdata <= S_AXIS_INPUT_tdata;
                M_AXIS_OUTPUT_MULT_tvalid <= S_AXIS_INPUT_tvalid;
                S_AXIS_INPUT_tready <= M_AXIS_OUTPUT_MULT_tready;
    
                -- Set the other outputs to zero
                M_AXIS_OUTPUT_ACC_tdata <= (others => '0');
                M_AXIS_OUTPUT_ACC_tvalid <= '0';
                M_AXIS_OUTPUT_ACC_tlast <= '0';
            end if;
        end if;
    end process;
end architecture behav;