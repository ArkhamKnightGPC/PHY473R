library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_interface is port(
	clock				:	in		std_logic;
	clock_25			:	in		std_logic;
	threshold		:	in  	std_logic_vector(5 downto 0);
	state_in					:	in		std_logic_vector(3 downto 0);
	
	vga_hsync		:	inout	std_logic;
	vga_vsync		:	inout	std_logic;
	vga_red			:	out	std_logic_vector(7 downto 0);
	vga_green		:	out	std_logic_vector(7 downto 0);
	vga_blue			:	out	std_logic_vector(7 downto 0);
	vga_nblank		:	out	std_logic;
	vga_nsync		:	out	std_logic;
	vga_clock		:	out	std_logic;
	
	pixel_value		:	in 	std_logic_vector(7 downto 0);
	pixel_address	: 	out	std_logic_vector(15 downto 0)
);
end vga_interface;

architecture rtl of vga_interface is

	constant HSYNC_CYC 	: 	integer	:=	96;
	constant HSYNC_BACK	:	integer	:=	48;
	constant HSYNC_TOTAL	:	integer	:= 800;
	
	constant VSYNC_CYC	:	integer	:= 2;
	constant VSYNC_BACK	:	integer	:= 32;
	constant	VSYNC_TOTAL	:	integer	:=	525;
	
	--offsets for display
	constant H_START 		:	integer	:= HSYNC_CYC + HSYNC_BACK + 192;
	constant	V_START		:	integer	:= VSYNC_CYC + VSYNC_BACK + 112;
	
	signal vga_rgb 		:	std_logic_vector(7 downto 0);
	signal aux 				:	natural range 0 to 700000;
	
	signal hcount			: 	integer range 0 to HSYNC_TOTAL;
	signal vcount			:	integer range 0 to VSYNC_TOTAL;
	
	signal vga_rgb_clipped : std_logic_vector(7 downto 0);

begin

	vga_nblank 	<= vga_hsync and vga_vsync;
	vga_nsync	<=	'0';
	vga_clock	<=	clock_25;
	
	--inside image region, we use grayscale value as rgb
	vga_rgb	<= pixel_value	when	(hcount >= H_START and hcount < H_START + 256 and vcount >= V_START and vcount < V_START + 256) else "00000000";
	vga_rgb_clipped <= "11111111" when (to_integer(unsigned(vga_rgb)) > 4*to_integer(unsigned(threshold))) else "00000000";
	
	vga_red	<= vga_rgb when (state_in = "0000" or state_in = "0001") else vga_rgb_clipped;
	vga_green<= vga_rgb when (state_in = "0000" or state_in = "0001") else vga_rgb_clipped;
	vga_blue	<= vga_rgb when (state_in = "0000" or state_in = "0001") else vga_rgb_clipped;
	
	--we compute address corresponding to pixel in memory
	aux <= (vcount - V_START)*256 + 255-(hcount - H_START) when (hcount >= H_START and hcount < H_START + 256 and vcount >= V_START and vcount < V_START + 256) else 0;
	pixel_address	<=	std_logic_vector(to_unsigned(aux, pixel_address'length));
	
	
	--generate Hsync signal
	p1: process(clock_25)
	begin
		if rising_edge(clock_25) then
			if	hcount < HSYNC_TOTAL then
				hcount	<=	hcount + 1;
			else
				hcount	<=	0;
			end if;
			
			if hcount < HSYNC_CYC then
				vga_hsync <= '0';
			else
				vga_hsync <= '1';
			end if;
		end if;
	end process;
	
	--generate Vsync signal
	p2: process(clock_25)
	begin
		if rising_edge(clock_25) then
			if hcount = 0 then
				if vcount < VSYNC_TOTAL then
					vcount	<=	vcount + 1;
				else
					vcount	<=	0;
				end if;
				
				if	vcount < VSYNC_CYC then
					vga_vsync	<=	'0';
				else
					vga_vsync	<=	'1';
				end if;
			end if;
		end if;
	end process;

end rtl;