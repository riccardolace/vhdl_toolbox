----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2024.03.08
-- Description: 
--   The block accumulates 'spsToAcc' samples. Subsequently, it is set to zero.
-- Revision:
--   0.01 - File Created
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.ALL;
  use IEEE.NUMERIC_STD.ALL;

library work;
  use work.pkg_vhdl_toolbox.all;

entity acc_N_sps is
generic (
  accType     : string  := "unsigned";  -- "unsigned" or "signed"
  spsToAcc    : integer := 31;  -- Number of input samples to accumulate. After that, the accumulator is set to zero.
  bitLength_x : integer := 16;
  bitLength_y : integer := 16  -- It is equal to the accumulator value
);
port (
  clk       : in  std_logic;
  rst       : in  std_logic;
  enb       : in  std_logic;
  x         : in  std_logic_vector(bitLength_x-1 DOWNTO 0);
  valid_out : out std_logic;
  y         : out std_logic_vector(bitLength_y-1 DOWNTO 0)  
);
end acc_N_sps;

architecture rtl of acc_N_sps is
  constant bitLengthCnt : integer := log2(spsToAcc)+1;
  constant inc     : std_logic_vector(bitLengthCnt-1 downto 0) := std_logic_vector(to_unsigned(1,bitLengthCnt));
  signal   hit     : std_logic;
  signal   reg_hit : std_logic;
  signal   cnt_slv : std_logic_vector(bitLengthCnt-1 downto 0);
  signal   cnt     : unsigned(bitLengthCnt-1 downto 0);
  signal   acc_slv : std_logic_vector(bitLength_y-1 DOWNTO 0);
begin
  
  counter_INST: entity work.counter_with_hit(rtl_unsigned)
  generic map (
    bitLength => bitLengthCnt,
    valToRst  => spsToAcc-1,
    valToHit  => spsToAcc-1
  )
  port map (
    clk => clk,
    rst => rst,
    enb => enb,
    inc => inc,
    hit => hit,
    cnt => cnt_slv
  );
  cnt <= unsigned(cnt_slv);

  delayHit: entity work.delay_sl
    port map (
      clk => clk,
      rst => rst,
      enb => enb,
      x   => hit,
      y   => reg_hit
    );
  
  -- Output ports
  valid_out <= reg_hit;
  y         <= acc_slv;

  unsigned_GEN: if accType="unsigned" generate
    signal val : unsigned(y'range);
    signal acc : unsigned(y'range);
  begin
    
    -- Input value
    val <= resize(unsigned(x), val'length);

    process(clk) begin
    if rising_edge(clk) then
      if rst='1' then
        acc <= (others=>'0');
      elsif enb='1' then
        if reg_hit='1' then
          acc <= val;
        else        
          acc <= acc + val;
        end if;
      end if;
    end if;
    end process;
    
    acc_slv <= std_logic_vector(acc);
  end generate;

  signed_GEN: if accType="signed" generate
    signal val : signed(y'range);
    signal acc : signed(y'range);
  begin
    
    -- Input value
    val <= resize(signed(x), val'length);

    process(clk) begin
    if rising_edge(clk) then
      if rst='1' then
        acc <= (others=>'0');
      elsif enb='1' then
        if reg_hit='1' then
          acc <= val;
        else        
          acc <= acc + val;
        end if;
      end if;
    end if;
    end process;
    
    acc_slv <= std_logic_vector(acc);
  end generate;

end architecture;