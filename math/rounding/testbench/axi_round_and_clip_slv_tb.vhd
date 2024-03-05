----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2024.02.20
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

use ieee.math_real.all;

use std.textio.all;
use std.env.finish;

entity axi_round_and_clip_slv_tb is
end axi_round_and_clip_slv_tb;

architecture sim of axi_round_and_clip_slv_tb is

  function flp2fxp(x:real; Fl:integer) return integer is
    variable x_tmp : real;
    variable y     : integer;
  begin
    
    x_tmp := x* (2**Fl);
    y     := integer(round(x_tmp));

    return y;
  end function flp2fxp;

  constant clk_hz : integer := 100e6;
  constant clk_period : time := 1 sec / clk_hz;

  signal clk : std_logic := '1';
  signal rst : std_logic := '1';
  
  constant WIDTH_IN  : integer := 24;
  constant WIDTH_OUT : integer :=  8;
  constant CLIP_BITS : integer :=  2;

  constant data_val  : real := -2.6;
  signal data_in     : std_logic_vector(WIDTH_IN-1 downto 0) := std_logic_vector(TO_SIGNED(flp2fxp(data_val, 15), WIDTH_IN));

  signal i_tvalid : std_logic := '0';
  signal i_tdata  : std_logic_vector(WIDTH_IN - 1 downto 0);
  signal i_tready : std_logic;
  signal o_tvalid : std_logic;
  signal o_tdata  : std_logic_vector(WIDTH_OUT - 1 downto 0);
  signal o_tready : std_logic := '0';



begin

  clk <= not clk after clk_period / 2;
  i_tdata <= data_in;
  
  DUT : entity work.axi_round_and_clip_slv(rtl)
    generic map (
      WIDTH_IN   => WIDTH_IN  ,
      WIDTH_OUT  => WIDTH_OUT ,
      CLIP_BITS  => CLIP_BITS
    )
    port map (
      clk      => clk      ,
      rst      => rst      ,
      i_tvalid => i_tvalid ,
      i_tdata  => i_tdata  ,
      i_tready => i_tready ,
      o_tvalid => o_tvalid ,
      o_tdata  => o_tdata  ,
      o_tready => o_tready    
    );

  SEQUENCER_PROC : process
  begin
    wait for clk_period * 2;

    rst <= '0';
    i_tvalid <= '1';
    o_tready <= '1';

    wait for clk_period * 1000000;
    assert false
      report "Replace this with your test cases"
      severity failure;

    finish;
  end process;

end architecture;