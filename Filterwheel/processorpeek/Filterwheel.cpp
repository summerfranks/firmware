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

#include "cgraph/CGraphFWHardwareInterface.hpp"

#include "format/formatf.h"

#include "Delay.h"

#include "FilterWheel.hpp"

uint32_t FWPosition = (uint32_t)-1; //Which filter do we believe we are currently at? Start invalid so we initialize on first request

int16_t ValidatedFWHomeStep()
{
	//Our final best answer:
	int16_t HomeStep = 0;
	
	//Where does each sensor think home was at?
	CGraphFWPositionStepRegister HomeA = FW->PosDetHomeA;
	CGraphFWPositionStepRegister HomeB = FW->PosDetHomeB;
	
	formatf("\nESC-FW: ValidatedFWHomeStep precorrected: ");
	HomeA.formatf();
	formatf(";");
	HomeB.formatf();
	
	//If on & off both zero, they've been reset
	bool AValid = (HomeA.OnStep != 0) && (HomeA.OffStep != 0);
	bool BValid = (HomeB.OnStep != 0) && (HomeB.OffStep != 0);
	
	//Also if they match it's not real
	if (HomeA.OnStep == HomeA.OffStep) { AValid = false; }
	if (HomeB.OnStep == HomeB.OffStep) { BValid = false; }
		
	//Correct for full revolutions:
	HomeA.OnStep %= MotorFullCircleSteps;
	HomeA.OffStep %= MotorFullCircleSteps;
	HomeB.OnStep %= MotorFullCircleSteps;
	HomeB.OffStep %= MotorFullCircleSteps;
	
	//Correct negatives
	if (HomeA.OnStep < 0) { HomeA.OnStep += MotorFullCircleSteps; }
	if (HomeA.OffStep < 0) { HomeA.OffStep += MotorFullCircleSteps; }
	if (HomeB.OnStep < 0) { HomeB.OnStep += MotorFullCircleSteps; }
	if (HomeB.OffStep < 0) { HomeB.OffStep += MotorFullCircleSteps; }
	
	//Correct splits/wrap-around
	if (abs((int)HomeA.OnStep - (int)HomeA.OffStep) > (MotorFullCircleSteps / 2)) { (HomeA.OnStep < HomeA.OffStep) ? HomeA.OnStep += MotorFullCircleSteps : HomeA.OffStep += MotorFullCircleSteps; }
	if (abs((int)HomeB.OnStep - (int)HomeB.OffStep) > (MotorFullCircleSteps / 2)) { (HomeB.OnStep < HomeB.OffStep) ? HomeB.OnStep += MotorFullCircleSteps : HomeB.OffStep += MotorFullCircleSteps; }
	
	//did that fail?
	if (abs((int)HomeA.OnStep - (int)HomeA.OffStep) > (MotorFullCircleSteps / 2)) { AValid = false; }
	if (abs((int)HomeB.OnStep - (int)HomeB.OffStep) > (MotorFullCircleSteps / 2)) { BValid = false; }
	
	formatf("\nESC-FW: ValidatedFWHomeStep post-corrected: ");
	HomeA.formatf();
	formatf(";");
	HomeB.formatf();
		
	//Pick the good one or average them
	if (AValid) { HomeStep = HomeA.MidStep(); }
	if (BValid) { HomeStep += HomeB.MidStep(); }
	if (AValid && BValid) { HomeStep /= 2; }
	
	return(HomeStep);
}

