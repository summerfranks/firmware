set_device -family {SmartFusion2} -die {M2S010} -speed {STD}
read_verilog -mode system_verilog {/home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/component/work/FCCC_C0/FCCC_C0_0/FCCC_C0_FCCC_C0_0_FCCC.v}
read_verilog -mode system_verilog {/home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/component/work/FCCC_C0/FCCC_C0.v}
read_verilog -mode system_verilog {/home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/component/work/Filterwheel_sb/CCC_0/Filterwheel_sb_CCC_0_FCCC.v}
read_verilog -mode system_verilog {/home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/component/work/Filterwheel_sb/FABOSC_0/Filterwheel_sb_FABOSC_0_OSC.v}
read_verilog -mode system_verilog {/home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/component/work/Filterwheel_sb_MSS/Filterwheel_sb_MSS.v}
read_verilog -mode system_verilog {/home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/component/Actel/DirectCore/CoreResetP/7.1.100/rtl/vlog/core/coreresetp_pcie_hotreset.v}
read_verilog -mode system_verilog {/home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/component/Actel/DirectCore/CoreResetP/7.1.100/rtl/vlog/core/coreresetp.v}
read_verilog -mode system_verilog -lib COREAPB3_LIB {/home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/component/Actel/DirectCore/CoreAPB3/4.1.100/rtl/vlog/core/coreapb3_muxptob3.v}
read_verilog -mode system_verilog -lib COREAPB3_LIB {/home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/component/Actel/DirectCore/CoreAPB3/4.1.100/rtl/vlog/core/coreapb3_iaddr_reg.v}
read_verilog -mode system_verilog -lib COREAPB3_LIB {/home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/component/Actel/DirectCore/CoreAPB3/4.1.100/rtl/vlog/core/coreapb3.v}
read_verilog -mode system_verilog {/home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/component/work/Filterwheel_sb/Filterwheel_sb.v}
read_vhdl -mode vhdl_2008 {/home/summer/projects/CGraph/firmware/FilterwheelTq144/fpga/BuildNumber.vhd}
read_vhdl -mode vhdl_2008 {/home/summer/projects/CGraph/firmware/include/fpga/IBufP1.vhd}
read_vhdl -mode vhdl_2008 {/home/summer/projects/CGraph/firmware/include/fpga/IBufP2.vhd}
read_vhdl -mode vhdl_2008 {/home/summer/projects/CGraph/firmware/include/fpga/IBufP3.vhd}
read_vhdl -mode vhdl_2008 {/home/summer/projects/CGraph/firmware/include/fpga/PPSCount.vhd}
read_vhdl -mode vhdl_2008 {/home/summer/projects/CGraph/firmware/FilterwheelTq144/fpga/RegisterSpace.vhd}
read_vhdl -mode vhdl_2008 {/home/summer/projects/CGraph/firmware/include/fpga/UartRxRaw.vhd}
read_vhdl -mode vhdl_2008 {/home/summer/projects/CGraph/firmware/include/fpga/UartRxExtClk.vhd}
read_vhdl -mode vhdl_2008 {/home/summer/projects/CGraph/firmware/include/fpga/fifo_gen.vhd}
read_vhdl -mode vhdl_2008 {/home/summer/projects/CGraph/firmware/include/fpga/gated_fifo.vhd}
read_vhdl -mode vhdl_2008 {/home/summer/projects/CGraph/firmware/include/fpga/UartRxFifoExtClk.vhd}
read_vhdl -mode vhdl_2008 {/home/summer/projects/CGraph/firmware/include/fpga/UartTx.vhd}
read_vhdl -mode vhdl_2008 {/home/summer/projects/CGraph/firmware/include/fpga/UartTxFifoExtClk.vhd}
read_vhdl -mode vhdl_2008 {/home/summer/projects/CGraph/firmware/include/fpga/VariableClockDivider.vhd}
read_vhdl -mode vhdl_2008 {/home/summer/projects/CGraph/firmware/include/fpga/ClockDivider.vhd}
read_vhdl -mode vhdl_2008 {/home/summer/projects/CGraph/firmware/include/fpga/FourWireStepperMotor.vhd}
read_vhdl -mode vhdl_2008 {/home/summer/projects/CGraph/firmware/include/fpga/OneShot.vhd}
read_vhdl -mode vhdl_2008 {/home/summer/projects/CGraph/firmware/include/fpga/FourWireStepperMotorDriver.vhd}
read_vhdl -mode vhdl_2008 {/home/summer/projects/CGraph/firmware/include/fpga/SpiMaster.vhd}
read_vhdl -mode vhdl_2008 {/home/summer/projects/CGraph/firmware/include/fpga/SpiDac.vhd}
read_vhdl -mode vhdl_2008 {/home/summer/projects/CGraph/firmware/include/fpga/SpiDevice.vhd}
read_vhdl -mode vhdl_2008 {/home/summer/projects/CGraph/firmware/FilterwheelTq144/fpga/Main.vhd}
read_verilog -mode system_verilog {/home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/component/work/Filterwheel/Filterwheel.v}
set_top_level {Filterwheel}
map_netlist
read_sdc {/home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/constraint/Filterwheel_derived_constraints.sdc}
check_constraints {/home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/constraint/synthesis_sdc_check.log}
