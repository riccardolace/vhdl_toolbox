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

entity acc_N_sps_tb is
end acc_N_sps_tb;

architecture sim of acc_N_sps_tb is

  constant clk_hz : integer := 100e6;
  constant clk_period : time := 1 sec / clk_hz;

  signal clk : std_logic := '1';
  signal rst : std_logic := '1';

  constant accType : string := "signed";
  constant spsToAcc : integer := 4;
  constant bitLength_x : integer := 16;
  constant bitLength_y : integer := 16;
  signal enb       : std_logic := '0';
  signal cnt       : unsigned(bitLength_x-1 DOWNTO 0) := (others => '0');
  signal x_uint    : unsigned(bitLength_x-1 DOWNTO 0) := to_unsigned(1, bitLength_x);
  signal x_int     : signed(bitLength_x-1 DOWNTO 0) := to_signed(-1, bitLength_x);
  signal x         : std_logic_vector(bitLength_x-1 DOWNTO 0);
  signal y         : std_logic_vector(bitLength_y-1 DOWNTO 0);
  signal valid_out : std_logic;

begin

  clk <= not clk after clk_period / 2;

  testSignal_PROC : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cnt    <= (others => '0');
        x_uint <= to_unsigned(1, bitLength_x);
        x_int  <= to_signed(-1, bitLength_x);
        
      elsif enb='1' then
        if cnt=spsToAcc-1 then
          cnt <= (others => '0');
          x_uint <= to_unsigned(1, bitLength_x);
          x_int  <= to_signed(-1, bitLength_x);
        else
          cnt <= cnt+1;
          x_uint <= x_uint + 1;
          x_int  <= x_int  - 1;
        end if;        
      end if;
    end if;
  end process;

  sigGen:   if accType="signed"   generate begin x <= std_logic_vector(x_int);  end generate;
  unsigGen: if accType="unsigned" generate begin x <= std_logic_vector(x_uint); end generate;

  DUT : entity work.acc_N_sps(rtl)
  generic map (
    accType     => accType     ,
    spsToAcc    => spsToAcc    ,
    bitLength_x => bitLength_x ,
    bitLength_y => bitLength_y 
  )  
  port map (
    clk => clk ,
    rst => rst ,
    enb => enb ,
    x   => x   ,
    valid_out => valid_out,
    y   => y   
  );

  SEQUENCER_PROC : process
  begin
    wait for clk_period * 2;
    rst <= '0';
    enb <= '1';
    
    wait for clk_period * (4*spsToAcc+4);
    assert false
      report "Replace this with your test cases"
      severity failure;

    finish;
  end process;

end architecture;