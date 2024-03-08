----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2024.03.08
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

entity multAdd_tb is
end multAdd_tb;

architecture sim of multAdd_tb is

  constant clk_hz : integer := 100e6;
  constant clk_period : time := 1 sec / clk_hz;

  signal clk : std_logic := '1';
  signal rst : std_logic := '1';

  signal enb : std_logic;
  signal A   : std_logic_vector(15 downto 0) := std_logic_vector(TO_SIGNED(2,16));
  signal B   : std_logic_vector(15 downto 0) := std_logic_vector(TO_SIGNED(2,16));
  signal C   : std_logic_vector(47 downto 0) := std_logic_vector(TO_SIGNED(5,48));
  signal Y   : std_logic_vector(47 downto 0);

begin

  clk <= not clk after clk_period / 2;

  DUT : entity work.multAdd(rtl)
  generic map (
    regA_len     => 1,
    regB_len     => 1,
    regC_len     => 0,
    regMult_len  => 1,
    regAdd_len   => 1,
    addOperation => "add",  -- "add" or "sub"
    Width_A      => 16,
    Width_B      => 16,
    Width_C      => 48
  )  
  port map (
    clk       => clk       ,
    rst       => rst       ,
    enb       => enb       ,
    A         => A         ,
    B         => B         ,
    C         => C         ,
    Y         => Y
  );

  SEQUENCER_PROC : process
  begin
    wait for clk_period * 2;
    rst <= '0';
    enb <= '1';
    
    wait for clk_period * 1000;
    assert false
      report "Replace this with your test cases"
      severity failure;

    finish;
  end process;

end architecture;