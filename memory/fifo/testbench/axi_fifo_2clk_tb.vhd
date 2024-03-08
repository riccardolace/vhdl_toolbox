----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2024.03.06
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

entity axi_fifo_2clk_tb is
end axi_fifo_2clk_tb;

architecture sim of axi_fifo_2clk_tb is

  -- Clock high
  constant clk_hz_high     : integer := 100e6;
  constant clk_period_high : time    := 1 sec / clk_hz_high;
  signal clk_high : std_logic := '1';
  
  -- Clock low
  constant clk_hz_low      : integer := 50e6;
  constant clk_period_low  : time    := 1 sec / clk_hz_low;
  signal clk_low : std_logic := '1';
  
  constant FIFO_DATA_WIDTH : integer := 16;
  signal rst      : std_logic := '1';
  signal i_tvalid : std_logic;
  signal i_tdata  : std_logic_vector(FIFO_DATA_WIDTH - 1 downto 0);
  signal i_tready : std_logic;
  signal o_tvalid : std_logic;
  signal o_tdata  : std_logic_vector(FIFO_DATA_WIDTH - 1 downto 0);
  signal o_tready : std_logic := '1';

  signal reg_valid : std_logic;
  signal reg_cnt   : unsigned(FIFO_DATA_WIDTH-1 downto 0);
  
begin

  clk_high <= not clk_high after clk_period_high / 2;
  clk_low  <= not clk_low  after clk_period_low  / 2;

  writeSide_PROC : process(clk_low)
  begin
    if rising_edge(clk_low) then
      if rst = '1' then
        reg_valid <= '0';
        reg_cnt <= (others => '0');
        
      else
        reg_valid <= '1';
        reg_cnt <= reg_cnt+1;
        
      end if;
    end if;
  end process;

  i_tvalid <= reg_valid;
  i_tdata  <= std_logic_vector(reg_cnt);

  DUT : entity work.axi_fifo_2clk
  generic map (
    ALMOST_FULL_OFFSET => 16,
    FIFO_ADDR_WIDTH    =>  9,
    FIFO_DATA_WIDTH    => 16,
    BRAM_TYPE          => "block"
  )
  port map (
    i_clk    => clk_low   ,
    i_rst    => rst       ,
    i_tvalid => i_tvalid  ,
    i_tdata  => i_tdata   ,
    i_tready => i_tready  ,
    o_clk    => clk_high  ,
    o_rst    => rst       ,
    o_tvalid => o_tvalid  ,
    o_tdata  => o_tdata   ,
    o_tready => o_tready
  );

  SEQUENCER_PROC : process
  begin
    wait for clk_period_high * 10;
    rst <= '0';
    
    wait for clk_period_high * 1000;
    assert false
      report "Replace this with your test cases"
      severity failure;

    finish;
  end process;

end architecture;