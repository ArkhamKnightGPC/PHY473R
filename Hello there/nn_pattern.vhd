-- nn_pattern.vhd
--
-- top-level-entity
--   neural network for pattern matching
--
-- FPGA Vision Remote Lab http://h-brs.de/fpga-vision-lab
-- (c) Steffen Reckels, Hochschule Bonn-Rhein-Sieg, 2021
--     Release: Marco Winzker, Hochschule Bonn-Rhein-Sieg, 4.02.2022

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity nn_pattern is
  port (clk       : in  std_logic;                      -- input clock
        reset_n   : in  std_logic;                      -- reset (invoked during configuration)
        enable_in : in  std_logic_vector(2 downto 0);   -- three slide switches
        -- video in                 
        lum_in      : in  std_logic_vector(7 downto 0);     
        -- Sortie afficheur LCD
        seg_a : out STD_LOGIC;
        seg_b : out STD_LOGIC;
        seg_c : out STD_LOGIC;
        seg_d : out STD_LOGIC;
        seg_e : out STD_LOGIC;
        seg_f : out STD_LOGIC;
        seg_g : out STD_LOGIC
        );                

end nn_pattern;
--
architecture behave of nn_pattern is
--
    -- input FFs
  signal reset             		: std_logic;
	signal enable            		: std_logic_vector(2 downto 0);
	--Signal converti en niveau de gris 
    signal lum     					: std_logic_vector(7 downto 0);
    -- output of signal processing
    signal symbol_label : std_logic_vector(4 downto 0);
    
--
begin
	
process
	variable result : integer range  0 to  255;
begin	
	wait until rising_edge(clk);   
	-- input FFs for control
    reset <= not reset_n;
	enable <= enable_in;
	 -- input FFs for video signal
	lum    <=  std_logic_vector(to_unsigned(lum_in, 8));
	
end process;
--
npu_instance: entity work.npu
    port map (
      --in  
      clk      	=> clk,
      reset    	=> reset,
      de_in    	=> de_0,
      data_in  	=> lum
      --out

    );  

control_instance: entity work.control
    generic map (delay => 21) 
    port map (
        --in
        clk   	=> clk,
        reset   => reset,
        vs_in	  => vs_0,
        hs_in 	=> hs_0,
        de_in   => de_0,
        --out
        vs_out	=> vs_1,
        hs_out 	=> hs_1,
        de_out  => de_1
    );    
--  
process
begin
  wait until rising_edge(clk);
    -- output FFs 
    vs_out  <= vs_1;
    hs_out  <= hs_1;
    de_out  <= de_1;

    if (de_1 = '1') then
      r_out   <= r_out_npu;
      g_out   <= g_out_npu;
      b_out   <= b_out_npu;
    else
  		r_out   <= "00000000";
  		g_out   <= "00000000";
  		b_out   <= "00000000";
    end if;
--
end process;
--
clk_o   <= clk;
clk_n_o <= not clk;
led     <= "000";
--
end behave;
--