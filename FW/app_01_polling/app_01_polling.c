

#include <stdint.h>
#include "system.h"
#include <stdio.h>

#define WAIT_UNITL_FALSE(x) while((x)){}
#define WAIT_UNITL_TRUE(x) while(!(x)){}

typedef struct {
	// reg 0-7
	uint32_t sw_led_unpacked[8];
	// reg 8
	unsigned sw_led_packed : 8;
	unsigned               : 24;
	// reg 9
	unsigned sw_changed    :  8;
	unsigned               : 24;
	// reg 10
	unsigned sw_set_leds   :  1;
	unsigned               : 31;
	// reg 11
	uint32_t invert_leds;
	uint32_t babadeda[4];
} bf_pio;
#define pio (*((volatile bf_pio*)SW_AND_LED_PIO_BASE))

static volatile uint32_t* digits = (volatile uint32_t*)TIME_MUXED_7SEGM_BASE;
static volatile uint32_t* timer = (volatile uint32_t*)TIMER_BASE;

int main() {
	pio.sw_led_packed = 0x81; // For debugging purposes.

	uint8_t cnt = 0;
	pio.sw_led_packed = cnt;

	timer[1] = 12000000; // modulo.
	timer[2] = 0; // Start it.


	while(1){
		///////////////////
		// Read inputs.

		// Poll wrapped flag.
		WAIT_UNITL_TRUE(timer[2] & (1 << 3));
		// Clear wrapped flag
		timer[2] &= ~(1 << 3);

		///////////////////
		// Calculate state.

		cnt++;

		///////////////////
		// Write outputs.
		pio.sw_led_packed = cnt;
	}

	return 0;
}
