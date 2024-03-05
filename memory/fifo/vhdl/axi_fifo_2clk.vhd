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

entity axi_fifo_2clk is
  generic (
    ALMOST_FULL_OFFSET : NATURAL := 16;
    FIFO_ADDR_WIDTH    : NATURAL := 9;
    FIFO_DATA_WIDTH    : NATURAL := 16;
    BRAM_TYPE          : STRING  := "block"
  );
  port (
    i_clk    : in  STD_LOGIC;
    i_rst    : in  STD_LOGIC;
    i_tvalid : in  STD_LOGIC;
    i_tdata  : in  STD_LOGIC_VECTOR(FIFO_DATA_WIDTH - 1 downto 0);
    i_tready : out STD_LOGIC;
    o_clk    : in  STD_LOGIC;
    o_rst    : in  STD_LOGIC;
    o_tvalid : out STD_LOGIC;
    o_tdata  : out STD_LOGIC_VECTOR(FIFO_DATA_WIDTH - 1 downto 0);
    o_tready : in  STD_LOGIC
  );
end entity;

architecture bhv of axi_fifo_2clk is

  signal int_tdata  : std_logic_vector(FIFO_DATA_WIDTH - 1 downto 0);
  signal int_tready : std_logic;

  -- read_int will assert when either a read occurs or the output register is empty (and there is data in the shift register fifo)
  signal read_int : std_logic;
  -- read will only assert when an actual 1read request occurs at the interface
  --signal read : std_logic;
  -- Read side states
  type Tstate is (ST_EMPTY, PRE_READ, READING);
  signal read_state : Tstate := ST_EMPTY;

  -- Addresses signals
  signal wr_addr : unsigned(FIFO_ADDR_WIDTH - 1 downto 0);
  signal rd_addr : unsigned(FIFO_ADDR_WIDTH - 1 downto 0);

  -- Empty and Full regs
  signal empty_reg : std_logic := '1';
  signal full_reg  : std_logic := '0';
  --signal full      : std_logic;
  signal empty     : std_logic;
  signal write     : std_logic;

  -- Signals used to handle the RAM
  signal dont_write_past_me : unsigned(FIFO_ADDR_WIDTH - 1 downto 0);
  signal becoming_full      : std_logic;

  -- RAM
  constant Size_Ram : integer := 2 ** FIFO_ADDR_WIDTH;
  type ram_type is array (0 to Size_Ram - 1) of std_logic_vector(FIFO_DATA_WIDTH - 1 downto 0);
  signal ram : ram_type := ((others =>(others => '0')));
  attribute ram_style        : string;
  attribute ram_style of ram : signal is BRAM_TYPE;

  -- Output Register
  signal reg_o_tvalid : std_logic := '0';
  signal reg_tdata    : std_logic_vector(FIFO_DATA_WIDTH - 1 downto 0);

  -- Cross Domain Clock signals
  constant C_SYNC_STAGES : INTEGER := 2;
  type T_SYNC_ADDR is array (NATURAL range <>) of UNSIGNED(wr_addr'RANGE);
  signal cdc_wr_addr : T_SYNC_ADDR(0 to C_SYNC_STAGES - 1);
  signal cdc_write   : STD_LOGIC_VECTOR(0 to C_SYNC_STAGES - 1);
  signal cdc_full    : STD_LOGIC_VECTOR(0 to C_SYNC_STAGES - 1);

begin

  -------- Write Side - BEGIN --------
  write    <= i_tvalid and (not cdc_full(cdc_full'LENGTH - 1));
  i_tready <= not cdc_full(cdc_full'LENGTH - 1);

  P_WR_ADDR: process (i_clk)
  begin
    if rising_edge(i_clk) then
      if i_rst = '1' then
        wr_addr <= (others => '0');
      elsif write = '1' then
        wr_addr <= wr_addr + 1;
      else
        wr_addr <= wr_addr;
      end if;
    end if;
  end process;

  P_WRITE_DATA: process (i_clk)
  begin
    if rising_edge(i_clk) then
      if write = '1' then
        ram(TO_INTEGER(UNSIGNED(wr_addr))) <= i_tdata;
      end if;
    end if;
  end process;
  -------- Write Side - END --------
  -------- Cross Domain Clock Signals - BEGIN --------

  CDC_IN_TO_OUT: process (o_clk)
  begin
    if rising_edge(o_clk) then
      if o_rst = '1' then
        cdc_wr_addr <= (others =>(others => '0'));
        --elsif o_tready='1' then
      else
        cdc_wr_addr(0) <= wr_addr;
        cdc_wr_addr(1 to cdc_wr_addr'LENGTH - 1) <= cdc_wr_addr(0 to cdc_wr_addr'LENGTH - 2);

        cdc_write(0) <= write;
        cdc_write(1 to cdc_write'LENGTH - 1) <= cdc_write(0 to cdc_write'LENGTH - 2);

      end if;
    end if;
  end process;

  CDC_OUT_TO_IN: process (i_clk)
  begin
    if rising_edge(i_clk) then
      if i_rst = '1' then
        cdc_full <= (others => '0');
        --elsif o_tready='1' then
      else
        cdc_full(0) <= full_reg;
        cdc_full(1 to cdc_wr_addr'LENGTH - 1) <= cdc_full(0 to cdc_wr_addr'LENGTH - 2);
      end if;
    end if;
  end process;
  -------- Cross Domain Clock Signals - END --------
  -------- Read Side - BEGIN --------
  read_int <= (not empty) and int_tready;
  --read     <= o_tready and reg_o_tvalid;

  P_READ_DATA: process (o_clk)
  begin
    if rising_edge(o_clk) then
      if read_state = PRE_READ or read_int = '1' then
        int_tdata <= ram(TO_INTEGER(unsigned(rd_addr)));
      end if;
    end if;
  end process;

  P_READ_FSM: process (o_clk)
  begin
    if rising_edge(o_clk) then
      if o_rst = '1' then
        read_state <= ST_EMPTY;
        rd_addr <= (others => '0');
        empty_reg <= '1';
      else

        case read_state is
          when ST_EMPTY =>
            if cdc_write(cdc_write'LENGTH - 1) = '1' then
              read_state <= PRE_READ;
            end if;

          when PRE_READ =>
            read_state <= READING;
            empty_reg <= '0';
            rd_addr <= rd_addr + 1;

          when READING =>
            if read_int = '1' then
              if rd_addr = wr_addr then
                empty_reg <= '1';
                if cdc_write(cdc_write'LENGTH - 1) = '1' then
                  read_state <= PRE_READ;
                else
                  read_state <= ST_EMPTY;
                end if;
              else
                rd_addr <= rd_addr + 1;
              end if;
            end if;

          when others =>
            read_state <= read_state;
            rd_addr <= rd_addr;
            empty_reg <= empty_reg;

        end case;
      end if;
    end if;
  end process;

  dont_write_past_me <= rd_addr - TO_UNSIGNED(ALMOST_FULL_OFFSET, rd_addr'LENGTH);
  becoming_full      <= '1' when cdc_wr_addr(cdc_wr_addr'LENGTH - 1) = dont_write_past_me else '0';

  process (o_clk)
  begin
    if rising_edge(o_clk) then
      if o_rst = '1' then
        full_reg <= '0';
      elsif read_int = '1' and write = '0' then
        full_reg <= '0';
      elsif write = '1' and read_int = '0' and becoming_full = '1' then
        full_reg <= '1';
      else
        full_reg <= full_reg;
      end if;
    end if;
  end process;

  empty <= empty_reg;
  --full  <= full_reg;

  -- Output registers
  process (o_clk)
  begin
    if rising_edge(o_clk) then
      if o_rst = '1' then
        reg_o_tvalid <= '0';
        reg_tdata <= (others => '0');
      elsif int_tready = '1' then
        reg_o_tvalid <= not empty;
        reg_tdata <= int_tdata;
      end if;
    end if;
  end process;

  int_tready <= o_tready or (not reg_o_tvalid);

  -- Output ports
  o_tvalid <= reg_o_tvalid;
  o_tdata  <= reg_tdata;

  -------- Read Side - END --------
end architecture;

