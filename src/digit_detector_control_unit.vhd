library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity digit_detector_control_unit is port(
	clock					:	in		std_logic;
	reset					:	in		std_logic;
	take_photo			:	in		std_logic;
	start_detection	:	in		std_logic;
	config_done			:	in		std_logic;
	detection_done		:	in		std_logic;
	state_out			:	out	std_logic_vector(3 downto 0)
);
end digit_detector_control_unit;

architecture rtl of digit_detector_control_unit is

	type state is(
		CONFIG,
		WAIT_PHOTO,
		WAIT_DETECTION,
		DETECTION,
		SHOW_RESULT
	);
	signal present_state, next_state : state;

begin

	--handle asynchronous reset
	p0: process(clock, reset)
	begin
		if reset = '1' then
			present_state <= CONFIG;
		elsif rising_edge(clock) then
			present_state <= next_state;
		end if;
	end process;
	
	--for each state: determine output values and transitions
	p1: process(present_state)
	begin
	
		case present_state is
		
		when CONFIG =>
			state_out <= "0000";
			if config_done = '1' then
				next_state <= WAIT_PHOTO;
			else
				next_state <= CONFIG;
			end if;
			
		when WAIT_PHOTO =>
			state_out <= "0001";
			if take_photo = '1' then
				next_state <= WAIT_DETECTION;
			else
				next_state <= WAIT_PHOTO;
			end if;
			
		when WAIT_DETECTION =>
			state_out <= "0010";
			if start_detection='1' then
				next_state <= DETECTION;
			else
				next_state <= WAIT_DETECTION;
			end if;
			
		when DETECTION =>
			state_out <= "0011";
			if detection_done='1' then
				next_state <= SHOW_RESULT;
			else
				next_state <= DETECTION;
			end if;
			
		when SHOW_RESULT =>
			state_out <= "0100";
			next_state <= SHOW_RESULT;
			
		when others => --just to avoid compilation error
			state_out <= "1111";
			next_state <= CONFIG;
			
		end case;
	end process;

end rtl;