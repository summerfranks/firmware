--! \brief Testbench for CGraphDmTypes
--! Minimal sanity test so the package analyzes and elaborates cleanly.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

library work;
use work.CGraphDMTypes.all;
use work.tb_utils_pkg.all;

entity CGraphDmTypes_tb is
end entity CGraphDmTypes_tb;

architecture sim of CGraphDmTypes_tb is
	signal test_name_display : string(1 to 80);
begin
	process
		variable arr : DMDacSetpointRam;
		variable arr_flat : DMDacSetpointRamFlat;
		variable arr_regs : DMDacSetpointRegisters;
		variable arr_proto_regs : DMProtoDacSetpointRegisters;
		variable arr_mappings : DacSetpointMappings_t;
	begin
		set_test_name(test_name_display, "CGraphDmTypes sanity");

		assert DMSetPointMSB = 23
			report "DMSetpointMSB"
			severity error;
		assert DMMaxControllerBoards = 6
			report "DMMaxControllerBoards"
			severity error;
		assert DMMDacsPerControllerBoard = 4
			report "DMMDacsPerControllerBoard"
			severity error;
		assert DMActuatorsPerDac = 40
			report "DMActuatorsPerDac"
			severity error;
		assert DMMaxActuators = DMActuatorsPerDac * DMMDacsPerControllerBoard * DMMaxControllerBoards
			report "DMMaxActuators"
			severity error;

		arr(0, 0, 0) := x"ABCDEF";
		assert_equal(arr(0, 0, 0), x"ABCDEF", "DMDacSetpointRam array element assignment");
		arr(0, 0, 1) := x"123456";
		assert_equal(arr(0, 0, 1), x"123456", "DMDacSetpointRam array element assignment");
		assert_equal(arr(0, 0, 0), x"ABCDEF", "DMDacSetpointRam array element assignment");
		
		for i in 0 to DMMaxControllerBoards - 1 loop
			for j in 0 to DMMDacsPerControllerBoard - 1 loop
				for k in 0 to DMActuatorsPerDac loop -- DMMacSetpointRam is defined as 0 to DMActuatorsPerDac
					arr(i, j, k) := std_logic_vector(to_unsigned(i * 10000 + j * 100 + k, DMSetpointMSB + 1));
					assert_equal(arr(i, j, k), std_logic_vector(to_unsigned(i * 10000 + j * 100 + k, DMSetpointMSB + 1)), "DMDacSetpointRam array element assignment");
				end loop;
			end loop;
		end loop;

		for i in 0 to DMMaxActuators - 1 loop
			arr_flat(i) := std_logic_vector(to_unsigned(i * 10000 + i * 100 + i, DMSetpointMSB + 1));
			assert_equal(arr_flat(i), std_logic_vector(to_unsigned(i * 10000 + i * 100 + i, DMSetpointMSB + 1)), "DMDacSetpointRamFlat array element assignment");
		end loop;

		for i in 0 to DMMaxControllerBoards - 1 loop
			for j in 0 to DMMDacsPerControllerBoard - 1 loop
				arr_regs(i, j) := std_logic_vector(to_unsigned(i * 10000 + j * 100, DMSetpointMSB + 1));
				assert_equal(arr_regs(i, j), std_logic_vector(to_unsigned(i * 10000 + j * 100, DMSetpointMSB + 1)), "DMDacSetpointRegisters array element assignment");
			end loop;
		end loop;

		for i in 0 to DMMaxControllerBoards - 1 loop
			arr_proto_regs(i) := std_logic_vector(to_unsigned(i * 10000, DMSetpointMSB + 1));
			assert_equal(arr_proto_regs(i), std_logic_vector(to_unsigned(i * 10000, DMSetpointMSB + 1)), "DMProtoDacSetpointRegisters array element assignment");
		end loop;

		for i in 0 to DMMaxActuators - 1 loop
			arr_mappings(i) := i;
			assert_equal(std_logic_vector(to_unsigned(arr_mappings(i), DMSetpointMSB + 1)), std_logic_vector(to_unsigned(i, DMSetpointMSB + 1)), "DacSetpointMappings_t array element assignment");
		end loop;

		finish;
	end process;
end architecture sim;
