----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2024.03.08
-- Description: 
--  Real multiplication with 1 output register
-- 
-- Revision:
--   0.01 - File Created
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mult is
generic (bitLength_x : integer := 16; bitLength_y : integer := 16);
port (clk  : IN  std_logic  ;
      rst  : IN  std_logic  ;
      enb  : IN  std_logic  ;
      x    : IN  std_logic_vector(bitLength_x-1 DOWNTO 0) ;
      y    : IN  std_logic_vector(bitLength_y-1 DOWNTO 0) ;
      z    : OUT std_logic_vector(bitLength_x+bitLength_y-1 DOWNTO 0)  
      );
end mult;

architecture rtl of mult is
  SIGNAL x     : signed(bitLength_x-1 DOWNTO 0);
  SIGNAL y     : signed(bitLength_y-1 DOWNTO 0);
  SIGNAL reg_z : signed(bitLength_x+bitLength_y-1 DOWNTO 0);
begin
  
  process(clk) begin
  if rising_edge(clk) then
    if rst='1' then
      reg_z <= (others=>'0');
    elsif enb='1' then
      reg_z <= x * y;
    end if;
  end if;
  end process;
  z <= reg_z;
end bhv;