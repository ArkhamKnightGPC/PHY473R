library ieee;

use ieee.std_logic_1164.all;

entity image_treatment_test is port(
);
end image_treatment_test;

architecture image_treatment_arch of image_treatment_test is

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

component ram is port( -- RAM 262144x10 (262144 words of size 10 bits)
       clock	     	: in  std_logic;
       address			: in  std_logic_vector(17 downto 0); --18 bit address
       data_in			: in  std_logic_vector(9 downto 0);
       write_enable  : in  std_logic;
       chip_enable  	: in  std_logic;
       data_out   	: out std_logic_vector(9 downto 0)
    );
end component;

begin
end architecture;