library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- USER CONTROLS
-- KEY(0) reset
-- KEY(1) take_photo

entity digit_detector is port(
	CLOCK_50		:	in		std_logic;
	KEY			:	in		std_logic_vector(3 downto 0);
	CMOS_MCLK 	: 	out	std_logic;
	CMOS_SDAT 	: 	out	std_logic;
	CMOS_SCLK 	: 	out	std_logic;
	CMOS_FVAL 	: 	in		std_logic;
	CMOS_LVAL 	: 	in		std_logic;
	CMOS_PIXCLK	: 	in		std_logic;
	CMOS_DATA 	: 	in		std_logic_vector(9 downto 0);
	VGA_HS		:	out	std_logic;
	VGA_VS		:	out	std_logic;
	VGA_R			:	out	std_logic_vector(7 downto 0);
	VGA_G			:	out	std_logic_vector(7 downto 0);
	VGA_B			:	out	std_logic_vector(7 downto 0);
	VGA_BLANK_N : 	out	std_logic;
	VGA_SYNC_N	: 	out	std_logic;
	VGA_CLK		: 	out 	std_logic;
	LEDG			:	out	std_logic_vector(7 downto 0); -- CURRENT STATE
	LEDR			:	out	std_logic_vector(17 downto 0) -- OUTPUT: detected digit
);
end digit_detector;

architecture rtl of digit_detector is

component digit_detector_datapath port(
	clock				:	in			std_logic;
	state_in			:	in			std_logic_vector(2 downto 0);
	state_photo		:	in			std_logic;
	state_rgb		:	in			std_logic;
	state_grayscale:	in			std_logic;
	state_detection:	in			std_logic;
	stop_photo		:	out		std_logic;
	rgb_done			:	out		std_logic;
	grayscale_done	:	out		std_logic;
	detection_done	:	out		std_logic;
	
	camera_serial_clk 	: out std_logic;
	camera_master_clk 	: out std_logic;
	camera_serial_data 	: out std_logic;
	camera_line_valid 	: in 	std_logic;
	camera_frame_valid 	: in 	std_logic;
	camera_pixclk 			: in 	std_logic;
	camera_data_out 		: in 	std_logic_vector(9 downto 0);
	
	Hsync				:	out	std_logic;
	Vsync				:	out	std_logic;
	red				:	out	std_logic_vector(7 downto 0);
	green				:	out	std_logic_vector(7 downto 0);
	blue				:	out	std_logic_vector(7 downto 0);
	nblanck 			: 	out	std_logic;
	nsync				: 	out	std_logic;
	pxclk				: 	out 	std_logic);
end component;

component digit_detector_control_unit port(
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
	state_out		:	out	std_logic_vector(2 downto 0));
end component;

signal state_out_internal : std_logic_vector(2 downto 0);
signal state_photo_internal : std_logic;
signal state_rgb_internal : std_logic;
signal state_grayscale_internal : std_logic;
signal state_detection_internal : std_logic;
signal photo_done_internal : std_logic;
signal rgb_done_internal : std_logic;
signal grayscale_done_internal : std_logic;
signal detection_done_internal : std_logic;
signal stop_photo_internal	: std_logic;

begin

G0: digit_detector_datapath port map(
	clock				=> CLOCK_50,
	state_in			=> state_out_internal,
	state_photo		=> state_photo_internal,
	state_rgb		=> state_rgb_internal,
	state_grayscale=> state_grayscale_internal,
	state_detection=> state_detection_internal,
	stop_photo => stop_photo_internal,
	rgb_done			=> rgb_done_internal,
	grayscale_done	=> grayscale_done_internal,
	detection_done	=> detection_done_internal,
	
	camera_serial_clk => CMOS_SCLK,
	camera_master_clk => CMOS_MCLK,
	camera_serial_data => CMOS_SDAT,

	camera_line_valid => CMOS_LVAL,
	camera_frame_valid => CMOS_FVAL,
	camera_pixclk => CMOS_PIXCLK,
	camera_data_out => CMOS_DATA,
	
	Hsync				=> VGA_HS,
	Vsync				=> VGA_VS,
	red				=> VGA_R,
	green				=> VGA_G,
	blue				=> VGA_B,
	nblanck 			=> VGA_BLANK_N,
	nsync				=> VGA_SYNC_N,
	pxclk				=> VGA_CLK
);

G1: digit_detector_control_unit port map(
	clock				=> CLOCK_50,
	reset				=> not KEY(0),
	take_photo		=> not KEY(1),
	stop_photo		=> stop_photo_internal,
	rgb_done			=> rgb_done_internal,
	grayscale_done	=> grayscale_done_internal,
	detection_done	=> detection_done_internal,
	state_photo		=>	state_photo_internal,
	state_rgb		=> state_rgb_internal,
	state_grayscale =>state_grayscale_internal,
	state_detection => state_detection_internal,
	state_out		=> state_out_internal
);

LEDG(2 downto 0) <= state_out_internal;
LEDR(0) <= state_photo_internal;
LEDR(1) <= state_rgb_internal;
LEDR(2) <= state_grayscale_internal;
LEDR(3) <= state_detection_internal;
LEDR(4) <= stop_photo_internal;


end rtl;