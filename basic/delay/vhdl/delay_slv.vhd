----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2024.02.20
-- Description: 
--   Delay of a STD_LOGIC_VECTOR.
-- 
-- Revision:
--   0.01 - File Created
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;

entity delay_slv is
  generic (bitLength : INTEGER := 16);
  port (clk : in  STD_LOGIC;
        rst : in  STD_LOGIC;
        enb : in  STD_LOGIC;
        x   : in  STD_LOGIC_VECTOR(bitLength - 1 downto 0);
        y   : out STD_LOGIC_VECTOR(bitLength - 1 downto 0));
end entity;

architecture rtl of delay_slv is
  signal int_x : STD_LOGIC_VECTOR(bitLength - 1 downto 0);
  signal reg_y : STD_LOGIC_VECTOR(bitLength - 1 downto 0);
begin
  int_x <= x;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        reg_y <= (others => '0');
      elsif enb = '1' then
        reg_y <= int_x;
      end if;
    end if;
  end process;
  y <= reg_y;
end architecture;
