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
  clk       : IN  STD_LOGIC;
  rst       : IN  STD_LOGIC;
  enb       : IN  STD_LOGIC;
  data_in   : IN  STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
  data_out  : OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0)
);
end cdc_sync_slv;

architecture rtl of cdc_sync_slv is
  
  TYPE T_arr IS ARRAY (natural range <>) OF STD_LOGIC_VECTOR(data_in'RANGE);
  SIGNAL regs : T_ARR(0 TO REGS_STAGE-1);
  ATTRIBUTE ram_style: STRING;
  ATTRIBUTE ram_style OF regs : SIGNAL IS "block";
  
begin

  process(clk)
  begin
  if rising_edge(clk) then
    if rst = '1' then
      regs <= (others=>(others=>'0'));
    elsif enb='1' then
      regs(0) <= data_in;
      regs(1 to regs'LENGTH-1) <= regs(0 to regs'LENGTH-2);
    end if;
  end if;
  end process;
  
  data_out <= regs(regs'LENGTH-1);

end bhv; 
