library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_image is port (
	clock 		: in std_logic;
	wr_bayer    : in std_logic;
	addr_bayer  : in std_logic_vector(7 downto 0);
	din_bayer   : in std_logic_vector(7 downto 0);
	stop_photo 	: out	std_logic;
	addr_grayscale: in std_logic_vector(7 downto 0);
	dout_grayscale: out std_logic_vector(7 downto 0)
);
end ram_image;

architecture rtl of ram_image is
	type ram_array is array (0 to 255) of std_logic_vector(7 downto 0); -- 16x16 matrix
	signal bayer_image : ram_array;
	signal grayscale_image : ram_array;
	signal i : integer range 0 to 255 := 0;
	signal j : integer range 0 to 3 := 0;
	signal addr_bayer_int : integer range 0 to 255 := 0;
	signal addr_grayscale_int : integer range 0 to 255 := 0;

begin
	p0: process(clock)
	begin
		if rising_edge(clock) then
			addr_bayer_int <= to_integer(unsigned(addr_bayer));
			addr_grayscale_int <= to_integer(unsigned(addr_grayscale));

			if wr_bayer = '1' then
				bayer_image(addr_bayer_int) <= din_bayer;
			end if;

			if i mod 2 = 0 then -- R or G
				if i mod 4 = 0 then -- R
					grayscale_image(i) <= bayer_image(i);
				else -- G
					grayscale_image(i) <= std_logic_vector((unsigned(bayer_image(i-1)) + unsigned(bayer_image(i+1))) srl 1);
				end if;
			else -- G or B
				if i mod 4 = 1 then -- G
					grayscale_image(i) <= std_logic_vector((unsigned(bayer_image(i-1)) + unsigned(bayer_image(i+1))) srl 1);
				else -- B
					grayscale_image(i) <= bayer_image(i);
				end if;
			end if;

			i <= i+1;
			if i = 256 then
				i <= 0;
				j <= j+1;
			end if;

			if j = 2 then
				stop_photo <= '1';
			else
				stop_photo <= '0';
			end if;

			dout_grayscale <= grayscale_image(addr_grayscale_int);
		end if;
	end process;
end architecture rtl;
