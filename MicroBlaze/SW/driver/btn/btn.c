/*
 * btn.c
 *
 *  Created on: 2025. 11. 5.
 *      Author: Jiyun
 */


#include "btn.h"

void BTN_Init(hBtn *btn, GPIO_TypeDef *gpio, uint8_t pinNum)
{
	int pinMode;

	btn->gpio = gpio;
	btn->pinNum = pinNum;
	btn->prevState = RELEASED;

	pinMode = btn->gpio->CR;
	pinMode &= ~(1<<pinNum);
	btn->gpio->CR = pinMode;
}

int BTN_getState(hBtn *btn)
{
	int curState = GPIO_ReadPin(btn->gpio, btn->pinNum);

	if ((curState == PUSHED) && (btn->prevState == RELEASED))
	{
		usleep(10000);
		btn->prevState = PUSHED;;
		return ACT_PUSHED;
	}
	else if ((curState == RELEASED) && (btn->prevState == PUSHED))
	{
		usleep(10000);
		btn->prevState = RELEASED;;
		return ACT_RELEASED;
	}
	return NO_ACT;
}
