

#include <stdint.h>
#include "system.h"
#include "sys/alt_irq.h"
#include <stdio.h>

#define WAIT_UNITL_0(x) while(x != 0){}
#define WAIT_UNITL_1(x) while(x != 1){}

static volatile uint32_t* pio = (volatile uint32_t*)SW_AND_LED_PIO_BASE;
static volatile uint32_t* digits = (volatile uint32_t*)TIME_MUXED_7SEGM_BASE;
static volatile uint32_t* timer = (volatile uint32_t*)TIMER_BASE;

static void timer_isr(void * context, alt_u32 id) {
	//timer[0] = 0;
	static uint8_t x = 0;
	x++;
	if(x == 16){
		x = 0;
	}
	pio[8] = x;
}

int main() {
	printf("%d\n", alt_ic_irq_enabled(TIMER_IRQ_INTERRUPT_CONTROLLER_ID, TIMER_IRQ));
	// Init IRQ.
	timer[0] = 8;
	alt_ic_isr_register(
		TIMER_IRQ_INTERRUPT_CONTROLLER_ID, //alt_u32 ic_id
		TIMER_IRQ, //alt_u32 irq
		timer_isr, //alt_isr_func isr
		NULL, //void *isr_context
		NULL //void *flags
	);
	//alt_ic_irq_enable(TIMER_IRQ_INTERRUPT_CONTROLLER_ID, TIMER_IRQ);
	printf("status = 0x%08x\n", __builtin_rdctl(0));

	printf("%d\n", alt_ic_irq_enabled(TIMER_IRQ_INTERRUPT_CONTROLLER_ID, TIMER_IRQ));


	//printf("alt_irq_pending() = 0x%08x\n", alt_irq_pending());
	printf("pio[8] = 0x%08x\n", pio[8]);
	printf("\n");

	pio[8] = 0x81;

#if 0
	printf("timer[0]:\n");
	for(int i = 0; i < 1000; i++){
		printf("%9d\n", timer[0]);
	}
#endif

	return 0;
}
