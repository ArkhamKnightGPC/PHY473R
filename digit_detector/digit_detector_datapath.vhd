library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity digit_detector_datapath is port(
	clock				:	in			std_logic;
	state_in			:	in			std_logic_vector(2 downto 0);
	state_photo		:	in			std_logic;
	state_rgb		:	in			std_logic;
	state_grayscale:	in			std_logic;
	state_detection:	in			std_logic;
	stop_photo		: 	out		std_logic;
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
	pxclk				: 	out 	std_logic
	
);
end digit_detector_datapath;

architecture rtl of digit_detector_datapath is

component camera_interface port(
	clk : in std_logic;
	state_photo: in std_logic;

	mem_addr_write : out std_logic_vector(7 downto 0);
	data_write : out std_logic_vector(7 downto 0);
	write_enable : out std_logic;

	camera_serial_clk : out std_logic;
	camera_master_clk : out std_logic;
	camera_serial_data : out std_logic;

	camera_line_valid : in std_logic;
	camera_frame_valid : in std_logic;
	camera_pixclk : in std_logic;
	camera_data_out : in std_logic_vector(9 downto 0));
end component;

component ram_image port (
	clock : in std_logic;
	wr_bayer    : in std_logic;
	addr_bayer  : in std_logic_vector(7 downto 0);
	din_bayer   : in std_logic_vector(7 downto 0);
	stop_photo 	: out	std_logic;
	
	addr_grayscale: in std_logic_vector(7 downto 0);
	dout_grayscale: out std_logic_vector(7 downto 0)
);
end component;

component vga_controller port(
        clk      : in    std_logic;
		  mem_out  : in std_logic_vector(7 downto 0);
        Hsync    : buffer std_logic;
        Vsync    : buffer std_logic;
        vga_red  : out   std_logic_vector(7 downto 0);
        vga_green: out   std_logic_vector(7 downto 0);
        vga_blue : out   std_logic_vector(7 downto 0);
		  mem_addr : out std_logic_vector(7 downto 0);
        nblanck  : out   std_logic;
        nsync    : out   std_logic;
        pxclk    : out   std_logic
    );
end component;

signal mem_addr_write_internal 	: 	std_logic_vector(7 downto 0);
signal data_write_internal 		: 	std_logic_vector(7 downto 0);
signal write_enable_internal 		: 	std_logic;

signal addr_grayscale_internal	: std_logic_vector(7 downto 0);
signal dout_grayscale_internal	: std_logic_vector(7 downto 0);
signal vga_clk_internal				: std_logic;

signal counter_rgb : natural range 0 to 256 := 0;
signal counter_grayscale : natural range 0 to 256 := 0;

begin

	p0: process(clock)
	begin
		if rising_edge(clock) then
			if state_rgb='1' then
				if counter_rgb = 255 then
					rgb_done <= '1';
				else
					counter_rgb <= counter_rgb + 1;
					rgb_done <= '0';
				end if;
			else
				counter_rgb <= 0;
				rgb_done <= '0';
			end if;
		end if;
	end process;
	
	p1: process(clock)
	begin
		if rising_edge(clock) then
			if state_grayscale='1' then
				if counter_grayscale = 255 then
					grayscale_done <= '1';
				else
					counter_grayscale <= counter_grayscale + 1;
					grayscale_done <= '0';
				end if;
			else
				counter_grayscale <= 0;
				grayscale_done <= '0';
			end if;
		end if;
	end process;

	G1: camera_interface port map(
		  clk => clock,
		  state_photo=> state_photo,
		  mem_addr_write => mem_addr_write_internal,
		  data_write => data_write_internal,
		  write_enable => write_enable_internal,
		  camera_serial_clk=> camera_serial_clk,
		  camera_master_clk=> camera_master_clk,
		  camera_serial_data=> camera_serial_data,
		  camera_line_valid=> camera_line_valid,
		  camera_frame_valid=> camera_frame_valid,
		  camera_pixclk=> camera_pixclk,
		  camera_data_out=> camera_data_out
	);
	
	G2: ram_image port map(
		clock => vga_clk_internal,
		wr_bayer    => write_enable_internal,
		addr_bayer  => mem_addr_write_internal,
		din_bayer   => data_write_internal,
		stop_photo => stop_photo,
		
		addr_grayscale => addr_grayscale_internal,
		dout_grayscale => dout_grayscale_internal
	);
	
	G3: vga_controller port map(
        clk      => clock,
		  mem_out  => dout_grayscale_internal,
		  Hsync 	=> Hsync,
        Vsync    => Vsync,
        vga_red  => red,
        vga_green=> green,
        vga_blue => blue,
		  mem_addr => addr_grayscale_internal,
        nblanck  => nblanck,
        nsync    => nsync,
        pxclk    => vga_clk_internal
    );
	 
	 pxclk <= vga_clk_internal;

end rtl;
