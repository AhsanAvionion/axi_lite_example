



#include <stdio.h>
#include "platform.h"
#include "xparameters.h"
#include "xil_printf.h"
u32 GPIO_OUPUT_OFFSET = 0x0000;
u32 GPIO_INPUT_OFFSET = 0x0004;
u32 pins_state = 0;

unsigned int val=0;
while(1){
		pins_state = ~pins_state;
		Xil_Out32(XPAR_MYGPIO_0_BASEADDR | GPIO_OUPUT_OFFSET, pins_state); // pin_high=1, pin_low=0
		val = Xil_In32(XPAR_MYGPIO_0_BASEADDR | GPIO_INPUT_OFFSET);
		xil_printf("gpio_input=%d\r\n",val);
		usleep(1000000);
	}