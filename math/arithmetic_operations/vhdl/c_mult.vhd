----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2024.03.08
-- Description: 
--  Complex multiplication based on 4 real multipliers. The latency is 2 clock cycles.
-- 
-- Revision:
--   0.01 - File Created
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity c_mult is
generic (bitLength_x : integer := 16; bitLength_y : integer := 16);
port (clk  : in  std_logic  ;
      rst  : in  std_logic  ;
      enb  : in  std_logic  ;
      x_re : in  std_logic_vector(bitLength_x-1 downto 0) ;
      x_im : in  std_logic_vector(bitLength_x-1 downto 0) ;
      y_re : in  std_logic_vector(bitLength_y-1 downto 0) ;
      y_im : in  std_logic_vector(bitLength_y-1 downto 0) ;
      z_re : out std_logic_vector(bitLength_x+bitLength_y-1 downto 0) ;
      z_im : out std_logic_vector(bitLength_x+bitLength_y-1 downto 0)  
      );
end c_mult;

architecture rtl of c_mult is
  signal a,b              : signed(bitLength_x-1 downto 0);
  signal c,d              : signed(bitLength_y-1 downto 0);
  signal prod_ac, prod_ad : signed(bitLength_x+bitLength_y-1 downto 0);
  signal prod_bc, prod_bd : signed(bitLength_x+bitLength_y-1 downto 0);
  signal reg_z_re         : signed(bitLength_x+bitLength_y-1 downto 0);
  signal reg_z_im         : signed(bitLength_x+bitLength_y-1 downto 0);
begin
  
  -- (a + jb) * (c + jd) =
  -- = ac + j ad + j bc - bd = 
  -- = (ac - bd) + j (ad + bc)
  a <= signed(x_re);
  b <= signed(x_im);
  c <= signed(y_re);
  d <= signed(y_im);

  process(clk) begin
  if rising_edge(clk) then
    if rst='1' then
      prod_ac  <= (others=>'0');
      prod_ad  <= (others=>'0');
      prod_bc  <= (others=>'0');
      prod_bd  <= (others=>'0');
      reg_z_re <= (others=>'0');
      reg_z_im <= (others=>'0');
    elsif enb='1' then
      prod_ac  <= a * c;
      prod_ad  <= a * d;
      prod_bc  <= b * c;
      prod_bd  <= b * d;
      reg_z_re <= prod_ac - prod_bd;
      reg_z_im <= prod_ad + prod_bc;
    end if;
  end if;
  end process;
  z_re <= std_logic_vector(reg_z_re);
  z_im <= std_logic_vector(reg_z_im);
end rtl;