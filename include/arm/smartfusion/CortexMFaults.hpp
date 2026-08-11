//
///           Copyright (c) by Franks Development, LLC
//
// This software is copyrighted by and is the sole property of Franks
// Development, LLC. All rights, title, ownership, or other interests
// in the software remain the property of Franks Development, LLC. This
// software may only be used in accordance with the corresponding
// license agreement.  Any unauthorized use, duplication, transmission,
// distribution, or disclosure of this software is expressly forbidden.
//
// This Copyright notice may not be removed or modified without prior
// written consent of Franks Development, LLC.
//
// Franks Development, LLC. reserves the right to modify this software
// without notice.
//
// Franks Development, LLC            support@franks-development.com
// 500 N. Bahamas Dr. #101           http://www.franks-development.com
// Tucson, AZ 85710
// USA
//
// Permission granted for perpetual non-exclusive end-use by the University of Arizona August 1, 2020
//

#pragma once

#include <stdint.h>
#ifdef DEBUG
	#include <stdio.h>
	#include <string.h>
#endif

#include "format/formatf.h"

	// See: https://developer.arm.com/documentation/dui0552/a/cortex-m3-peripherals/system-control-block
	// See: https://interrupt.memfault.com/blog/cortex-m-hardfault-debug

	// Recovering the Call Stack
	// To fix a fault, we will want to determine what code was running when the fault occurred. To accomplish this, we need to recover the register state at the time of exception entry.
	// If the fault is readily reproducible and we have a debugger attached to the board, we can manually add a breakpoint for the function which handles the exception. In GDB this will look something like
	//	(gdb) break HardFault_Handler
	// Upon exception entry some registers will always be automatically saved on the stack. Depending on whether or not an FPU is in use, either a basic or extended stack frame will be pushed by hardware.
	// Regardless, the hardware will always push the same core set of registers to the very top of the stack which was active prior to entering the exception. ARM Cortex-M devices have two stack pointers, msp & psp. Upon exception entry, the active stack pointer is encoded in bit 2 of the EXC_RETURN value pushed to the link register. If the bit is set, the psp was active prior to exception entry, else the msp was active.
	//	(gdb) p/x $lr
	//	$4 = 0xfffffffd
	//	# psp was active prior to exception if bit 2 is set
	//	# otherwise, the msp was active
	//	(gdb) p/x $lr&(1<<2)
	//	$5 = 0x4
	//	# First eight values on stack will always be:
	//	# r0, r1, r2, r3, r12, LR, pc, xPSR
	//	(gdb) p/a *(uint32_t[8] *)$psp
	//	$16 = {
	//	  0x0 <g_pfnVectors>,
	//	  0x200003c4 <ucHeap+604>,
	//	  0x10000000,
	//	  0xe0000000,
	//	  0x200001b8 <ucHeap+80>,
	//	  0x61 <illegal_instruction_execution+16>,
	//	  0xe0000000,
	//	  0x80000000
	//	}
	// Offset 6 and 7 in the array dumped hold the LR (illegal_instruction_execution) & PC (0xe0000000) so we now can see exactly where the fault originated!
	
	// Faults from Faults!
	// The astute observer might wonder what happens when a new fault occurs in the code dealing with a fault. If you have enabled configurable fault handlers (i.e MemManage, BusFault, or UsageFault), a fault generated in these handlers will trigger a HardFault.
	// Once in the HardFault Handler, the ARM Core is operating at a non-configurable priority level, -1. At this level or above, a fault will put the processor in an unrecoverable state where a reset is expected. This state is known as Lockup.
	// Typically, the processor will automatically reset upon entering lockup but this is not a requirement per the specification. For example, you may have to enable a hardware watchdog for a reset to take place. It's worth double checking the reference manual for the MCU being used for clarification.
	// When a debugger is attached, lockup often has a different behavior. For example, on the NRF52840, "Reset from CPU lockup is disabled if the device is in debug interface mode"5.
	// When a lockup happens, the processor will repeatedly fetch the same fixed instruction, 0xFFFFFFFE or the instruction which triggered the lockup, in a loop until a reset occurs.
	// Fun Fact: Whether or not some classes of MemManage or BusFaults trigger a fault from an exception is actually configurable via the MPU_CTRL.HFNMIENA & CCR.BFHFNMIGN register fields, respectively.

	// Halting & Determining Core Register State
	// What if we are trying to debug an issue that is not easy to reproduce? Even if we have a debugger attached, useful state may be overwritten before we have a chance to halt the debugger and take a look.
	// The first thing we can do is to programmatically trigger a breakpoint when the system faults:
	//	// NOTE: If you are using CMSIS, the registers can also be
	//	// accessed through CoreDebug->DHCSR & CoreDebug_DHCSR_C_DEBUGEN_Msk
	//	#define HALT_IF_DEBUGGING()                              
	//	  do {                                                   
	//		if ((*(volatile uint32_t *)0xE000EDF0) & (1 << 0)) { 
	//		  __asm("bkpt 1");                                   
	//		}                                                    
	//	} while (0)

