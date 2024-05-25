library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity digit_detector is port(
	CLOCK_50		:	in		std_logic;
	KEY			:	in		std_logic_vector(3 downto 0);
	SW        	: 	in 	std_logic_vector(17 downto 0);
	CMOS_MCLK 	: 	out	std_logic;
	CMOS_SDAT 	: 	inout	std_logic;
	CMOS_SCLK 	: 	out	std_logic;
	CMOS_FVAL 	: 	in		std_logic;
	CMOS_LVAL 	: 	in		std_logic;
	CMOS_PIXCLK	: 	in		std_logic;
	CMOS_DATA 	: 	in		std_logic_vector(9 downto 0);
	VGA_HS		:	inout	std_logic;
	VGA_VS		:	inout	std_logic;
	VGA_R			:	out	std_logic_vector(7 downto 0);
	VGA_G			:	out	std_logic_vector(7 downto 0);
	VGA_B			:	out	std_logic_vector(7 downto 0);
	VGA_BLANK_N : 	out	std_logic;
	VGA_SYNC_N	: 	out	std_logic;
	VGA_CLK		: 	out 	std_logic;
	LCD_DATA 	: 	out	std_logic_vector(7 downto 0);
	LCD_EN		: 	out	std_logic;
	LCD_RW		: 	out	std_logic;
	LCD_RS		: 	out	std_logic;
	LCD_BLON		: 	out	std_logic;
	LCD_ON		: 	out	std_logic;
	LEDG			:	out	std_logic_vector(7 downto 0);
	LEDR			:	out	std_logic_vector(17 downto 0)
);
end digit_detector;

architecture rtl of digit_detector is

	component digit_detector_control_unit port(
		clock					:	in		std_logic;
		reset					:	in		std_logic;
		take_photo			:	in		std_logic;
		start_detection	:	in		std_logic;
		config_done			:	in		std_logic;
		detection_done		:	in		std_logic;
		state_out			:	out	std_logic_vector(3 downto 0)
	);
	end component;
	
	component digit_detector_datapath port(
		clock						:	in		std_logic;
		clock_25					:	in		std_logic;
		reset						:	in		std_logic;
		state_in					:	in		std_logic_vector(3 downto 0);
		exposition				:	in		std_logic_vector(11 downto 0);
		threshold				:	in		std_logic_vector(5 downto 0);
		camera_serial_clock	:	out	std_logic;
		camera_master_clock	:	out	std_logic;
		camera_serial_data	: 	inout	std_logic;
		camera_line_valid		:	in		std_logic;
		camera_frame_valid	:	in		std_logic;
		camera_data				:	in		std_logic_vector(9 downto 0);
		camera_pixel_clock	:	in		std_logic;
		vga_hsync				:	inout	std_logic;
		vga_vsync				:	inout	std_logic;
		vga_red					:	out	std_logic_vector(7 downto 0);
		vga_green				:	out	std_logic_vector(7 downto 0);
		vga_blue					:	out	std_logic_vector(7 downto 0);
		vga_nblank				:	out	std_logic;
		vga_nsync				:	out	std_logic;
		vga_clock				:	out	std_logic;
		lcd_data 				: 	out	std_logic_vector(7 downto 0);
		lcd_en					: 	out	std_logic;
		lcd_rw					: 	out	std_logic;
		lcd_rs					: 	out	std_logic;
		lcd_blon					: 	out	std_logic;
		lcd_on					: 	out	std_logic;
		config_done				:	out	std_logic;
		detection_done			:	out	std_logic;
		classification			:	out	std_logic_vector(2 downto 0)
	);
	end component;
	
	signal config_done_internal, detection_done_internal : std_logic;
	signal classification_internal: std_logic_vector(2 downto 0);
	signal state_internal : std_logic_vector(3 downto 0);
	
	signal exposition_internal : std_logic_vector(11 downto 0);
	signal threshold_internal	: std_logic_vector(5 downto 0);
	signal clock_25	:	std_logic := '0';

begin

	exposition_internal	<= SW(11 downto 0);
	threshold_internal	<= SW(17 downto 12);

	--convert CLOCK_50 to 25MHz
	p0: process(CLOCK_50)
	begin
		if rising_edge(CLOCK_50) then
			clock_25 <= not clock_25;
		end if;
	end process;

	G0: digit_detector_control_unit port map(
		clock					=> CLOCK_50,
		reset					=> not KEY(0),
		take_photo			=> not KEY(1),
		start_detection	=> not KEY(2),
		config_done			=> config_done_internal,
		detection_done		=>	detection_done_internal,
		state_out			=> state_internal);
	
	G1: digit_detector_datapath port map(
		clock						=> CLOCK_50,
		clock_25					=>	clock_25,
		reset						=> not KEY(0),
		state_in					=> state_internal,
		exposition				=> exposition_internal,
		threshold				=> threshold_internal,
		camera_serial_clock	=> CMOS_SCLK,
		camera_master_clock	=> CMOS_MCLK,
		camera_serial_data	=> CMOS_SDAT,
		camera_line_valid		=> CMOS_LVAL,
		camera_frame_valid	=> CMOS_FVAL,
		camera_data				=> CMOS_DATA,
		camera_pixel_clock	=> CMOS_PIXCLK,
		vga_hsync				=> VGA_HS,
		vga_vsync				=> VGA_VS,
		vga_red					=> VGA_R,
		vga_green				=> VGA_G,
		vga_blue					=> VGA_B,
		vga_nblank				=> VGA_BLANK_N,
		vga_nsync				=> VGA_SYNC_N,
		vga_clock				=> VGA_CLK,
		lcd_data 				=> LCD_DATA,
		lcd_en					=> LCD_EN,
		lcd_rw					=> LCD_RW,
		lcd_rs					=> LCD_RS,
		lcd_blon					=> LCD_BLON,
		lcd_on					=> LCD_ON,
		config_done				=> config_done_internal,
		detection_done			=> detection_done_internal,
		classification			=> classification_internal);
		
		LEDG(3 downto 0) <= state_internal;
		LEDG(6) <= config_done_internal;
		LEDG(7) <= detection_done_internal;
		
		--at state SHOW_RESULT, we display classification result
		LEDR(2 downto 0) <= classification_internal;

end rtl;