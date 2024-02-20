----------------------------------------------------------------------------------
-- Engineer: Daniele Giardino
-- 
-- Create Date: 2024.02.21
-- Description: 
--   Test Bench.
-- 
-- Revision:
--   0.01 - File Created
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library work;
  use work.pkg_vhdl_toolbox.all;

entity delay_ram_slv is
  generic (bitLength   : INTEGER := 16;
           delayLength : INTEGER := 256;
           Ram_Type    : STRING  := "block"
          );
  port (clk : in  STD_LOGIC;
        rst : in  STD_LOGIC;
        enb : in  STD_LOGIC;
        x   : in  STD_LOGIC_VECTOR(bitLength - 1 downto 0);
        y   : out STD_LOGIC_VECTOR(bitLength - 1 downto 0));
end entity;

architecture bhv of delay_ram_slv is

  -- RAM
  type arr_1d is array (NATURAL range <>) of STD_LOGIC_VECTOR(bitLength - 1 downto 0);
  signal ram : arr_1d(0 to delayLength - 1) := (others =>(others => '0'));
  attribute ram_style        : string;
  attribute ram_style of ram : signal is Ram_Type;

  -- Address signals
  constant Ram_width_addr : INTEGER := (log2(NATURAL(delayLength))) + 1;

  ---- This address is used to read from the RAM
  signal add_r : UNSIGNED(Ram_width_addr - 1 downto 0) := TO_UNSIGNED(1, Ram_width_addr); -- Address

  ---- This address is used to write to the RAM
  signal add_w : UNSIGNED(Ram_width_addr - 1 downto 0) := TO_UNSIGNED(0, Ram_width_addr);

  ---- This address is used to clear the RAM content. When rst='1', the logic writes all_zeros to RAM
  signal addr_rst : unsigned(Ram_width_addr - 1 downto 0) := (others => '0');

  -- Output register
  signal reg_y : STD_LOGIC_VECTOR(bitLength - 1 downto 0) := (others => '0');

  -- RAM Signals
  signal fifo_wr      : std_logic; -- Write enable
  signal fifo_i_addr  : unsigned(Ram_width_addr - 1 downto 0) := (others => '0');
  signal fifo_i_tdata : std_logic_vector(x'RANGE);

begin

  -- COUNTER READ AND WRITE
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        add_r <= TO_UNSIGNED(1, Ram_width_addr);
        add_w <= TO_UNSIGNED(0, Ram_width_addr);
        addr_rst <= addr_rst + 1;
      elsif enb = '1' then
        if (add_r =(delayLength - 1)) then
          add_r <= TO_UNSIGNED(0, Ram_width_addr);
        else
          add_r <= add_r + 1;
        end if;
        if (add_w =(delayLength - 1)) then
          add_w <= TO_UNSIGNED(0, Ram_width_addr);
        else
          add_w <= add_w + 1;
        end if;
        addr_rst <= TO_UNSIGNED(0, Ram_width_addr);
      else
        addr_rst <= TO_UNSIGNED(0, Ram_width_addr);
        add_w <= add_w;
        add_r <= add_r;
      end if;
    end if;
  end process;

  -- Reset logic
  fifo_i_addr  <= addr_rst when rst = '1' else add_w;
  fifo_i_tdata <= (others => '0') when rst = '1' else x;
  fifo_wr      <= rst or enb;

  process (clk)
  begin
    if rising_edge(clk) then
      if fifo_wr = '1' then
        ram(TO_INTEGER(fifo_i_addr)) <= fifo_i_tdata;
      end if;
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      if enb = '1' then
        reg_y <= ram(TO_INTEGER(add_r));
      end if;
    end if;
  end process;
  y <= reg_y;

end architecture;
