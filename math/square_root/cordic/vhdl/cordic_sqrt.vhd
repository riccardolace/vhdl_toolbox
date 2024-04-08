----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2024.04.03
--
-- Description: 
--   Cordic square root.
--
--                              ┌───────┐
--                        ┌────>│ DELAY ├─────────────────────────────────────────────┐    
--                        │     └───────┘                                             │    ┌───────┐  
--                        │                                                           │    │       │    
--             ┌───────┐  │     ┌───────┐                                             └───>│ RIGHT │   data_out
--             │       │  │     │       │  shifted                ┌──────────────┐         │ BIT   ├────>
--  data_in    │ COUNT │  │     │ LEFT  │  data     ┌────────┐    │ CORDIC GAIN  │         │ SHIFT │  
--      ───┬──>│ ZERO  ├──┴────>│ BIT   ├──────────>│ CORDIC ├───>│ COMPENSATION ├────────>│       │
--         │   │ BITS  │        │ SHIFT │           └────────┘    │              │         └───────┘ 
--         │   │       │  ┌────>│       │                         └──────────────┘
--         │   └───────┘  │     └───────┘            
--         │              │
--         └──────────────┘
--
--
--
--   Relation between 'Wl_in' and 'Valid out length'
--       ┌───────┬──────────────────┐
--       │ Wl_in │ Valid out length │
--       ├───────┼──────────────────┤
--       │  36   │ 53 clock cycles  │
--       ├───────┼──────────────────┤
--       │  35   │ 53 clock cycles  │
--       ├───────┼──────────────────┤
--       │  34   │ 51 clock cycles  │
--       ├───────┼──────────────────┤
--       │  33   │ 51 clock cycles  │
--       ├───────┼──────────────────┤
--       │  32   │ 49 clock cycles  │
--       ├───────┼──────────────────┤
--       │  31   │ 49 clock cycles  │
--       ├───────┼──────────────────┤
--       │  30   │ 45 clock cycles  │
--       ├───────┼──────────────────┤
--       │  29   │ 45 clock cycles  │
--       ├───────┼──────────────────┤
--       │  18   │ 33 clock cycles  │
--       ├───────┼──────────────────┤
--       │  17   │ 33 clock cycles  │
--       ├───────┼──────────────────┤
--       │  16   │ 31 clock cycles  │
--       ├───────┼──────────────────┤
--       │  15   │ 31 clock cycles  │
--       ├───────┼──────────────────┤
--       │  14   │ 27 clock cycles  │
--       ├───────┼──────────────────┤
--       │  13   │ 27 clock cycles  │
--       └───────┴──────────────────┘
--
-- Revision:
--   0.01 - File Created
--
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

library work;
  use work.pkg_vhdl_toolbox.all;

entity cordic_sqrt is
  generic (
    Wl_in  : integer := 36;  -- It must be even. If set to odd, VHDL function outputs Wl=Wl_in+1
    Wl_out : integer := 18
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    i_tvalid  : in  std_logic;
    i_tdata   : in  std_logic_vector(Wl_in-1 downto 0);
    i_tready  : out std_logic;
    o_tdata   : out std_logic_vector(Wl_out-1 downto 0);
    o_tvalid  : out std_logic;
    o_tready  : in  std_logic
  );
end cordic_sqrt;

