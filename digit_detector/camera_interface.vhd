library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity camera_interface is
    port (
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
        camera_data_out : in std_logic_vector(9 downto 0)
    );
end camera_interface;

architecture rtl of camera_interface is
	 
	component clk_25MHz
		PORT
		(
			areset		: IN STD_LOGIC  := '0';
			inclk0		: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC ;
			locked		: OUT STD_LOGIC 
		);
	end component;

    signal clk25 : std_logic := '0';

    -- 1289x1033 active pixels by default
    signal Hcount, dh : unsigned(10 downto 0);
    signal Vcount, dv : unsigned(10 downto 0);
	 signal aux : unsigned(7 downto 0);
	 
	 constant h1: integer   := 637;   
    constant h2: integer   := 637+15;
    
    constant v1: integer   := 509;   
    constant v2: integer   := 509+15;

begin

    -- generate 25MHz master clock
    G0: clk_25MHz port map (
        areset => '0',
        inclk0 => clk,
        c0 => clk25,
        locked => open
    );

    camera_master_clk <= clk25;
    camera_serial_clk <= '1'; --lets try without comm at first
    camera_serial_data <= '1';

    p2: process(camera_pixclk)
    begin

        if rising_edge(camera_pixclk) then

            if camera_line_valid = '1' then -- read valid pixel
					write_enable <= state_photo; --we only write picture to memory if we are in the right state!!!
		 
					if Hcount = 1023 then
						Hcount <= "00000000000";
						
						if Vcount = 1279 then
						  Vcount <= "00000000000";
						else
						  Vcount <= Vcount + 1;
						end if;
						
					else
						Hcount <= Hcount + 1;
					end if;

					 if Hcount >= h1 and Hcount <= h2 and Vcount >= v1 and Vcount <= v2 then
						dh <= Hcount - h1;
						dv <= Vcount - v1;
						aux <= (dv(7 downto 0) sll 4) + dh(7 downto 0);
						mem_addr_write <= std_logic_vector(aux);
						data_write <= camera_data_out(9 downto 2);
					 else
						mem_addr_write <= "00000000";
						data_write <= "00000000";
					 end if;

            else
                data_write <= "00000000";
                write_enable <= '0';
            end if;

        end if;
    end process;

end rtl;
