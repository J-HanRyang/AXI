 /*
 * ap.c
 *
 *  Created on: 2025. 11. 4.
 *      Author: kccistc
 */

#include "ap.h"
#include "sleep.h"
#include "powerInd/powerInd.h"

hBtn upBtn;
hLed led0;

void millisCounter();
void ISR();

void ap_main()
{
	FND_Init();
	initPowerInd();
	initCounter();

	while(1)
	{
		dispPowerInd();
		exeCounter();

		ISR();
	}
}

void millisCounter()
{
	incMillis();
	usleep(1000);
}

void ISR()
{
	millisCounter();
	FND_DispNumber();
}
