----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2024.04.03
-- Description:
--  Barrel shifters (case of s=(s2,s1,s0)).
--
--             s0  ┌─────┐    s1  ┌─────┐    s2  ┌─────┐
--             ───>│     │    ───>│     │    ───>│     │
--                 │     │        │     │        │     │
--  data_in   ┌───>│ MUX │   ┌───>│ MUX │   ┌───>│ MUX │
--        ────┤    │     ├───┤    │     ├───┤    │     ├───> data_out
--            └───>│     │   └───>│     │   └───>│     │
--             >>1 └─────┘    >>2 └─────┘    >>4 └─────┘
--
-- Revision:
--   0.01 - File Created
--
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.math_real.all;
  use ieee.numeric_std.all;

entity barrelShifter is
  generic (
    shiftDirection    : string := "left";       -- "left" or "right"
    shiftSign         : string := "unsigned";   -- "signed" or "unsigned"
    shiftType         : string := "arithmetic"; -- "arithmetic" or "logical"
    bitDataLength     : integer := 8 ;
    bitSelectorLength : integer := 3
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    enb       : in  std_logic;
    x         : in  std_logic_vector(bitDataLength - 1 downto 0);
    sel       : in  std_logic_vector(bitSelectorLength - 1 downto 0);
    valid_out : out std_logic;
    y         : out std_logic_vector(bitDataLength - 1 downto 0)
  );
end entity;

architecture rtl of barrelShifter is

  -- Array of shifted signals
  type vec1D_slv_type is array (0 to bitSelectorLength) of std_logic_vector(bitDataLength-1 downto 0);
  signal vec1D_slv : vec1D_slv_type;

  -- Valid output
  signal valid_arr : std_logic_vector(0 to bitSelectorLength-1);

begin

  -- Pas the input data to the array
  vec1D_slv(0) <= x;
  
  levels_GEN : for i in 0 to bitSelectorLength-1 generate
  
    -- Shifted value
    constant shiftVal    : integer := integer(2**real(i));
  
    -- Shifted signal
    signal shiftedSignal : std_logic_vector(bitDataLength-1 downto 0);
    
    -- Delayed sel(i)
    signal sel_delay : std_logic;

  begin
  
    arithmeticLeft_GEN: if shiftDirection="left" and shiftType="arithmetic" generate begin
      signed_GEN: if shiftSign="signed" generate begin
        shiftedSignal <= std_logic_vector(shift_left(signed(vec1D_slv(i)) , shiftVal ));
      end generate;
      unsigned_GEN: if shiftSign="unsigned" generate begin
        shiftedSignal <= std_logic_vector(shift_left(unsigned(vec1D_slv(i)) , shiftVal ));
      end generate;
    end generate;
  
    logicalLeft_GEN: if shiftDirection="left" and shiftType="logical" generate begin
      signed_GEN: if shiftSign="signed" generate begin
        shiftedSignal <= std_logic_vector(shift_left(unsigned(vec1D_slv(i)) , shiftVal ));
      end generate;
      unsigned_GEN: if shiftSign="unsigned" generate begin
        shiftedSignal <= std_logic_vector(shift_left(unsigned(vec1D_slv(i)) , shiftVal ));
      end generate;
    end generate;
  
    arithmeticRight_GEN: if shiftDirection="right" and shiftType="arithmetic" generate begin
      signed_GEN: if shiftSign="signed" generate begin
        shiftedSignal <= std_logic_vector(shift_right(signed(vec1D_slv(i)) , shiftVal ));
      end generate;
      unsigned_GEN: if shiftSign="unsigned" generate begin
        shiftedSignal <= std_logic_vector(shift_right(unsigned(vec1D_slv(i)) , shiftVal ));
      end generate;
    end generate;
  
    logicalRight_GEN: if shiftDirection="right" and shiftType="logical" generate begin
      signed_GEN: if shiftSign="signed" generate begin
        shiftedSignal <= std_logic_vector(shift_right(unsigned(vec1D_slv(i)) , shiftVal ));
      end generate;
      unsigned_GEN: if shiftSign="unsigned" generate begin
        shiftedSignal <= std_logic_vector(shift_right(unsigned(vec1D_slv(i)) , shiftVal ));
      end generate;
    end generate;
  
    delaySelBit_INST: entity work.delay_chain_sl(rtl)
    generic map (
      delayLength => i
    )
    port map (
      clk => clk        ,
      rst => rst        ,
      enb => enb        ,
      x   => sel(i)     ,
      y   => sel_delay
    );
  

    shifter_PROC : process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          vec1D_slv(i+1) <= (others=>'0');
          
        elsif enb='1' then
          if sel_delay='1' then
            vec1D_slv(i+1) <= shiftedSignal;
          else
            vec1D_slv(i+1) <= vec1D_slv(i);
          end if;
        end if;
      end if;
    end process;
  
  end generate;
  
  validOut_PROC : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        valid_arr <= (others => '0');
        
      elsif enb='1' then
        valid_arr(0) <= '1';
        valid_arr(1 to valid_arr'length-1) <= valid_arr(0 to valid_arr'length-2);
        
      end if;
    end if;
  end process;
  
  valid_out <= enb and valid_arr(valid_arr'length-1);
  y <= vec1D_slv(bitSelectorLength);
  
end architecture rtl;
