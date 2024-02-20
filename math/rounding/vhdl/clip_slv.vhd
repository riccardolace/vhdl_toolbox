----------------------------------------------------------------------------------
-- Engineer: Daniele Giardino
-- 
-- Create Date: 2024.02.21
-- Description: 
--   The block allows you to reduce the size of a `std_logic_vector` saturating it.
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

entity clip_slv is
  generic (
    WIDTH_IN  : integer := 24;
    WIDTH_OUT : integer := 16
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

architecture rtl of clip_slv is
  signal int_data_out  : std_logic_vector(WIDTH_OUT-1 downto 0);
  signal reg_data_out  : std_logic_vector(WIDTH_OUT-1 downto 0);
  signal reg_valid_out : std_logic;
begin

  SAME_WIDTH_GEN: if WIDTH_IN = WIDTH_OUT generate
  begin
    int_data_out <= data_in;
  end generate;

  DIFFERENT_WIDTH_GEN: if WIDTH_IN /= WIDTH_OUT generate
    constant c_OR_zeros          : std_logic_vector(WIDTH_IN-WIDTH_OUT downto 0) := (others => '0');
    constant c_AND_ones          : std_logic_vector(WIDTH_IN-WIDTH_OUT downto 0) := (others => '1');
    constant c_zeros             : std_logic_vector(WIDTH_OUT - 1 downto 0) := (others => '0');
    constant c_ones              : std_logic_vector(WIDTH_OUT - 1 downto 0) := (others => '1');
    signal data_in_highPart      : std_logic_vector(WIDTH_IN-WIDTH_OUT downto 0);
    signal reduction_OR_data_in  : std_logic;
    signal reduction_AND_data_in : std_logic;
    signal overflow_sel          : std_logic_vector(1 downto 0);
    signal overflow              : std_logic;
  begin
    
    data_in_highPart      <= data_in(WIDTH_IN - 1 downto WIDTH_OUT - 1);
    reduction_OR_data_in  <= '0' when data_in_highPart = c_OR_zeros else '1';
    reduction_AND_data_in <= '1' when data_in_highPart = c_AND_ones else '0';
    overflow              <= reduction_OR_data_in and (not(reduction_AND_data_in));

    -- Output register
    overflow_sel <= overflow & data_in(WIDTH_IN - 1);
    int_data_out <= ("1" & c_zeros) when (overflow_sel = "11") else
                    ("0" & c_ones)  when (overflow_sel = "10") else
                                    data_in(WIDTH_OUT - 1 downto 0);
    data_out <= int_data_out;
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

  data_out <= int_data_out;
  sync_valid_out <= reg_valid_out;
  sync_data_out  <= reg_data_out;  

end architecture;
