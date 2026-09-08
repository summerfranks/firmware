--! \brief Testbench for CGraphTypes
--! Checks PeekRamDepth=11, PeekRamType index range 0..(2**11)-1, and that assigning x"AB" to arr(0) reads back x"AB".

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

library work;
use work.CGraphTypes.all;
use work.tb_utils_pkg.all;

entity CGraphTypes_tb is
end entity CGraphTypes_tb;

architecture sim of CGraphTypes_tb is
	signal test_name_display : string(1 to 80);
begin
	process
		variable arr : PeekRamType;
	begin
		set_test_name(test_name_display, "CGraphTypes sanity");

		assert PeekRamDepth = 11
			report "PeekRamDepth should be 11"
			severity error;

		assert arr'low = 0
			report "PeekRamType low bound should be 0"
			severity error;

		assert arr'high = (2**PeekRamDepth) - 1
			report "PeekRamType high bound should be (2**PeekRamDepth)-1"
			severity error;

		arr(0) := x"AB";
		assert_equal(arr(0), x"AB", "PeekRamType array element assignment");

		finish;
	end process;
end architecture sim;

