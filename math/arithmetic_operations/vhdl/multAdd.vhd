----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2024.03.08
-- Description: 
--   The output Y is evaluated as A*B+C.
--   Pipeline registers can inserted.
-- 
-- Revision:
--   0.01 - File Created
--
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity multAdd is 
generic ( regA_len     : integer := 1;
          regB_len     : integer := 1;
          regC_len     : integer := 0;
          regMult_len  : integer := 1;
          regAdd_len   : integer := 1;
          addOperation : string  := "sum";  -- "sum" or "sub"
          Width_A      : integer := 16;
          Width_B      : integer := 16;
          Width_C      : integer := 48
);
port (
    clk : in  std_logic;
    rst : in  std_logic;
    enb : in  std_logic;
    A   : in  std_logic_vector(Width_A-1 downto 0);
    B   : in  std_logic_vector(Width_B-1 downto 0);
    C   : in  std_logic_vector(Width_C-1 downto 0);
    Y   : out std_logic_vector(Width_C-1 downto 0)
  );
end multAdd;

architecture rtl of multAdd is
  
  -- In and Out signals
  signal int_A : signed(A'range);
  signal int_B : signed(B'range);
  signal int_C : signed(C'range);
  signal int_Y : signed(Y'range);

  -- Registers
  signal int_Mult : signed(Width_A+Width_B-1 downto 0);
  signal int_Add  : signed(Width_C-1 downto 0);
  signal reg_Mult : signed(Width_A+Width_B-1 downto 0);
  signal reg_Add  : signed(Width_C-1 downto 0);

begin

  ----------------------------------------------------------------
  -- Reg A
  ----------------------------------------------------------------
  regA_yesGEN : if regA_len>0 generate
    signal reg : std_logic_vector(A'range);
  begin
    reg_inst: entity work.delay_chain_slv(rtl)
      generic map(bitLength => Width_A, delayLength => regA_len)
      port map(clk => clk, rst => rst, enb => enb, x => A, y => reg);
    int_A <= signed(reg);
  end generate;
  
  regA_noGEN : if regA_len=0 generate
  begin
    int_A <= signed(A);
  end generate;
  
  
  ----------------------------------------------------------------
  -- Reg B
  ----------------------------------------------------------------
  regB_yesGEN : if regB_len>0 generate
    signal reg : std_logic_vector(B'range);
  begin
    reg_inst: entity work.delay_chain_slv(rtl)
      generic map(bitLength => Width_B, delayLength => regB_len)
      port map(clk => clk, rst => rst, enb => enb, x => B, y => reg);
    int_B <= signed(reg);
  end generate;
  
  regB_noGEN : if regB_len=0 generate
  begin
    int_B <= signed(B);
  end generate;
  
  
  ----------------------------------------------------------------
  -- Reg C
  ----------------------------------------------------------------
  regC_yesGEN : if regC_len>0 generate
    signal reg : std_logic_vector(C'range);
  begin
    reg_inst: entity work.delay_chain_slv(rtl)
      generic map(bitLength => Width_C, delayLength => regC_len)
      port map(clk => clk, rst => rst, enb => enb, x => C, y => reg);
    int_C <= signed(reg);
  end generate;
  
  regC_noGEN : if regC_len=0 generate
  begin
    int_C <= signed(C);
  end generate;


  ----------------------------------------------------------------
  -- Arithmetic Operations
  ----------------------------------------------------------------

  regMult_yesGEN : if regMult_len>0 generate
    signal m_i, m_o : std_logic_vector(int_mult'range);
  begin
    m_i <= std_logic_vector(int_A * int_B);
    reg_inst: entity work.delay_chain_slv(rtl)
      generic map(bitLength => int_Mult'length, delayLength => regMult_len)
      port map(clk => clk, rst => rst, enb => enb, x => m_i, y => m_o);
    int_Mult <= signed(m_o);
  end generate;
  
  regMult_noGEN : if regMult_len=0 generate
  begin
    int_Mult <= int_A * int_B;
  end generate;

  regSum_yesGEN : if regAdd_len>0 generate
    signal s_i, s_o: std_logic_vector(int_Add'range);
  begin
    sum_GEN: if addOperation="sum" generate begin
      s_i <= std_logic_vector(resize(int_Mult, int_C'length) + int_C);
    end generate;
    sub_GEN: if addOperation="sub" generate begin
      s_i <= std_logic_vector(resize(int_Mult, int_C'length) - int_C);
    end generate;
    
    reg_inst: entity work.delay_chain_slv(rtl)
      generic map(bitLength => int_Add'length, delayLength => regAdd_len)
      port map(clk => clk, rst => rst, enb => enb, x => s_i, y => s_o);
    int_Add <= signed(s_o);
  end generate;

  regSum_noGEN : if regAdd_len=0 generate
  begin
    sum_GEN: if addOperation="sum" generate begin
      int_Add <= resize(int_Mult, int_C'length) + int_C;
    end generate;
    sub_GEN: if addOperation="sub" generate begin
      int_Add <= resize(int_Mult, int_C'length) - int_C;
    end generate;
  end generate;


  ----------------------------------------------------------------
  -- Output ports
  ----------------------------------------------------------------
  Y <= std_logic_vector(int_Add);

end architecture;