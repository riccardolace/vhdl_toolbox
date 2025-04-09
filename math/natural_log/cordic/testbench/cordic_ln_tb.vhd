----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2025.02.27
-- Description: 
--   Test Bench.
-- 
-- Revision:
--   0.01 - File Created
--
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.math_real.all;
  use ieee.numeric_std.all;

  use std.textio.all;
  use std.env.finish;

library work;
use work.pkg_vhdl_toolbox.flp_to_fxp;

entity cordic_ln_tb is
end entity;

architecture sim of cordic_ln_tb is

  -------- Constants and signals --------
  constant clk_hz         : integer := 1e9;
  constant clk_period     : time    := 1 sec / clk_hz;
  constant waitNumOfCycle : integer := 1;

  signal clk : std_logic := '1';
  signal rst : std_logic := '1';

  -- DUT signals
  constant Wl_in              : integer := 36;
  constant Fl                 : integer := Wl_in-1;
  constant Wl_out             : integer := 16;
  constant Fl_out             : integer := (Wl_out - 1 - integer(floor(log2(real(Wl_in)))));
  signal dut_i_tvalid         : std_logic;
  signal dut_i_tdata_real     : real;
  signal dut_i_tdata_slv      : std_logic_vector(Wl_in+1 downto 0);
  signal dut_i_tdata          : std_logic_vector(Wl_in-1 downto 0);
  signal dut_i_tready         : std_logic;
  signal dut_o_tdata          : std_logic_vector(Wl_out-1 downto 0);
  signal dut_o_tdata_ref      : signed(Wl_out-1 downto 0);
  signal dut_o_tvalid         : std_logic;
  signal dut_o_tready         : std_logic;

  -- Data in values
  type test_data_in_arr_type is array (NATURAL RANGE <>) of real;
  signal i : integer := 0;
  signal load_data : boolean;
  constant test_data_in_arr : test_data_in_arr_type(0 to 14) := (
    0.0,
    0.0,
    1.0/(2**(Fl-1)),
    0.0012,
    0.3210,
    0.4500,
    0.5500,
    0.9500,
    1.0000,
    1.0500,
    1.4500,
    1.5000,
    1.5500,
    1.9000,
    1.9000
  );
  -- constant test_data_in_arr : test_data_in_arr_type(0 to 1) := (0.9, 0.9);
  signal test_print : std_logic_vector(Wl_in downto 0);
	
  type dataOutRef_type is array (0 to 255) of signed(Wl_out-1 downto 0);
  signal dataOutRef       : dataOutRef_type;
  signal dataOutRef_last  : signed(Wl_out-1 downto 0);
  signal dataOutRef_delay : integer := 47;
  

begin

  clk <= not clk after clk_period / 2;

  DUT: entity work.cordic_ln(cordic_unrolled)
  generic map (
    Wl_in  =>  Wl_in ,
    Wl_out =>  Wl_out 
  )
  port map (
    clk      => clk           ,
    rst      => rst           ,
    i_tvalid => dut_i_tvalid  ,
    i_tdata  => dut_i_tdata   , 
    i_tready => dut_i_tready  ,
    o_tdata  => dut_o_tdata   ,
    o_tvalid => dut_o_tvalid  ,
    o_tready => dut_o_tready
  );

  outRef_PROC : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        dataOutRef <= (others=>(others => '0'));
        
      elsif load_data then
        dataOutRef(0) <= dut_o_tdata_ref;
        dataOutRef(1 to dataOutRef'length-1) <= dataOutRef(0 to dataOutRef'length-2);
        
      end if;
    end if;
  end process;
  dataOutRef_last <= dataOutRef(dataOutRef_delay-1);
  
  SEQUENCER_PROC: process
  begin
    rst <= '1';
    load_data  <= false;
    dut_o_tready <= '0';
    test_print <= flp_to_fxp(0.26, Wl_in+1, Wl_in-1);
    wait for clk_period * 2;

    rst <= '0';
    dut_o_tready <= '1';
    wait for clk_period * 5;

    load_data <= true;
    wait for clk_period * 2;
    
    load_data <= false;
    wait for clk_period * 60;
    
    load_data <= true;
    wait for clk_period * 100;
    -- assert false
    --   report "FINISH!"
    --   severity failure;
		-- finish;
		wait;
  end process;

  process (clk)
  	variable data_un : std_logic_vector(Wl_in downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        i <= 0;
		    dut_i_tvalid <= '0';
        dut_o_tdata_ref <= (others => '0');
      else
        if load_data then
          if i<test_data_in_arr'length-1 then
            dut_i_tdata     <= dut_i_tdata_slv(Wl_in-1 downto 0);
            dut_o_tdata_ref <= signed(flp_to_fxp(log(dut_i_tdata_real), Wl_out, Fl_out) );
            i <= i+1;
          end if;
  				dut_i_tvalid <= '1';
        else
          dut_i_tvalid <= '0';
        end if;

      end if;
    end if;
  end process;
  
	-- The 'flp_to_fxp' function generates a signed value, 
	-- but we need unsigned values with Wl_in bits.
	-- So, we define a variable with 2 extra bits and 
	-- only the Wl_in bits will be extracted.
  dut_i_tdata_real 	<= test_data_in_arr(i);
  dut_i_tdata_slv 	<= flp_to_fxp(dut_i_tdata_real, Wl_in+2, Fl);


end architecture;