//~ namespace CortexMFaults
//~ {
	union UsageFaultStatusRegister
	{
		// This register is a 2 byte register which summarizes any faults that are not related to memory access failures, such as executing invalid instructions or trying to enter invalid states.

		// Configurable UsageFault:
		// It is worth noting that some classes of UsageFaults are configurable via the Configuration and Control Register (CCR) located at address 0xE000ED14.
		// Bit 4 (DIV_0_TRP) - Controls whether or not divide by zeros will trigger a fault.
		// Bit 3 (UNALIGN_TRP) - Controls whether or not unaligned accesses will always generate a fault.
		// NOTE: On reset both of these optional faults are disabled. It is generally a good idea to enable DIV_0_TRP to catch mathematical errors in your code.

		uint16_t all;
		
		struct
		{
			uint16_t UnDefInstr : 1; // Indicates an undefined instruction was executed. This can happen on exception exit if the stack got corrupted. A compiler may emit undefined instructions as well for code paths that should be unreachable.
			uint16_t InvStateESPR : 1; // Indicates the processor has tried to execute an instruction with an invalid Execution Program Status Register (EPSR) value. Among other things the ESPR tracks whether or not the processor is in thumb mode state. Instructions which use "interworking addresses"2 (bx & blx or ldr & ldm when loading a pc-relative value) must set bit[0] of the instruction to 1 as this is used to update ESPR.T. If this rule is violated, a INVSTATE exception will be generated. When writing C code, the compiler will take care of this automatically, but this is a common bug which can arise when hand-writing assembly.
			uint16_t InvPC : 1; // Indicates an integrity check failure on EXC_RETURN. We'll explore an example below. EXC_RETURN is the value branched to upon return from an exception. If this fault flag is set, it means a reserved EXC_RETURN value was used on exception exit.
			uint16_t NoCP : 1; //  Indicates that a Cortex-M coprocessor instruction was issued but the coprocessor was disabled or not present. One common case where this fault happens is when code is compiled to use the Floating Point extension (-mfloat-abi=hard -mfpu=fpv4-sp-d16) but the coprocessor was not enabled on boot.
			uint16_t reserved1 : 4;
			uint16_t UnAligned : 1; //  Indicates an unaligned access operation occurred. Unaligned multiple word accesses, such as accessing a uint64_t that is not 16-byte aligned, will always generate this fault. With the exception of Cortex-M0 MCUs, whether or not unaligned accesses below 4 bytes generate a fault is also configurable.
			uint16_t DivByZero : 1; // Indicates a divide instruction was executed where the denominator was zero. This fault is configurable.
			uint16_t reserved2 : 6;
			
		} __attribute__((__packed__));
		
		void formatf() const { ::formatf("UsageFaultStatusRegister: all=0x%.4X; UnDefInstr=%c, InvStateESPR=%c, InvPC=%c, NoCP=%c, UnAligned=%c, DivByZero=%c", all, UnDefInstr?'Y':'N', InvStateESPR?'Y':'N', InvPC?'Y':'N', NoCP?'Y':'N', UnAligned?'Y':'N', DivByZero?'Y':'N'); }
			
	} __attribute__((__packed__));
	
	union BusFaultStatusRegister
	{
		// This register is a 1 byte register which summarizes faults related to instruction prefetch or memory access failures.
		
		// Imprecise Bus Error Debug Tips
		// Imprecise errors are one of the hardest classes of faults to debug. They result asynchronously to instruction execution flow. This means the registers stacked on exception entry will not point to the code that caused the exception.
		// Instruction fetches and data loads should always generate synchronous faults for Cortex-M devices and be precise. Conversely, store operations can generate asynchronous faults. This is because writes will sometimes be buffered prior to being flushed to prevent pipeline stalls so the program counter will advance before the actual data store completes.
		// When debugging an imprecise error, you will want to inspect the code around the area reported by the exception for a store that looks suspicious. If the MCU has support for the ARM Embedded Trace Macrocell (ETM), the history of recently executed instructions can be viewed by some debuggers3.
	
		// Auxiliary Control Register (ACTLR) - 0xE000E008
		// This register allows for some hardware optimizations or features to be disabled typically at the cost of overall performance or interrupt latency. The exact configuration options available are specific to the Cortex-M implementation being used.
		// For the Cortex M3 & Cortex M4 only, there is a trick to make all IMPRECISE accesses PRECISE by disabling any write buffering. This can be done by setting bit 1 (DISDEFWBUF) of the register to 1.
		// For the Cortex M7, there is no way to force all stores to be synchronous / precise.

		uint8_t all;
		
		struct
		{
			uint8_t IBusErr : 1; // 
			uint8_t PrecisErr : 1; // Indicates that the instruction which was executing prior to exception entry triggered the fault.
			uint8_t ImprecisErr : 1; // This flag is very important. It tells us whether or not the hardware was able to determine the exact location of the fault. We will explore some debug strategies when this flag is set in the next section and walk through a code exampe below.
			uint8_t UnStkErr : 1; //  Indicates that a fault occurred trying to return from an exception. This typically arises if the stack was corrupted while the exception was running or the stack pointer was changed and its contents were not initialized correctly.
			uint8_t StkErr : 1; //  Indicates that a fault occurred during exception entry. Both are situations where the hardware is automatically saving state on the stack. One way this error may occur is if the stack in use overflows off the valid RAM address range while trying to service an exception. We'll go over an example below.
			uint8_t LspErr : 1; // Indicates that a fault occurred during lazy state preservation. Both are situations where the hardware is automatically saving state on the stack. One way this error may occur is if the stack in use overflows off the valid RAM address range while trying to service an exception. We'll go over an example below.
			uint8_t BFARValid : 1; // Indicates that the Bus Fault Address Register (BFAR), a 32 bit register located at 0xE000ED38, holds the address which triggered the fault. We'll walk through an example using this info below.
			
		} __attribute__((__packed__));
		
		void formatf() const { ::formatf("BusFaultStatusRegister: all=0x%.2X; IBusErr=%c, PrecisErr=%c, ImprecisErr=%c, UnStkErr=%c, StkErr=%c, LspErr=%c, BFARValid=%c", all, IBusErr?'Y':'N', PrecisErr?'Y':'N', ImprecisErr?'Y':'N', UnStkErr?'Y':'N', StkErr?'Y':'N', LspErr?'Y':'N', BFARValid?'Y':'N'); }
			
	} __attribute__((__packed__));
	
	struct BusFaultAddressRegister
	{
		// The BFAR contains the address of the location that generated a BusFault. See the register summary in Table 4.12 for its attributes. The bit assignments are:
		// When an unaligned access faults the address in the BFAR is the one requested by the instruction, even if it is not the address of the fault.
		// Flags in the BFSR indicate the cause of the fault, and whether the value in the BFAR is valid. See BusFault Status Register.

		uint32_t all; // When the BFARVALID bit of the BFSR is set to 1, this field holds the address of the location that generated the BusFault
		
		void formatf() const { ::formatf("BusFaultAddressRegister: fault at 0x%.8lX", (unsigned long)all); }
			
	} __attribute__((__packed__));
	
	union MemManageFaultStatusRegister
	{
		// This register reports Memory Protection Unit faults.
		// Typically MPU faults will only trigger if the MPU has been configured and enabled by the firmware. However, there are a few memory access errors that will always result in a MemManage fault - such as trying to execute code from the system address range (0xExxx.xxxx).
		
		uint8_t all;
		
		struct
		{
			uint8_t IAccViol : 1; // Indicates that an attempt to execute an instruction triggered an MPU or Execute Never (XN) fault. 
			uint8_t DAccViol : 1; // Indicates that a data access triggered the MemManage fault.
			uint8_t reserved1 : 1;
			uint8_t MemUnStkErr : 1; // Indicates that a fault occurred while returning from an exception
			uint8_t MemStkErr : 1; // Indicates that a MemManage fault occurred during exception entry. For example, this could happen if an MPU region is being used to detect stack overflows.
			uint8_t MemLspErr : 1; //Indicates that a MemManage fault occurred during lazy state preservation. For example, this could happen if an MPU region is being used to detect stack overflows.
			uint8_t reserved2 : 1;
			uint8_t MMARValid : 1; // Indicates that the MemManage Fault Address Register (MMFAR), a 32 bit register located at 0xE000ED34, holds the address which triggered the MemManage fault.
			
		} __attribute__((__packed__));
		
		void formatf() const { ::formatf("MemManageFaultStatusRegister: all=0x%.2X; IAccViol=%c, DAccViol=%c, MemUnStkErr=%c, MemStkErr=%c, MemLspErr=%c, MMARValid=%c", all, IAccViol?'Y':'N', DAccViol?'Y':'N', MemUnStkErr?'Y':'N', MemStkErr?'Y':'N', MemLspErr?'Y':'N', MMARValid?'Y':'N'); }
			
	} __attribute__((__packed__));
	
	struct MemManageFaultAddressRegister
	{
		// The MMFAR contains the address of the location that generated a MemManage fault. See the register summary in Table 4.12 for its attributes. The bit assignments are:
		// When an unaligned access faults, the address is the actual address that faulted. Because a single read or write instruction can be split into multiple aligned accesses, the fault address can be any address in the range of the requested access size.
		// Flags in the MMFSR indicate the cause of the fault, and whether the value in the MMFAR is valid. See MemManage Fault Status Register.
		
		uint32_t all; // When the MMARVALID bit of the MMFSR is set to 1, this field holds the address of the location that generated the MemManage fault
		
		void formatf() const { ::formatf("MemManageFaultAddressRegister: fault at 0x%.8lX", (unsigned long)all); }
			
	} __attribute__((__packed__));

	
	union ConfigurableFaultStatusRegistersCFSR
	{
		uint32_t all;
		
		struct
		{
			MemManageFaultStatusRegister MMFSR;
			BusFaultStatusRegister BFSR;
			UsageFaultStatusRegister UFSR;
		} __attribute__((__packed__));
		
		void formatf() const 
		{ 
			::formatf("ConfigurableFaultStatusRegistersCFSR: all=0x%.8lX; ", (unsigned long)all); 
			MMFSR.formatf();
			::formatf("; ");
			BFSR.formatf();
			::formatf("; ");
			UFSR.formatf();
			//~ ::formatf("\n");
		}
			
	} __attribute__((__packed__));
	
	union HardFaultStatusRegister
	{
		// "HFSR": 0xE000ED2C: This registers explains the reason a HardFault exception was triggered.
		
		uint32_t all;
		
		struct
		{
			uint32_t reserved1 : 1;
			uint32_t VectTable : 1; // Indicates a fault occurred because of an issue reading from an address in the vector table. This is pretty atypical but could happen if there is a bad address in the vector table and an unexpected interrupt fires.
			uint32_t reserved2 : 28;
			uint32_t Forced : 1; // This means a configurable fault (i.e. the fault types we discussed in previous sections) was escalated to a HardFault, either because the configurable fault handler was not enabled or a fault occurred within the handler.
			uint32_t DebugEvt : 1; // Indicates that a debug event (i.e executing a breakpoint instruction) occurred while the debug subsystem was not enabled
			
		} __attribute__((__packed__));
		
		void formatf() const { ::formatf("HardFaultStatusRegister: all=0x%.8lX; VectTable=%c, Forced=%c, DebugEvt=%c", (unsigned long)all, VectTable?'Y':'N', Forced?'Y':'N', DebugEvt?'Y':'N'); }
			
	} __attribute__((__packed__));
	
	union AuxillaryControlRegister
	{
		// "ACTLR": 0xE000E008: 
		// This register allows for some hardware optimizations or features to be disabled typically at the cost of overall performance or interrupt latency. The exact configuration options available are specific to the Cortex-M implementation being used.
		// For the Cortex M3 & Cortex M4 only, there is a trick to make all IMPRECISE accesses PRECISE by disabling any write buffering. This can be done by setting bit 1 (DISDEFWBUF) of the register to 1.
		
		uint32_t all;
		
		struct
		{
			uint32_t DisMCycInt : 1; // When set to 1, disables interruption of load multiple and store multiple instructions. This increases the interrupt latency of the processor because any LDM or STM must complete before the processor can stack the current state and enter the interrupt handler.
			uint32_t DisDefWBuf : 1; // When set to 1, disables write buffer use during default memory map accesses. This causes all BusFaults to be precise BusFaults but decreases performance because any store to memory must complete before the processor can execute the next instruction. This bit only affects write buffers implemented in the Cortex-M3 processor.
			uint32_t DisITFold : 1; // When set to 1, disables IT folding. see About IT folding for more information.
			uint32_t reserved : 29;
			
		} __attribute__((__packed__));
		
		void formatf() const { ::formatf("AuxillaryControlRegister: all=0x%.8lX; DisDefWBuf=%c", (unsigned long)all, DisDefWBuf?'Y':'N'); }
			
	} __attribute__((__packed__));
	
	union ApplicationInterruptResetControlRegister
	{
		// "AIRCR": 0xE000ED0C: 
		// https://developer.arm.com/documentation/dui0552/a/cortex-m3-peripherals/system-control-block
		// This register allows for some hardware optimizations or features to be disabled typically at the cost of overall performance or interrupt latency. The exact configuration options available are specific to the Cortex-M implementation being used.
		// For the Cortex M3 & Cortex M4 only, there is a trick to make all IMPRECISE accesses PRECISE by disabling any write buffering. This can be done by setting bit 1 (DISDEFWBUF) of the register to 1.
		
		uint32_t all;
		
		struct
		{
			uint32_t VectReset : 1; // Reserved for Debug use. This bit reads as 0. When writing to the register you must write 0 to this bit, otherwise behavior is Unpredictable.
			uint32_t VectCTClrActive : 1; // Reserved for Debug use. This bit reads as 0. When writing to the register you must write 0 to this bit, otherwise behavior is Unpredictable.
			uint32_t SysResetReq : 1; // System reset request bit is implementation defined: 0 = no system reset request; 1 = asserts a signal to the outer system that requests a reset. This is intended to force a large system reset of all major components except for debug. This bit reads as 0.
			uint32_t reserved1 : 5;
			uint32_t PriGroup : 3; // Interrupt priority grouping field is implementation defined. This field determines the split of group priority from subpriority, see Binary point.
			uint32_t reserved2 : 4;
			uint32_t Endianness : 1; // Data endianness bit is implementation defined: 0 = Little-endian, 1 = Big-endian.
			uint32_t VectKey : 3; // Register key: Reads as 0xFA05; on writes, write 0x5FA to VECTKEY, otherwise the write is ignored.
			
		} __attribute__((__packed__));
		
		ApplicationInterruptResetControlRegister(uint32_t Key, uint32_t SysReset) : SysResetReq(SysReset), VectKey(Key)
		{ }
		
		void formatf() const { ::formatf("ApplicationInterruptResetControlRegister: all=0x%.8lX", (unsigned long)all); }
			
	} __attribute__((__packed__));
	
	static const uint32_t ApplicationInterruptResetControlRegisterVectKey = 0x000005FAUL;
	
	union ConfigurationAndControlRegister
	{
		// "CCR": 0xE000ED14: 
		// default: 0x00000200
		// https://support.arm.com/documentation/dui0552/a/cortex-m3-peripherals/system-control-block/configuration-and-control-register?lang=en
		// The CCR controls entry to Thread mode and enables:
		// the handlers for NMI, hard fault and faults escalated by FAULTMASK to ignore BusFaults
		// trapping of divide by zero and unaligned accesses
		// access to the STIR by unprivileged software, see Software Trigger Interrupt Register.

		uint32_t all;
		
		struct
		{
			uint32_t NonBaseThreadEnA : 1; // [0] Indicates how the processor enters Thread mode: 0 = processor can enter Thread mode only when no exception is active; 1 = processor can enter Thread mode from any level under the control of an EXC_RETURN value, see Exception return.
			uint32_t UserSetMPend : 1; // [1] Enables unprivileged software access to the STIR, see Software Trigger Interrupt Register: 0 = disable1 = enable.
			uint32_t reserved1 : 1; // [2]
			uint32_t UnAlignedTrap : 1; // [3] Enables unaligned access traps: 0 = do not trap unaligned halfword and word accesses1 = trap unaligned halfword and word accesses; If this bit is set to 1, an unaligned access generates a UsageFault.; Unaligned LDM, STM, LDRD, and STRD instructions always fault irrespective of whether UNALIGN_TRP is set to 1.
			uint32_t DivZeroTrap : 1; // [4] Enables faulting or halting when the processor executes an SDIV or UDIV instruction with a divisor of 0: 0 = do not trap divide by 0; 1 = trap divide by 0; When this bit is set to 0, a divide by zero returns a quotient of 0.
			uint32_t reserved2 : 3; // [5:7]
			uint32_t BusFaultHandleNMIGn : 1; // [8] Enables handlers with priority -1 or -2 to ignore data BusFaults caused by load and store instructions. This applies to the hard fault, NMI, and FAULTMASK escalated handlers: 0 = data bus faults caused by load and store instructions cause a lock-up; 1 = handlers running at priority -1 and -2 ignore data bus faults caused by load and store instructions.; Set this bit to 1 only when the handler and its data are in absolutely safe memory. The normal use of this bit is to probe system devices and bridges to detect control path problems and fix them.
			uint32_t StackAlign : 1; // [9] Indicates stack alignment on exception entry: 0 = 4-byte aligned1 = 8-byte aligned; On exception entry, the processor uses bit[9] of the stacked PSR to indicate the stack alignment. On return from the exception it uses this stacked bit to restore the correct stack alignment.
			//bits 10:31 reserved...
			
		} __attribute__((__packed__));
		
		ConfigurationAndControlRegister() : all(0)
		{ }
		
		void formatf() const { ::formatf("ConfigurationAndControlRegister: all=0x%.8lX", (unsigned long)all); }
			
	} __attribute__((__packed__));

	struct ContextStateFrame
	{
		// a C struct to represent the register stacking upon a fault:

		uint32_t r0;
		uint32_t r1;
		uint32_t r2;
		uint32_t r3;
		uint32_t r12;
		uint32_t lr;
		uint32_t pc_return_addr;
		uint32_t xpsr;
		
		void formatf() const { ::formatf("ContextStateFrame: r0=0x%.8lX, r1=0x%.8lX, r2=0x%.8lX, r3=0x%.8lX, r12=0x%.8lX, lr=0x%.8lX, pc_return_addr=0x%.8lX, xpsr=0x%.8lX", (unsigned long)r0, (unsigned long)r1, (unsigned long)r2, (unsigned long)r3, (unsigned long)r12, (unsigned long)lr, (unsigned long)pc_return_addr, (unsigned long)xpsr); }
		
	} __attribute__((__packed__));

	//r/o:
	static const UsageFaultStatusRegister* UFSR __attribute__((__used__)) = reinterpret_cast<const UsageFaultStatusRegister*>(0xE000ED2AUL);
	static const BusFaultStatusRegister* BFSR __attribute__((__used__)) = reinterpret_cast<const BusFaultStatusRegister*>(0xE000ED29UL);
	static const BusFaultAddressRegister* BFAR __attribute__((__used__)) = reinterpret_cast<const BusFaultAddressRegister*>(0xE000ED38UL);
	static const MemManageFaultStatusRegister* MMFSR __attribute__((__used__)) = reinterpret_cast<const MemManageFaultStatusRegister*>(0xE000ED28UL);
	static const MemManageFaultAddressRegister* MMFAR __attribute__((__used__)) = reinterpret_cast<const MemManageFaultAddressRegister*>(0xE000ED34UL);
	static const ConfigurableFaultStatusRegistersCFSR* CFSR __attribute__((__used__)) = reinterpret_cast<const ConfigurableFaultStatusRegistersCFSR*>(0xE000ED28UL);
	static const HardFaultStatusRegister* HFSR __attribute__((__used__)) = reinterpret_cast<const HardFaultStatusRegister*>(0xE000ED2CUL);
	
	//r/w:
	static AuxillaryControlRegister* ACTLR __attribute__((__used__)) = reinterpret_cast<AuxillaryControlRegister*>(0xE000E008);
	static ApplicationInterruptResetControlRegister* AIRCR __attribute__((__used__)) = reinterpret_cast<ApplicationInterruptResetControlRegister*>(0xE000ED0C);
	static ConfigurationAndControlRegister* CCR __attribute__((__used__)) = reinterpret_cast<ConfigurationAndControlRegister*>(0xE000ED14);
	
//~ };
