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

entity priorityEncoder_tb is
end entity;

architecture sim of priorityEncoder_tb is

  constant clk_hz     : integer := 1e9;
  constant clk_period : time    := 1 sec / clk_hz;

  signal clk : std_logic := '1';
  signal rst : std_logic := '1';

  constant n : integer := 3;
  constant bitLength_x : integer := 2**n;
  constant bitLength_y : integer := n;
  signal enb   : std_logic;
  signal x     : std_logic_vector(bitLength_x - 1 downto 0);
  signal y     : std_logic_vector(bitLength_y - 1 downto 0);
  signal reg_y : std_logic_vector(bitLength_y - 1 downto 0);

begin

  clk <= not clk after clk_period / 2;

  DUT: entity work.priorityEncoder(rtl) 
  generic map (
    n => n
  ) 
  port map (
    clk => clk,
    rst => rst,
    enb => enb,
    x   => x,
    y   => y,
    reg_y   => reg_y
  );

  SEQUENCER_PROC: process
  begin
    rst <= '1';
    enb <= '0';
    x <= "00000000";
    wait for clk_period * 2;

    rst <= '0';
    enb <= '1';
    x <= "00000000";
    wait for clk_period * 2;

    x <= "00000000";  wait for clk_period * 1;
    x <= "00000001";  wait for clk_period * 1;
    x <= "00000010";  wait for clk_period * 1;
    x <= "00000011";  wait for clk_period * 1;
    x <= "00000100";  wait for clk_period * 1;
    x <= "00000101";  wait for clk_period * 1;
    x <= "00000110";  wait for clk_period * 1;
    x <= "00000111";  wait for clk_period * 1;
    x <= "00001000";  wait for clk_period * 1;
    x <= "00001001";  wait for clk_period * 1;
    x <= "00001010";  wait for clk_period * 1;
    x <= "00001011";  wait for clk_period * 1;
    x <= "00001100";  wait for clk_period * 1;
    x <= "00001101";  wait for clk_period * 1;
    x <= "00001110";  wait for clk_period * 1;
    x <= "00001111";  wait for clk_period * 1;
    x <= "00010000";  wait for clk_period * 1;
    x <= "00010001";  wait for clk_period * 1;
    x <= "00010010";  wait for clk_period * 1;
    x <= "00010011";  wait for clk_period * 1;
    x <= "00010100";  wait for clk_period * 1;
    x <= "00010101";  wait for clk_period * 1;
    x <= "00010110";  wait for clk_period * 1;
    x <= "00010111";  wait for clk_period * 1;
    x <= "00011001";  wait for clk_period * 1;
    x <= "00011010";  wait for clk_period * 1;
    x <= "00011011";  wait for clk_period * 1;
    x <= "00011100";  wait for clk_period * 1;
    x <= "00011101";  wait for clk_period * 1;
    x <= "00011110";  wait for clk_period * 1;
    x <= "00011111";  wait for clk_period * 1;    
    x <= "11111111";  wait for clk_period * 1;    
    wait for clk_period * 10;
    assert false
      report "Replace this with your test cases"
      severity failure;

    finish;
  end process;

end architecture;
