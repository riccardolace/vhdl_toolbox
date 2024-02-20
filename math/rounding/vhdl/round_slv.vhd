----------------------------------------------------------------------------------
-- Engineer: Daniele Giardino
-- 
-- Create Date: 2024.02.21
-- Description: 
--   The block allows you to implement various rounding logics.
--   See the table for information.
--     
--    ╔══════════════════╦════════╦════════════════════════════╗
--    ║    Round Type    ║ Number ║         Description        ║
--    ╠══════════════════╬════════╬════════════════════════════╣
--    │ Truncation       │    0   │ Round to negative infinity │
--    │──────────────────┼────────┼────────────────────────────│
--    │ Round to zero    │    1   │ Original behavior          │
--    │──────────────────┼────────┼────────────────────────────│
--    │ Round to nearest │    2   │ Lowest noise               │
--    └──────────────────┴────────┴────────────────────────────┘
--   
--   If you use 'sync_valid_out' and 'sync_data_out', 
--   you have to consider that 1 pipeline register is used.
--
-- Revision:
--   0.01 - File Created
--
-- Notes
--
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity round_slv is
  generic (
    WIDTH_IN   : integer := 17;
    WIDTH_OUT  : integer := 16;
    ROUND_TYPE : integer := 0 -- See the table.
  );
  port (
    clk            : in  std_logic;
    rst            : in  std_logic;
    enb            : in  std_logic;
    data_in        : in  std_logic_vector(WIDTH_IN - 1 downto 0);
    data_out       : out std_logic_vector(WIDTH_OUT - 1 downto 0); -- Combinational logic
    sync_valid_out : out std_logic;                                -- Synchronous logic
    sync_data_out  : out std_logic_vector(WIDTH_OUT - 1 downto 0)  -- Synchronous logic
  );
end entity;

architecture rtl of round_slv is

  signal data_in_trunc  : signed(WIDTH_IN - 1 downto WIDTH_IN - WIDTH_OUT);
  signal round_corr     : std_logic;
  signal round_corr_slv : signed(data_in_trunc'range);

  signal int_data_out  : std_logic_vector(WIDTH_OUT - 1 downto 0);
  signal reg_data_out  : std_logic_vector(WIDTH_OUT - 1 downto 0);
  signal reg_valid_out : std_logic;

begin

  SAME_WIDTH_GEN: if WIDTH_IN = WIDTH_OUT generate
  begin
    int_data_out <= data_in;
  end generate;

  DIFFERENT_WIDTH_GEN: if WIDTH_IN /= WIDTH_OUT generate
  begin

    -- Truncation
    ROUND_TRUNC_GEN: if ROUND_TYPE = 0 generate
      constant round_corr_trunc : std_logic := '0';
    begin
      round_corr <= round_corr_trunc;
    end generate;

    -- Round to Zero
    ROUND_TO_ZERO_GEN: if ROUND_TYPE = 1 generate
      constant c_OR_zeros : std_logic_vector(WIDTH_IN - WIDTH_OUT - 1 downto 0) := (others => '0');
      signal data_in_highPart     : std_logic_vector(WIDTH_IN - WIDTH_OUT - 1 downto 0);
      signal reduction_OR_data_in : std_logic;
      signal round_corr_rtz       : std_logic;
    begin
      data_in_highPart     <= data_in(WIDTH_IN - WIDTH_OUT - 1 downto 0);
      reduction_OR_data_in <= '0' when data_in_highPart = c_OR_zeros else '1';
      round_corr_rtz       <= data_in(WIDTH_IN - 1) and reduction_OR_data_in;
      round_corr           <= round_corr_rtz;
    end generate;

    -- Round to nearest
    ROUND_TO_NEAREST_GEN: if ROUND_TYPE = 2 generate
      constant c_AND_ones : std_logic_vector(WIDTH_OUT - 2 downto 0) := (others => '1');
      signal data_in_highPart        : std_logic_vector(WIDTH_OUT - 2 downto 0);
      signal reduction_AND_data_in   : std_logic;
      signal round_corr_nearest      : std_logic;
      signal round_corr_nearest_safe : std_logic;
    begin
      data_in_highPart      <= data_in(WIDTH_IN - 2 downto WIDTH_IN - WIDTH_OUT);
      reduction_AND_data_in <= '1' when data_in_highPart = c_AND_ones else '0';
      round_corr_nearest    <= data_in(WIDTH_IN - WIDTH_OUT - 1);

      CORR_NEAREST_SAFE_GEN_0: if (WIDTH_IN - WIDTH_OUT) > 1 generate
        signal cond : std_logic;
      begin
        cond                    <= (not (data_in(WIDTH_IN - 1)) and reduction_AND_data_in);
        round_corr_nearest_safe <= '0' when cond = '1' else round_corr_nearest;
      end generate;

      CORR_NEAREST_SAFE_GEN_1: if (WIDTH_IN - WIDTH_OUT) <= 1 generate
      begin
        round_corr_nearest_safe <= round_corr_nearest;
      end generate;

      round_corr <= round_corr_nearest_safe;
    end generate;

    -- Default rounding
    ROUND_DEFAULT_GEN: if ROUND_TYPE < 0 or ROUND_TYPE > 2 generate
    begin
      round_corr <= '0';
    end generate;

    -- Output data
    data_in_trunc  <= signed(data_in(WIDTH_IN - 1 downto WIDTH_IN - WIDTH_OUT));
    round_corr_slv <= to_signed(1, round_corr_slv'length) when round_corr = '1' else (others => '0');
    int_data_out   <= std_logic_vector(data_in_trunc + round_corr_slv);

  end generate;

  OUT_REG_PROC: process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        reg_valid_out <= '0';
        reg_data_out <= (others => '0');

      elsif enb = '1' then
        reg_valid_out <= '1';
        reg_data_out <= int_data_out;
      else
        reg_valid_out <= '0';
        reg_data_out <= reg_data_out;
      end if;
    end if;
  end process;

  data_out       <= int_data_out;
  sync_valid_out <= reg_valid_out;
  sync_data_out  <= reg_data_out;

end architecture;
