----------------------------------------------------------------------------------
-- Engineer: Daniele Giardino
-- 
-- Create Date: 2024.02.20
-- Description: 
--   Test Bench.
-- 
-- Design:
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

entity counter_with_hit_tb is
end entity;

architecture sim of counter_with_hit_tb is

  constant clk_hz     : integer := 1e9;
  constant clk_period : time    := 1 sec / clk_hz;

  signal clk : std_logic := '1';
  signal rst : std_logic := '1';

  constant bitLength : INTEGER := 16;
  constant valToRst  : INTEGER := 2 ** 16 - 1;
  constant valToHit  : INTEGER := 0;
  signal enb : STD_LOGIC := '0';
  signal inc : STD_LOGIC_VECTOR(bitLength - 1 downto 0);
  signal hit : STD_LOGIC;
  signal cnt : STD_LOGIC_VECTOR(bitLength - 1 downto 0);

begin

  clk <= not clk after clk_period / 2;

  DUT: entity work.counter_with_hit(bhv_unsigned)
    generic map (
      bitLength => bitLength,
      valToRst  => valToRst,
      valToHit  => valToHit
    )
    port map (
      clk => clk,
      rst => rst,
      enb => enb,
      inc => inc,
      hit => hit,
      cnt => cnt
    );

  SEQUENCER_PROC: process
  begin
    wait for clk_period * 2;

    rst <= '0';
    enb <= '1';
    inc <= std_logic_vector(to_unsigned(1, inc'length));

    wait for clk_period * 10;

    -- assert false
    --   report "Replace this with your test cases"
    --   severity failure;
    -- finish;
  end process;

end architecture;
