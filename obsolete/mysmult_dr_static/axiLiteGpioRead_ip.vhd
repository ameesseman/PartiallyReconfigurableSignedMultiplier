library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity axiLiteGpioRead_ip is
        port(  clock, resetn: in std_logic;
               slv_reg_wren: in std_logic;
               slv_reg0: in std_logic_vector (31 downto 0);
               slv_reg1: out std_logic_vector (31 downto 0);
			   switch0, switch1: in std_logic
			   );
end axiLiteGpioRead_ip;

architecture structure of axiLiteGpioRead_ip is
	
	type state is (S1, S2);
	signal y: state;
	
	signal E: std_logic;
    
begin

    slv_reg1(31 downto 2) <= (others => '0');
	slv_reg1(1 downto 0) <= switch1&switch0;

	
	Transitions: process (resetn, clock, slv_reg_wren)
	begin
	   if resetn = '0' then
	       y <= S1;
	    elsif (clock'event and clock='1') then
	       case y is
	           when S1 => if slv_reg_wren = '1' then y <= S2; else y <= S1; end if;
	           when S2 => if slv_reg_wren = '1' then y <= S2; else y <= S1; end if;
	       end case;
	    end if;
	end process;
	
	Outputs: process (y, slv_reg_wren)
	begin
	   E <= '0';
	   case y is
	       when S1 =>
	       when S2 => if slv_reg_wren = '0' then E <= '1'; end if;
	   end case;
	end process;
	 
end structure;

