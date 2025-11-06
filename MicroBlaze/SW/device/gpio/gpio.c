/*
 * gpio.c
 *
 *  Created on: 2025. 11. 4.
 *      Author: Jiyun
 */
#include "gpio.h"

void GPIO_Init(GPIO_TypeDef *gpio, uint8_t dir)
{
	gpio->CR = dir;
}

void GPIO_Write(GPIO_TypeDef *gpio, uint8_t data)
{
	gpio->ODR = data;
}

uint8_t GPIO_Read(GPIO_TypeDef *gpio)
{
	return gpio->IDR;
}

void GPIO_Set(GPIO_TypeDef *gpio, uint8_t pinNum)
{
	gpio->ODR |= (1<<pinNum) ;
}

void GPIO_Reset(GPIO_TypeDef *gpio, uint8_t pinNum)
{
	gpio->ODR &= ~(1<<pinNum);
}

void GPIO_Toggle(GPIO_TypeDef *gpio, uint8_t pinNum)
{
	gpio->ODR ^= (1<<pinNum);
}

int GPIO_ReadPin(GPIO_TypeDef *gpio, uint8_t pinNum)
{
	if (!(gpio->IDR & (1<<pinNum)))	return 0;
	else							return 1;
}
