//
///           University of Arizona
///           Steward Observatory
///           UASAL - UA Space Astrophysics Labratory
///           CAAO - Center for Astronomical Adaptive Optics
///           MagAOX
//

#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <sys/types.h>
#include <algorithm>
#include <math.h>

#include "Delay.h"

#include "arm/BuildParameters.h"

#include "cgraph/CGraphPacket.hpp"

#include "cgraph/CGraphFSMHardwareInterface.hpp"
extern CGraphFSMHardwareInterface* volatile FSM;

#include "format/formatf.h"

#include "CmdTableAscii.hpp"

//~ #include "CmdTableBinary.hpp"

//~ #include "uart/BinaryUart.hpp"

#include "Uarts.hpp"

#include "MonitorAdc.hpp"
extern CGraphFSMMonitorAdc MonitorAdc;

bool BISTModeEnabled = false;
//~ bool BISTModeEnabled = true;
const int MaxLoops = 1024;

//Enable this if malloc problems occur (!!we shouldn't be using malloc, but c-libraries sometimes link it in!!)
//~ class MTracer
//~ {
//~ public:

//~ MTracer()
//~ {
//~ putenv("MALLOC_TRACE=/home/root/FSMTrace.txt");
//~ mtrace(); /* Starts the recording of memory allocations and releases */
//~ }
//~ } mtracer;

extern "C"
{	
	unsigned long long fclk_for_delay_loops = 102000000;

    void wooinit(void) __attribute__((constructor));

	//Does the current clib need this?
    void AtExit()
    {
        //~ mwTerm();
    }

	//Does the current clib need this?
    void mwOutFunc(int c)
    {
        putchar(c);
    }
};

bool Process()
{
    bool Bored = true;
	
	MonitorAdc.Process();
	
	ProcessAllUarts();
	
	//Enable this if we need to debug ascii and binary on the same uart (note: madness ensues!)
	//~ {
		//~ if (FPGAUartPinout0.dataready())
		//~ {
			//~ Bored = false;
			
			//~ char c = FPGAUartPinout0.getcqq();
			
			//~ UsbUartAscii.remoteputcqq(c);
			//~ UsbUartBinary.remoteputcqq(c);
		//~ }
		//~ if (UsbUartAscii.remotedataready()) { FPGAUartPinout0.putcqq(UsbUartAscii.remotegetcqq()); }
		//~ if (UsbUartBinary.remotedataready()) { FPGAUartPinout0.putcqq(UsbUartBinary.remotegetcqq()); }
	//~ }
	
    //~ if (FpgaUartParser3.Process()) { Bored = false; }    
	//~ if (FpgaUartParser2.Process()) { Bored = false; }    
	//~ if (FpgaUartParser1.Process()) { Bored = false; }    
	//~ //if (FpgaUartParser0.Process()) { Bored = false; }    
	//~ //if (FpgaUartParserUsb.Process()) { Bored = false; }    
	//~ //if (DbgUartUsb.Process()) { Bored = false; }    
    if (DbgUart485_0.Process()) { Bored = false; }
	
    return(Bored);
}

