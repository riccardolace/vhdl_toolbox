----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2025.03.25
--
-- Description: 
--   Implementation of a DDS to generate a complex wave.
--
-- Revision:
--   2025.03.25 - File Created
--
-- Notes
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity dds_c_wave is
  generic (
    implStruct : string  := "no_symmetry"; 					-- "no_symmetry"
    bitLength  : integer := 16;
    RomStyle   : string  := "distributed"; 					-- "block" or "distributed".
    Wn         : real    := 2.0 * MATH_PI / 64.0;		-- Normalized frequency
    n_start    : integer := 0;
    n_end      : integer := 63
  );
  port (
    clk  : in std_logic;
    rst  : in std_logic;
    enb  : in std_logic;
    y_re : out signed(bitLength - 1 downto 0);
    y_im : out signed(bitLength - 1 downto 0)
  );
end dds_c_wave;

-- No Symmetry
architecture rtl of dds_c_wave is
begin

  no_symmetry_STRUCT : if implStruct = "no_symmetry" generate
  
  begin
  
    g_gen_cos : entity work.gen_cos(rtl)
      generic map (
        implStruct => "no_symmetry", -- "no_symmetry"
        bitLength => bitLength,
        RomStyle  => RomStyle,
        Wn        => Wn,
        n_start   => n_start,
        n_end     => n_end
      )
      port map (
        clk => clk,
        rst => rst,
        enb => enb,
        y   => y_re
      );
  
    g_gen_sin : entity work.gen_sin(rtl)
      generic map (
        implStruct => "no_symmetry", -- "no_symmetry"
        bitLength => bitLength,
        RomStyle  => RomStyle,
        Wn        => Wn,
        n_start   => n_start,
        n_end     => n_end
      )
      port map (
        clk => clk,
        rst => rst,
        enb => enb,
        y   => y_im
      );
  
  end generate no_symmetry_STRUCT;    
end rtl;