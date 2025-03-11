----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2024.03.28
-- Description: 
--   Truth table of a priority encoder 4:2
--
--     ┌────┬────┬────┬────┬┬────┬────┬┬────┐
--     │ x3 │ x2 │ x1 │ x0 ││ y1 │ y0 ││  A │
--     ├────┼────┼────┼────┼┼────┼────┼┼────┤
--     │  0 │  0 │  0 │  0 ││  0 │  0 ││  0 │
--     ├────┼────┼────┼────┼┼────┼────┼┼────┤
--     │  0 │  0 │  0 │  1 ││  0 │  0 ││  1 │
--     ├────┼────┼────┼────┼┼────┼────┼┼────┤
--     │  0 │  0 │  1 │  - ││  0 │  1 ││  1 │
--     ├────┼────┼────┼────┼┼────┼────┼┼────┤
--     │  0 │  1 │  - │  - ││  1 │  0 ││  1 │
--     ├────┼────┼────┼────┼┼────┼────┼┼────┤
--     │  1 │  - │  - │  - ││  1 │  1 ││  1 │
--     └────┴────┴────┴────┴┴────┴────┴┴────┘
--
--   Block diagram.
--                 ┌─────────────┐    z0           ┌─────────┐
--     x0    ─────>│             ├────────────────>│         ├────> y0
--     x1    ─────>│ PRIORITY    ├────────────────>│ 2^n     ├────> y1
--     .           │             │       .         │ BINARY  │  .
--     .           │ RESOLUTION  │       .         │ ENCODER │  .
--     .           │             │       .         │         │  .
-- x_{2^n-1} ─────>│             ├────────────────>│         ├────> y_{n-1}
--                 └─────────────┘    z_{2^n-1}    └─────────┘
--
--   - PRIORITY RESOLUTION finds the MSB equal to 1
--   - 2^n BINARY ENCODER converts the output of the previous block to a number 1
-- 
-- Revision:
--   0.01 - File Created
--
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.math_real.ALL;
  use ieee.numeric_std.ALL;

entity priorityEncoder is
  generic (
    n : integer := 3
  );
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    enb   : in  std_logic;
    x     : in  std_logic_vector(2**n - 1 downto 0);
    y     : out std_logic_vector(n - 1 downto 0);
    reg_y : out std_logic_vector(n - 1 downto 0)  -- Reg y
  );
end entity;

architecture rtl of priorityEncoder is
  
  -------- Constants --------
  constant bitLength_x : integer := (x'length);
  constant bitLength_y : integer := (y'length);

  -------- Priority Resolution--------
  signal z : std_logic_vector(x'range);

  -------- 2^n Binary Encoder --------
  -- To track which input bits contribute to each output bit, the code utilizes an array of signals named inBitsUsed.
  -- Each element in this array, inBitsUsed(i), is a std_logic_vector that keeps a record of the input bits (i) 
  -- that were used to compute the corresponding output bit.
  type inBitsUsed_type is array (0 to bitLength_y-1) of std_logic_vector(bitLength_x-1 downto 0);
  signal inBitsUsed : inBitsUsed_type;
  constant allZeros : std_logic_vector(bitLength_x-1 downto 0) := (others => '0');
  signal y_tmp : std_logic_vector(bitLength_y - 1 downto 0);
  signal y_r   : std_logic_vector(bitLength_y - 1 downto 0);

begin

  -------- Priority Resolution --------
  priorityEncoder_GEN: for i in 0 to z'length-1 generate
  begin

    iNoLast_GEN: if i<z'length-1 generate
      constant c_zeros : std_logic_vector(z'length-1 downto i+1) := (others => '0');
      signal xk : std_logic_vector(z'length-1 downto i+1);
    begin
      xk   <= x(z'length-1 downto i+1);
      z(i) <= '1' when (x(i)='1' and xk=c_zeros) else '0';
    end generate;

    iLast_GEN: if i=z'length-1 generate
    begin
      z(i) <= '1' when x(i)='1' else '0';
    end generate;

  end generate;

  -------- 2^n Binary Encoder --------
  bitOut_GEN: for o in 0 to bitLength_y-1 generate
    signal inBitsUsed_o : std_logic_vector(bitLength_x-1 downto 0);
  begin
  
    bitIn_GEN: for i in 0 to bitLength_x-1 generate
      constant i_slv : std_logic_vector(bitLength_x-1 downto 0) := std_logic_vector(to_unsigned(i, bitLength_x));
    begin

      bitInIsUsed_if_GEN: if i_slv(o)='1' generate
      begin
        inBitsUsed_o(i) <= z(i);
      end generate;
      bitInIsNotUsed_if_GENif_GEN: if i_slv(o)/='1' generate
      begin
        inBitsUsed_o(i) <= '0';
      end generate;

    end generate;

    y_tmp(o) <= '1' when inBitsUsed_o/=allZeros else '0';
  end generate;

  outputReg_PROC : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        y_r <= (others=>'0');
      elsif enb='1' then
        y_r <= y_tmp;
      end if;
    end if;
  end process;
  
  -- Output ports
  y     <= y_tmp;
  reg_y <= y_r;

end architecture;
