---------------------------------------------------------------------------
-- This VHDL file was developed by Daniel Llamocca (2013).  It may be
-- freely copied and/or distributed at no cost.  Any persons using this
-- file for any purpose do so at their own risk, and are responsible for
-- the results of such use.  Daniel Llamocca does not guarantee that
-- this file is complete, correct, or fit for any particular purpose.
-- NO WARRANTY OF ANY KIND IS EXPRESSED OR IMPLIED.  This notice must
-- accompany any copy of this file.
--------------------------------------------------------------------------

-- Iterative (or sequential) Multiplier N*N
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top_smult is --final signed_mult_out_circuit
	generic (N: INTEGER:= 8;
			 mode: STRING := "2C");
--	generic (N: INTEGER:= 4);-- for sim uncomment this line 
	port (clock, resetn: in std_logic;
			dA, dB: in std_logic_vector (N-1 downto 0);
			resultUn: in std_logic_vector (2*N -1 downto 0);
			Pf: out std_logic_vector (2*N -1 downto 0);
			dAabs, dBabs: out std_logic_vector (N-1 downto 0));
end top_smult;

architecture Behavioral of top_smult is

    component my_addsub
        generic (N: INTEGER:= 4);
        port(	addsub   : in std_logic;
               x, y     : in std_logic_vector (N-1 downto 0);
             s        : out std_logic_vector (N-1 downto 0);
                overflow : out std_logic;
               cout     : out std_logic);
    end component;
    
-- declearing signals here
	signal signf,Asign,Bsign: std_logic;
		
begin

	gu: if mode = "2C" generate
		Asign <= DA(N-1);
		Bsign <= DB(N-1);
		signf <= dA(N-1) xor dB(N-1);
	        -- my abs values
		AAabs: my_addsub generic map (N => N)                       --Input A
		port map(addsub => Asign,x => "00000000", y => DA , s => dAabs);
		
		BBabs: my_addsub generic map (N => N)                                   --Input B
		port map(addsub => Bsign,x => "00000000", y => DB , s => dBabs);
		--port map(addsub => Bsign,x => "0000", y => DB , s => dBabs);-- for sim
		
		MMagabs: my_addsub generic map (N => 2*N)                               --Output F
		port map(addsub => signf,x => "0000000000000000", y => resultUn , s => pf);
		--port map(addsub => signf,x => "00000000", y => resultUn , s => pf);-- for sim
	end generate; 
	
	gd: if mode = "SM" generate
	    dAabs <= '0' & dA (N-2 downto 0);
		dBabs <= '0' & dB (N-2 downto 0);
		signf <= dA(N-1) xor dB(N-1);
		Pf <= signf & resultUn(2*N-2 downto 0);
	end generate;
		



end Behavioral;