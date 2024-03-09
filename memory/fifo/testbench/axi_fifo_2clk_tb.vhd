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

  -- Clock write side
  constant clk_hz_wr     : integer := 100e6;
  constant clk_period_wr : time    := 1 sec / clk_hz_wr;
  signal clk_wr : std_logic := '1';
  
  -- Clock read side
  constant clk_hz_rd      : integer := 130e6;
  constant clk_period_rd  : time    := 1 sec / clk_hz_rd;
  signal clk_rd : std_logic := '1';
  
  -- Write data
  -- Counter is used to generate an appropriate valid signal 
  signal   wr_cnt   : unsigned(7 downto 0) := to_unsigned(0,8);
  constant wr_max : integer   := 1;  -- It defines the sample rate (clk_hz_wr/wr_max sps)
  signal   wr_enb : std_logic := '1';
  
  constant FIFO_DATA_WIDTH : integer := 16;
  signal rst      : std_logic := '1';
  signal i_tvalid : std_logic;
  signal i_tdata  : std_logic_vector(FIFO_DATA_WIDTH - 1 downto 0);
  signal i_tready : std_logic;
  signal o_tvalid : std_logic;
  signal o_tdata  : std_logic_vector(FIFO_DATA_WIDTH - 1 downto 0);
  signal o_tready : std_logic := '1';

  signal reg_valid : std_logic;
  signal reg_data  : unsigned(FIFO_DATA_WIDTH-1 downto 0);
  
begin

  clk_wr  <= not clk_wr after clk_period_wr / 2;
  clk_rd  <= not clk_rd after clk_period_rd  / 2;

  writeSide_PROC : process(clk_wr)
  begin
    if rising_edge(clk_wr) then
      if rst = '1' then
        reg_valid <= '0';
        wr_cnt   <= (others => '0');
        reg_data <= (others => '0');
        
      elsif wr_enb='1' then
        
        if wr_cnt=wr_max-1 then
          reg_valid <= '1';
          reg_data  <= reg_data+1;
          wr_cnt    <= (others=>'0');
        else
          reg_valid <= '0';
          reg_data  <= reg_data;
          wr_cnt    <= wr_cnt + 1;
        end if;
      
      else
        reg_valid <= '0';
        reg_data  <= reg_data;
        wr_cnt    <= wr_cnt;

      end if;
    end if;
  end process;

  i_tvalid <= reg_valid;
  i_tdata  <= std_logic_vector(reg_data);

  DUT : entity work.axi_fifo_2clk
  generic map (
    MIN_SAMPLES_TO_READ =>  1,
    ALMOST_FULL_OFFSET  => 16,
    FIFO_ADDR_WIDTH     =>  9,
    FIFO_DATA_WIDTH     => 16,
    BRAM_TYPE           => "block"
  )
  port map (
    i_clk    => clk_wr    ,
    i_rst    => rst       ,
    i_tvalid => i_tvalid  ,
    i_tdata  => i_tdata   ,
    i_tready => i_tready  ,
    o_clk    => clk_rd    ,
    o_rst    => rst       ,
    o_tvalid => o_tvalid  ,
    o_tdata  => o_tdata   ,
    o_tready => o_tready
  );

  SEQUENCER_PROC : process
  begin
    wait for clk_period_wr * 10;
    rst    <= '0';
    wr_enb <= '1';
    
    wait for clk_period_wr * 1000;
    wr_enb <= '0';
    
    wait for clk_period_wr * 1000;
    wr_enb <= '1';
    
    wait for clk_period_wr * 1000;
    wr_enb <= '0';
    
    wait for clk_period_wr * 1000;
    wr_enb <= '1';
    
    wait for clk_period_wr * 1000;
    wr_enb <= '0';
    
    wait for clk_period_wr * 1000;
    wr_enb <= '1';
    
    wait for clk_period_wr * 1000;
    wr_enb <= '0';
    
    wait for clk_period_wr * 50;
    
    assert false
      report "Replace this with your test cases"
      severity failure;

    finish;
  end process;

end architecture;