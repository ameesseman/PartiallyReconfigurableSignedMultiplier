-- VHDL project: VHDL code for comparator
-- fpga4student.com FPGA projects, Verilog projects, VHDL projects

--NOT MY CODE. FOUND ONLINE

library IEEE;
use IEEE.std_logic_1164.all;

entity comparator_nbits is
generic( N : integer := 8);
port ( 
      a, b: in std_logic_vector(N-1 downto 0);
      z : out std_logic     -- output 1 when a = b
      );
end comparator_nbits;

architecture Behavioral of comparator_nbits is
signal AB: std_logic_vector(N-1 downto 0); -- temporary variables

signal sig_same : std_logic_vector(N-1 downto 0);

begin

sig_same <= (others => '1');

 ga: for j in 0 to N-1 generate
        AB(j) <= (not A(j)) xnor (not B(j));  
    end generate;

 with AB select
    z <= '1' when "11111111",          --will not synthesize with sig_same now for some reason???
         '0' when others;
         
end Behavioral;

