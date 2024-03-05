library ieee;
use ieee.std_logic_1164.all;

entity majority_gate is
	port(	a,b,c 	: in 	std_logic;
			output 	: out std_logic );
end majority_gate;

architecture dataflow of majority_gate is
begin
	output <= (a and b) or (b and c) or (a and c);
end dataflow;
