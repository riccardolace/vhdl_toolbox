----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2024.03.08
-- Description: 
--   FIR filter implementation. The signals are represented using Q notation.
--   Therefore, the output signal is represented as a signal with 
--  'Width_out' bits where 'Width_out-1' represents the fractional part.
-- 
-- Revision:
--   0.01 - File Created
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity fir_filter is
  generic (
    -- Coefficients parameters
    Coeffs_file  : string  := "../python/coeffs_len64_Wl18.txt";
    Coeffs_len   : integer := 64;

    -- FIR filter parameters
    Width_in     : integer := 16;
    Width_coeffs : integer := 18;
    Width_sum    : integer := 40; -- Width_in + Width_coeffs + log2(Coeffs_len)
    Clip_bits    : integer :=  5;
    Width_out    : integer := 18
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    enb       : in  std_logic;
    valid_in  : in  std_logic;
    data_in   : in  std_logic_vector(Width_in-1 downto 0);
    valid_out : out std_logic;
    data_out  : out std_logic_vector(Width_out-1 downto 0)
  );
end fir_filter;

-- No symmetry is considered for the design. 
-- For the implementation see https://docs.xilinx.com/r/en-US/am004-versal-dsp-engine/Systolic-FIR-Filter
architecture rtl_noSym of fir_filter is

  ----------------------------------------------------------------
  -- Functions

  -- 1d array type
  type coeff_arr_type is array (0 to Coeffs_len - 1) of std_logic_vector(Width_coeffs - 1 downto 0);

  -- It reads the coefficients from file
  impure function readCoeffsFromFile(fileName : in string) return coeff_arr_type is
    file f         : text is fileName;
    variable fLine : line;
    variable rom   : coeff_arr_type;
    variable temp  : bit_vector(Width_coeffs - 1 downto 0);
  begin
    for rig in 0 to Coeffs_len - 1 loop
      readline(f, fLine);
      read(fLine, temp);
      rom(rig) := to_stdlogicvector(temp);
    end loop;
    return rom;
  end function;
  
  
  ----------------------------------------------------------------
  -- Signals

  -- Enable and valid combination
  signal enbValid : std_logic;

  -- Coefficients
  constant coeffs_arr : coeff_arr_type := (readCoeffsFromFile(Coeffs_file));
  
  -- Delay chain of the input signal
  type delayChain_type is array (0 to Coeffs_len-1) of std_logic_vector(Width_in-1 downto 0);
  signal delayChain : delayChain_type;
  
  -- Array of the multAdd output
  type sum_arr_type is array (0 to Coeffs_len-1) of std_logic_vector(Width_sum-1 downto 0);
  signal sum_arr : sum_arr_type;
  
  -- Valid signal
  signal tmp_valid : std_logic;

  -- Round and clip enable
  signal enb_roundAndClip : std_logic;
  
begin

  -- Enable and valid combination
  enbValid <= enb and valid_in;
  
  ----------------------------------------------------------------
  -- Multiplication and Sum perfromed by a DSP block
  ----------------------------------------------------------------
  dspCascade_GEN : for i in 0 to Coeffs_len-1 generate
    -- multAdd signals
    signal A : std_logic_vector(Width_in-1 downto 0);
    signal B : std_logic_vector(Width_coeffs-1 downto 0);
    signal C : std_logic_vector(Width_sum-1 downto 0);
    signal Y : std_logic_vector(Width_sum-1 downto 0);
  begin
  
    -- Delayed signal
    A <= delayChain(i);
  
    -- Coefficient
    B <= coeffs_arr(i);
  
    -- First block
    i_equal_0_GEN: if i=0 generate
    begin
      delay_GEN: entity work.delay_slv
      generic map (
        bitLength => Width_in
      )
      port map (
        clk => clk          ,
        rst => rst          ,
        enb => enbValid     ,
        x   => data_in      ,
        y   => delayChain(i)
      );     
      C <= (others=>'0');
    end generate;
   
    i_greater_0_GEN: if i>0 generate begin
      delay_GEN: entity work.delay_chain_slv
      generic map (
        bitLength   => Width_in,
        delayLength => 2
      )
      port map (
        clk => clk              ,
        rst => rst              ,
        enb => enbValid         ,
        x   => delayChain(i-1)  ,
        y   => delayChain(i)
      );     
      C <= sum_arr(i-1);
    end generate;
    
    sum_arr(i) <= Y;
   
    multAdd_inst : entity work.multAdd(rtl)
    generic map (
      regA_len     => 0,
      regB_len     => 1,
      regC_len     => 0,
      regMult_len  => 1,
      regAdd_len   => 1,
      addOperation => "sum",  -- "sum" or "sub"
      Width_A      => Width_in,
      Width_B      => Width_coeffs,
      Width_C      => Width_sum
    )  
    port map (
      clk       => clk       ,
      rst       => rst       ,
      enb       => enbValid  ,
      A         => A         ,
      B         => B         ,
      C         => C         ,
      Y         => Y
    );
  
  end generate;
  
  
  ----------------------------------------------------------------
  -- Rounding, saturation and valid signal
  ----------------------------------------------------------------
  
  -- Valid out
  validOut_inst: entity work.delay_chain_sl
  generic map (
    delayLength => Coeffs_len + 2
  )
  port map (
    clk => clk      ,
    rst => rst      ,
    enb => enbValid ,
    x   => '1'      ,
    y   => tmp_valid   
  );
  
  -- Round and clip
  enb_roundAndClip <= enbValid and tmp_valid;
  roundAndClip_inst: entity work.round_and_clip_slv
  generic map (
    WIDTH_IN  => Width_sum ,
    WIDTH_OUT => Width_out ,
    CLIP_BITS => Clip_bits 
  )
  port map (
    clk            => clk                   ,
    rst            => rst                   ,
    enb            => enb_roundAndClip      ,
    data_in        => sum_arr(Coeffs_len-1) ,
    sync_valid_out => valid_out             ,
    sync_data_out  => data_out
  );
  


end architecture;