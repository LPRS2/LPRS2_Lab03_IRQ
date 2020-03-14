

#include <stdint.h>
#include "system.h"

void busy_wait(int ms){
	//TODO
}

int main() {
	volatile uint32_t* pio = (volatile uint32_t*)SW_AND_LED_PIO_BASE;

	uint8_t reset; // SW[0]
	uint8_t pause; // SW[1]
	uint8_t moduo; // SW[7:2]

	uint8_t cnt;


	while(1) { // Infinite loop.
		// Read inputs.
		//TODO Прочитати SW у reset, pause, moduo.

		// Calculate state.
		//TODO Срачунати стање cnt.

		// Write outputs.
		//TODO Уписати резултат у LED.
	}

	return 0;
}
