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

entity fir_decimator_tb is
end fir_decimator_tb;

architecture sim of fir_decimator_tb is
  
  -- 'fileDataIn' and 'fileDataOut' are used for the simulation and the relative path used
  -- in the testbench file refers to the xsim folder location, which is inside the project directory.
  -- See https://support.xilinx.com/s/article/66843?language=en_US
  constant fileDataIn  : string := "../../../../../digital_signal_processing/sample_rate_converter/testbench/data_in.txt";
  constant fileDataOut : string := "../../../../../digital_signal_processing/sample_rate_converter/testbench/data_out.txt";
  
  -- 'fileCoeffs' is passed to the DUT and the relative path file used 
  -- by the DUT file refers to the DUT file folder location.
  constant fileCoeffs  : string := "../testbench/coeffs_len128_Wl18_M8.txt";
  constant DecimFactor : integer :=   3;
  constant Coeffs_len  : integer := 128;
  
  constant clk_hz     : integer := 100e6;
  constant clk_period : time := 1 sec / clk_hz;

  signal clk : std_logic := '1';
  signal rst : std_logic := '1';
  
  constant Width_in     : integer := 16;
  constant Width_out    : integer := 18;
  
  signal enb       : std_logic;
  signal valid_in  : std_logic;
  signal data_in   : std_logic_vector(Width_in-1 downto 0);
  signal valid_out : std_logic;
  signal data_out  : std_logic_vector(Width_out-1 downto 0);

begin

  ---------- Read Process ----------
  readData_PROC : process(clk)
    file     f     : text open read_mode is fileDataIn;
    variable fLine : line;
    variable temp  : bit_vector(Width_in - 1 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        data_in <= (others=>'0');
        valid_in <= '0';

      elsif enb='1' then

        if (not endfile(f)) then
          readline(f, fLine);
          read(fLine, temp);
          data_in <= to_stdlogicvector(temp);
          valid_in <= '1';
        else
          data_in <= data_in; 
          valid_in <= '0';
        end if;
      else
        data_in <= (others => '0');
        valid_in <= '0';
      end if;
        
    end if;
  end process;


  ---------- DUT ----------

  clk <= not clk after clk_period / 2;

  DUT : entity work.fir_decimator(rtl_polyphase)
  generic map (
    -- Interpolation Factor
    DecimFactor => DecimFactor,
    DelayType   => "DelayChain",

    -- Coefficients parameters
    Coeffs_file  => fileCoeffs,
    Coeffs_len   => Coeffs_len,

    -- FIR filter parameters
    Width_in     => 16,
    Width_coeffs => 18,
    Width_sum    => 40, -- Width_in + Width_coeffs + log2(Coeffs_len)
    Width_acc    => 42, -- Width_sum + log2(DecimFactor)
    Clip_bits    =>  9,
    Width_out    => 18
  )
  port map (
    clk       => clk       ,
    rst       => rst       ,
    enb       => enb       ,
    valid_in  => valid_in  ,
    data_in   => data_in   ,
    valid_out => valid_out ,
    data_out  => data_out  
  );

  SEQUENCER_PROC : process
  begin
    wait for clk_period * 2;
    rst <= '0';
    enb <= '1';
    
    wait for clk_period * 1000000;
    assert false
      report "Replace this with your test cases"
      severity failure;

    finish;
  end process;

  ---------- Write Process ----------

  -- Write Process
  process(clk)
    file out_stream : text open write_mode is fileDataOut;
    variable row    : line;
  begin
    if rising_edge(clk) then
      if valid_out='1' then
        write(row, to_bitvector(data_out));
        writeline(out_stream,row);
      end if;
    end if;
  end process;



end architecture;