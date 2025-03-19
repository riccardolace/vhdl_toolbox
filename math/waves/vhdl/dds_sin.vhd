----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2025.03.14
--
-- Description: 
--   Implementation of a DDS to generate a sine wave.
--   
-- Revision:
--   2025.03.25 - FIX: The address signal was not reset when it reached its maximum value, 
--                but rather when it reached the overflow.  
--   2025.03.14 - File Created
--
-- Notes:
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity dds_sin is
  generic (
    implStruct : string  := "no_symmetry"; 					-- "no_symmetry"
    bitLength  : integer := 16;
    RomStyle   : string  := "distributed"; 					-- "block" or "distributed".
    Wn         : real    := 2.0 * MATH_PI / 64.0;		-- Normalized frequency
    n_start    : integer := 0;
    n_end      : integer := 63
  );
  port (
    clk : in std_logic;
    rst : in std_logic;
    enb : in std_logic;
    y   : out signed(bitLength - 1 downto 0)
  );
end dds_sin;

-- No Symmetry
architecture rtl of dds_sin is
begin

  no_symmetry_STRUCT : if implStruct = "no_symmetry" generate

    -- LUT size

    constant lutSize : integer := abs(n_end - n_start) + 1;

    -- Type
    type t_arr is array (natural range <>) of signed(bitlength - 1 downto 0);

    -- Function
    function f_sin (
      Wn       : real;
      n_start  : integer;
      n_end    : integer;
      WidthBit : integer
    ) return t_arr is
      variable Ampl    : real := (2.0 ** (WidthBit - 1) - 1.0);
      variable temp    : real;
      variable arr_out : t_arr(0 to lutSize-1);
      variable i       : integer := 0;
    begin

      if n_start <= n_end then
        for n in n_start to n_end loop
          temp       := ROUND(SIN(Wn * real(n)) * Ampl);
          arr_out(i) := TO_SIGNED(integer(temp), WidthBit);
          i          := i + 1;
        end loop;
      else
        for n in n_start downto n_end loop
          temp       := ROUND(SIN(Wn * real(n)) * Ampl);
          arr_out(i) := TO_SIGNED(integer(temp), WidthBit);
          i          := i + 1;
        end loop;
      end if;

      return arr_out;
    end function;

    -- Sin Array
    signal lut_arr                 : t_arr(0 to lutSize - 1) := f_sin(Wn, n_start, n_end, bitLength);
    signal addr                    : unsigned(integer(ceil(log2(real(lutSize)))) - 1 downto 0);
    attribute rom_style            : string;
    attribute rom_style of lut_arr : signal is "distributed";

    -- Signal
    signal reg_y : SIGNED(bitLength - 1 downto 0);

  begin

    process (clk) begin
      if rising_edge(clk) then
        if rst = '1' then
          addr  <= (others => '0');
          reg_y <= (others => '0');
        elsif enb = '1' then
          if addr=lutSize-1 then
            addr <= (others => '0');
          else
            addr  <= addr + 1;
          end if;
          reg_y <= lut_arr(TO_INTEGER(addr));
        end if;
      end if;
    end process;

    y <= reg_y;

  end generate no_symmetry_STRUCT;

end rtl;
