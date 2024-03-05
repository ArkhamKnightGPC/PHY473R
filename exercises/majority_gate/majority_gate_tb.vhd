--pragma translate_off /* indicates that synthesis must not compile testbench */

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity majority_gate_tb is
end majority_gate_tb;

architecture test of majority_gate_tb is

	component majority_gate is
		port(	a,b,c 	: in 	std_logic;
				output 	: out std_logic );
	end component;
	
	signal count	: std_logic_vector(2 downto 0); /*3 bit counter*/
	signal output	: std_logic;	/*output of majority_gate*/ 

begin

	DUT: majority_gate port map(count(0), count(1), count(2), output); /*instantiate the gate (DUT - design under test)*/
	
	process begin
		count <= "000";
		for i in 0 to 7 loop /*generate all input patterns*/
			wait for 10ns;
			report "count = " & to_string(count) & ", output = " & to_string(output);
			count <= count + 1;
		end loop;
		
		std.env.stop(0);
	end process;
	
end test;

--pragma translate_on