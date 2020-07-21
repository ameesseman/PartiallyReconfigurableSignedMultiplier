----------------------------------------------------------------------------------
-- Company: Oakland University
-- Engineer: Hussein Alawsi
-- 
-- Create Date: 05/30/2020 11:38:05 PM
-- Design Name: 
-- Module Name: signed_mult_ip - Behavioral
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

entity sam_2c_rp is
    generic(N : INTEGER := 8);
--    generic(N : INTEGER := 4);-- for sim
    Port (clock, resetn: in std_logic; 
           DA : in STD_LOGIC_VECTOR (N-1 downto 0);
           DB : in STD_LOGIC_VECTOR (N-1 downto 0);
           resultUn: in std_logic_vector (2*N-1 downto 0);
           done : out STD_LOGIC;
           P : out STD_LOGIC_VECTOR (2*N-1 downto 0);
           dAabs, dBabs: out std_logic_vector (N-1 downto 0));
end sam_2c_rp;

architecture Behavioral of sam_2c_rp is

	component top_smult is --final signed_mult_out_circuit
	generic (N: INTEGER:= 8;
			 mode: STRING := "2C");
	port (clock, resetn: in std_logic;
			dA, dB: in std_logic_vector (N-1 downto 0);
			resultUn: in std_logic_vector (2*N -1 downto 0);
			Pf: out std_logic_vector (2*N -1 downto 0);
			dAabs, dBabs: out std_logic_vector (N-1 downto 0));
	end component;

constant mode: STRING:= "SM"; -- "2C", "SM" are allowed

begin

	rp: top_smult
		generic map( N => N, mode => mode)
		port map( clock => clock,
				  resetn => resetn,
			      dA => dA, 
				  dB => dB,
			      resultUn => resultUn,
			      Pf => P,
			      dAabs => dAabs,
				  dBabs => dBabs
				);

    
end Behavioral;
