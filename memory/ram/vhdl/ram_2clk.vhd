----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2024.02.20
-- Description: 
-- 
-- 
-- Revision:
--   0.01 - File Created
--
-- Notes
--  The following table can assist you in determining the size of your logic 
--  when using Xilinx Block Ram.
--
--    ---------------------------------------------------------------
--     DATA_WIDTH | FIFO_SIZE | FIFO Depth | RDCOUNT/WRCOUNT Width --
--     ===========|===========|============|=======================--
--       37-72    |  "36Kb"   |     512    |         9-bit         --
--       19-36    |  "36Kb"   |    1024    |        10-bit         --
--       19-36    |  "18Kb"   |     512    |         9-bit         --
--       10-18    |  "36Kb"   |    2048    |        11-bit         --
--       10-18    |  "18Kb"   |    1024    |        10-bit         --
--        5-9     |  "36Kb"   |    4096    |        12-bit         --
--        5-9     |  "18Kb"   |    2048    |        11-bit         --
--        1-4     |  "36Kb"   |    8192    |        13-bit         --
--        1-4     |  "18Kb"   |    4096    |        12-bit         --
--    ---------------------------------------------------------------
--
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity ram_2clk is
  generic (
    RAM_ADDR_WIDTH : INTEGER := 10;
    RAM_DATA_WIDTH : INTEGER := 32
  );
  port (
    clka     : in  STD_LOGIC;
    clkb     : in  STD_LOGIC;
    ena      : in  STD_LOGIC;
    enb      : in  STD_LOGIC;
    wea      : in  STD_LOGIC;
    addra    : in  STD_LOGIC_VECTOR(RAM_ADDR_WIDTH - 1 downto 0);
    addrb    : in  STD_LOGIC_VECTOR(RAM_ADDR_WIDTH - 1 downto 0);
    data_in  : in  STD_LOGIC_VECTOR(RAM_DATA_WIDTH - 1 downto 0);
    data_out : out STD_LOGIC_VECTOR(RAM_DATA_WIDTH - 1 downto 0)
  );
end entity;

architecture bhv of ram_2clk is

  type T_arr is array (NATURAL range <>) of STD_LOGIC_VECTOR(data_in'RANGE);
  signal ram : T_ARR(0 to 2 ** RAM_ADDR_WIDTH - 1);
  attribute ram_style        : STRING;
  attribute ram_style of ram : signal is "block";

begin

  process (clka)
  begin
    if rising_edge(clka) then
      if ena = '1' then
        if wea = '1' then
          RAM(TO_INTEGER(UNSIGNED(addra))) <= data_in;
        end if;
      end if;
    end if;
  end process;

  process (clkb)
  begin
    if rising_edge(clkb) then
      if enb = '1' then
        data_out <= RAM(TO_INTEGER(UNSIGNED(addrb)));
      end if;
    end if;
  end process;

end architecture;
