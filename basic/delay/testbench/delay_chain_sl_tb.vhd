----------------------------------------------------------------------------------
-- Engineer: Daniele Giardino
-- 
-- Create Date: 2024.02.21
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

entity delay_chain_sl_tb is
end entity;

architecture sim of delay_chain_sl_tb is

  constant clk_hz     : integer := 1e9;
  constant clk_period : time    := 1 sec / clk_hz;

  signal clk : std_logic := '1';
  signal rst : std_logic := '1';

  constant delayLength : INTEGER := 4;
  signal enb : STD_LOGIC;
  signal x   : STD_LOGIC;
  signal y   : STD_LOGIC;

begin

  clk <= not clk after clk_period / 2;

  DUT: entity work.delay_chain_sl
    generic map (
      delayLength => delayLength
    )
    port map (
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
    x <= '1';

    wait for clk_period * 10;
    assert false
      report "Replace this with your test cases"
      severity failure;

    finish;
  end process;

end architecture;
