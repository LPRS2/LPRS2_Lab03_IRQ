// Г32

#include <stdint.h>
#include "system.h"
#include "sys/alt_irq.h"
#include <stdio.h>

#define WAIT_UNITL_FALSE(x) while((x)){}
#define WAIT_UNITL_TRUE(x) while(!(x)){}

#define pio_p32 ((volatile uint32_t*)SW_AND_LED_PIO_BASE)
#define digits_p32 ((volatile uint32_t*)(TIME_MUXED_7SEGM_BASE+0x20))
#define timer_p32 ((volatile uint32_t*)(TIMER_BASE+0x20))

#define SEGM_0             1
#define SEGM_1             3
#define SEGM_2             2
#define SEGM_3             0
#define TIMER_CNT          0
#define TIMER_MODULO       3
#define TIMER_CTRL_STATUS  2
#define TIMER_MAGIC        1
#define TIMER_RESET_FLAG   3
#define TIMER_PAUSE_FLAG   0
#define TIMER_WRAP_FLAG    1
#define TIMER_WRAPPED_FLAG 2
#define TIMER_RESET        (TIMER_RESET_FLAG+4)
#define TIMER_PAUSE        (TIMER_PAUSE_FLAG+4)
#define TIMER_WRAP         (TIMER_WRAP_FLAG+4)
#define TIMER_WRAPPED      (TIMER_WRAPPED_FLAG+4)

#define SEGM_0 1
#define SEGM_1 3
#define SEGM_2 2
#define SEGM_3 0

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
	static uint8_t cnt = 0;
	
	///////////////////
	// Read inputs.
	
	///////////////////
	// Calculate state.
	
	cnt++;
	
	///////////////////
	// Write outputs.
	
	pio.sw_led_packed = cnt;
	digits_p32[SEGM_0] = cnt & 0xf;
	digits_p32[SEGM_1] = cnt>>4;
}

int main() {
	printf("TIMER_CNT         = 0x%08lx\n", timer_p32[TIMER_CNT]);
	printf("TIMER_MODULO      = 0x%08lx\n", timer_p32[TIMER_MODULO]);
	printf("TIMER_CTRL_STATUS = 0x%08lx\n", timer_p32[TIMER_CTRL_STATUS]);
	printf("TIMER_MAGIC       = 0x%08lx\n", timer_p32[TIMER_MAGIC]);
	printf("TIMER_RESET       = 0x%08lx\n", timer_p32[TIMER_RESET]);
	printf("TIMER_PAUSE       = 0x%08lx\n", timer_p32[TIMER_PAUSE]);
	printf("TIMER_WRAP        = 0x%08lx\n", timer_p32[TIMER_WRAP]);
	printf("TIMER_WRAPPED     = 0x%08lx\n", timer_p32[TIMER_WRAPPED]);

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
	timer_p32[TIMER_CTRL_STATUS] = 0; // Start it.

	// Doing something in background.
#if 1
	printf("timer_p32 cnt reg:\n");
	for(int i = 0; i < 10; i++){
		printf("%9d\n", (int)timer_p32[TIMER_CNT]);
	}
#endif

	return 0;
}
