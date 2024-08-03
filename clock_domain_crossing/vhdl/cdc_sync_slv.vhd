----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2024.02.20
-- Description: 
--   Synchronizer is used to synchronize a pulse generated 
--   in a faster clock domain (Clock1 in the design) to 
--   a slower clock domain (Clock2 in the design).
--
--  Design         
--                                               Synchronization Chain for REGS_STAGE=2
--                ╔═══════════════════╗          ╔══════════════════════════════════════╗
--                ║ Clock Domain 1    ║          ║ Clock Domain 2                       ║
--                ║                   ║          ║                                      ║
--                ║                   ║          ║                                      ║
--                ║     ┌───────┐     ║          ║     ┌───────┐        ┌───────┐       ║
--                ║     │       │     ║          ║     │       │        │       │       ║      Output 
--      Data ─────╬────>│ D   Q ├─────╬──────────╬────>│ D   Q ├───────>│ D   Q ├───────╬────> Registers
--                ║     │       │     ║          ║     │       │        │       │       ║
--                ║     │╲      │     ║          ║     │╲      │        │╲      │       ║
--    Clock1 ─────╬────>│╱      │     ║          ║ ┌──>│╱      │   ┌───>│╱      │       ║
--                ║     │       │     ║          ║ │   │       │   │    │       │       ║
--                ║     └───────┘     ║          ║ │   └───────┘   │    └───────┘       ║
--                ║                   ║          ║ │               │                    ║
--                ║                   ║          ║ │               │                    ║
--                ╚═══════════════════╝          ╚═╬═══════════════╬════════════════════╝
--                                                 │               │
--                                       Clock2 ───┴───────────────┘
-- 
-- Revision:
--   [2024.02.20] - File Created
--   [2024.03.09] - File renamed from cdc_sync to cdc_sync_slv
--
----------------------------------------------------------------------------------

library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cdc_sync_slv is
generic (
  REGS_STAGE : INTEGER :=  2;  -- Pipeline Registers
  DATA_WIDTH : INTEGER := 16
);
port(
  clk       : in  std_logic;
  rst       : in  std_logic;
  enb       : in  std_logic;
  data_in   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
  data_out  : out std_logic_vector(DATA_WIDTH-1 downto 0)
);
end cdc_sync_slv;

architecture rtl of cdc_sync_slv is
  
  type T_arr is array (natural range <>) of std_logic_vector(data_in'range);
  signal regs : T_ARR(0 TO REGS_STAGE-1);
  attribute ASYNC_REG: STRING;
  attribute ASYNC_REG of regs : signal is "true";
  
begin

  process(clk)
  begin
  if rising_edge(clk) then
    if rst = '1' then
      regs <= (others=>(others=>'0'));
    elsif enb='1' then
      regs(0) <= data_in;
      regs(1 to regs'length-1) <= regs(0 to regs'length-2);
    end if;
  end if;
  end process;
  
  data_out <= regs(regs'length-1);

end rtl; 
