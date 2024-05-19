library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity digit_detector_datapath is port(
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
	camera_pixel_clock	:	in		std_logic;
	camera_data				:	in		std_logic_vector(9 downto 0);
	
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
	classification			:	out 	std_logic
);
end digit_detector_datapath;

architecture rtl of digit_detector_datapath is

	component ram_image port(
			address_a		: in 	std_logic_vector(15 downto 0);
			address_b		: in 	std_logic_vector(15 downto 0);
			clock				: in 	std_logic;
			data_a			: in 	std_logic_vector (7 downto 0);
			data_b			: in 	std_logic_vector (7 downto 0);
			wren_a			: in 	std_logic;
			wren_b			: in 	std_logic;
			q_a				: out std_logic_vector (7 downto 0);
			q_b				: out std_logic_vector (7 downto 0));
	end component;
	
	component ram_perceptron port(
			address	: in 	std_logic_vector(15 downto 0);
			clock		: in 	std_logic;
			data		: in 	std_logic_vector(15 downto 0);
			wren		: in 	std_logic;
			q			: out std_logic_vector(15 downto 0));
	end component;
	
	component vga_interface port(
		clock				:	in		std_logic;
		clock_25			:	in		std_logic;
		threshold		:	in		std_logic_vector(5 downto 0);
		state_in			:	in		std_logic_vector(3 downto 0);
		vga_hsync		:	inout	std_logic;
		vga_vsync		:	inout	std_logic;
		vga_red			:	out	std_logic_vector(7 downto 0);
		vga_green		:	out	std_logic_vector(7 downto 0);
		vga_blue			:	out	std_logic_vector(7 downto 0);
		vga_nblank		:	out	std_logic;
		vga_nsync		:	out	std_logic;
		vga_clock		:	out	std_logic;
		pixel_value		:	in 	std_logic_vector(7 downto 0);
		pixel_address	: 	out	std_logic_vector(15 downto 0));
	end component;
	
	component camera_interface port(
		clock						:	in		std_logic;
		clock_25					:	in		std_logic;
		reset						:	in		std_logic;
		exposition				:	in		std_logic_vector(11 downto 0);
		pixel_address			:	out	std_logic_vector(15 downto 0);
		pixel_data				:	out	std_logic_vector(7 downto 0);
		good_pixel				:	out	std_logic;
		camera_serial_clock	:	out	std_logic;
		camera_master_clock	:	out	std_logic;
		camera_serial_data	:	inout	std_logic;
		camera_line_valid		:	in		std_logic;
		camera_frame_valid	:	in		std_logic;
		camera_pixel_clock	:	in		std_logic;
		camera_data				:	in		std_logic_vector(9 downto 0);
		config_done				:	out	std_logic);
	end component;
	
	component lcd_interface port(
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
	
	signal pixel_address_vga, pixel_address_camera, pixel_address_port_a : std_logic_vector(15 downto 0);
	signal pixel_value_vga, pixel_value_camera : std_logic_vector(7 downto 0);
	signal write_enable_camera_data, good_pixel_camera : std_logic;
	
	signal cnt_detection: integer range 0 to 65536;
	signal address_detection : std_logic_vector(15 downto 0);
	signal pixel_detection : std_logic_vector(7 downto 0);
	signal perceptron_weight : std_logic_vector(15 downto 0);
	signal aux : integer range -10000000000 to 10000000000;
	signal pixel_detection_black_and_white : integer range 0 to 1;
	
	signal lcd_message_select : std_logic_vector(1 downto 0);
	
begin

	--state dependant logic
	p0: process(clock)
	begin
		if rising_edge(clock) then
			case state_in is
			
				when "0000"=> --CONFIG
					write_enable_camera_data <= '0';
					cnt_detection <= 0;
					detection_done <= '0';
					aux <= 0;
					classification <= '0';
					lcd_message_select <= "00";
					
				when "0001"=> --WAIT_PHOTO
					write_enable_camera_data <= good_pixel_camera;
				
				when "0010"=> --WAIT_DETECTION
					write_enable_camera_data <= '0';
					
				when "0011"=> --DETECTION
					if cnt_detection = 65536 then
						cnt_detection <= 0;
						detection_done <= '1';
						if aux - 100000 > 0 then  --Heaviside step as activation function (biais = -100000)
							classification <= '1';
							lcd_message_select <= "10";
						else
							classification <= '0';
							lcd_message_select <= "01";
						end if;
					else
						cnt_detection <= cnt_detection + 1;
						detection_done <= '0';
						aux <= aux + to_integer(signed(perceptron_weight))*pixel_detection_black_and_white;
					end if;
					
				when others=> --SHOW_RESULT
					write_enable_camera_data <= '0';
			end case;
		end if;
	end process;
	
	address_detection <= std_logic_vector(to_unsigned(cnt_detection, address_detection'length));
	pixel_address_port_a <= pixel_address_camera when (write_enable_camera_data='1') else address_detection;
	
	G0: ram_image port map(
			address_a		=> pixel_address_port_a,
			address_b		=> pixel_address_vga,
			clock				=> clock_25,
			data_a			=> pixel_value_camera,
			data_b			=> "00000000",
			wren_a			=> write_enable_camera_data,
			wren_b			=> '0', --port dedicated for vga read
			q_a				=> pixel_detection,
			q_b				=> pixel_value_vga
	);
	pixel_detection_black_and_white <= 0 when (to_integer(unsigned(pixel_detection)) > 4*to_integer(unsigned(threshold))) else 1;
	
	G1: ram_perceptron port map(
			address	=> address_detection,
			clock		=> clock_25,
			data		=> "0000000000000000",
			wren		=> '0', --we only read perceptron weights, never write!!
			q			=> perceptron_weight);
	
	G2: vga_interface port map(
		clock				=> clock,
		clock_25			=> clock_25,
		threshold		=> threshold,
		state_in			=> state_in,
		vga_hsync		=> vga_hsync,
		vga_vsync		=> vga_vsync,
		vga_red			=> vga_red,
		vga_green		=> vga_green,
		vga_blue			=> vga_blue,
		vga_nblank		=> vga_nblank,
		vga_nsync		=> vga_nsync,
		vga_clock		=> vga_clock,
		pixel_value		=> pixel_value_vga,
		pixel_address	=> pixel_address_vga);
	
	G3: camera_interface port map(
		clock						=> clock,
		clock_25					=>	clock_25,
		reset						=> reset,
		exposition				=> exposition,
		pixel_address			=> pixel_address_camera,
		pixel_data				=> pixel_value_camera,
		good_pixel				=> good_pixel_camera,
		camera_serial_clock	=> camera_serial_clock,
		camera_master_clock	=> camera_master_clock,
		camera_serial_data	=> camera_serial_data,
		camera_line_valid		=> camera_line_valid,
		camera_frame_valid	=> camera_frame_valid,
		camera_pixel_clock	=> camera_pixel_clock,
		camera_data				=>	camera_data,
		config_done				=> config_done);
		
	G4: lcd_interface port map(
		clock				=> clock,
		reset				=> reset,
		message_select	=> lcd_message_select,
		lcd_on			=> lcd_on,
		lcd_blon			=> lcd_blon,
		lcd_data			=> lcd_data,
		lcd_rs			=> lcd_rs,
		lcd_rw			=> lcd_rw,
		lcd_enable		=> lcd_en);

end rtl;