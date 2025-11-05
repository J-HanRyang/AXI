/*
 * upCounter.c
 *
 *  Created on: 2025. 11. 5.
 *      Author: kccistc
 */


#include "../Counter/Counter.h"

enum {
	STOP,
	UP,
	DOWN,
	CLEAR
};

int CounterState = STOP;
int counter = 0;

// Led
hLed upLed;
hLed downLed;

// Btn
hBtn btnStop;
hBtn btnUpCount;
hBtn btnDownCount;
hBtn btnClear;

void initCounter()
{
	CounterState = STOP;
	counter = 0;

	FND_Init();

	LED_Init(&upLed, LED_GPIO, LED_1);
	LED_Init(&downLed, LED_GPIO, LED_2);

	BTN_Init(&btnUpCount, BTN_GPIO, BTN_U);
	BTN_Init(&btnStop, BTN_GPIO, BTN_R);
	BTN_Init(&btnClear, BTN_GPIO, BTN_L);
	BTN_Init(&btnDownCount, BTN_GPIO, BTN_D);
}

void exeCounter()
{
	switch (CounterState)
	{
	case STOP :
		if (BTN_getState(&btnUpCount) == ACT_PUSHED)		CounterState = UP;
		else if (BTN_getState(&btnDownCount) == ACT_PUSHED)	CounterState = DOWN;
		else if (BTN_getState(&btnClear) == ACT_PUSHED)		CounterState = CLEAR;
		break;

	case UP :
		runUpCounter();
		if (BTN_getState(&btnStop) == ACT_PUSHED)			CounterState = STOP;
		else if (BTN_getState(&btnDownCount) == ACT_PUSHED) CounterState = DOWN;
		break;

	case DOWN :
		runDownCounter();
		if (BTN_getState(&btnStop) == ACT_PUSHED)			CounterState = STOP;
		else if (BTN_getState(&btnUpCount) == ACT_PUSHED) 	CounterState = UP;
		break;

	case CLEAR :
		clearCounter();
		CounterState = STOP;
		break;
	}
}

void runUpCounter()
{
	static uint32_t prevTime = 0;
	uint32_t curTime = millis();
	if (curTime - prevTime < 100) return;
	prevTime = curTime;

	if (counter >= 9999)	counter = 0;
	else counter++;

	FND_SetNumber(counter);

	LED_Off(&downLed);
	LED_Toggle(&upLed);
}

void runDownCounter()
{
	static uint32_t prevTime = 0;
	uint32_t curTime = millis();
	if (curTime - prevTime < 100) return;
	prevTime = curTime;

	if (counter <= 0)	counter = 9999;
	else counter--;

	FND_SetNumber(counter);

	LED_Toggle(&downLed);
	LED_Off(&upLed);
}

void clearCounter()
{
	counter = 0;
	FND_SetNumber(counter);
}
