----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/25/2023 01:38:23 PM
-- Design Name: 
-- Module Name: MAC - behav
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library ieee;
use ieee.STD_LOGIC_1164.ALL;

-- Synthesis only
use ieee.fixed_pkg.all; 

-- Simulation only
-- library ieee_proposed;
-- use ieee_proposed.fixed_pkg.all;

use work.rnn_pkg.all;

entity MAC is
    port ( 
        clk         : in std_logic;
        rst         : in std_logic;
        en          : in std_logic;

        data_in     : in data_t;
        weight_in   : in data_t;

        data_out    : out acc_t
    );
end MAC;

architecture behav of MAC is

    signal acc : acc_t;

    signal output_buffer : acc_t;

begin

    process (clk, rst)
        variable mult   : sfixed(data_t'high * 2 + 1 downto data_t'low*2);
        variable sum    : sfixed(data_t'high + 1 downto data_t'low); 
    begin

        if rst = '1' then
            acc <= (others => '0');
        elsif rising_edge(clk) then
            if en = '1' then
                acc <=  resize(acc + (data_in * weight_in), acc_t'high, acc_t'low);

                output_buffer <= acc;
            end if;
        end if;

    end process;
    
    data_out <= output_buffer;
end behav;
