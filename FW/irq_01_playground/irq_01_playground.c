

#include <stdint.h>
#include "system.h"
#include <stdio.h>

#define WAIT_UNITL_0(x) while(x != 0){}
#define WAIT_UNITL_1(x) while(x != 1){}

int main() {
	volatile uint32_t* pio = (volatile uint32_t*)SW_AND_LED_PIO_BASE;

	printf("sizeof(pio) = %d\n", sizeof(pio));
	printf("sizeof(*pio) = %d\n", sizeof(*pio));
	printf("pio = 0x%08x\n", pio);
	printf("\n");

	pio[0] = 1;
	printf("pio[0] = 0x%08x\n", pio[0]);

	pio[0] = 0;
	printf("pio[0] = 0x%08x\n", pio[0]);
	printf("\n");

	//TODO Faster.
	for(int i = 0; i < 8; i++){
		pio[i] = pio[i];
	}

	printf("pio[9] = 0x%08x\n", pio[9]);
	WAIT_UNITL_0(pio[0]);
	WAIT_UNITL_1(pio[0]);
	WAIT_UNITL_0(pio[0]);
	printf("pio[9] = 0x%08x\n", pio[9]);
	printf("pio[9] = 0x%08x\n", pio[9]);
	printf("\n");


	pio[11] = 0x10;


	//TODO Print all regs.
	//TODO All LEDs to 1's.

	return 0;
}
