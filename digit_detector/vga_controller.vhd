library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity vga_controller is
    port (
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
end entity vga_controller;

architecture rtl of vga_controller is
    constant h1: integer   := 96;    -- h_pulse
    constant h2: integer   := 144;   -- h_pulse + hbp
    constant h3: integer   := 784;   -- h_pulse + hbp + h_active
    constant h4: integer   := 800;   -- h_pulse + hbp + h_active + hfp
    
    constant v1: integer   := 2;     -- v_pulse
    constant v2: integer   := 35;    -- v_pulse + vbp
    constant v3: integer   := 515;   -- v_pulse + vbp + v_active
    constant v4: integer   := 525;   -- v_pulse + vbp + v_active + vfp
    
    signal Hactive, Vactive, dena : std_logic;
    signal pixel_clk : std_logic;
    signal Hcount : positive range 1 to h4;
    signal Vcount : positive range 1 to v4;

begin

    --display enable
    dena <= Hactive and Vactive;
    
    nblanck <= '1'; -- no direct blanking
    nsync <= '0'; -- no sync on green
    
    -- convert clock 50MHz to 25 MHz
    p1: process(clk)
    begin
        if rising_edge(clk) then
            pixel_clk <= not pixel_clk;
        end if;
    end process;
    
    pxclk <= pixel_clk;
    
    -- generate Hsync signal
    p2: process(pixel_clk)
    begin
        if rising_edge(pixel_clk) then
            Hcount <= Hcount + 1;
            if Hcount = h1 then
                Hsync <= '1';
            elsif Hcount = h2 then
                Hactive <= '1';
            elsif Hcount = h3 then
                Hactive <= '0';
            elsif Hcount = h4 then
                Hsync <= '0';
                Hcount <= 1;
            end if;
        end if;
    end process;
    
    -- generate Vsync signal
    p3: process(Hsync)
    begin
        if Hsync'event and Hsync = '0' then
            Vcount <= Vcount + 1;
            if Vcount = v1 then
                Vsync <= '1';
            elsif Vcount = v2 then
                Vactive <= '1';
            elsif Vcount = v3 then
                Vactive <= '0';
            elsif Vcount = v4 then
                Vsync <= '0';
                Vcount <= 1;
            end if;
        end if;
    end process;
    
    -- generate image
    p4: process(clk)
		variable aux : natural range 0 to 2000;
    begin
		if dena = '1' then
		
			if (Hcount>=h2+312 and Hcount<=h2+312+15 and Vcount>=v2+232 and Vcount<=v2+232+15) then
				aux := (Vcount - v2 - 232)*16 + (Hcount - h2 - 312);
				mem_addr <= std_logic_vector(to_unsigned(aux, mem_addr'length));
				vga_red 	<= mem_out;
				vga_green 	<= mem_out;
				vga_blue 	<= mem_out;
			else
				mem_addr 	<= "00000000";
				vga_red     <= "00000000";
				vga_green   <= "00000000";
				vga_blue    <= "00000000";
			end if;
								
		end if;
	end process;
	
end rtl;
