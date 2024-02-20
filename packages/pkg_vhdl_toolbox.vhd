----------------------------------------------------------------------------------
-- Engineer: Daniele Giardino
-- 
-- Create Date: 2024.02.21
-- Description: 
--   Test Bench.
-- 
-- Design:
-- 
-- Revision:
--   0.01 - File Created
--
----------------------------------------------------------------------------------


library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

package pkg_vhdl_toolbox is

  -- FUNCTIONS
  function log2(i : natural) return natural;
  function inv(a : real) return real;

  -- TYPES
  type t_complex_std_vec16 is record
    re : std_logic_vector(15 downto 0);
    im : std_logic_vector(15 downto 0);
  end record;

  type t_complex_int16 is record
    re : signed(15 downto 0);
    im : signed(15 downto 0);
  end record;

  type t_complex_uint16 is record
    re : unsigned(15 downto 0);
    im : unsigned(15 downto 0);
  end record;

end package;

package body pkg_vhdl_toolbox is

  -- FUNCTIONS
  -- Log2
  function log2(i : natural) return natural is
    variable temp    : natural := i;
    variable ret_val : natural := 0;
  begin
    while temp > 1 loop
      ret_val := ret_val + 1;
      temp := temp / 2;
    end loop;
    return ret_val;
  end function;

  -- Reciprocal
  function inv(a : real) return real is
    variable x : real := a;
    --variable Thr  : real := 5.9605e-08;  -- pow(2,-24)
    variable h : real := 0.0;
  begin
    while (a * x > 1.0) loop
      x := x * 0.5;
    end loop;

    for n in 0 to 19 loop
      h := 1.0 - a * x;
      x := x *(1.0 + h *(1.0 + h));
    end loop;
    return x;
  end function;

end package body;



