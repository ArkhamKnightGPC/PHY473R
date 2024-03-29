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
		LCD_BLON	: out std_logic;
		LCD_ON	: out std_logic
	);
end lcd_test;

architecture lcd_test_arch of lcd_test is

	component lcd_display is port(
		clock				: in	std_logic;
		reset				: in	std_logic;
		message_select	: in 	std_logic_vector(1 downto 0);
		lcd_on			: out std_logic;
		lcd_blon			: out std_logic;
		lcd_data			: out	std_logic_vector(7 downto 0);
		lcd_rs			: out std_logic;
		lcd_rw			: out std_logic;
		lcd_enable		: out std_logic);
	end component;

begin

	G1: lcd_display port map(
		clock				=> CLOCK_50,
		reset				=> KEY(0),
		message_select => KEY(2 downto 1),
		lcd_on 			=> LCD_ON,
		lcd_blon 		=> LCD_BLON,
		lcd_data 		=> LCD_DATA,
		lcd_rs			=> LCD_RS,
		lcd_rw			=> LCD_RW,
		lcd_enable		=>	LCD_EN);

end lcd_test_arch;