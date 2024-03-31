library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram is port( -- RAM 4x8 (4 words of size 8 bits)
       clock	     	: in  std_logic;
       address			: in  std_logic_vector(1 downto 0); --2 bit address
       data_in			: in  std_logic_vector(7 downto 0);
       write_enable  : in  std_logic;
       chip_enable  	: in  std_logic;
       data_out   	: out std_logic_vector(7 downto 0)
    );
end ram;

architecture ram_mif of ram is

  type   ram_type is array(0 to 3) of std_logic_vector(7 downto 0);
  signal ram_memory : ram_type;
  
  -- configure initial values of ram using .mif file
  attribute ram_init_file: string;
  attribute ram_init_file of ram_memory: signal is "ram_initial_content.mif";
  
begin

  process(clock)
  begin
    if rising_edge(clock)  then
          if chip_enable = '0' then --data is store on rising edge of write_enable with chip_enable='0'
           
              -- write_enable is active LOW
              if (write_enable = '0') 
                  then ram_memory(to_integer(unsigned(address))) <= data_in;
              end if;
            
          end if;
      end if;
  end process;

  -- memory output
  data_out <= ram_memory(to_integer(unsigned(address)));
  
end architecture ram_mif;