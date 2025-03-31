----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2025.02.27
--
-- Description: 
-- This VHDL code implements a natural logarithm (ln) function using the CORDIC algorithm.
--
-- Input:
--   - 'input_data': An unsigned value representing the argument for the natural logarithm.
--     - The input is treated as an unsigned fixed-point number in UQ1.FF format, where:
--       - '1' bit represents the integer part.
--       - 'FF' bits (defined as Wl_in-1) represent the fractional part.
--     - This format restricts the input range to [0, 2 - 2^(-FF)).
--     - Note: While ln(0) is mathematically undefined, this block will converge to the minimum value for an input of 0.
--
-- Output:
--   - 'output_data': A signed fixed-point value representing the natural logarithm of the input.
--     - The output is represented in QX.Y format (where $X=floor(log2(Wl_out)+1)$ and $Y=Wl_in-X$ are determined based on the implementation details).
--     - The output range is limited to [ln(0), ln(2-2^(-FF))). Since ln(2-2^(-FF)) < ln(2), the maximum representable value is less than ln(2).
--     - The output is signed to correctly represent the negative values resulting from ln(x) for x < 1.
--
-- Implementation Details:
--   - The CORDIC algorithm is used for the logarithm computation.
--   - The input is interpreted as a fixed-point number to enable efficient hardware implementation.
--
--
-- Block diagram:
--                                                                      ┌───────┐
--                          ┌──────────────────────────────────────────>│ DELAY ├──┐
--                          │                                           └───────┘  │
--                          │                                                      │
--                          │                                                      │    ┌─────────────┐    ┌───────┐ 
--              ┌───────┐   │    ┌───────┐  shifted  ┌────────┐         ┌───────┐  └───>│ LEFT        │    │ ROUND │ data_out
--   data_in    │ COUNT │ n │    │ LEFT  │  data     │ CORDIC │         │ LEFT  │       │ BIT SHIFT   ├───>│ AND   ├──────────>
--       ───┬──>│ ZERO  ├───┴───>│ BIT   ├──────────>│ KERNEL ├────────>│ SHIFT ├──────>│ COMPENSATOR │    │ CLIP  │ 
--          │   │ BITS  │  ┌────>│ SHIFT │           │        │         │ BY 1  │       └─────────────┘    └───────┘ 
--          │   └───────┘  │     └───────┘           └────────┘         └───────┘
--          │              │
--          └──────────────┘
--
--
-- Revision:
--   2025.02.27 - File Created
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.pkg_vhdl_toolbox.flp_to_fxp;

entity cordic_ln is
  generic (
    Wl_in  : integer := 36;
    Wl_out : integer := 18
  );
  port (
    clk : in std_logic;
    rst : in std_logic;

    -- Input interface
    i_tvalid : in std_logic;
    i_tdata  : in std_logic_vector(Wl_in - 1 downto 0);
    i_tready : out std_logic;

    -- Output interface
    o_tdata  : out std_logic_vector(Wl_out - 1 downto 0);
    o_tvalid : out std_logic;
    o_tready : in std_logic
  );
end cordic_ln;

