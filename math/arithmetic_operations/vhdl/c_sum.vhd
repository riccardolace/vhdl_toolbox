----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2024.03.08
-- Description: 
--  Complex sum. The latency is 1 clock cycle.
-- 
-- Revision:
--   0.01 - File Created
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity c_sum is
generic (bitLength : integer := 16);
port (clk  : in  std_logic  ;
      rst  : in  std_logic  ;
      enb  : in  std_logic  ;
      x_re : in  std_logic_vector(bitLength-1 downto 0);
      x_im : in  std_logic_vector(bitLength-1 downto 0);
      y_re : in  std_logic_vector(bitLength-1 downto 0);
      y_im : in  std_logic_vector(bitLength-1 downto 0);
      z_re : out std_logic_vector(bitLength-1 downto 0);
      z_im : out std_logic_vector(bitLength-1 downto 0) 
      );
end c_sum;

architecture rtl of c_sum is
  signal reg_z_re : signed(bitLength-1 downto 0);
  signal reg_z_im : signed(bitLength-1 downto 0);
begin
  process(clk) begin
  if rising_edge(clk) then
    if rst='1' then
      reg_z_re <= (others=>'0');
      reg_z_im <= (others=>'0');
    elsif enb='1' then
      reg_z_re <= signed(x_re) + signed(y_re);
      reg_z_im <= signed(x_im) + signed(y_im);
    end if;
  end if;
  end process;
  z_re <= std_logic_vector(reg_z_re);
  z_im <= std_logic_vector(reg_z_im);
end bhv;

