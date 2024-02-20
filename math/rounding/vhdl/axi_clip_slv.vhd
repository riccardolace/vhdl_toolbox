----------------------------------------------------------------------------------
-- Engineer: Daniele Giardino
-- 
-- Create Date: 2024.02.20
-- Description: 
--   AXI version of the block 'clip_slv.vhd'.
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

entity axi_clip_slv is
  generic (
    WIDTH_IN  : integer := 17;
    WIDTH_OUT : integer := 16
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

architecture rtl of axi_clip_slv is

  signal reg_o_tvalid  : std_logic;
  signal reg_o_tdata   : std_logic_vector(WIDTH_OUT - 1 downto 0);
  signal reg_o_tready  : std_logic;
  signal clip_data_in  : std_logic_vector(WIDTH_IN - 1 downto 0);
  signal clip_data_out : std_logic_vector(WIDTH_OUT - 1 downto 0);

begin

  SAME_WIDTH_GEN: if WIDTH_IN = WIDTH_OUT generate
  begin
    i_tready <= o_tready;
    o_tvalid <= i_tvalid;
    o_tdata  <= i_tdata;
  end generate;

  DIFFERENT_WIDTH_GEN: if WIDTH_IN > WIDTH_OUT generate
  begin

    clip_data_in <= i_tdata;
    i_tready     <= reg_o_tready;
    o_tvalid     <= reg_o_tvalid;
    o_tdata      <= reg_o_tdata;

    REGS_PROC: process (clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          reg_o_tready <= '0';
          reg_o_tvalid <= '0';
          reg_o_tdata <= (others => '0');
        else
          reg_o_tready <= o_tready;
          reg_o_tvalid <= i_tvalid;
          reg_o_tdata <= clip_data_out;
        end if;
      end if;
    end process;

    clip_slv_inst: entity work.clip_slv
      generic map (
        WIDTH_IN  => WIDTH_IN,
        WIDTH_OUT => WIDTH_OUT
      )
      port map (
        clk            => clk,
        rst            => rst,
        enb            => '1', -- It is fixed to 1 because the register is used in the 'REGS_PROC'
        data_in        => clip_data_in,
        data_out       => clip_data_out,
        sync_valid_out => open,
        sync_data_out  => open
      );
  end generate;

end architecture;
