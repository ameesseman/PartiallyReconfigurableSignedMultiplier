----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/17/2020 05:04:44 PM
-- Design Name: 
-- Module Name: genStartSignal - Behavioral
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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity genStartSignal is
    Generic(N : integer := 32);
    Port ( clock,resetn: in std_logic;
           idata : in STD_LOGIC_VECTOR (N-1 downto 0);
           Z : out STD_LOGIC);
end genStartSignal;

architecture Behavioral of genStartSignal is

component comparator_nbits is
generic( N : integer := 32);
port ( 
      a, b: in std_logic_vector(N-1 downto 0);
      z : out std_logic     -- output 1 when a = b
      );
end component;

component my_rege is
   generic (N: INTEGER:= 4);
	port ( clock, resetn: in std_logic;
	       E, sclr: in std_logic; -- sclr: Synchronous clear
			 D: in std_logic_vector (N-1 downto 0);
	       Q: out std_logic_vector (N-1 downto 0));
end component;

signal sig_new_out, sig_last_out: std_logic_vector(N-1 downto 0);
signal sig_comp_out, sig_comp_inv: std_logic;

begin

sig_comp_inv <= not(sig_comp_out);
Z<= sig_comp_inv;

newv: my_rege 
        generic map(N => N)
        port map(clock => clock,
                 resetn => resetn, 
                 E => '1',
                 sclr => '0',
                 D => idata,
                 Q => sig_new_out
                 );
                 
lastv: my_rege 
        generic map(N => N)
        port map(clock => clock,
                 resetn => resetn, 
                 E => sig_comp_inv,
                 sclr => '0',
                 D => idata,
                 Q => sig_last_out
                 );  
                 
comp:  comparator_nbits
        generic map(N => N)
        port map(a =>  sig_new_out,
                 b => sig_last_out,
                 z =>   sig_comp_out
                 );         


end Behavioral;
