----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2024.02.20
-- Description: 
--   The block allows you to round and reduce the size of a 'std_logic_vector'.
--   The blocks 'round_slv_inst.vhd' and 'clip_slv_inst.vhd' are implemented, and 
--   and the sync_outputes are used. Combinational output 'data_out' is not implemented.
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

entity round_and_clip_slv is
  generic (
    WIDTH_IN  : integer := 24;
    WIDTH_OUT : integer := 16;
    CLIP_BITS : integer := 3
  );
  port (
    clk            : in  std_logic;
    rst            : in  std_logic;
    enb            : in  std_logic;
    data_in        : in  std_logic_vector(WIDTH_IN - 1 downto 0); -- Combinational logic
    sync_valid_out : out std_logic;                               -- Synchronous logic
    sync_data_out  : out std_logic_vector(WIDTH_OUT - 1 downto 0) -- Synchronous logic
  );
end entity;

architecture rtl of round_and_clip_slv is

  signal int_tdata  : std_logic_vector(WIDTH_OUT + CLIP_BITS - 1 downto 0);
  signal int_tvalid : std_logic;
  signal clip_enb   : std_logic;

begin

  SAME_WIDTH_GEN: if WIDTH_IN = WIDTH_OUT + CLIP_BITS generate
  begin
    int_tvalid <= enb;
    int_tdata  <= data_in;
  end generate;

  DIFFERENT_WIDTH_GEN: if WIDTH_IN /= WIDTH_OUT + CLIP_BITS generate
  begin

    round_slv_inst: entity work.round_slv
      generic map (
        WIDTH_IN   => WIDTH_IN,
        WIDTH_OUT  => WIDTH_OUT + CLIP_BITS,
        ROUND_TYPE => 2
      )
      port map (
        clk            => clk,
        rst            => rst,
        enb            => enb,
        data_in        => data_in,
        data_out       => open,
        sync_valid_out => int_tvalid,
        sync_data_out  => int_tdata
      );
  end generate;
  
  clip_enb <= int_tvalid;
  clip_slv_inst: entity work.clip_slv
    generic map (
      WIDTH_IN  => WIDTH_OUT + CLIP_BITS,
      WIDTH_OUT => WIDTH_OUT
    )
    port map (
      clk            => clk,
      rst            => rst,
      enb            => clip_enb,
      data_in        => int_tdata,
      data_out       => open,
      sync_valid_out => sync_valid_out,
      sync_data_out  => sync_data_out
    );

end architecture;
