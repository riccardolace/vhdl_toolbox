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

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  use std.textio.all;
  use std.env.finish;

entity delay_slv_tb is
end entity;

architecture sim of delay_slv_tb is

  constant clk_hz     : integer := 1e9;
  constant clk_period : time    := 1 sec / clk_hz;

  signal clk : std_logic := '1';
  signal rst : std_logic := '1';

  constant bitLength : INTEGER := 16;
  signal enb : STD_LOGIC;
  signal x   : STD_LOGIC_VECTOR(bitLength - 1 downto 0);
  signal y   : STD_LOGIC_VECTOR(bitLength - 1 downto 0);

begin

  clk <= not clk after clk_period / 2;

  DUT: entity work.delay_slv(bhv) generic map (
    bitLength => bitLength
  ) port map (
    clk => clk,
    rst => rst,
    enb => enb,
    x   => x,
    y   => y
  );

  SEQUENCER_PROC: process
  begin
    wait for clk_period * 2;

    rst <= '0';
    enb <= '1';
    x <= std_logic_vector(to_unsigned(31, x'length));

    wait for clk_period * 10;
    assert false
      report "Replace this with your test cases"
      severity failure;

    finish;
  end process;

end architecture;
