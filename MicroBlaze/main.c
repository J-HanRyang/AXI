#include "xil_printf.h"
#include "driver/common/millis.h"
#include "ap/ap.h"

int main()
{
	print("Hello World!\n");
	xil_printf("Hi!\n");

	ap_main();

	return 0;
}
