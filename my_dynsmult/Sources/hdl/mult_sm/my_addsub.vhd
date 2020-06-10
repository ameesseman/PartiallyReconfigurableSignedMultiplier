---------------------------------------------------------------------------
-- This VHDL file was developed by Daniel Llamocca (2013).  It may be
-- freely copied and/or distributed at no cost.  Any persons using this
-- file for any purpose do so at their own risk, and are responsible for
-- the results of such use.  Daniel Llamocca does not guarantee that
-- this file is complete, correct, or fit for any particular purpose.
-- NO WARRANTY OF ANY KIND IS EXPRESSED OR IMPLIED.  This notice must
-- accompany any copy of this file.
--------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity my_addsub is
	generic (N: INTEGER:= 4);
	port(	addsub   : in std_logic;
		   x, y     : in std_logic_vector (N-1 downto 0);
         s        : out std_logic_vector (N-1 downto 0);
			overflow : out std_logic;
		   cout     : out std_logic);
end my_addsub;

architecture structure of my_addsub is

	component fulladd
		port( cin, x, y : in std_logic;
				s, cout   : out std_logic);
	end component;

	signal c: std_logic_vector (N downto 0);
	signal yx: std_logic_vector (N-1 downto 0);
	
begin

   c(0) <= addsub; cout <= c(N);
	overflow <= c(N) xor c(N-1);	
	
	gi: for i in 0 to N-1 generate
			   yx(i) <= y(i) xor addsub;
				fi: fulladd port map (cin => c(i), x => x(i), y => yx(i), s => s(i), cout => c(i+1));
	    end generate;
   
end structure;