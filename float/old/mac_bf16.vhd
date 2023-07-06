library ieee;
use ieee.std_logic_1164.all;

entity mac_bf16 is
    port (
        clk   : in std_logic;
        rst : in std_logic;
        
        en          : in std_logic;

        data_in     : in std_logic_vector(15 downto 0);
        weight_in   : in std_logic_vector(15 downto 0);

        data_out    : out std_logic_vector(15 downto 0);
        valid       : out std_logic
    );
end entity;

architecture rtl of mac_bf16 is
    component bf16_fmadd is
        port(
            clk: in std_logic;
            reset: in std_logic;
    
            en : in std_logic;
    
            mult1: in std_logic_vector(15 downto 0);
            mult2: in std_logic_vector(15 downto 0);
            
            additive: in std_logic_vector(15 downto 0);
    
            result: out std_logic_vector(15 downto 0)
        );
    end component;

    signal acc : std_logic_vector(15 downto 0);
    signal result : std_logic_vector(15 downto 0);

begin

    process(clk, rst)
        constant NUM_PIPELINE_STAGES : natural := 4;
        variable counter : natural range 0 to (NUM_PIPELINE_STAGES-1) := 0;
    begin
        if rst = '1' then
            acc <= (others => '0');
            counter := 0;
            valid <= '0';
        elsif rising_edge(clk) then
            if en = '1' then
                acc <= result;

                if counter = (NUM_PIPELINE_STAGES-1) then
                    valid <= '1';
                else
                    valid <= '0';
                    counter := counter + 1;
                end if;
            else 
                valid <= '0';
            end if;
        end if;
    end process;

    data_out <= acc;

    fmadd : bf16_fmadd
        port map(
            clk => clk,
            reset => rst,
            en => en,
            mult1 => data_in,
            mult2 => weight_in,
            additive => acc,
            result => result
        );
end rtl;
