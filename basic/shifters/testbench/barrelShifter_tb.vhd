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

entity barrelShifter_tb is
end entity;

architecture sim of barrelShifter_tb is

  constant clk_hz     : integer := 1e9;
  constant clk_period : time    := 1 sec / clk_hz;

  signal clk : std_logic := '1';
  signal rst : std_logic := '1';

  constant bitDataLength : integer := 8;
  constant bitSelectorLength : integer := 3;
  signal enb        : std_logic;
  signal x          : std_logic_vector(bitDataLength - 1 downto 0);
  signal sel        : std_logic_vector(bitSelectorLength - 1 downto 0);
  signal valid_out  : std_logic;
  signal y          : std_logic_vector(bitDataLength - 1 downto 0);

begin

  clk <= not clk after clk_period / 2;

  DUT: entity work.barrelShifter(rtl) 
  generic map (
    shiftDirection    => "left",       -- "left" or "right"
    shiftSign         => "unsigned",   -- "signed" or "unsigned"
    shiftType         => "arithmetic", -- "arithmetic" or "logical"
    bitDataLength     => bitDataLength,
    bitSelectorLength => bitSelectorLength
  ) 
  port map (
    clk       => clk,
    rst       => rst,
    enb       => enb,
    x         => x,
    sel       => sel,
    valid_out => valid_out,
    y         => y
  );

  SEQUENCER_PROC: process
  begin
    rst <= '1';
    enb <= '0';
    x   <= "00000001";
    sel <= "000";
    wait for clk_period * bitSelectorLength;

    rst <= '0';
    enb <= '1';
    wait for clk_period * bitSelectorLength;

    sel <= "000"; wait for clk_period*bitSelectorLength;
    sel <= "001"; wait for clk_period*bitSelectorLength;
    sel <= "010"; wait for clk_period*bitSelectorLength;
    sel <= "011"; wait for clk_period*bitSelectorLength;
    sel <= "100"; wait for clk_period*bitSelectorLength;
    sel <= "101"; wait for clk_period*bitSelectorLength;
    sel <= "110"; wait for clk_period*bitSelectorLength;
    sel <= "111"; wait for clk_period*bitSelectorLength;
    
    wait for clk_period * 10;
    assert false
      report "Replace this with your test cases"
      severity failure;

    finish;
  end process;

end architecture;
