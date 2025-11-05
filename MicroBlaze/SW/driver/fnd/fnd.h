/*
 * fnd.h
 *
 *  Created on: 2025. 11. 4.
 *      Author: kccistc
 */

#ifndef SRC_DRIVER_FND_FND_H_
#define SRC_DRIVER_FND_FND_H_

#include "../../device/gpio/gpio.h"

typedef struct {
	GPIO_TypeDef *gpio_seg;
	GPIO_TypeDef *gpio_com;
	int digit_1;
	int digit_10;
	int digit_100;
	int digit_1000;
}hFnd;

void FND_Init();
void FND_DispNumber();
void FND_AllOff();
void FND_SelDigit(int digit);
void FND_ShowDigit(int digit);
void FND_SetNumber(int number);
int FND_GetNumber();

#endif /* SRC_DRIVER_FND_FND_H_ */