void FWHome()
{
	size_t i = 0;
	
	//Turn things on
	CGraphFWHardwareControlRegister HCR;
	HCR.PosLedsEnA = 1;
    HCR.PosLedsEnB = 1;
	HCR.MotorEnable = 1;
	FW->ControlRegister = HCR.all;		
	
	//stabilize lights & sensors
	delayms(SensorPowerOnDelayMs);

	//Try to start with motor homed
	CGraphFWMotorControlStatusRegister MCSR;
	MCSR = FW->MotorControlStatus;
	MCSR.SeekStep = 0;
	FW->MotorControlStatus = MCSR.all;		
	
	//Wait for it to move
	for (i = 0; i < MotorFindHomeTimeoutMs; i++)
	{
		MCSR = FW->MotorControlStatus;
		if (MCSR.SeekStep == MCSR.CurrentStep) { break; }
		delayms(1);
	}

	//Clear step registers
	HCR.ResetSteps = 1;
	FW->ControlRegister = HCR.all;		
	HCR.ResetSteps = 0;
	FW->ControlRegister = HCR.all;		

	//Now go around all the way once
	MCSR.SeekStep = MotorFindHomeSteps;
	FW->MotorControlStatus = MCSR.all;		
	
	//Wait for it to move
	for (i = 0; i < MotorFindHomeTimeoutMs; i++)
	{
		MCSR = FW->MotorControlStatus;
		if (MCSR.SeekStep == MCSR.CurrentStep) { break; }
		delayms(1);
	}
	
	//Now send it to the real home we just passed on our way around.
	int16_t HomeStep = ValidatedFWHomeStep();
	
	//Backlash
	MCSR.SeekStep = HomeStep - BacklashSteps;
	FW->MotorControlStatus = MCSR.all;		
	
	formatf("\nESC-FW: Attempting to move motor to: %d.", HomeStep - BacklashSteps);
	
	//Wait for it to move
	for (i = 0; i < MotorFindHomeTimeoutMs; i++)
	{
		MCSR = FW->MotorControlStatus;
		if ((HomeStep - BacklashSteps) == MCSR.CurrentStep) { break; }
		delayms(1);
	}
	
	//Final resting place
	MCSR.SeekStep = HomeStep;
	FW->MotorControlStatus = MCSR.all;		
	
	formatf("\nESC-FW: Attempting to move motor to: %d.", HomeStep);
	
	//Wait for it to move
	for (i = 0; i < MotorFindHomeTimeoutMs; i++)
	{
		MCSR = FW->MotorControlStatus;
		if (HomeStep == MCSR.CurrentStep) { break; }
		delayms(1);
	}
	
	formatf("\nESC-FW: Move complete; motor reports: %d, i = %u.", MCSR.CurrentStep, i);
			
	//Clear step registers (by definition home [filter #1] is now zero)
	HCR.ResetSteps = 1;
	FW->ControlRegister = HCR.all;		
	HCR.ResetSteps = 0;
	FW->ControlRegister = HCR.all;		
	
	CGraphFWPositionStepRegister HomeA = FW->PosDetHomeA;
	CGraphFWPositionStepRegister HomeB = FW->PosDetHomeB;
	
	formatf("\nESC-FW: Step registers reset: ");
	HomeA.formatf();
	formatf(";");
	HomeB.formatf();
	
	//Lets assume that all worked and we're really at the home filter!
	FWPosition = 1;
	
	//Turn things off
	HCR.PosLedsEnA = 0;
    HCR.PosLedsEnB = 0;
	HCR.MotorEnable = 0;
	FW->ControlRegister = HCR.all;		
}

