----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: YYYY.MM.DD
-- Description: 
-- 
-- Revision:
--   0.01 - File Created
--
----------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use std.textio.all;

library work;
  use work.pkg_vhdl_toolbox.all;

entity rom_slv is
  generic (romSize   : integer := 64;            -- Number of elements
           romStyle  : string  := "distributed"; -- "block" or "distributed" for Xilinx
           romPath   : string  := "data.txt";    -- Text file composed of 'romSize' samples represented in binary format (ex. 01011). Each row represents a value
           bitLength : integer := 16             -- Number of bits
          );
  port (clk       : in  std_logic;
        rst       : in  std_logic;
        enb       : in  std_logic;
        addr_rd   : in  std_logic_vector(log2(natural(romSize))-1 downto 0);
        valid_out : out std_logic;
        data_out  : out std_logic_vector(bitLength - 1 downto 0)
       );
end entity;

-- Input port 'addr_rd' is not used. The rom values are read sequentially 
-- using an address generated internally. The address signal is incremented
-- when enable is high.
architecture bhv_intAddress of rom_slv is

  -- 1d array type
  type rom_arr_type is array (0 to romSize - 1) of std_logic_vector(bitLength - 1 downto 0);

  ----------------------------------------------------------------
  -- FUNCTIONS

  -- It reads from file and init the ROM.
  impure function initRomFromFile(romFileName : in string) return rom_arr_type is
    file RomFile : text is romFileName;
    variable romFileLine : line;
    variable rom         : rom_arr_type;
    variable temp        : bit_vector(bitLength - 1 downto 0);
  begin
    for rig in 0 to romSize - 1 loop
      readline(RomFile, romFileLine);
      read(romFileLine, temp);
      rom(rig) := to_stdlogicvector(temp);
    end loop;
    return rom;
  end function;

  ----------------------------------------------------------------
  -- Signals

  -- ROM
  signal romData : rom_arr_type := (initRomFromFile(romPath));
  attribute rom_style            : string;
  attribute rom_style of romData : signal is romStyle;

  -- Output registers
  signal reg_valid_out : std_logic;
  signal reg_data_out : std_logic_vector(bitLength - 1 downto 0) := (others => '0');
  
  -- Internal address
  constant Width_addr : integer := (log2(natural(romSize)));
  signal add_r     : unsigned(Width_addr - 1 downto 0)        := TO_UNSIGNED(0, Width_addr);

begin

  romBlock_GEN: if romStyle = "block" generate

  begin

    readAddr_PROC: process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          add_r <= (others => '0');
        elsif enb = '1' then
          if add_r =(romSize - 1) then
            add_r <= (others => '0');
          else
            add_r <= add_r + 1;
          end if;
        end if;
      end if;
    end process;

    regDataOut_PROC: process(clk)
    begin
      if rising_edge(clk) then
        if enb = '1' then
          reg_data_out <= romData(TO_INTEGER(add_r));
        end if;
      end if;
    end process;

    validOut_PROC : process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          reg_valid_out <= '0';
        elsif enb='1' then
          reg_valid_out <= '1';
        else
          reg_valid_out <= '0';
        end if;
      end if;
    end process;

    valid_out <= reg_valid_out;
    data_out  <= reg_data_out;

  end generate;

  romDistributed_GEN: if romStyle = "distributed" generate
  begin
    readAddr_PROC: process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          add_r <= (others => '0');
        elsif enb = '1' then
          if add_r =(romSize - 1) then
            add_r <= (others => '0');
          else
            add_r <= add_r + 1;
          end if;
        end if;
      end if;
    end process;

    regDataOut_PROC: process(clk)
    begin
      if rising_edge(clk) then
        if rst='1' then
          reg_data_out <= (others => '0');
        elsif enb = '1' then
          reg_data_out <= romData(TO_INTEGER(add_r));
        end if;
      end if;
    end process;

    validOut_PROC : process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          reg_valid_out <= '0';
        elsif enb='1' then
          reg_valid_out <= '1';
        else
          reg_valid_out <= '0';
        end if;
      end if;
    end process;

    valid_out <= reg_valid_out;
    data_out <= reg_data_out;
  end generate;

end architecture;

-- Input port 'addr_rd' is used to read the rom values.
architecture bhv_extAddress of rom_slv is

  -- 1d array type
  type rom_arr_type is array (0 to romSize - 1) of std_logic_vector(bitLength - 1 downto 0);

  ----------------------------------------------------------------
  -- FUNCTIONS

  -- It reads from file and init the ROM.
  impure function initRomFromFile(romFileName : in string) return rom_arr_type is
    file RomFile : text is romFileName;
    variable romFileLine : line;
    variable rom         : rom_arr_type;
    variable temp        : bit_vector(bitLength - 1 downto 0);
  begin
    for rig in 0 to romSize - 1 loop
      readline(RomFile, romFileLine);
      read(romFileLine, temp);
      rom(rig) := to_stdlogicvector(temp);
    end loop;
    return rom;
  end function;

  ----------------------------------------------------------------
  -- Signals

  -- ROM
  signal romData : rom_arr_type := (initRomFromFile(romPath));
  attribute rom_style            : string;
  attribute rom_style of romData : signal is romStyle;

  -- Output registers
  signal reg_valid_out : std_logic;
  signal reg_data_out : std_logic_vector(bitLength - 1 downto 0) := (others => '0');
  
begin

  romBlock_GEN: if romStyle = "block" generate

  begin

    regDataOut_PROC: process(clk)
    begin
      if rising_edge(clk) then
        if enb = '1' then
          reg_data_out <= romData(TO_INTEGER(unsigned(addr_rd)));
        end if;
      end if;
    end process;

    validOut_PROC : process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          reg_valid_out <= '0';
        elsif enb='1' then
          reg_valid_out <= '1';
        else
          reg_valid_out <= '0';
        end if;
      end if;
    end process;

    valid_out <= reg_valid_out;
    data_out <= reg_data_out;

  end generate;

  romDistributed_GEN: if romStyle = "distributed" generate
  begin

    regDataOut_PROC: process(clk)
    begin
      if rising_edge(clk) then
        if rst='1' then
          reg_data_out <= (others => '0');
        elsif enb = '1' then
          reg_data_out <= romData(TO_INTEGER(unsigned(addr_rd)));
        end if;
      end if;
    end process;

    validOut_PROC : process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          reg_valid_out <= '0';
        elsif enb='1' then
          reg_valid_out <= '1';
        else
          reg_valid_out <= '0';
        end if;
      end if;
    end process;

    valid_out <= reg_valid_out;
    data_out <= reg_data_out;
  end generate;

end architecture;

