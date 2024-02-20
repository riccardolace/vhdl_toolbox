----------------------------------------------------------------------------------
-- Engineer: Daniele Giardino
-- 
-- Create Date: 2024.02.21
-- Description: 
--   Test Bench.
-- 
-- Revision:
--   0.01 - File Created
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;

entity delay_chain_slv is
  generic (bitLength   : INTEGER := 16;
           delayLength : INTEGER := 1024
          );
  port (clk : in  STD_LOGIC;
        rst : in  STD_LOGIC;
        enb : in  STD_LOGIC;
        x   : in  STD_LOGIC_VECTOR(bitLength - 1 downto 0);
        y   : out STD_LOGIC_VECTOR(bitLength - 1 downto 0));
end entity;

architecture bhv of delay_chain_slv is
  type arr_1d is array (NATURAL range <>) of STD_LOGIC_VECTOR(bitLength - 1 downto 0);
  signal reg_y : arr_1d(0 to delayLength - 1);

begin

  process (clk)
  begin
    if rising_edge(clk) then

      if rst = '1' then
        reg_y <= (others =>(others => '0'));
      elsif enb = '1' then
        reg_y(0) <= x;
        for n in 1 to delayLength - 1 loop
          reg_y(n) <= reg_y(n - 1);
        end loop;
      end if;

    end if;
  end process;

  y <= reg_y(delayLength - 1);

end architecture;