void FWSeekPosition(const uint32_t SeekPos)
{
	size_t i = 0;
	
	int16_t DestinationStep = 0; //Where we going in terms of motor units?
	
	//is the index bogus? We either need to initialize for the first time, or the user asked us to do a forced intializeaiton...
	if (SeekPos > FWMaxPosition) { FWHome(); }
	
	//Already there?
	if (FWPosition == SeekPos) { return; }
		
	//Sun safe position? 
	if (0 == SeekPos)
	{
		DestinationStep = MotorSunSafeStep;
	}
	else
	{
		DestinationStep = (MotorFullCircleSteps / FWMaxPosition) * (SeekPos - 1);
	}
	
	//Turn things on
	CGraphFWHardwareControlRegister HCR;
	HCR.PosLedsEnA = 1;
    HCR.PosLedsEnB = 1;
	HCR.MotorEnable = 1;
	FW->ControlRegister = HCR.all;		
	
	//stabilize lights & sensors
	delayms(SensorPowerOnDelayMs);

	//Where we at?
	CGraphFWMotorControlStatusRegister MCSR;
	MCSR = FW->MotorControlStatus;
		
	//Backlash
	formatf("\nESC-FW: Attempting to move motor to: %d.", DestinationStep - BacklashSteps);
	MCSR.SeekStep = DestinationStep - BacklashSteps;
	FW->MotorControlStatus = MCSR.all;		
	
	//Wait for it to move
	for (i = 0; i < MotorFindHomeTimeoutMs; i++)
	{
		MCSR = FW->MotorControlStatus;
		if ((DestinationStep - BacklashSteps) == MCSR.CurrentStep) { break; }
		delayms(1);
	}	
	
	//Final resting place
	formatf("\nESC-FW: Attempting to move motor to: %d.", DestinationStep);
	MCSR.SeekStep = DestinationStep;
	FW->MotorControlStatus = MCSR.all;		

	//Wait for it to move
	for (i = 0; i < MotorFindHomeTimeoutMs; i++)
	{
		MCSR = FW->MotorControlStatus;
		if (DestinationStep == MCSR.CurrentStep) { break; }
		delayms(1);
	}	

	formatf("\nESC-FW: Move complete; motor reports: %d, i = %u.", MCSR.CurrentStep, i);
	
	//Ok, let's assume we are where we think we are now!
	FWPosition = SeekPos;
	
	//Turn things off
	HCR.PosLedsEnA = 0;
    HCR.PosLedsEnB = 0;
	HCR.MotorEnable = 0;
	FW->ControlRegister = HCR.all;		
}

