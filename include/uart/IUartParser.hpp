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
#ifndef _IUartParser_H_
#define _IUartParser_H_

#include <stdint.h>
#include <stdio.h>
#include "uart/IUart.h"

class IUartParser
{
public:
	IUartParser(class IUart& pinout) : Pinout(pinout) { }
	virtual ~IUartParser() { }
	
	IUart& Pinout;

	virtual bool Process() = 0;
	
	void puts(const char* s, const size_t len)
	{
		for (size_t i = 0; i < len; i++)
		{
			if ('\0' == s[i]) { break; }
			
			Pinout.putcqq(s[i]);
		}
	}
};

#endif // _IUartParser_H_
