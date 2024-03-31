library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lcd_display2 is port(
	clock				: in  std_logic;
	reset				: in  std_logic;
	char_to_display		: in  std_logic_vector(7 downto 0);
	lcd_on				: out std_logic;
	lcd_blon			: out std_logic;
	lcd_data			: out std_logic_vector(7 downto 0);
	lcd_rs				: out std_logic;
	lcd_rw				: out std_logic;
	lcd_enable			: out std_logic);
end lcd_display2;

architecture lcd_display2_arch of lcd_display2 is

	subtype charcode is std_logic_vector( 0 to 7 );
	type lcd_bus_data is array( 0 to 15 ) of charcode;

	-- Clear screen.
	constant CLR:   charcode := "00000001";
	-- Display ON, with cursor.
	constant DON:   charcode := "00001110";
	-- Set Entry Mode to increment cursor automatically after each character is displayed.
	constant SEM:   charcode := "00000110";
	-- Home cursor
	constant HOME:  charcode := "00000010";
	-- Function set for 8-bit data transfer and 2-line display
	constant SET:   charcode := "00111000";
	
	--give LCD time to process the whole message (1ms relative to CLOCK_50)
	constant CLOCK_COUNT : integer := 50000*50;
	
	-- store message during processing by lcd display
	signal lcd_message: lcd_bus_data;
	signal ch: charcode;
	
begin

	lcd_on <= '1';
	lcd_blon <= '1';

	process_message_select: process(char_to_display)
	begin
		lcd_message( 0 ) <= SET;
		lcd_message( 1 ) <= DON;
		lcd_message( 2 ) <= SEM;
		lcd_message( 3 ) <= CLR; 
		lcd_message( 4 ) <= char_to_display; 
		lcd_message( 5 ) <= char_to_display;
		lcd_message( 6 ) <= char_to_display;  
		lcd_message( 7 ) <= char_to_display;
		lcd_message( 8 ) <= char_to_display;
		lcd_message( 9 ) <= char_to_display;
		lcd_message( 10 ) <= char_to_display;
		lcd_message( 11 ) <= char_to_display;
		lcd_message( 12 ) <= char_to_display; 
		lcd_message( 13 ) <= char_to_display;
		lcd_message( 14 ) <= char_to_display;
		lcd_message( 15 ) <= char_to_display;
	end process process_message_select;
	
	get_next_char: process(clock, char_to_display, lcd_message, reset)
		variable count: integer range 0 to 15;
		variable time_count: integer range 0 to CLOCK_COUNT;
	begin
		if rising_edge(clock) then
			if reset = '1' then
				time_count := 0;
				count := 0;
			elsif time_count = CLOCK_COUNT then
				if count = 15 then
					ch <= lcd_message(15);
					count := 0;
				else
					ch <= lcd_message(count);
					count := count + 1;
				end if;
				time_count := 0;
			else
				time_count := time_count + 1;
			end if;
		end if;
	end process get_next_char;
	
	write_char_on_lcd: process(ch, clock, reset)
		variable time_count: integer range 0 to CLOCK_COUNT;
	begin
		if rising_edge(clock) then
			  if reset = '1' then
					time_count := 0;
					lcd_enable <= '0';
			  elsif time_count = CLOCK_COUNT then
					if (ch < "00100000") or (ch = "00111000") then
						 lcd_rs <= '0'; -- instruction
					else
						 lcd_rs <= '1'; -- data
					end if;
					
					lcd_rw <= '0';
					lcd_data <= ch;
					lcd_enable <= '1';
					time_count := 0;
			  else
					time_count := time_count + 1;
					lcd_enable <= '0';
			  end if;
		 end if;
	end process write_char_on_lcd;

	
end architecture;
