----------------------------------------------------------------------------------
-- Engineer: Daniele Giardino
-- 
-- Create Date: 2024.02.21
-- Description: 
-- 
-- 
-- Design:
--                              ┌───┐
--                 valToRst ───>│ = ├──> hit
--                              └─┬─┘
--           ┌─────┐              │
--   Inc ───>│ Sum │       ┌───┐  │
--        ┌─>│     ├──────>│Reg├──┼────> cnt
--        │  └─────┘       └───┘  │
--        │                       │
--        └───────────────────────┘
-- 
-- Revision:
--   0.01 - File Created
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity counter_with_hit is
  generic (bitLength : INTEGER := 16;          -- Bit Length
           valToRst  : INTEGER := 2 ** 16 - 1; -- Value to reset the counter
           valToHit  : INTEGER := 0            -- Value to generate the hit
          );
  port (clk : in  STD_LOGIC;
        rst : in  STD_LOGIC;
        enb : in  STD_LOGIC;
        inc : in  STD_LOGIC_VECTOR(bitLength - 1 downto 0);
        hit : out STD_LOGIC;
        cnt : out STD_LOGIC_VECTOR(bitLength - 1 downto 0));
end entity;

-- Unsigned

architecture bhv_unsigned of counter_with_hit is
  signal reg_cnt : UNSIGNED(bitLength - 1 downto 0);
begin

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        reg_cnt <= (others => '0');
      elsif enb = '1' then
        if reg_cnt = TO_UNSIGNED(valToRst, bitLength) then
          reg_cnt <= (others => '0');
        else
          reg_cnt <= reg_cnt + UNSIGNED(inc);
        end if;
      end if;
    end if;
  end process;

  hit <= '1' when reg_cnt = TO_UNSIGNED(valToHit, bitLength) else '0';
  cnt <= STD_LOGIC_VECTOR(reg_cnt);
end architecture;


