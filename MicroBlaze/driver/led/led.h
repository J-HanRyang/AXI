/*
 * led.h
 *
 *  Created on: 2025. 11. 4.
 *      Author: Jiyun
 */

#ifndef SRC_DRIVER_LED_LED_H_
#define SRC_DRIVER_LED_LED_H_

#include "../../device/gpio/gpio.h"

#define LED_GPIO	GPIOB
#define LED_0		GPIO_PIN_4
#define LED_1 		GPIO_PIN_5
#define LED_2 		GPIO_PIN_6
#define LED_3 		GPIO_PIN_7


typedef struct {
	GPIO_TypeDef *gpio;
	int pinNum;
}hLed;

void LED_Init(hLed *pLed, GPIO_TypeDef *gpio, int pinNum);
void LED_On(hLed *pLed);
void LED_Off(hLed *pLed);
void LED_Toggle(hLed *pLed);

#endif /* SRC_DRIVER_LED_LED_H_ */
