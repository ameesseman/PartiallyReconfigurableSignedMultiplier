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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity smult_ip is
	port (	clock: in std_logic;
			rst: in std_logic; -- high-level reset				
			DI: in std_logic_vector (31 downto 0);
			DO: out std_logic_vector (31 downto 0);
			ofull, iempty: in std_logic;
			owren, irden: out std_logic;
			done_irq: out std_logic
		  );				
end smult_ip;

architecture structure of smult_ip is

    component static is	
	generic ( N: INTEGER:= 8);
	port (	clock: in std_logic;
			rst: in std_logic; -- high-level reset				
			DI: in std_logic_vector (31 downto 0);
			ofull, iempty: in std_logic;
			owren, irden: out std_logic;
			Ain, Bin: out std_logic_vector(N-1 downto 0);				--inputs A and B from AXI bus sent to RP
			abs_Ain, abs_Bin: in std_logic_vector(N-1 downto 0);	    --received from RP, abs values of A and B
			unsProd: out std_logic_vector((N*2)-1 downto 0);			--unsigned product of abs_Ain and abs_Bin sent back to RP
			pFinal: in std_logic_vector((N*2)-1 downto 0); 
			pFinalReg: out std_logic_vector((N*2)-1 downto 0);
			done_irq: out std_logic
			);				
	end component;
	
	component sam_2c_rp is
    generic(N : INTEGER := 8);
    Port (clock, resetn: in std_logic; 
           DA : in STD_LOGIC_VECTOR (N-1 downto 0);
           DB : in STD_LOGIC_VECTOR (N-1 downto 0);
           resultUn: in std_logic_vector (2*N-1 downto 0);
           done : out STD_LOGIC;
           P : out STD_LOGIC_VECTOR (2*N-1 downto 0);
           dAabs, dBabs: out std_logic_vector (N-1 downto 0));
	end component;
	
--	component signed_mult_out_c is --final signed_mult_out_circuit
--        generic (N: INTEGER:= 8);
--    --	generic (N: INTEGER:= 4);-- for sim uncomment this line 
--        port (clock, resetn: in std_logic;
--                dA, dB: in std_logic_vector (N-1 downto 0);
--                resultUn: in std_logic_vector (2*N -1 downto 0);
--                Pf: out std_logic_vector (2*N -1 downto 0);
--                dAabs, dBabs: out std_logic_vector (N-1 downto 0));
--    end component;
	
	
signal zeros: std_logic_vector(15 downto 0);
constant N: INTEGER:= 8;
	
	
--
-- INTERNAL SIGNALS
--
signal resetn: std_logic;

--from static
signal sig_Ain, sig_Bin: std_logic_vector(N-1 downto 0); 
signal sig_unsP: std_logic_vector((N*2)-1 downto 0); 
signal sig_finalProductRegistered: std_logic_vector((N*2)-1 downto 0);

--from RP
signal sig_absA, sig_absB: std_logic_vector(N-1 downto 0); 
signal sig_finalProduct: std_logic_vector((N*2)-1 downto 0);

--data to oFIFO
signal sig_outData: std_logic_vector(31 downto 0);

begin

resetn <= not (rst);
zeros <= (others => '0');

--constructing signal that will be sent to oFIFO
sig_outData <= zeros&sig_finalProductRegistered;
DO <= sig_outData;

 				 
-- static IP
gL: static generic map ( N => N )
			 port map (	rst => rst,
						clock => clock,					
						DI => DI,
						ofull => ofull, 
						iempty => iempty,
						owren => owren,
						irden => irden,
						Ain => sig_Ain,
						Bin => sig_Bin,				
						abs_Ain => sig_absA, 
						abs_Bin => sig_absB,		
						unsProd => sig_unsP, 
						pFinal => sig_finalProduct,
						pFinalReg => sig_finalProductRegistered,	
						done_irq => done_irq			
						);
					
rP: sam_2c_rp 
		generic map (N => N)
		port map ( clock => clock, 
				   resetn => resetn, 
				   DA => sig_Ain,  
				   DB => sig_Bin,  
				   resultUn => sig_unsP, 
				   done => open,  
				   P => sig_finalProduct,  
				   dAabs => sig_absA, 
				   dBabs =>	sig_absB 
				  );

--my_2c: signed_mult_out_c generic map (N => N)
--    port map(clock=> clock, resetn => resetn, dA => sig_Ain, dB => sig_Bin, resultUn => sig_unsP,
--            pf => sig_finalProduct, dAabs=> sig_absA, dBabs=> sig_absB );
            			  
			

end structure;