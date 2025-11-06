/*
 * ap.h
 *
 *  Created on: 2025. 11. 4.
 *      Author: Jiyun
 */

#ifndef SRC_AP_AP_H_
#define SRC_AP_AP_H_

#include "../driver/led/led.h"
#include "../driver/fnd/fnd.h"
#include "../driver/btn/btn.h"
#include "../driver/common/millis.h"
#include "counter/counter.h"
#include "powerInd/powerInd.h"

void ap_main();
void mTimeCounter();
void millisCounter();
void ISR();

#endif /* SRC_AP_AP_H_ */
