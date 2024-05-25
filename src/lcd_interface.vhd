library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- we hardcode possible messages that can be displayed and use input message_select to choose the message

entity lcd_interface is port(
	clock				: in	std_logic;
	reset				: in	std_logic;
	message_select	: in 	std_logic_vector(1 downto 0);
	lcd_on			: out std_logic;
	lcd_blon			: out std_logic;
	lcd_data			: out	std_logic_vector(7 downto 0);
	lcd_rs			: out std_logic;
	lcd_rw			: out std_logic;
	lcd_enable		: out std_logic);
end lcd_interface;

architecture rtl of lcd_interface is

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
	
	-- alphabet used to encode messages
	constant A:     charcode := "01000001";
	constant B:     charcode := "01000010";
	constant C:     charcode := "01000011";
	constant D:     charcode := "01000100";
	constant E:     charcode := "01000101";
	constant F:     charcode := "01000110";
	constant G:     charcode := "01000111";
	constant H:     charcode := "01001000";
	constant I:     charcode := "01001001";
	constant J:     charcode := "01001010";
	constant K:     charcode := "01001011";
	constant L:     charcode := "01001100";
	constant M:     charcode := "01001101";
	constant N:     charcode := "01001110";
	constant O:     charcode := "01001111";
	constant P:     charcode := "01010000";
	constant Q:     charcode := "01010001";
	constant R:     charcode := "01010010";
	constant S:     charcode := "01010011";
	constant T:     charcode := "01010100";
	constant U:     charcode := "01010101";
	constant V:     charcode := "01010110";
	constant W:     charcode := "01010111";
	constant X:     charcode := "01011000";
	constant Y:     charcode := "01011001";
	constant Z:     charcode := "01011010";
	constant SP:    charcode := "00100000";	-- Space
	constant BRL:   charcode := "00101000";   -- Left Bracket
	constant BRR:   charcode := "00101001";   -- Right Bracket
	constant DASH:  charcode := "00101101";   -- Dash, as in hypen
	constant COLON: charcode := "00111010";   -- Colon:  :
	constant APO:	 charcode := "00100111";	-- Apostrophe
	
	--give LCD time to process the whole message (1ms relative to CLOCK_50)
	constant CLOCK_COUNT : integer := 50000*50;
	
	-- store message during processing by lcd display
	signal lcd_message: lcd_bus_data;
	signal ch: charcode;
	
begin

	lcd_on <= '1';
	lcd_blon <= '1';

	process_message_select: process(message_select)
	begin
		case message_select is
			-- "00" is the reset message. MUST be selected initially.
			when "00" =>
				lcd_message( 0 ) <= SET;
				lcd_message( 1 ) <= DON;
				lcd_message( 2 ) <= SEM;
				lcd_message( 3 ) <= CLR; 
				lcd_message( 4 ) <= SP; 
				lcd_message( 5 ) <= SP;
				lcd_message( 6 ) <= SP;  
				lcd_message( 7 ) <= SP;
				lcd_message( 8 ) <= SP;
				lcd_message( 9 ) <= SP;
				lcd_message( 10 ) <= SP;
				lcd_message( 11 ) <= SP;
				lcd_message( 12 ) <= SP; 
				lcd_message( 13 ) <= SP;
				lcd_message( 14 ) <= SP;
				lcd_message( 15 ) <= SP;
			when "01" => -- ZERO WINS
				lcd_message( 0 ) <= HOME;
				lcd_message( 1 ) <= Z;
				lcd_message( 2 ) <= E;
				lcd_message( 3 ) <= R;
				lcd_message( 4 ) <= O;
				lcd_message( 5 ) <= SP;
				lcd_message( 6 ) <= SP;
				lcd_message( 7 ) <= SP;
				lcd_message( 8 ) <= SP;
				lcd_message( 9 ) <= SP;
				lcd_message( 10 ) <= SP;
				lcd_message( 11 ) <= SP;
				lcd_message( 12 ) <= SP;
				lcd_message( 13 ) <= SP;
				lcd_message( 14 ) <= SP;
				lcd_message( 15 ) <= SP;
			when "10" => -- ONE WINS
				lcd_message( 0 ) <= HOME;
				lcd_message( 1 ) <= O;
				lcd_message( 2 ) <= N;
				lcd_message( 3 ) <= E;
				lcd_message( 4 ) <= SP;
				lcd_message( 5 ) <= SP;
				lcd_message( 6 ) <= SP;
				lcd_message( 7 ) <= SP;
				lcd_message( 8 ) <= SP;
				lcd_message( 9 ) <= SP;
				lcd_message( 10 ) <= SP;
				lcd_message( 11 ) <= SP;
				lcd_message( 12 ) <= SP;
				lcd_message( 13 ) <= SP;
				lcd_message( 14 ) <= SP;
				lcd_message( 15 ) <= SP;
			when others => -- TWO WINS
				lcd_message( 0 ) <= HOME;
				lcd_message( 1 ) <= T;
				lcd_message( 2 ) <= W;
				lcd_message( 3 ) <= O;
				lcd_message( 4 ) <= SP;
				lcd_message( 5 ) <= SP;
				lcd_message( 6 ) <= SP;
				lcd_message( 7 ) <= SP;
				lcd_message( 8 ) <= SP;
				lcd_message( 9 ) <= SP;
				lcd_message( 10 ) <= SP;
				lcd_message( 11 ) <= SP;
				lcd_message( 12 ) <= SP;
				lcd_message( 13 ) <= SP;
				lcd_message( 14 ) <= SP;
				lcd_message( 15 ) <= SP;
		end case;
	end process process_message_select;
	
	get_next_char: process(clock, message_select, lcd_message, reset)
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

	
end rtl;