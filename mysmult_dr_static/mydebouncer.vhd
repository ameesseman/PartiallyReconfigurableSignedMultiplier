---------------------------------------------------------------------------
-- This VHDL file was developed by Daniel Llamocca (2014).  It may be
-- freely copied and/or distributed at no cost.  Any persons using this
-- file for any purpose do so at their own risk, and are responsible for
-- the results of such use.  Daniel Llamocca does not guarantee that
-- this file is complete, correct, or fit for any particular purpose.
-- NO WARRANTY OF ANY KIND IS EXPRESSED OR IMPLIED.  This notice must
-- accompany any copy of this file.
--------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;

-- Debounces a signal to properly detect a pulse.
entity mydebouncer is
    generic (COUNT: INTEGER := 2*(10**6));  -- 20 ms for T=10 ns (f=100 MHz)
	port (resetn, clock: in std_logic; -- clock: 100 MHz, resetn: active-low reset
	      w: in std_logic;
		  w_db: out std_logic);
end mydebouncer;

architecture behaviour of mydebouncer is

	component my_genpulse_sclr
		generic (COUNT: INTEGER:= 10**7); -- (10**7) cycles of T = 10 ns --> 10 ms
		port (clock, resetn, E, sclr: in std_logic;
				Q: out std_logic_vector ( integer(ceil(log2(real(COUNT)))) - 1 downto 0);
				z: out std_logic);
	end component;
	
	type state is (S0, S1, S2, S3, S4);
	signal y: state;
	
	signal E, sclr, z: std_logic;
	
begin

-- 10 ms counter
c1: my_genpulse_sclr generic map (COUNT => COUNT) 
    port map (clock => clock, resetn => resetn, E => E, sclr => sclr, z => z);
	 
-- Main FSM:
	Transitions: process (resetn, clock, w, z)
	begin
		if resetn = '0' then -- asynchronous signal
			y <= S0; -- if resetn asserted, go to initial state: S1			
		elsif (clock'event and clock = '1') then
			case y is
				when S0 =>
					if w = '0' then y <= S1; else y <= S1; end if;
					
				when S1 =>
					if w = '1' then y <= S2; else y <= S1; end if;
				
				when S2 =>
					if w = '1' then
						if z = '1' then y <= S3; else y <= S2; end if;
					else
						y <= S1;
					end if;
					
				when S3 =>
					if w = '1' then y <= S3; else y <= S4; end if;
				
				when S4 =>
					if w = '1' then
						y <= S3;
					else
						if z = '1' then y <= S1; else y <= S4; end if;
					end if;

			end case;			
		end if;		
	end process;
	
	Outputs: process (y, w)
	begin
		-- Initialization of FSM outputs:
		w_db <= '0'; E <= '0'; sclr <= '0';
		case y is
		
			when S0 =>
			
			when S1 =>
				E <= '1'; sclr <= '1'; 
				
			when S2 =>
				E <= '1';
				if w = '0' then sclr <= '1'; end if;
							
			when S3 =>
				w_db <= '1';
			
			when S4 =>
				w_db <= '1'; E <= '1';
				if w = '1' then sclr <= '1'; end if;
				
		end case;
	end process;
 
end behaviour;