//
///           University of Arizona
///           Steward Observatory
///           UASAL - UA Space Astrophysics Labratory
///           CAAO - Center for Astronomical Adaptive Optics
///           MagAOX
//

#pragma once
#include <stdint.h>

#include "format/formatf.h"

union UartStatusRegister
{
    uint32_t all;
    struct 
    {
        uint32_t RxFifoEmpty : 1;
        uint32_t RxFifoFull : 1;
        uint32_t TxFifoEmpty : 1;
        uint32_t TxFifoFull : 1;
		uint32_t reserved1 : 4;
		uint32_t RxFifoCount : 10;
		uint32_t TxFifoCount : 10;
		uint32_t reserved2 : 4;

    } __attribute__((__packed__));

    UartStatusRegister() { all = 0; }
	UartStatusRegister(const uint32_t& a) { all = a; }
	UartStatusRegister(const uint32_t* a) { all = *a; }

    //~ void formatf() const { ::formatf("UartStatusRegister: RxE:%c, RxF:%c, TxE:%c, TxF:%c, RxC:%u, TxC:%u", RxFifoEmpty?'Y':'N', RxFifoFull?'Y':'N', TxFifoEmpty?'Y':'N', TxFifoFull?'Y':'N', RxFifoCount + (RxFifoCountHi << 8), TxFifoCount + (TxFifoCountHi << 8)); }
	void formatf() const { ::formatf("UartStatusRegister: RxE:%c, RxF:%c, TxE:%c, TxF:%c, RxC:%lu, TxC:%lu", RxFifoEmpty?'Y':'N', RxFifoFull?'Y':'N', TxFifoEmpty?'Y':'N', TxFifoFull?'Y':'N', RxFifoCount, TxFifoCount); }

} __attribute__((__packed__));

//EOF
