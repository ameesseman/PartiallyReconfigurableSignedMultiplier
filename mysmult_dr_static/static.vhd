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

entity static is	
	generic ( N: INTEGER:= 8);
	port (	clock: in std_logic;
			rst: in std_logic; -- high-level reset				
			DI: in std_logic_vector (31 downto 0);
			ofull, iempty: in std_logic;
			owren, irden: out std_logic
			Ain, Bin: out std_logic_vector(N-1 downto 0)				--inputs A and B from AXI bus sent to RP
			abs_Ain, abs_Bin: in std_logic_vector(N-1 downto 0)			--received from RP, abs values of A and B
			unsProd: std_logic_vector((N*2)-1 downto 0)					--unsigned product of abs_Ain and abs_Bin sent back to RP
			);				
end mycordic_ip;

architecture structure of mycordic_ip is


--
-- Unsigned iterative multiplier
--
component mult8x8 is
    generic (N: INTEGER:= 8);
--    generic (N: INTEGER:= 4);
	port (clock, resetn: in std_logic;
	      s: in std_logic;
	      DA: in std_logic_vector (N-1 downto 0);
	      DB: in std_logic_vector (N-1 downto 0);
	      P: out std_logic_vector (2*N-1 downto 0);
		  done: out std_logic);
end component;


--
--	Hold Input data A and B 
--
component my_rege is
		generic (N: INTEGER:= 4);
		port ( clock, resetn: in std_logic;
			   E, sclr: in std_logic; -- sclr: Synchronous clear
			   D: in std_logic_vector (N-1 downto 0);
			   Q: out std_logic_vector (N-1 downto 0));
	end component;
	
--
-- Used to tell FSM that new data has been received
--
component genStartSignal is
    Generic(N : integer := 32);
    Port ( clock,resetn: in std_logic;
           idata : in STD_LOGIC_VECTOR (N-1 downto 0);
           Z : out STD_LOGIC);
end component;



--Signals
signal resetn: std_logic;
	
type state is (S1, S2, S3, S4, S5, S6, S7);
signal y: state;

signal sig_done: std_logic;			--from iterative multiplier

--Input data register
signal sig_ABdata: std_logic_vector(31 downto 0);

--Comparators output
signal sig_compA, sig_compB: std_logic;
signal sig_new_data: std_logic;				--fsm input

--FSM
signal sig_Eri, sig_s: std_logic;			--fsm output signals
signal count_internal: integer range 0 to 7;	      


--signal zeros: std_logic_vector(N-1 downto 0);

begin

resetn <= not(rst);
sig_new_data <= sig_compA and sig_compB;
Ain <= sig_ABdata(7 downto 0);
Bin <= sig_ABdata(15 downto 8);

-- ****************************
-- Controllingo BOTH the Input/Output side:	
-- **************************** 
		Transitions: process (rst, clock, iempty, ofull, sig_done, sig_new_data)
		begin
			if rst = '1' then
				y <= S1; 
				count_internal <= 0;       --setting to zero is necessary to cause unwanted behavior on reset
			elsif (clock'event and clock = '1') then
				case y is
					when S1 =>
					    if iempty = '1' then y <= S2; else y <= S1; end if;
					    
					when S2 =>
                        if iempty = '0' and ofull = '0' then
								y <= S3; 
						else y <= S2; 
						end if;
						
					when S3 =>
						if sig_new_data = '1' then y <= S4; 
						else 
							if count = 5 then y <= S4; count <= 0;
							else count <= count+1; y <= S3;
							end if;
						end if;
				
					when S4 =>
						y <= S5;
	
					when S5 =>
						if sig_done = '1' then y <= S6; else y <= S5; end if;
                        
					when S6 =>
						if count = 5 then y <= S7; count <= 0;
						else count <= count+1; y <= S6;
						end if;
                       			   
					when S7 =>
                       y <= S2;
					   
				end case;
			end if;
		end process;
				
		Outputs: process (y, iempty, ofull)
		begin
			-- Initialization of signals
			sig_s <= '0';
			sig_Eri <= '0';
			irden <= '0';
			owren <= '0';

			case y is
				when S1 =>	
					--do nothing
				
				--load A and B into input register
				when S2 =>
                    if iempty = '0' and ofull = '0' then
                        irden <= '1'; sig_Eri <= '1';
					end if;	
				
				when S3 =>
					--waiting for new input data (sig_new_data = '1' or 5 clock cycles passed)
				
				when S4 =>
					sig_s <= '1';
				
				when S5 =>
					--no outputs
					
				when S6 =>
					--no outputs. Waiting a few clock cycles so RP is finished with data
				
				when S7 =>
					owren <= '1';
				

				end case;
			
		end process;
		
		
	mult: mult8x8
		generic map ( N => 8 )
		port map ( clock => clock,
				   resetn => resetn,
				   s => sig_s,
				   DA => abs_Ain,
				   DB => abs_Bin,
				   P => unsProd,
				   done => sig_done
				   );


-- Register for holding X and Y in values before Zin and mode are fed to Cordic circuit       
    reg: my_rege generic map(N => 32)
        port map(clock => clock,  
                 resetn => resetn, 
                 E => sig_Eri, 
                 sclr => '0', 
                 D => DI, 
                 Q => sig_ABdata
                 );

	ac: genStartSignal
        generic map(N => N)        --use 14 because this in BCD will be 20 bits and all we need
                                    --20 bits BCD is 5 dec values which allows up to 999.99degF
        port map( clock => clock,
                  resetn => resetn,
                  idata => abs_Ain,
                  Z =>  sig_compA
                  );   


	bc: genStartSignal
        generic map(N => N)        --use 14 because this in BCD will be 20 bits and all we need
                                    --20 bits BCD is 5 dec values which allows up to 999.99degF
        port map( clock => clock,
                  resetn => resetn,
                  idata => abs_Bin,
                  Z =>  sig_compB
                  ); 				



end structure;