----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2025.03.25
--
-- Description: 
--   Test Bench.
-- 
-- Revision:
--   2025.03.25 - File Created
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity dds_c_wave_tb is
end entity dds_c_wave_tb;

architecture sim of dds_c_wave_tb is

  -- Clock period
  constant clk_period : time := 1 ns;
  
  -- Signals
  constant bitLength : integer := 16;
  constant nPoints   : integer := 64;
  constant Wn : real := 2.0 * MATH_PI / real(nPoints);
  signal clk  : std_logic := '1';
  signal rst  : std_logic;
  signal enb  : std_logic;
  signal y_re : signed(bitLength - 1 downto 0);
  signal y_im : signed(bitLength - 1 downto 0);

begin

  clk <= not clk after clk_period/2;

  SEQUENCER_PROC: process
  begin
    rst <= '1';
    enb <= '0';

    wait for clk_period * 2;
    rst <= '0';
    enb <= '1';
    
    wait for clk_period * 10000;
    assert false
      report "Replace this with your test cases"
      severity failure;

  end process;

  DUT: entity work.dds_c_wave
    generic map (
      implStruct => "no_symmetry", -- "no_symmetry"
      bitLength  => bitLength,
      RomStyle   => "block", -- "block" or "distributed".
      Wn         => Wn,
      n_start    => 0,
      n_end      => nPoints-1
    )
    port map (
      clk  => clk  ,
      rst  => rst  ,
      enb  => enb  ,
      y_re => y_re ,
      y_im => y_im  
    );
  
end architecture;