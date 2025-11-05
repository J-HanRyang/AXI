/*
 * millis.h
 *
 *  Created on: 2025. 11. 5.
 *      Author: kccistc
 */

#ifndef SRC_DRIVER_COMMON_MILLIS_H_
#define SRC_DRIVER_COMMON_MILLIS_H_

#include <stdint.h>

void incMillis();
void decMillis();
uint32_t millis();
void clearMillis();
void setMillis(uint32_t t);

#endif /* SRC_DRIVER_COMMON_MILLIS_H_ */
