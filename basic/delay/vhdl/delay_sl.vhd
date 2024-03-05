----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2024.02.20
-- Description: 
--   Test Bench.
-- 
-- Revision:
--   0.01 - File Created
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;

entity delay_sl is
  port (clk : in  STD_LOGIC;
        rst : in  STD_LOGIC;
        enb : in  STD_LOGIC;
        x   : in  STD_LOGIC;
        y   : out STD_LOGIC);
end entity;

architecture bhv of delay_sl is
  signal int_x : STD_LOGIC;
  signal reg_y : STD_LOGIC;
begin
  int_x <= x;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        reg_y <= '0';
      elsif enb = '1' then
        reg_y <= int_x;
      else
        reg_y <= reg_y;
      end if;
    end if;
  end process;
  y <= reg_y;
end architecture;
