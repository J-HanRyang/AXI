/*
 * upCounter.h
 *
 *  Created on: 2025. 11. 5.
 *      Author: Jiyun
 */

#ifndef SRC_AP_COUNTER_COUNTER_H_
#define SRC_AP_COUNTER_COUNTER_H_

#include <stdint.h>
#include "../../driver/fnd/fnd.h"
#include "../../driver/led/led.h"
#include "../../driver/btn/btn.h"
#include "../../driver/common/millis.h"

void initCounter();
void exeCounter();
void runUpCounter();
void runDownCounter();
void clearCounter();


#endif /* SRC_AP_COUNTER_COUNTER_H_ */
