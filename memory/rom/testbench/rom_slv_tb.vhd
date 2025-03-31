----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2024.03.05
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

entity rom_slv_tb is
end entity;

architecture sim of rom_slv_tb is

  constant clk_hz     : integer := 1e9;
  constant clk_period : time    := 1 sec / clk_hz;

  signal clk : std_logic := '1';
  signal rst : std_logic := '1';

  constant bitLength : INTEGER := 16;
  signal enb : STD_LOGIC := '0';
  signal data_out : STD_LOGIC_VECTOR(bitLength - 1 downto 0);
  signal addr_rd : std_logic_vector(5 downto 0);
  signal valid_out : std_logic;
  
begin

  clk <= not clk after clk_period / 2;

  DUT: entity work.rom_slv(rtl_intAddress)
    generic map (
      romSize   => 64,
      romStyle  => "distributed",
      romPath   => "../testbench/data_unsigned.txt",
      bitLength => bitLength
    )
    port map (
      clk       => clk,
      rst       => rst,
      enb       => enb,
      addr_rd   => addr_rd,
      valid_out => valid_out,
      data_out  => data_out
    );

  addrGenerator_PROC : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        addr_rd <= (others => '0');
        
      elsif enb='1' then
        addr_rd <= std_logic_vector(unsigned(addr_rd)+1);
        
      end if;
    end if;
  end process;

  SEQUENCER_PROC: process
  begin
    wait for clk_period * 2;

    rst <= '0';
    enb <= '1';

    wait for clk_period * 10;

    -- assert false
    --   report "Replace this with your test cases"
    --   severity failure;
    -- finish;
  end process;

end architecture;