architecture cordic_unrolled of cordic_sqrt is

  -------- Word length --------
  -- Use Wl_in to define the Word Length (Wl).
  function setWordLength(Wl_in : integer) return integer is
    variable Wl : integer := 0;
  begin
    if ((Wl_in mod 2) = 0) then
      Wl := Wl_in;
    else
      Wl := Wl_in+1;
    end if;
    return Wl;
  end function;
  constant Wl : integer := setWordLength(Wl_in);

  -------- Number of iterations --------

  -- Estimate the number of iterations of the cordic algorithm
  function cordicEstimateNumIterations(Wl : integer) return integer is
    variable i              : integer := 1;
    variable i_rep          : integer := 4;
    variable numIterations  : integer := 0;
  begin
    i             := 1;
    i_rep         := 3*i+1;
    numIterations := 0;
    while (i<=Wl) loop
      if (i=i_rep) then
        i_rep := 3*i+1;
      else
        i := i+1;
      end if;
      numIterations := numIterations+1;
    end loop;
    return numIterations;
  end function; 

  -------- Indices of the Cordic algorithm --------

  -- Cordic Iterations
  constant cordicIterations : integer := cordicEstimateNumIterations(Wl);

  -- Estimate the indices of the Cordic algorithm
  type cordicForLoopIndex_type is array (0 to cordicIterations-1) of integer;
  function cordicEstimateIndices(Wl : integer) return cordicForLoopIndex_type is
    variable i     : integer := 1;
    variable j     : integer := 0;
    variable i_rep : integer := 4;
    variable cordicForLoopIndex : cordicForLoopIndex_type;
  begin
    i     := 1;
    i_rep := 3*i+1;
    j     := 0;
    while (i<=Wl) loop
      cordicForLoopIndex(j) := i;
      if (i=i_rep) then
        i_rep := 3*i+1;
      else
        i := i+1;
      end if;
      j := j+1;
    end loop;
    return cordicForLoopIndex;
  end function;

  -- Indices
  constant cordicForLoopIndex : cordicForLoopIndex_type := cordicEstimateIndices(Wl);

  -------- Cordic gain --------

  -- Estimate the Cordic gain of the square root
  function cordicSqrtGain(Wl : integer) return real is
    variable An             : real    := 1.0;
    variable i              : integer := 1;
    variable i_rep          : integer := 4;
    variable cordicGain     : real    := 0.0;
  begin
    An    := 1.0;
    i     := 1;
    i_rep := 3*i+1;
  
    while (i<=Wl) loop
      An := An * SQRT(1.0 - (2.0**(real(-2*i))) );

      if (i=i_rep) then
        i_rep := 3*i+1;
      else
        i := i+1;
      end if;

    end loop;

    cordicGain := 1.0 / An;
    return cordicGain;
  end function;

  -- Cordic Gain
  constant cordicGain_real  : real    := cordicSqrtGain(Wl);


  ----------------------------------------------------------------
  -- Signals

  -- Global Enable
  signal enb : std_logic;

  -- Input and Output registers
  signal reg_i_tvalid : std_logic;
  signal reg_i_tdata  : std_logic_vector(Wl-1 downto 0);
  signal reg_i_tready : std_logic;
  signal reg_o_tdata  : std_logic_vector(Wl_out-1 downto 0);
  signal reg_o_tvalid : std_logic;
  signal reg_o_tready : std_logic;
  signal int_o_tvalid : std_logic;
  signal int_o_tdata  : std_logic_vector(Wl_out-1 downto 0);
  
  -------- Count zero bits --------
  constant zeros_encoder_Wl         : integer := (log2(Wl)+1);
  signal zeros_encoderInput         : std_logic_vector(2**zeros_encoder_Wl-1  downto 0);
  signal zeros_encoderOutput        : std_logic_vector(zeros_encoder_Wl-1     downto 0);
  signal zeros_encoderNumZeros      : std_logic_vector(zeros_encoderOutput'range);
  signal zeros_encoderNumZeros_Even : std_logic_vector(zeros_encoderOutput'range);
  signal zeros_delayChainInput      : std_logic_vector(zeros_encoderOutput'range);
  signal zeros_delayChainOutput     : std_logic_vector(zeros_encoderOutput'range);
  constant delay_leftBitShift       : integer := log2(Wl/2)+2;
  constant delay_cordicKernel       : integer := cordicIterations;
  constant delay_rightBitShift      : integer := log2(Wl/2)+2;
  constant delay_multCordicComp     : integer := 1;
  constant zeros_delayChainLength   : integer := delay_leftBitShift + delay_cordicKernel + delay_multCordicComp;

  -------- Left Bit Shift --------
  signal leftShift_x    : std_logic_vector(Wl-1 downto 0);
  signal leftShift_sel  : std_logic_vector(zeros_encoderOutput'range);
  signal leftShift_y    : std_logic_vector(Wl-1 downto 0);

  -------- Cordic Kernel --------
  type cordicKernel_data_type is array (0 to cordicIterations) of signed(Wl downto 0);
  constant c_cor_ker_val_025  : signed(Wl downto 0) := shift_left(to_signed(1, Wl+1), Wl-4);
  signal reg_cor_ker_x        : cordicKernel_data_type;
  signal reg_cor_ker_y        : cordicKernel_data_type;
  signal reg_cor_ker_valid    : std_logic_vector(0 to cordicIterations);

  -------- Gain compensation of the Cordic Algorithm --------
  constant  cordiGainWl               : integer := 16;
  constant  cordicGain_int            : integer := integer(round(cordicGain_real * (2.0**real(cordiGainWl-1))));
  signal    multCordicGain_x          : std_logic_vector(Wl-1  downto 0);
  constant  multCordicGain_y          : std_logic_vector(cordiGainWl-1 downto 0) := std_logic_vector(to_unsigned(cordicGain_int, cordiGainWl));
  signal    multCordicGain_z          : std_logic_vector(multCordicGain_x'length+multCordicGain_y'length-1  downto 0);
  signal    multCordicGain_z_shifted  : std_logic_vector(multCordicGain_z'length-1  downto 0);

  -------- Right Bit Shift --------
  signal rightShift_x   : std_logic_vector(multCordicGain_z_shifted'length-1 downto 0);
  signal rightShift_sel : std_logic_vector(zeros_encoderOutput'range);
  signal rightShift_y   : std_logic_vector(rightShift_x'length-1 downto 0);

  -------- Valid out of the processing (from input regs to output regs) --------
  constant dsp_valid_len : integer := delay_leftBitShift+delay_cordicKernel+delay_rightBitShift+delay_multCordicComp;
  signal dsp_valid : std_logic;

begin
  
  -------- Input and Output Registers --------
  -- 2 clock latency that are not counted in the valid_latency
  process(clk)
  begin
  if rising_edge(clk) then
    if rst='1' then
      reg_i_tvalid <= '0';
      reg_i_tdata  <= (others=>'0');
      reg_i_tready <= '0'; 
      reg_o_tdata  <= (others=>'0');
      reg_o_tvalid <= '0';
      reg_o_tready <= '0';
    else
      -- Input Interface
      reg_i_tvalid <= i_tvalid;
      reg_i_tdata  <= std_logic_vector(resize(unsigned(i_tdata), Wl));
      reg_i_tready <= reg_o_tready;
    
      -- Output Interface
      if dsp_valid='1' then
        reg_o_tvalid <= int_o_tvalid;
        reg_o_tdata  <= int_o_tdata;
      end if;
      reg_o_tready   <= o_tready; 
  
    end if;
  end if;
  end process;


  -- Global Enable 
  enb <= reg_i_tvalid and reg_o_tready;


  -------- Find the MSB zeros --------
  -- 1 Clock Latency

  -- Encoder Input (0 delay)
  -- zerosEncoderInput_GEN: for i in 0 to zeros_encoderInput'length-1 generate
  -- begin
  --   fill_GEN: if i<Wl/2 generate begin
  --     zeros_encoderInput(i) <= reg_i_tdata((Wl-2*i)-1) or reg_i_tdata((Wl-2*i)-2);
  --   end generate;
  --   noFill_GEN: if i>=Wl/2 generate begin
  --     zeros_encoderInput(i) <= '0';
  --   end generate;
  -- end generate;
  zeros_encoderInput(Wl-1 downto 0) <= reg_i_tdata;
  zeros_encoderInput(zeros_encoderInput'length-1 downto Wl) <= (others => '0');
  
  zeroEncoder_INST: entity work.priorityEncoder(rtl) 
  generic map (
    n => zeros_encoderOutput'length 
  ) 
  port map (
    clk   => clk,
    rst   => rst,
    enb   => enb,
    x     => zeros_encoderInput,
    y     => zeros_encoderOutput,
    reg_y => open
  );
  zeros_encoderNumZeros       <= std_logic_vector((Wl-1) - unsigned(zeros_encoderOutput));
  zeros_encoderNumZeros_Even  <= zeros_encoderNumZeros(zeros_encoderNumZeros'length-1 downto 1) & "0";
  zeros_delayChainInput       <= zeros_encoderNumZeros_Even;
  
  zerosDelayChain_INST: entity work.delay_chain_slv
  generic map (
    bitLength   => zeros_delayChainInput'length,
    delayLength => zeros_delayChainLength
  )
  port map (
    clk => clk,
    rst => rst,
    enb => enb,
    x   => zeros_delayChainInput,
    y   => zeros_delayChainOutput
  );

  -------- Left Bit Shift --------
  -- 'bitSelectorLength' clock latency
  leftShift_x   <= reg_i_tdata;
  leftShift_sel <= zeros_encoderNumZeros_Even;

  leftShift_INST: entity work.barrelShifter(rtl) 
  generic map (
    shiftDirection    => "left"               , -- "left" or "right"
    shiftSign         => "unsigned"           , -- "signed" or "unsigned"
    shiftType         => "arithmetic"         , -- "arithmetic" or "logical"
    bitDataLength     => leftShift_x'length   ,
    bitSelectorLength => leftShift_sel'length
  ) 
  port map (
    clk       => clk            ,
    rst       => rst            ,
    enb       => enb            ,
    x         => leftShift_x    ,
    sel       => leftShift_sel  ,
    valid_out => open           ,
    y         => leftShift_y
  );


  -------- CORDIC Square Root Kernel --------
  -- Clock Cycles Latency related to 'cordicIterations'. 
  -- Initialization
  -- x = u + 0.25
  -- y = u - 0.25
  -- 
  -- The first elements of the arrays 'reg_cor_ker_x(0)' and 'reg_cor_ker_y(0)' are not a registers.
  reg_cor_ker_x(0) <= signed( "0" & leftShift_y ) + c_cor_ker_val_025;
  reg_cor_ker_y(0) <= signed( "0" & leftShift_y ) - c_cor_ker_val_025;


  CORDIC_STAGES: for idx in 1 to cordicIterations generate
    constant valShift : integer := cordicForLoopIndex(idx-1);
  begin
    process(clk)
    begin
    if rising_edge(clk) then
      if rst='1' then
        reg_cor_ker_x(idx) <= (others=>'0');
        reg_cor_ker_y(idx) <= (others=>'0');
      elsif enb='1' then
        if reg_cor_ker_y(idx-1)<0  then
          reg_cor_ker_x(idx) <= reg_cor_ker_x(idx-1) + shift_right(reg_cor_ker_y(idx-1), valShift);
          reg_cor_ker_y(idx) <= reg_cor_ker_y(idx-1) + shift_right(reg_cor_ker_x(idx-1), valShift);
           
        else
          reg_cor_ker_x(idx) <= reg_cor_ker_x(idx-1) - shift_right(reg_cor_ker_y(idx-1), valShift);
          reg_cor_ker_y(idx) <= reg_cor_ker_y(idx-1) - shift_right(reg_cor_ker_x(idx-1), valShift);
          
        end if;
      else
        reg_cor_ker_x(idx) <= reg_cor_ker_x(idx);  
        reg_cor_ker_y(idx) <= reg_cor_ker_y(idx);  
      end if;
    end if;
    end process;

  end generate;


  -------- Gain compensation of the Cordic Algorithm --------
  -- 1 Clock Cycles Latency.
  -- multCordicGain_x <= rightShift_y(Wl-1 downto 0);
  multCordicGain_x <= std_logic_vector(reg_cor_ker_x(cordicIterations)(Wl-1 downto 0));
  multGainCordic_PROC : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        multCordicGain_z <= (others => '0');
      elsif enb='1' then
        multCordicGain_z <= std_logic_vector(unsigned(multCordicGain_x) *unsigned(multCordicGain_y));
      end if;
    end if;
  end process;
  multCordicGain_z_shifted <= std_logic_vector(shift_right(unsigned(multCordicGain_z),cordiGainWl-2));


  -------- Right shift related to the previous left shift --------
  -- 'bitSelectorLength' clock latency
  rightShift_x   <= std_logic_vector(multCordicGain_z_shifted);
  rightShift_sel <= '0' & zeros_delayChainOutput(zeros_delayChainOutput'length-1 downto 1);
  
  rightShift_INST: entity work.barrelShifter(rtl)
  generic map (
    shiftDirection    => "right"                , -- "left" or "right"
    shiftSign         => "unsigned"             , -- "signed" or "unsigned"
    shiftType         => "arithmetic"           , -- "arithmetic" or "logical"
    bitDataLength     => rightShift_x'length    ,
    bitSelectorLength => rightShift_sel'length
  ) 
  port map (
    clk       => clk            ,
    rst       => rst            ,
    enb       => enb            ,
    x         => rightShift_x   ,
    sel       => rightShift_sel ,
    valid_out => open           ,
    y         => rightShift_y
  );



  -------- DSP valid --------
  dspValid_INST: entity work.delay_chain_sl(rtl)
  generic map (
    delayLength => dsp_valid_len
  )
  port map (
    clk => clk        ,
    rst => rst        ,
    enb => enb        ,
    x   => '1'        ,
    y   => dsp_valid
  );


  -------- Output Ports assignments --------

  -- Input side - ready
  i_tready <= reg_i_tready;

  -- Output side - Valid out
  int_o_tvalid <= enb and dsp_valid;
  o_tvalid <= reg_o_tvalid;
  
  -- Output side - Data out
  outRoundLogic_GEN: if (Wl-Wl_out)>0 generate
    signal val_round        : unsigned(int_o_tdata'length downto 0);
    signal int_o_tdata_cut  : unsigned(int_o_tdata'length downto 0);
    signal int_o_tdata_r    : unsigned(int_o_tdata'length downto 0);
  begin
    int_o_tdata_cut <= unsigned(rightShift_y(Wl-1 downto Wl-Wl_out-1));
    val_round(val_round'length-1 downto 1) <= (others=>'0');
    val_round(0) <= int_o_tdata_cut(0);

    int_o_tdata_r <= int_o_tdata_cut + val_round;
    int_o_tdata   <= std_logic_vector(int_o_tdata_r(int_o_tdata_r'length-1 downto 1));
  end generate;

  outNoRoundLogic_GEN: if (Wl-Wl_out)=0 generate
  begin
    int_o_tdata <= rightShift_y(Wl-1 downto Wl-Wl_out);
  end generate;

  o_tdata  <= reg_o_tdata;
  
  
--  BISOGNA BILANCIARE I RITARDI
  
end cordic_unrolled;
