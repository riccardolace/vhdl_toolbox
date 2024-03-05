----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2024.02.20
-- Description: 
--   Cascade of the 'axi_round_slv.vhd' and 'axi_clip_slv.vhd'.
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

entity axi_round_and_clip_slv is
  generic (
    WIDTH_IN  : integer := 24;
    WIDTH_OUT : integer := 16;
    CLIP_BITS : integer := 3
  );
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    i_tvalid : in  std_logic;
    i_tdata  : in  std_logic_vector(WIDTH_IN - 1 downto 0);
    i_tready : out std_logic;
    o_tvalid : out std_logic;
    o_tdata  : out std_logic_vector(WIDTH_OUT - 1 downto 0);
    o_tready : in  std_logic
  );
end entity;

architecture rtl of axi_round_and_clip_slv is

  signal int_tdata  : std_logic_vector(WIDTH_OUT + CLIP_BITS - 1 downto 0);
  signal int_tvalid : std_logic;
  signal int_tready : std_logic;

begin

  SAME_WIDTH_GEN: if WIDTH_IN = WIDTH_OUT + CLIP_BITS generate
  begin
    int_tvalid <= i_tvalid;
    int_tdata  <= i_tdata;
    i_tready   <= int_tready;
  end generate;

  DIFFERENT_WIDTH_GEN: if WIDTH_IN /= WIDTH_OUT + CLIP_BITS generate
  begin
    axi_round_slv_inst: entity work.axi_round_slv(rtl)
    generic map (
        WIDTH_IN   => WIDTH_IN,
        WIDTH_OUT  => WIDTH_OUT + CLIP_BITS,
        ROUND_TYPE => 2
    )
    port map (
        clk      => clk,
        rst      => rst,
        i_tvalid => i_tvalid,
        i_tdata  => i_tdata,
        i_tready => i_tready,
        o_tvalid => int_tvalid,
        o_tdata  => int_tdata,
        o_tready => int_tready
    );
  end generate;

  CLIP_BITS_NO_ZERO_GEN: if CLIP_BITS > 0 generate
  begin
    axi_clip_slv_inst: entity work.axi_clip_slv(rtl)
    generic map (
        WIDTH_IN  => WIDTH_OUT + CLIP_BITS,
        WIDTH_OUT => WIDTH_OUT
    )
    port map (
        clk      => clk,
        rst      => rst,
        i_tvalid => int_tvalid,
        i_tdata  => int_tdata,
        i_tready => int_tready,
        o_tvalid => o_tvalid,
        o_tdata  => o_tdata,
        o_tready => o_tready
    );
  end generate;

end architecture;
