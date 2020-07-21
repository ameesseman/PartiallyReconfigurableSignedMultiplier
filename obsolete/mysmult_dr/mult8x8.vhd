---------------------------------------------------------------------------
-- This VHDL file was developed by Daniel Llamocca (2019).  It may be
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

entity mult8x8 is
    generic (N: INTEGER:= 8);
--    generic (N: INTEGER:= 4);
	port (clock, resetn: in std_logic;
	      s: in std_logic;
	      DA: in std_logic_vector (N-1 downto 0);
	      DB: in std_logic_vector (N-1 downto 0);
	      P: out std_logic_vector (2*N-1 downto 0);
		  done: out std_logic);
end mult8x8;


architecture behaviour of mult8x8 is
component my_pashiftreg_sclr 
   generic (N: INTEGER:= 4;
	         DIR: STRING:= "LEFT");
	port ( clock, resetn: in std_logic;
	       din, E, sclr, s_l: in std_logic; -- din: shiftin input
			 D: in std_logic_vector (N-1 downto 0);
	       Q: out std_logic_vector (N-1 downto 0);
          shiftout: out std_logic);
end component;

-- my rege

component my_rege
   generic (N: INTEGER:= 4);
	port ( clock, resetn: in std_logic;
	       E, sclr: in std_logic; -- sclr: Synchronous clear
			 D: in std_logic_vector (N-1 downto 0);
	       Q: out std_logic_vector (N-1 downto 0));
end component;

-- my adder_sub

component my_addsub
	generic (N: INTEGER:= 4);
	port(	addsub   : in std_logic;
		   x, y     : in std_logic_vector (N-1 downto 0);
         s        : out std_logic_vector (N-1 downto 0);
			overflow : out std_logic;
		   cout     : out std_logic);
end component;
    
    
-- name the signals here
 
signal DX, A, PI, Pt:std_logic_vector (2*N-1 downto 0);
signal B: std_logic_vector (N-1 downto 0);
signal L, E, EP, sclrP, z: std_logic;

-- state machine signal
type state is (S1, S2, S3);
	signal y: state;

begin
DX <= "00000000"&DA;
--DX <= "0000"&DA;-- for sim 
z <= not(B(7) or B(6) or B(5) or B(4) or B(3) or B(2) or B(1) or B(0));
--z <= not( B(3) or B(2) or B(1) or B(0));-- for sim

-- shift Register A left 

ra: my_pashiftreg_sclr generic map (N => 2*N, DIR => "LEFT")
port map (clock => clock, sclr =>'0', resetn => resetn, din => '0', E => E, S_l => L, D => DX, Q => A);


--Shift register B RIGHT

rb: my_pashiftreg_sclr generic map (N => N, DIR => "RIGHT")
port map (clock => clock, resetn => resetn, sclr =>'0', din => '0', E => E, S_l => L, D => DB, Q => B);



-- Adder

ga: my_addsub generic map (N => 2*N)
port map(addsub => '0',x => A, y => Pt , s => PI);


-- regester

rP: my_rege generic map(N => 2*N)
port map(clock => clock, resetn=> resetn, E => EP, sclr => sclrP, D => PI, Q => Pt);


P <= Pt;


-- state machine
Transitions: process (resetn, clock, s, z, B(0))
	begin
		if resetn = '0' then -- asynchronous signal
			y <= S1; -- if resetn asserted, go to initial state: S1			
		elsif (clock'event and clock = '1') then
			case y is
				when S1 => if s = '1' then y <= S2; else y <= S1; end if;
				when S2 => if z = '1' then y <= S3; else y <= S2; end if;
				when S3 => if s = '1' then y <= S3; else y <= S1; end if;
			end case;
		end if;
	end process;
	
	Outputs: process (y, s,z,B(0))
	begin
	   -- Initialization of output signals
		sclrP <= '0'; EP <= '0'; L <= '0'; E <= '0'; done <= '0';
		case y is
			when S1 => 
					sclrP <= '1'; EP <= '1';
					if s = '1' then
						L <= '1'; E <= '1';
					end if;
			
			when S2 =>
				E <= '1';
				if z = '0' then
					if B(0) = '1' then EP <= '1'; end if;
				end if;
				
			when S3 =>
				done <= '1';
		end case;
	end process;


end behaviour;