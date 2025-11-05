/*
 * btn.h
 *
 *  Created on: 2025. 11. 5.
 *      Author: kccistc
 */

#ifndef SRC_DRIVER_BTN_BTN_H_
#define SRC_DRIVER_BTN_BTN_H_

#include "../../device/gpio/gpio.h"

#define BTN_GPIO	GPIOC
#define BTN_U		GPIO_PIN_0
#define BTN_L		GPIO_PIN_1
#define BTN_R		GPIO_PIN_2
#define BTN_D		GPIO_PIN_3

enum {
	RELEASED = 0,
	PUSHED
};

enum {
	ACT_PUSHED = 0,
	ACT_RELEASED,
	NO_ACT
};


typedef struct {
	GPIO_TypeDef *gpio;
	int pinNum;
	int prevState;
}hBtn;

void BTN_Init(hBtn *btn, GPIO_TypeDef *gpio, uint8_t punNum);
int BTN_getState(hBtn *btn);

#endif /* SRC_DRIVER_BTN_BTN_H_ */