bool ValidateFWPosition()
{
	//is the index bogus? We either need to initialize for the first time, or the user asked us to do a forced intializeaiton
	if (FWPosition > FWMaxPosition) { FWHome(); }
		
	//Get the motor position
	CGraphFWMotorControlStatusRegister MCSR;
	MCSR = FW->MotorControlStatus;
	
	//If we're moving, just let it finish
	if (MCSR.SeekStep != MCSR.CurrentStep) { return(true); }
	
	formatf("\nESC-FW: MoveValidateFWPostition(%u): Motor is at: %u; ", FWPosition, MCSR.CurrentStep);
	
	//If we're in the sun safe position, the lights are invalid, as long at the motor is in approximately the right location it's ok
	if (0 == FWPosition)
	{
		if ( (MCSR.CurrentStep > (MotorSunSafeStep - 2)) && (MCSR.CurrentStep < (MotorSunSafeStep + 2)) ) { return(true); }
		return(false);
	}

	//All other positions, the lights better match where we're at!

	//Turn things on
	CGraphFWHardwareControlRegister HCR;
	HCR.PosLedsEnA = 1;
    HCR.PosLedsEnB = 1;
	HCR.MotorEnable = 0;
	FW->ControlRegister = HCR.all;		
	
	//stabilize lights & sensors
	delayms(SensorPowerOnDelayMs);
	
	//Get the lights
	CGraphFWPositionSenseRegister PSR;
	PSR = FW->PositionSensors;
	
	formatf("; ");
	PSR.formatf();	
	
	//"Home" Light Position - Filter #1
	bool Lights1A = ( (PSR.PosSenseHomeA == 0) & (PSR.PosSenseBit0A == 1) & (PSR.PosSenseBit1A == 1) & (PSR.PosSenseBit2A == 1) );
	bool Lights1B = ( (PSR.PosSenseHomeB == 0) & (PSR.PosSenseBit0B == 1) & (PSR.PosSenseBit1B == 1) & (PSR.PosSenseBit2B == 1) );

	//"1" Light Position - Filter #2
	bool Lights2A = ( (PSR.PosSenseHomeA == 1) & (PSR.PosSenseBit0A == 0) & (PSR.PosSenseBit1A == 1) & (PSR.PosSenseBit2A == 1) );
	bool Lights2B = ( (PSR.PosSenseHomeB == 1) & (PSR.PosSenseBit0B == 0) & (PSR.PosSenseBit1B == 1) & (PSR.PosSenseBit2B == 1) );
	
	//"2" Light Position - Filter #3
	bool Lights3A = ( (PSR.PosSenseHomeA == 1) & (PSR.PosSenseBit0A == 1) & (PSR.PosSenseBit1A == 0) & (PSR.PosSenseBit2A == 1) );
	bool Lights3B = ( (PSR.PosSenseHomeB == 1) & (PSR.PosSenseBit0B == 1) & (PSR.PosSenseBit1B == 0) & (PSR.PosSenseBit2B == 1) );
	
	//"3" Light Position - Filter #4
	bool Lights4A = ( (PSR.PosSenseHomeA == 1) & (PSR.PosSenseBit0A == 0) & (PSR.PosSenseBit1A == 0) & (PSR.PosSenseBit2A == 1) );
	bool Lights4B = ( (PSR.PosSenseHomeB == 1) & (PSR.PosSenseBit0B == 0) & (PSR.PosSenseBit1B == 0) & (PSR.PosSenseBit2B == 1) );
	
	//"4" Light Position - Filter #5
	bool Lights5A = ( (PSR.PosSenseHomeA == 1) & (PSR.PosSenseBit0A == 1) & (PSR.PosSenseBit1A == 1) & (PSR.PosSenseBit2A == 0) );
	bool Lights5B = ( (PSR.PosSenseHomeB == 1) & (PSR.PosSenseBit0B == 1) & (PSR.PosSenseBit1B == 1) & (PSR.PosSenseBit2B == 0) );
	
	//"5" Light Position - Filter #6
	bool Lights6A = ( (PSR.PosSenseHomeA == 1) & (PSR.PosSenseBit0A == 0) & (PSR.PosSenseBit1A == 1) & (PSR.PosSenseBit2A == 0) );
	bool Lights6B = ( (PSR.PosSenseHomeB == 1) & (PSR.PosSenseBit0B == 0) & (PSR.PosSenseBit1B == 1) & (PSR.PosSenseBit2B == 0) );
	
	//"6" Light Position - Filter #7
	bool Lights7A = ( (PSR.PosSenseHomeA == 1) & (PSR.PosSenseBit0A == 1) & (PSR.PosSenseBit1A == 0) & (PSR.PosSenseBit2A == 0) );
	bool Lights7B = ( (PSR.PosSenseHomeB == 1) & (PSR.PosSenseBit0B == 1) & (PSR.PosSenseBit1B == 0) & (PSR.PosSenseBit2B == 0) );
	
	//"7" Light Position - Filter #8
	bool Lights8A = ( (PSR.PosSenseHomeA == 1) & (PSR.PosSenseBit0A == 0) & (PSR.PosSenseBit1A == 0) & (PSR.PosSenseBit2A == 0) );
	bool Lights8B = ( (PSR.PosSenseHomeB == 1) & (PSR.PosSenseBit0B == 0) & (PSR.PosSenseBit1B == 0) & (PSR.PosSenseBit2B == 0) );

	//So do the lights match or not?
	switch(FWPosition)
	{
		case 1: { return(Lights1A | Lights1B); }
		case 2: { return(Lights2A | Lights2B); }
		case 3: { return(Lights3A | Lights3B); }
		case 4: { return(Lights4A | Lights4B); }
		case 5: { return(Lights5A | Lights5B); }
		case 6: { return(Lights6A | Lights6B); }
		case 7: { return(Lights7A | Lights7B); }
		case 8: { return(Lights8A | Lights8B); }
	}
	
	return(false);
}

//EOF
