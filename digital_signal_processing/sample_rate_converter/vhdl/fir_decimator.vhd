----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2024.03.08
-- Description: 
--   FIR Decimator. The signals are represented using Q notation.
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
  use ieee.math_real.all;
  use std.textio.all;

library work;
  use work.pkg_vhdl_toolbox.all;

entity fir_decimator is
  generic (
    -- Decimation Factor
    DecimFactor : integer := 4;
    DelayType   : string  := "DelayRam";  -- (1) "DelayChain"; (2) "DelayRam" based on "block" type

    -- Coefficients parameters
    Coeffs_file  : string  := "../testbench/coeffs_len64_Wl18_L8.txt";
    Coeffs_len   : integer := 64;

    -- FIR filter parameters
    Width_in     : integer := 16;
    Width_coeffs : integer := 18;
    Width_sum    : integer := 38; -- Width_in + Width_coeffs + log2(Coeffs_len)
    Width_acc    : integer := 40; -- Width_sum + log2(DecimFactor)
    Clip_bits    : integer :=  4;
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
end fir_decimator;


-- For the implementation see https://docs.xilinx.com/r/en-US/am004-versal-dsp-engine/Decimating
architecture rtl_polyphase of fir_decimator is

  ----------------------------------------------------------------
  -- Parameters
  
  -- Number of DSP blocks
  constant numDSP : integer := integer(ceil(real(Coeffs_len)/real(DecimFactor)));

  ----------------------------------------------------------------
  -- Functions
  
  -- Matrix containing all the coefficients. Each column is the set of coefficients used by a single DSP.
  type polyphaseMatrix_type is array(0 to DecimFactor-1, 0 to numDSP-1) of std_logic_vector(Width_coeffs - 1 downto 0);
  
  -- It reads the coefficients from file
  impure function fillPolyphaseMatrix(fileName : in string) return polyphaseMatrix_type is
    file f         : text is fileName;
    variable fLine : line;
    variable rom   : polyphaseMatrix_type;
    variable temp  : bit_vector(Width_coeffs - 1 downto 0);
    variable n     : integer;
    variable j     : integer;
  begin
    
    -- Variable used to count the coefficients of the file
    n := 0;
    
    for c in 0 to numDSP-1 loop
      -- Variable used to write in column
      j := c;
      
      -- 'j' must be lower than DecimFactor
      while j>(DecimFactor-1) loop
        j := j - DecimFactor;
      end loop;
            
      for r in 0 to DecimFactor-1 loop
        -- Read coeff
        if n<Coeffs_len then
          readline(f, fLine);
          read(fLine, temp);
          rom(j,c) := to_stdlogicvector(temp);

          -- Increment the number of coefficient to read
          n := n+1;
        else
          rom(j,c) := (others=>'0');
        end if;
        
        -- Mod function implemented for 'j' variable
        if j=0 then
          j := DecimFactor-1;
        else
          j :=  j-1;
        end if;
        

      end loop;
    end loop;
    return rom;
  end function;

  

  ----------------------------------------------------------------
  -- Signals

  -- Control logic
  type state_type is (IDLE, COUNT);
  signal state : state_type;
  signal addr_rd : unsigned(log2(DecimFactor) downto 0);
  signal enbDSP   : std_logic;

  -- Coefficients
  -- constant coeffs_arr : coeff_arr_type := (readCoeffsFromFile(Coeffs_file));
  constant polyPhaseMatrix : polyphaseMatrix_type := fillPolyphaseMatrix(Coeffs_file);

  -- Delay chain of the input signal
  type delayChain_type is array (-1 to numDSP-1) of std_logic_vector(Width_in-1 downto 0);
  signal delayChain : delayChain_type;
  
  -- Array of the multAdd output
  type sum_arr_type is array (-1 to numDSP-1) of std_logic_vector(Width_sum-1 downto 0);
  signal sum_arr : sum_arr_type;
  
  -- Valid signal
  signal tmp_valid : std_logic;

  -- Accumulator
  signal acc_enb       : std_logic;
  signal acc_valid_out : std_logic;
  signal acc_data_out  : std_logic_vector(Width_acc-1 downto 0);

  -- Round and clip enable
  signal round_enb       : std_logic;
  signal round_valid_out : std_logic;
  signal round_data_out  : std_logic_vector(data_out'range);
  
begin

  -- Control logic
  controlLogic_PROC : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        state <= IDLE;
        addr_rd <= (others => '0');

      elsif enb='1' then
        case state is
  
          when IDLE =>
            if valid_in='1' then
              state   <= COUNT;
              addr_rd <= (others => '0');
            end if;

          when COUNT => 
            if addr_rd=DecimFactor-1-1 and valid_in='0' then
              state   <= IDLE;
              addr_rd <= (others => '0');
            elsif addr_rd=DecimFactor-1 and valid_in='1' then
              state   <= COUNT;
              addr_rd <= (others => '0');
            elsif valid_in='1' then
              state   <= COUNT;
              addr_rd <= addr_rd + 1;
            else
              state   <= state;
              addr_rd <= addr_rd;
            end if;
        end case;
  
      end if;
    end if;
  end process;

  enbDSP <= (enb and valid_in) when state=COUNT else '0';

  ----------------------------------------------------------------
  -- Multiplication and Sum perfromed by a DSP block
  ----------------------------------------------------------------

  reg_dataIn_inst: entity work.delay_slv
  generic map (
    bitLength   => Width_in
  )
  port map (
    clk => clk      ,
    rst => rst      ,
    enb => (enb and valid_in)  ,
    x   => data_in  ,
    y   => delayChain(-1)
  );
  sum_arr(-1) <= (others => '0');

  dspCascade_GEN: for i in 0 to numDSP-1 generate

    signal regA_tmp : std_logic_vector(Width_in-1 downto 0);

    -- multAdd signals
    signal A : std_logic_vector(Width_in-1 downto 0);
    signal B : std_logic_vector(Width_coeffs-1 downto 0);
    signal C : std_logic_vector(Width_sum-1 downto 0);
    signal Y : std_logic_vector(Width_sum-1 downto 0);

  begin
    
    -- Delay Propagation
    propagationDelayChain_GEN: if DelayType="DelayChain" generate
    begin
      delay_inst: entity work.delay_chain_slv
      generic map (
        bitLength   => Width_in ,
        delayLength => 2
        )
      port map (
        clk => clk             ,
        rst => rst             ,
        enb => enbDSP          ,
        x   => delayChain(i-1) ,
        y   => regA_tmp
      );
    end generate;    

    propagationDelayRam_GEN: if DelayType="DelayRam" generate
    begin
      delay_inst: entity work.delay_ram_slv
      generic map (
        bitLength   => Width_in    ,
        delayLength => DecimFactor ,
        Ram_Type    => "block"
      )
      port map (
        clk => clk             ,
        rst => rst             ,
        enb => enbDSP          ,
        x   => delayChain(i-1) ,
        y   => regA_tmp
      );
    end generate;    

    propagationDelay_inst: entity work.delay_slv
    generic map (
      bitLength   => Width_in
    )
    port map (
      clk => clk           ,
      rst => rst           ,
      enb => enbDSP        ,
      x   => regA_tmp       ,
      y   => delayChain(i)
    );

    -- Delayed signal
    A <= delayChain(i-1);

    -- Coefficients
    B <= polyPhaseMatrix(to_integer(addr_rd), i);

    -- Sum propagation
    C <= sum_arr(i-1);
    
    multAdd_inst : entity work.multAdd(rtl)
    generic map (
      regA_len     => 2,
      regB_len     => 2,
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
      enb       => enbDSP    ,
      A         => A         ,
      B         => B         ,
      C         => C         ,
      Y         => Y
    );

    sum_arr(i) <= Y;
   
  end generate;
  
  -- Valid out
  validOut_inst: entity work.delay_chain_sl
  generic map (
    delayLength => numDSP + 3
  )
  port map (
    clk => clk      ,
    rst => rst      ,
    enb => enbDSP ,
    x   => '1'      ,
    y   => tmp_valid   
  );
  
  acc_enb <= enbDSP and tmp_valid;
  accumulator_inst: entity work.acc_N_sps
  generic map (
    accType     => "signed"    ,
    spsToAcc    => DecimFactor ,
    bitLength_x => Width_sum   ,
    bitLength_y => Width_acc  
  )
  port map (
    clk       => clk               ,
    rst       => rst               ,
    enb       => acc_enb           ,
    x         => sum_arr(numDSP-1) ,
    valid_out => acc_valid_out     ,
    y         => acc_data_out
  );

  
  ----------------------------------------------------------------
  -- Rounding, saturation and valid signal
  ----------------------------------------------------------------
  
  -- Round and clip
  round_enb <= enbDSP and acc_valid_out;
  roundAndClip_inst: entity work.round_and_clip_slv
  generic map (
    WIDTH_IN  => Width_acc ,
    WIDTH_OUT => Width_out ,
    CLIP_BITS => Clip_bits 
  )
  port map (
    clk            => clk             ,
    rst            => rst             ,
    enb            => round_enb       ,
    data_in        => acc_data_out    ,
    sync_valid_out => round_valid_out ,
    sync_data_out  => round_data_out
  );
  
  -- Output ports
  valid_out <= enbDSP and round_valid_out;
  data_out  <= round_data_out;

end architecture;