architecture cordic_unrolled of cordic_ln is

  ---------------- Number of iterations ----------------

  -- Estimate the number of iterations of the cordic algorithm
  function cordicEstimateNumIterations(Wl : integer) return integer is
    variable i                              : integer := 1;
    variable i_rep                          : integer := 4;
    variable numIterations                  : integer := 0;
  begin
    i             := 1;
    i_rep         := 3 * i + 1;
    numIterations := 0;
    while (i <= Wl) loop
      if (i = i_rep) then
        i_rep := 3 * i + 1;
      else
        i := i + 1;
      end if;
      numIterations := numIterations + 1;
    end loop;
    return numIterations;
  end function;

  -- Cordic Iterations
  constant cordicIterations : integer := cordicEstimateNumIterations(Wl_in);

  ---------------- Word length and notations ----------------

  -- Output notation
  constant Wl_out_int : integer := integer(floor(log2(real(Wl_in))));   -- Integer part
  constant Wl_out_frc : integer := Wl_out - Wl_out_int - 1;             -- Fractional part ("1" is subtracted to consider the sign)

  -- Word length of the CORDIC kernel
  constant c_Wl_cordicKernel  : integer := Wl_in + integer(ceil(log2(real(cordicIterations))));

  -- Fractional part of the CORDIC kernel
  constant c_Wl_cordicKernel_frc  : integer := Wl_in-1;

  -- Estimate the indices of the Cordic algorithm
  type cordicForLoopIndex_type is array (0 to cordicIterations - 1) of integer;

  function cordicEstimateIndices(Wl : integer) return cordicForLoopIndex_type is
    variable i                        : integer := 1;
    variable j                        : integer := 0;
    variable i_rep                    : integer := 4;
    variable cordicForLoopIndex       : cordicForLoopIndex_type;
  begin
    i     := 1;
    i_rep := 3 * i + 1;
    j     := 0;
    while (i <= Wl) loop
      cordicForLoopIndex(j) := i;
      if (i = i_rep) then
        i_rep := 3 * i + 1;
      else
        i := i + 1;
      end if;
      j := j + 1;
    end loop;
    return cordicForLoopIndex;
  end function;

  -- Indices
  constant cordicForLoopIndex : cordicForLoopIndex_type := cordicEstimateIndices(Wl_in);

  ---------------- Math values used in the CORDIC Kernel and Post-processing sections ----------------

  -------- atanh FXP --------
  --
  -- 'atanh(x)' can be rewritten as:
  --      atanh(x) = log((1.0+x)/(1.0-x)) / 2.0 = (log(1.0+x) - log(1.0-x))/2.0
  --
  function atanh_fxp_gen(j : integer) return signed is
    variable x               : real;
    variable atanh_r         : real;
    variable atanh_fxp       : signed(c_Wl_cordicKernel - 1 downto 0);
  begin
    x := 1.0 / (2.0**real(j));
    if abs(x) >= 0.0 and abs(x) < 1.0 then
      atanh_r := (log(1.0 + x) - log(1.0 - x))/2.0;
      -- atanh_r := arctanh(x);
    else
      atanh_r := 0.0;
    end if;
    atanh_fxp := signed(flp_to_fxp(atanh_r, c_Wl_cordicKernel, c_Wl_cordicKernel_frc));
    return atanh_fxp;
  end function;

  -------- n*ln(2) --------
  --
  -- n*ln(2) elements are saved in a LUT. In this way, in the post-processing only the sum is needed.

  type n_ln2_arr_type is array (natural range<>) of signed(c_Wl_cordicKernel - 1 downto 0);

  function n_dot_ln2_arr_gen(numElements : integer) return n_ln2_arr_type is

    variable shift_val0   : real;
    variable shift_val1   : real;
    variable x          : real;
    variable x_fxp      : signed(c_Wl_cordicKernel - 1 downto 0);
    variable ret        : n_ln2_arr_type(0 to numElements-1) := (others => (others => '0'));

  begin

    -- Find all 'n ln(2)' values
    for n in 0 to numElements - 1 loop

      -- FLP value
      x := real(n) * MATH_LOG_OF_2;

      -- FLP to FXP
      x_fxp := signed(flp_to_fxp(x, c_Wl_cordicKernel, c_Wl_cordicKernel_frc));
      
      -- Assign
      ret(n) := x_fxp;

      end loop;
    return ret;
  end function;


  ----------------------------------------------------------------
  -- Signals

  -- Global Enable
  signal enb : std_logic;

  -------- Count zero bits --------
  constant zeros_encoder_Wl         : integer := Wl_out_int +1;
  signal zeros_encoderInput         : std_logic_vector(2 ** zeros_encoder_Wl - 1 downto 0);
  signal zeros_encoderOutput        : std_logic_vector(zeros_encoder_Wl - 1 downto 0);
  signal zeros_encoderNumZeros      : std_logic_vector(zeros_encoderOutput'range);
  signal zeros_delayChainInput      : std_logic_vector(zeros_encoderOutput'range);
  signal zeros_delayChainOutput     : std_logic_vector(zeros_encoderOutput'range);
  constant delay_leftBitShift       : integer := Wl_out_int;
  constant delay_cordicKernel       : integer := cordicIterations;
  constant delay_postProcessing_x2  : integer := 1;
  constant zeros_delayChainLength   : integer := delay_leftBitShift + delay_cordicKernel + delay_postProcessing_x2;

  -------- Left Bit Shift --------
  signal leftShift_x         : std_logic_vector(Wl_in - 1 downto 0);
  signal leftShift_sel       : std_logic_vector(zeros_encoderOutput'range);
  signal leftShift_y         : std_logic_vector(Wl_in - 1 downto 0);
  signal leftShift_valid_out : std_logic;

  -------- Cordic Kernel --------
  type cordicKernel_data_type is array (0 to cordicIterations) of signed(c_Wl_cordicKernel - 1 downto 0);
  constant c_cor_ker_val_1 : signed(c_Wl_cordicKernel - 1 downto 0) := shift_left(to_signed(1, c_Wl_cordicKernel), c_Wl_cordicKernel_Frc);
  signal reg_cor_ker_x     : cordicKernel_data_type;
  signal reg_cor_ker_y     : cordicKernel_data_type;
  signal reg_cor_ker_z     : cordicKernel_data_type;
  signal reg_cor_ker_valid : std_logic_vector(0 to cordicIterations);

  -------- Post-processing --------
  constant n_ln2_arr          : n_ln2_arr_type(0 to 2**zeros_encoder_Wl-1) := n_dot_ln2_arr_gen(2**zeros_encoder_Wl);
  signal post_z_dot_2         : signed(c_Wl_cordicKernel - 1 downto 0);
  signal post_n_ln2           : signed(c_Wl_cordicKernel - 1 downto 0);
  signal reg_post_sub_ln      : signed(c_Wl_cordicKernel - 1 downto 0);
  signal reg_post_valid       : std_logic;

  -- Round output data
  constant round_c_Wl_in  : integer := c_Wl_cordicKernel;
  constant round_c_Wl_out : integer := Wl_out;
  constant round_c_clip   : integer := c_Wl_cordicKernel - (c_Wl_cordicKernel_frc + Wl_out_int + 1);
  signal round_enb       : std_logic;
  signal round_data_in   : std_logic_vector(c_Wl_cordicKernel-1 downto 0);
  signal round_valid_out : std_logic;
  signal round_data_out  : std_logic_vector(Wl_out - 1 downto 0);

begin

  -- Global Enable 
  enb <= i_tvalid and o_tready;

  ----------------------------------------------------------------
  -- Pre-processing
  ----------------------------------------------------------------

  -------- Find the MSB zeros --------
  -- 1 Clock Latency
  zeros_encoderInput(Wl_in - 1 downto 0)                         <= i_tdata;
  zeros_encoderInput(zeros_encoderInput'length - 1 downto Wl_in) <= (others => '0');

  zeroEncoder_INST : entity work.priorityEncoder(rtl)
    generic map(
      n => zeros_encoderOutput'length
    )
    port map
    (
      clk   => clk,
      rst   => rst,
      enb   => enb,
      x     => zeros_encoderInput,
      y     => zeros_encoderOutput,
      reg_y => open
    );
  zeros_encoderNumZeros <= std_logic_vector((Wl_in - 1) - unsigned(zeros_encoderOutput));
  zeros_delayChainInput <= zeros_encoderNumZeros;

  zerosDelayChain_INST : entity work.delay_chain_slv
    generic map(
      bitLength   => zeros_delayChainInput'length,
      delayLength => zeros_delayChainLength
    )
    port map
    (
      clk => clk,
      rst => rst,
      enb => enb,
      x   => zeros_delayChainInput,
      y   => zeros_delayChainOutput
    );

  -------- Left Bit Shift --------
  -- 'bitSelectorLength' clock latency
  leftShift_x   <= i_tdata;
  leftShift_sel <= zeros_encoderNumZeros;

  leftShift_INST : entity work.barrelShifter(rtl)
    generic map(
      shiftDirection    => "left", -- "left" or "right"
      shiftSign         => "unsigned", -- "signed" or "unsigned"
      shiftType         => "arithmetic", -- "arithmetic" or "logical"
      bitDataLength     => leftShift_x'length,
      bitSelectorLength => leftShift_sel'length
    )
    port map
    (
      clk       => clk,
      rst       => rst,
      enb       => enb,
      x         => leftShift_x,
      sel       => leftShift_sel,
      valid_out => leftShift_valid_out,
      y         => leftShift_y
    );

  ----------------------------------------------------------------
  -- CORDIC Kernel
  ----------------------------------------------------------------

  -- Clock Cycles Latency related to 'cordicIterations'. 
  -- Initialization
  -- x = u + 1.0
  -- y = u - 1.0
  -- 
  -- The first elements of the arrays 'reg_cor_ker_x(0)', 'reg_cor_ker_y(0)' and 'reg_cor_ker_z(0)' are not a registers.
  reg_cor_ker_x(0)     <= resize(signed("0" & leftShift_y), c_Wl_cordicKernel) + c_cor_ker_val_1;
  reg_cor_ker_y(0)     <= resize(signed("0" & leftShift_y), c_Wl_cordicKernel) - c_cor_ker_val_1;
  reg_cor_ker_z(0)     <= to_signed(0, c_Wl_cordicKernel);
  reg_cor_ker_valid(0) <= leftShift_valid_out;

  CORDIC_STAGES : for idx in 1 to cordicIterations generate

    -- Constants
    constant valShift  : integer                                := cordicForLoopIndex(idx - 1);
    constant atanh_lut : signed(c_Wl_cordicKernel - 1 downto 0) := atanh_fxp_gen(valShift);
  begin
    process (clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          reg_cor_ker_x(idx)     <= (others => '0');
          reg_cor_ker_y(idx)     <= (others => '0');
          reg_cor_ker_z(idx)     <= (others => '0');
          reg_cor_ker_valid(idx) <= '0';
        elsif enb = '1' then
          reg_cor_ker_valid(idx) <= reg_cor_ker_valid(idx - 1);

          if reg_cor_ker_y(idx - 1) < 0 then
            reg_cor_ker_x(idx) <= reg_cor_ker_x(idx - 1) + shift_right(reg_cor_ker_y(idx - 1), valShift);
            reg_cor_ker_y(idx) <= reg_cor_ker_y(idx - 1) + shift_right(reg_cor_ker_x(idx - 1), valShift);
            reg_cor_ker_z(idx) <= reg_cor_ker_z(idx - 1) - atanh_lut;
          else
            reg_cor_ker_x(idx) <= reg_cor_ker_x(idx - 1) - shift_right(reg_cor_ker_y(idx - 1), valShift);
            reg_cor_ker_y(idx) <= reg_cor_ker_y(idx - 1) - shift_right(reg_cor_ker_x(idx - 1), valShift);
            reg_cor_ker_z(idx) <= reg_cor_ker_z(idx - 1) + atanh_lut;

          end if;

        else
          reg_cor_ker_x(idx)     <= reg_cor_ker_x(idx);
          reg_cor_ker_y(idx)     <= reg_cor_ker_y(idx);
          reg_cor_ker_z(idx)     <= reg_cor_ker_z(idx);
          reg_cor_ker_valid(idx) <= reg_cor_ker_valid(idx);
        end if;
      end if;
    end process;

  end generate;

  ----------------------------------------------------------------
  -- Post-processing
  ----------------------------------------------------------------

  -------- Left shift the result by 2 --------
  -- Since the algorithm converges to 'z = 0.5 * ln(x)', the left shifting allows to have 'ln(x)'
  post_z_dot_2 <= shift_left(reg_cor_ker_z(cordicIterations), 1);

  -------- Sub to compensate the left shift of the pre-processing --------
  post_n_ln2 <= n_ln2_arr(to_integer(unsigned(zeros_delayChainOutput)));
  subPostProcessing_PROC : process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        reg_post_sub_ln <= (others => '0');
        reg_post_valid  <= '0';
      elsif enb = '1' then
        reg_post_sub_ln <= resize(post_z_dot_2, reg_post_sub_ln'length) - post_n_ln2;
        reg_post_valid  <= reg_cor_ker_valid(cordicIterations);

      end if;
    end if;
  end process;

  -------- Rounding --------
  round_enb     <= enb and reg_post_valid;
  round_data_in <= std_logic_vector(reg_post_sub_ln);
  out_roundAndClip_INST : entity work.round_and_clip_slv(rtl)
    generic map(
      WIDTH_IN  => round_c_Wl_in  ,
      WIDTH_OUT => round_c_Wl_out ,
      CLIP_BITS => round_c_clip    
    )
    port map
    (
      clk            => clk,
      rst            => rst,
      enb            => round_enb,
      data_in        => round_data_in,
      sync_valid_out => round_valid_out,
      sync_data_out  => round_data_out
    );

  -------- Output Ports assignments --------

  -- Input side - ready
  i_tready <= o_tready;

  -- Output side - Valid out
  o_tvalid <= i_tvalid and round_valid_out;
  o_tdata  <= round_data_out;

end cordic_unrolled;
