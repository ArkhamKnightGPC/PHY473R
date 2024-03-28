library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lcd_test is
	port(
		CLOCK_50	: in 	std_logic;
		KEY		: in	std_logic_vector(3 downto 0);
		LCD_DATA : out std_logic_vector(7 downto 0);
		LCD_EN	: out std_logic;
		LCD_RW	: out std_logic;
		LCD_RS	: out std_logic;
		LCD_ON	: out std_logic
	);
end lcd_test;

architecture lcd_test_arch of lcd_test is

		type StateType is (STATE_A, STATE_B);
		signal CurrentState, NextState : StateType;

begin
	LCD_ON <= '1';
	LCD_EN <= '1';
	
	LCD_RW <= '0'; --we write data to the LCD
	
	process(CLOCK_50)
	begin
		if rising_edge(CLOCK_50) then
			if KEY(0) = '0' then --button is pressed
				CurrentState <= STATE_A; --initialize state machine
			elsif rising_edge(CLOCK_50) then
				CurrentState <= Next_State; --state transition logic
			end if;
		end if;
	end process;
	
	process(CurrentState)
	begin
		case CurrentState is
			when STATE_A =>
					LCD_RS <= '1'; --send character data to LCD
			when STATE_B =>
		end case;LCD_RS
	end process;
	
end lcd_test_arch;