int main(int argc, char *argv[])
{	
	int loop = 0;
	unsigned long daca = 0;
	unsigned long dacb = 0;
	unsigned long dacc = 0;
	const double radius = 1.0;
	
    //Tell C lib (stdio.h) not to buffer output, so we can ditch all the fflush(stdout) calls...
    //~ setvbuf(stdout, NULL, _IONBF, 0);

    //~ if (argc > 2)

	FPGAUartPinout0.putcqq('\n');
	FPGAUartPinout0.putcqq('\n');
	FPGAUartPinout0.putcqq('\n');
	FPGAUartPinout0.putcqq('\n');
	FPGAUartPinout0.putcqq('\n');
	FPGAUartPinout0.putcqq('\n');
	FPGAUartPinout0.putcqq('\n');
	FPGAUartPinout0.putcqq('\n');
	FPGAUartPinout0.putcqq('\n');
	FPGAUartPinout0.putcqq('H');
	FPGAUartPinout0.putcqq('e');
	FPGAUartPinout0.putcqq('l');
	FPGAUartPinout0.putcqq('l');
	FPGAUartPinout0.putcqq('o');
	FPGAUartPinout0.putcqq(' ');
	FPGAUartPinout0.putcqq('E');
    FPGAUartPinout0.putcqq('S');
    FPGAUartPinout0.putcqq('C');
    FPGAUartPinout0.putcqq('-');
    FPGAUartPinout0.putcqq('F');
    FPGAUartPinout0.putcqq('S');
	FPGAUartPinout0.putcqq('M');
	FPGAUartPinout0.putcqq('\n');

	formatf("\n\nESC-FSM: v%s.b%s; Offset of ControlRegister: 0x%.2lX, expected: 0x%.2lX.", GITVERSION, BUILDNUM, (unsigned long)offsetof(CGraphFSMHardwareInterface, ControlRegister), 32UL);
	
	//~ ShowBuildParameters();

	//~ formatf("\nUartFifo3: 0x%.2lX, expected: 0x%.2lX.", (unsigned long)offsetof(CGraphFSMHardwareInterface, UartFifo3), 152UL);
	//~ formatf("\nOffset of FSM->ControlRegister: 0x%.2lX, expected: 0x%.2lX; size: %lu.", (unsigned long)offsetof(CGraphFSMHardwareInterface, ControlRegister), 32UL, sizeof(CGraphFSMHardwareControlRegister));
	//~ formatf("\nOffset of FSM->MonitorAdcSpiTransactionRegister: 0x%.2lX, expected: 0x%.2lX.", (unsigned long)offsetof(CGraphFSMHardwareInterface, MonitorAdcSpiTransactionRegister), 104UL);
	formatf("\nOffset of FSM->LatchAdcs: 0x%.2lX, expected: 0x%.2lX.", (unsigned long)offsetof(CGraphFSMHardwareInterface, LatchAdcs), 200UL);
	formatf("\nOffset of FSM->AdcAAccumulator: 0x%.2lX, expected: 0x%.2lX.", (unsigned long)offsetof(CGraphFSMHardwareInterface, AdcAAccumulator), 60UL);
	formatf("\nOffset of FSM->AdcBAccumulator: 0x%.2lX, expected: 0x%.2lX.", (unsigned long)offsetof(CGraphFSMHardwareInterface, AdcBAccumulator), 68UL);
	formatf("\nOffset of FSM->Uart0RxFifoPeekReadAddr: 0x%.2lX, expected: 0x%.2lX.", (unsigned long)offsetof(CGraphFSMHardwareInterface, Uart0RxFifoPeekReadAddr), 164UL);
	

	//~ DbgUartUsb.Init();
	DbgUart485_0.Init();

    //~ DbgUartUsb.SetEcho(false);
    DbgUart485_0.SetEcho(false);
	
	//~ MonitorAdc.SetMonitor(true);
	MonitorAdc.SetMonitor(false);
	MonitorAdc.Init();
	
	//~ uint8_t i = 0;
    while(true)
    {
		loop++;
		if (loop >= MaxLoops) { loop = 0; }
		
		Process();
		
		if (BISTModeEnabled)
		{
			//How are we testing Circuit Breakers & Faults?
			
			//How are we testing the A/B output drivers and D/A's?
			
			//Show current A/D values:
			{
				//Prepare for atomic read of samples (do as an 8-bit pointer so the processor doesn't crash !#@$%#!):
				*((uint8_t*)&(FSM->LatchAdcs)) = loop | 1;
				AdcAccumulator A, B, C, D;
				A.Samples = FSM->AdcAAccumulator;
				A.SetHiWord(FSM->AdcAAccumulatorHiandNumAccums);
				B.Samples = FSM->AdcBAccumulator;
				B.SetHiWord(FSM->AdcBAccumulatorHiandNumAccums);
				C.Samples = FSM->AdcCAccumulator;	
				C.SetHiWord(FSM->AdcCAccumulatorHiandNumAccums);
				
				double Av, Bv, Cv;
				Av = (4.096 * (double)A.Samples) / (8388608.0 * (double)A.NumAccums);
				Bv = (4.096 * (double)B.Samples) / (8388608.0 * (double)B.NumAccums);
				Cv = (4.096 * (double)C.Samples) / (8388608.0 * (double)C.NumAccums);
				formatf("\n\nBIST: ADCs: current values: Num: %5d, 0x%016llx, 0x%016llx, 0x%016llx, %+1.6lf, %+1.6lf, %+1.6lf\n", A.NumAccums, A.Samples, B.Samples, C.Samples, Av, Bv, Cv);
				A.formatf();
				B.formatf();
				C.formatf();
			}
			
			//Update the D/A's every so often
			if (0 == loop % 4)
			{
				FSM->DacASetpoint = daca;
				FSM->DacBSetpoint = dacb;
				FSM->DacCSetpoint = dacc;

				//~ unsigned long rba = FSM->DacASetpoint;
				//~ unsigned long rbb = FSM->DacBSetpoint;
				//~ unsigned long rbc = FSM->DacCSetpoint;
				
				double ang = (double)(loop % 60) * 6.0;
				double rada = (ang / 360.0) * 6.28;
				double radb = ((ang + 120) / 360.0) * 6.28;
				double radc = ((ang + 240) / 360.0) * 6.28;
				double carta = ((sin(rada) + 1.0) / 2.0) * radius;
				double cartb = ((sin(radb) + 1.0) / 2.0) * radius;
				double cartc = ((sin(radc) + 1.0) / 2.0) * radius;
				daca = (unsigned long)(carta * 0x0000FFFFUL);
				dacb = (unsigned long)(cartb * 0x0000FFFFUL);
				dacc = (unsigned long)(cartc * 0x0000FFFFUL);
				
				formatf("\n\nBIST: DACs: %lu, %lu, %lu", daca, dacb, dacc);
			}
			
			//Telmetry - this tests the power supplies voltage & current
			{
				formatf("\n\nBIST: Telemetery: ");
				
				size_t j = loop % 36;
				switch(j)
				{
					case 0: { formatf("IHV: %3.6lf V\n", MonitorAdc.GetIHV()); }
					case 1: { formatf("INV: %3.6lf V\n", MonitorAdc.GetINV()); }
					case 2: { formatf("I6V: %3.6lf V\n", MonitorAdc.GetI6V()); }
					case 3: { formatf("I3VD: %3.6lf V\n", MonitorAdc.GetI3VD()); }
					case 4: { formatf("I2VD: %3.6lf V\n", MonitorAdc.GetI2VD()); }
					case 5: { formatf("I1V: %3.6lf V\n", MonitorAdc.GetI1V()); }
					case 6: { formatf("StrainBP: %3.6lf V\n", MonitorAdc.GetStrainBP()); }
					case 7: { formatf("StrainBM: %3.6lf V\n", MonitorAdc.GetStrainBM()); }
					case 8: { formatf("StrainB: %3.6lf V\n", MonitorAdc.GetStrainB()); }
					case 9: { formatf("StrainDP: %3.6lf V\n", MonitorAdc.GetStrainDP()); }
					case 10: { formatf("StrainDM: %3.6lf V\n", MonitorAdc.GetStrainDM()); }
					case 11: { formatf("StrainD: %3.6lf V\n", MonitorAdc.GetStrainD()); }
					case 12: { formatf("StrainCM: %3.6lf V\n", MonitorAdc.GetStrainCM()); }
					case 13: { formatf("StrainCP: %3.6lf V\n", MonitorAdc.GetStrainCP()); }
					case 14: { formatf("StrainC: %3.6lf V\n", MonitorAdc.GetStrainC()); }
					case 15: { formatf("StrainAM: %3.6lf V\n", MonitorAdc.GetStrainAM()); }
					case 16: { formatf("StrainAP: %3.6lf V\n", MonitorAdc.GetStrainAP()); }
					case 17: { formatf("StrainA: %3.6lf V\n", MonitorAdc.GetStrainA()); }
					case 18: { formatf("P5VD: %3.6lf V\n", MonitorAdc.GetP5VD()); }
					case 19: { formatf("I2VA: %3.6lf V\n", MonitorAdc.GetI2VA()); }
					case 20: { formatf("Temp: %3.6lf V\n", MonitorAdc.GetTemp()); }
					case 21: { formatf("P3V3D: %3.6lf V\n", MonitorAdc.GetP3V3D()); }
					case 22: { formatf("P28V: %3.6lf V\n", MonitorAdc.GetP28V()); }
					case 23: { formatf("P2V2: %3.6lf V\n", MonitorAdc.GetP2V2()); }
					case 24: { formatf("P2V5D: %3.6lf V\n", MonitorAdc.GetP2V5D()); }
					case 25: { formatf("P1V2: %3.6lf V\n", MonitorAdc.GetP1V2()); }
					case 26: { formatf("P2V5A: %3.6lf V\n", MonitorAdc.GetP2V5A()); }
					case 27: { formatf("P4V3: %3.6lf V\n", MonitorAdc.GetP4V3()); }
					case 28: { formatf("I3VA: %3.6lf V\n", MonitorAdc.GetI3VA()); }
					case 29: { formatf("P3V3A: %3.6lf V\n", MonitorAdc.GetP3V3A()); }
					case 30: { formatf("P6V: %3.6lf V\n", MonitorAdc.GetP6V()); }
					case 31: { formatf("P5VA: %3.6lf V\n", MonitorAdc.GetP5VA()); }
					case 32: { formatf("LuxRads: %3.6lf V\n", MonitorAdc.GetLuxRads()); }
					case 33: { formatf("N18V: %3.6lf V\n", MonitorAdc.GetN18V()); }
					case 34: { formatf("N20V: %3.6lf V\n", MonitorAdc.GetN20V()); }
					case 35: { formatf("P125V: %3.6lf V\n", MonitorAdc.GetP125V()); }
					default : { }
				}
			}
		}
    }

    return(0);
}

//EOF
