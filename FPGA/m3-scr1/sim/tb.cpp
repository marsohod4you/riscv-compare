#include <stdlib.h>
#include "obj_dir/Vmax10.h"

int main(int argc, char **argv) {
	// Initialize Verilators variables
	Verilated::commandArgs(argc, argv);

	// Create an instance of our module under test
	Vmax10 *m3_top_module = new Vmax10;

	// switch the clock
	int clock = 0;
	int num_cycles = 0;
	m3_top_module->KEY0 = 1;
	m3_top_module->KEY1 = 1;
	m3_top_module->SERIAL_RX = 1;
	printf("Testbench started!\n");
	while( !Verilated::gotFinish() )
	{
		m3_top_module->CLK100MHZ = clock;
		m3_top_module->eval();
		clock ^= 1;
		num_cycles++;
		//if( num_cycles==2000000000 )
		//	break;
	}
	printf("Testbench finished!\n");
	delete m3_top_module;
	exit(EXIT_SUCCESS);
}

