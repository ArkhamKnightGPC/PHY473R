--------------------------------------------------------------------------------
--
--   FileName:         lcd_controller.vhd
--   Dependencies:     none
--   Design Software:  Quartus Prime Version 17.0.0 Build 595 SJ Lite Edition
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 6/2/2006 Scott Larson
--     Initial Public Release
--   Version 2.0 6/13/2012 Scott Larson
--   Version 3.0 11/6/2019 Scott Larson
--     Added LCD configuration using generics
--    
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY lcd_controller IS
  GENERIC(
    clk_freq       :  INTEGER    := 50;    --system clock frequency in MHz
    display_lines  :  STD_LOGIC  := '1';   --number of display lines (0 = 1-line mode, 1 = 2-line mode)
    character_font :  STD_LOGIC  := '0';   --font (0 = 5x8 dots, 1 = 5x10 dots)
    display_on_off :  STD_LOGIC  := '1';   --display on/off (0 = off, 1 = on)
    cursor         :  STD_LOGIC  := '0';   --cursor on/off (0 = off, 1 = on)
    blink          :  STD_LOGIC  := '0';   --blink on/off (0 = off, 1 = on)
    inc_dec        :  STD_LOGIC  := '1';   --increment/decrement (0 = decrement, 1 = increment)
    shift          :  STD_LOGIC  := '0');  --shift on/off (0 = off, 1 = on)
  PORT(
    clk        : IN   STD_LOGIC;                     --system clock
    reset_n    : IN   STD_LOGIC;                     --active low reinitializes lcd
    lcd_enable : IN   STD_LOGIC;                     --latches data into lcd controller
    lcd_bus    : IN   STD_LOGIC_VECTOR(9 DOWNTO 0);  --data and control signals
    busy       : OUT  STD_LOGIC := '1';              --lcd controller busy/idle feedback
    rw, rs, e  : OUT  STD_LOGIC;                     --read/write, setup/data, and enable for lcd
    lcd_data   : OUT  STD_LOGIC_VECTOR(7 DOWNTO 0)); --data signals for lcd
END lcd_controller;

ARCHITECTURE controller OF lcd_controller IS
  TYPE CONTROL IS(power_up, initialize, ready, send);
  SIGNAL  state  : CONTROL;
BEGIN
  PROCESS(clk)
    VARIABLE clk_count : INTEGER := 0; --event counter for timing
  BEGIN
    IF(clk'EVENT and clk = '1') THEN

      CASE state IS
         
        --wait 50 ms to ensure Vdd has risen and required LCD wait is met
        WHEN power_up =>
          busy <= '1';
          IF(clk_count < (50000 * clk_freq)) THEN    --wait 50 ms
            clk_count := clk_count + 1;
            state <= power_up;
          ELSE                                       --power-up complete
            clk_count := 0;
            rs <= '0';
            rw <= '0';
            lcd_data <= "00110000";
            state <= initialize;
          END IF;
          
        --cycle through initialization sequence  
        WHEN initialize =>
          busy <= '1';
          clk_count := clk_count + 1;
          IF(clk_count < (10 * clk_freq)) THEN       --function set
            lcd_data <= "0011" & display_lines & character_font & "00";
            e <= '1';
            state <= initialize;
          ELSIF(clk_count < (60 * clk_freq)) THEN    --wait 50 us
            lcd_data <= "00000000";
            e <= '0';
            state <= initialize;
          ELSIF(clk_count < (70 * clk_freq)) THEN    --display on/off control
            lcd_data <= "00001" & display_on_off & cursor & blink;
            e <= '1';
            state <= initialize;
          ELSIF(clk_count < (120 * clk_freq)) THEN   --wait 50 us
            lcd_data <= "00000000";
            e <= '0';
            state <= initialize;
          ELSIF(clk_count < (130 * clk_freq)) THEN   --display clear
            lcd_data <= "00000001";
            e <= '1';
            state <= initialize;
          ELSIF(clk_count < (2130 * clk_freq)) THEN  --wait 2 ms
            lcd_data <= "00000000";
            e <= '0';
            state <= initialize;
          ELSIF(clk_count < (2140 * clk_freq)) THEN  --entry mode set
            lcd_data <= "000001" & inc_dec & shift;
            e <= '1';
            state <= initialize;
          ELSIF(clk_count < (2200 * clk_freq)) THEN  --wait 60 us
            lcd_data <= "00000000";
            e <= '0';
            state <= initialize;
          ELSE                                       --initialization complete
            clk_count := 0;
            busy <= '0';
            state <= ready;
          END IF;    
       
        --wait for the enable signal and then latch in the instruction
        WHEN ready =>
          IF(lcd_enable = '1') THEN
            busy <= '1';
            rs <= lcd_bus(9);
            rw <= lcd_bus(8);
            lcd_data <= lcd_bus(7 DOWNTO 0);
            clk_count := 0;            
            state <= send;
          ELSE
            busy <= '0';
            rs <= '0';
            rw <= '0';
            lcd_data <= "00000000";
            clk_count := 0;
            state <= ready;
          END IF;
        
        --send instruction to lcd        
        WHEN send =>
          busy <= '1';
          IF(clk_count < (50 * clk_freq)) THEN       --do not exit for 50us
            IF(clk_count < clk_freq) THEN              --negative enable
              e <= '0';
            ELSIF(clk_count < (14 * clk_freq)) THEN    --positive enable half-cycle
              e <= '1';
            ELSIF(clk_count < (27 * clk_freq)) THEN    --negative enable half-cycle
              e <= '0';
            END IF;
            clk_count := clk_count + 1;
            state <= send;
          ELSE
            clk_count := 0;
            state <= ready;
          END IF;

      END CASE;    
  
      --reset
      IF(reset_n = '0') THEN
          state <= power_up;
      END IF;
    
    END IF;
  END PROCESS;
END controller;
