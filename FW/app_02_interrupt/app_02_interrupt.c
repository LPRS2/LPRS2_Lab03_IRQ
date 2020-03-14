

#include <stdint.h>
#include "system.h"
#include "sys/alt_irq.h"
#include <stdio.h>

#define WAIT_UNITL_FALSE(x) while((x)){}
#define WAIT_UNITL_TRUE(x) while(!(x)){}

typedef struct {
	// reg 0
	unsigned sw0_led0 : 1;
	unsigned _res0 : 31;
	unsigned sw1_led1 : 1;
	unsigned _res1 : 31;
	unsigned sw2_led2 : 1;
	unsigned _res2 : 31;
	unsigned sw3_led3 : 1;
	unsigned _res3 : 31;
	unsigned sw4_led4 : 1;
	unsigned _res4 : 31;
	unsigned sw5_led5 : 1;
	unsigned _res5 : 31;
	unsigned sw6_led6 : 1;
	unsigned _res6 : 31;
	unsigned sw7_led7 : 1;
	unsigned _res7 : 31;
	// reg 8
	unsigned sw_led : 8;
	unsigned _res8 : 24;
	// reg 9
	unsigned sw_changed : 8;
	unsigned _res9 : 24;
	// reg 10
	unsigned sw_set_leds : 1;
	unsigned _res10 : 31;
	// reg 11
	uint32_t invert_leds;
	uint32_t babadeda0;
	uint32_t babadeda1;
	uint32_t babadeda2;
	uint32_t babadeda3;

} bf_pio;
#define pio (*((volatile bf_pio*)SW_AND_LED_PIO_BASE))

static volatile uint32_t* digits = (volatile uint32_t*)TIME_MUXED_7SEGM_BASE;
static volatile uint32_t* timer = (volatile uint32_t*)TIMER_BASE;

static void timer_isr(void * context, alt_u32 id) {
	static uint8_t x = 0;
	x++;
	pio.sw_led = x;
}

int main() {
	pio.sw_led = 0x81; // For debugging purposes.

	// Init IRQ.
	alt_ic_isr_register(
		TIMER_IRQ_INTERRUPT_CONTROLLER_ID, //alt_u32 ic_id
		TIMER_IRQ, //alt_u32 irq
		timer_isr, //alt_isr_func isr
		NULL, //void *isr_context
		NULL //void *flags
	);


	timer[1] = 12000000; // modulo.
	timer[2] = 0; // Start it.

#if 1
	printf("timer cnt reg:\n");
	for(int i = 0; i < 10; i++){
		printf("%9d\n", timer[0]);
	}
#endif

	return 0;
}
