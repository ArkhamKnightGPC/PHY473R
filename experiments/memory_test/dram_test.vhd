library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dram_test is port(
    CLOCK_50: in std_logic;
    SW: in std_logic_vector(17 downto 0);
    LCD_DATA : out std_logic_vector(7 downto 0);
    LCD_EN	: out std_logic;
    LCD_RW	: out std_logic;
    LCD_RS	: out std_logic;
    LCD_BLON	: out std_logic;
    LCD_ON	: out std_logic
);
end dram_test;

architecture dram_arch of dram_test is
component ram is port( -- RAM 4x8 (4 words of size 8 bits)
       clock	     	: in  std_logic;
       address			: in  std_logic_vector(1 downto 0); --2 bit address
       data_in			: in  std_logic_vector(7 downto 0);
       write_enable  : in  std_logic;
       chip_enable  	: in  std_logic;
       data_out   	: out std_logic_vector(7 downto 0)
    );
end component;

component lcd_display2 is port(
	clock				: in  std_logic;
	reset				: in  std_logic;
	char_to_display		: in  std_logic_vector(7 downto 0);
	lcd_on				: out std_logic;
	lcd_blon			: out std_logic;
	lcd_data			: out std_logic_vector(7 downto 0);
	lcd_rs				: out std_logic;
	lcd_rw				: out std_logic;
	lcd_enable			: out std_logic);
end component;

signal char_to_display_aux : std_logic_vector(7 downto 0) := "01000001";

begin

G1: ram port map(
    clock => CLOCK_50,
    address => SW(2 downto 1),
    data_in => "00000000",
    write_enable => '1', -- active LOW
    chip_enable => '0', -- active LOW
    data_out => char_to_display_aux
    );

G2: lcd_display2 port map(
    clock => CLOCK_50,
    reset => SW(0),
    char_to_display => char_to_display_aux,
    lcd_on => LCD_ON,
    lcd_blon => LCD_BLON,
    lcd_data => LCD_DATA,
    lcd_rs => LCD_RS,
    lcd_rw => LCD_RW,
    lcd_enable => LCD_EN
);

end architecture;