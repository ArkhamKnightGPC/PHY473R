library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity digit_detector_control_unit is port(
	clock				:	in		std_logic;
	reset				:	in		std_logic;
	take_photo		:	in		std_logic;
	stop_photo		:	in		std_logic;
	rgb_done			:	in		std_logic;
	grayscale_done	:	in		std_logic;
	detection_done	:	in		std_logic;
	state_photo		:	out 	std_logic;
	state_rgb		:	out	std_logic;
	state_grayscale:	out	std_logic;
	state_detection:	out	std_logic;
	state_out		:	out	std_logic_vector(2 downto 0)
);
end digit_detector_control_unit;

architecture rtl of digit_detector_control_unit is

	type state is(
		START,
		TAKING_PHOTO,
		CONVERT_TO_RGB,
		CONVERT_TO_GRAYSCALE,
		DETECTION,
		DONE
	);
	signal present_state, next_state: state;

begin

	p1: process(clock, reset)
	begin
		if reset='1' then
			present_state <= START;
		elsif	rising_edge(clock) then
			present_state <= next_state;
		end if;
	end process;
	
	--Circuit outputs and next_state logic
	p2: process(present_state, take_photo, stop_photo, rgb_done, grayscale_done, detection_done)
	begin
		case present_state is
			when START=>
				state_out <= "000";
				state_photo <= '0';
				state_rgb <= '0';
				state_grayscale <= '0';
				state_detection <= '0';
				if take_photo='1' then
					next_state <= TAKING_PHOTO;
				else
					next_state <= START;
				end if;
			when TAKING_PHOTO=>
				state_out <= "001";
				state_photo <= '1';
				state_rgb <= '0';
				state_grayscale <= '0';
				state_detection <= '0';
				if stop_photo='1' then
					next_state <= CONVERT_TO_RGB;
				else
					next_state <= TAKING_PHOTO;
				end if;
			when CONVERT_TO_RGB=>
				state_out <= "010";
				state_photo <= '0';
				state_rgb <= '1';
				state_grayscale <= '0';
				state_detection <= '0';
				if rgb_done='1' then
					next_state <= CONVERT_TO_GRAYSCALE;
				else
					next_state <= CONVERT_TO_RGB;
				end if;
			when CONVERT_TO_GRAYSCALE=>
				state_out <= "011";
				state_photo <= '0';
				state_rgb <= '0';
				state_grayscale <= '1';
				state_detection <= '0';
				if grayscale_done='1' then
					next_state <= DETECTION;
				else
					next_state <= CONVERT_TO_GRAYSCALE;
				end if;
			when DETECTION=>
				state_out <= "100";
				state_photo <= '0';
				state_rgb <= '0';
				state_grayscale <= '0';
				state_detection <= '1';
				if	detection_done='1' then
					next_state <= DONE;
				else
					next_state <= DETECTION;
				end if;
			when DONE =>
				state_out <= "101";
				state_photo <= '0';
				state_rgb <= '0';
				state_grayscale <= '0';
				state_detection <= '0';
				next_state <= DONE;
			when others =>
				next_state <= START;--Just in case something goes really wrong
			end case;
	end process;

end rtl;
