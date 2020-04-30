
#include <stdint.h>
#include "system.h"
#include "sys/alt_irq.h"
#include <stdio.h>

#define WAIT_UNITL_FALSE(x) while((x)){}
#define WAIT_UNITL_TRUE(x) while(!(x)){}

#define pio_p32 ((volatile uint32_t*)SW_AND_LED_PIO_BASE)
#define digits_p32 ((volatile uint32_t*)TIME_MUXED_7SEGM_BASE)
#define timer_p32 ((volatile uint32_t*)TIMER_BASE)

#define TIMER_CNT 0
#define TIMER_MODULO 1
#define TIMER_CTRL_STAT 2

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

static void timer_isr(void * context) {
	static uint8_t x = 0;
	x++;
	pio.sw_led_packed = x;
}

int main() {
	pio.sw_led_packed = 0x81; // For debugging purposes.

	// Init IRQ.
	alt_ic_isr_register(
		TIMER_IRQ_INTERRUPT_CONTROLLER_ID, //alt_u32 ic_id
		TIMER_IRQ, //alt_u32 irq
		timer_isr, //alt_isr_func isr
		NULL, //void *isr_context
		NULL //void *flags
	);


	timer_p32[TIMER_MODULO] = 12000000; // modulo.
	timer_p32[TIMER_CTRL_STAT] = 0; // Start it.

#if 1
	printf("timer_p32 cnt reg:\n");
	for(int i = 0; i < 10; i++){
		printf("%9d\n", (int)timer_p32[TIMER_CNT]);
	}
#endif

	return 0;
}
