----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2024.04.03
-- Description: 
--   Test Bench.
-- 
-- Revision:
--   0.01 - File Created
--
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.math_real.all;
  use ieee.numeric_std.all;

  use std.textio.all;
  use std.env.finish;

entity cordic_sqrt_tb is
end entity;

architecture sim of cordic_sqrt_tb is

  constant clk_hz     : integer := 1e9;
  constant clk_period : time    := 1 sec / clk_hz;
  constant waitNumOfCycle : integer := 1;

  signal clk : std_logic := '1';
  signal rst : std_logic := '1';

  constant Wl_in              : integer := 13;
  constant Wl_out             : integer :=  7;
  signal dut_i_tvalid         : std_logic;
  signal dut_i_tdata          : std_logic_vector(Wl_in-1 downto 0);
  signal dut_i_tdata_un       : unsigned(Wl_in-1 downto 0);
  signal dut_i_tready         : std_logic;
  signal dut_o_tdata          : std_logic_vector(Wl_out-1 downto 0);
  signal dut_o_tdata_ref      : real;
  signal dut_o_tvalid         : std_logic;
  signal dut_o_tready         : std_logic;

  type dataOutRef_type is array (0 to 255) of unsigned(Wl_out-1 downto 0);
  signal dataOutRef       : dataOutRef_type;
  signal dataOutRef_last  : unsigned(Wl_out-1 downto 0);
  signal dataOutRef_delay : integer := 53; -- Time to obtain a valid data
  
begin

  clk <= not clk after clk_period / 2;

  DUT: entity work.cordic_sqrt(cordic_unrolled)
  generic map (
    Wl_in  =>  Wl_in ,  -- It must be even. If set to odd, VHDL function outputs Wl=Wl_in+1
    Wl_out =>  Wl_out 
  )
  port map (
    clk      => clk           ,
    rst      => rst           ,
    i_tvalid => dut_i_tvalid  ,
    i_tdata  => dut_i_tdata   , 
    i_tready => dut_i_tready  ,
    o_tdata  => dut_o_tdata   ,
    o_tvalid => dut_o_tvalid  ,
    o_tready => dut_o_tready
  );

  outRef_PROC : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        dataOutRef <= (others=>(others => '0'));
        
      else
        dataOutRef(0) <= to_unsigned(integer(dut_o_tdata_ref), Wl_out);
        dataOutRef(1 to dataOutRef'length-1) <= dataOutRef(0 to dataOutRef'length-2);
        
      end if;
    end if;
  end process;
  dut_o_tdata_ref <= CEIL ( SQRT ( real(to_integer(dut_i_tdata_un(Wl_in-1 downto 0)))) );
  dataOutRef_last <= dataOutRef(dataOutRef_delay-1);
  
  dut_i_tdata <= std_logic_vector(dut_i_tdata_un);
  SEQUENCER_PROC: process
  begin
    rst <= '1';
    dut_i_tvalid <= '0';
    dut_i_tdata_un  <= shift_left(to_unsigned(1, Wl_in), Wl_in-1);
    dut_o_tready <= '0';
    wait for clk_period * 2;

    rst <= '0';
    dut_i_tvalid <= '1';
    dut_o_tready <= '1';
    wait for clk_period * 100;
    
    dut_i_tdata_un  <= shift_left(to_unsigned(1, Wl_in), Wl_in-3); wait for clk_period;
    dut_i_tdata_un  <= shift_left(to_unsigned(1, Wl_in), Wl_in-2); wait for clk_period;
    dut_i_tdata_un  <= shift_left(to_unsigned(1, Wl_in), Wl_in-3); wait for clk_period;
    dut_i_tdata_un  <= shift_left(to_unsigned(1, Wl_in), Wl_in-4); wait for clk_period;
    dut_i_tdata_un  <= shift_left(to_unsigned(1, Wl_in), Wl_in-5); wait for clk_period;
    dut_i_tdata_un  <= shift_left(to_unsigned(1, Wl_in), Wl_in-6); wait for clk_period;
    dut_i_tdata_un  <= shift_left(to_unsigned(1, Wl_in), Wl_in-7); wait for clk_period;
    dut_i_tdata_un  <= shift_left(to_unsigned(1, Wl_in), Wl_in-8) + 1235; wait for clk_period;


    wait for clk_period * 100;
    assert false
      report "Replace this with your test cases"
      severity failure;

    finish;
  end process;

end architecture;
