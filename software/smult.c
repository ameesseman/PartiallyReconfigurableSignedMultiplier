/**
 * Author:
 * Created:   06.13.2020
 *
 * This file is able to perform DPR of a Zynq-7000 chip with two different reconfigurable modules (RM's)
 * The RM's for this example are a 2C and SM signed multipliers
 * There are three different modes: automatic run, switch-based, and IRQ-based modes
 **/

#include <stdio.h>
#include <limits.h>
#include "xil_types.h"
#include "mysmult_static.h"
#include "xparameters.h"
#include "axiLiteGpioRead.h"
#include "xstatus.h"
#include "xil_printf.h"
#include "stdio.h"
#include "xil_io.h"
#include "xil_cache.h"
#include "xscugic.h"

// Another way to do this is by using the devcfg_polled_example.c: you load the .bin file using XMD and then use this devcfg_polled_example.c file

// libraries to read/write SD
#include "xsdps.h" // SD device driver
#include "ff.h" // FAT system module.

#include "xtra_func.h"
// libraries for DevC (including PCAP and DMA)
#include "xdevcfg.h"

/* Requirements:
   - These files require the use of the ‘xilffs’ library and the
     enabling of the string manipulation functions in the xilffs library.
   - In 'Generate Linker Script', change the heap/stack size to allow for input, intermediate data.
     Also, place the code, and heap/stack in the largest memory (DDR).
     This project has been tested to work with: Heap: 9.54 MB  Stack: 68.36 KB. Bitstream size: 2035 KB
*/
FATFS FatFs; // work area (file system object) for logical drive

#define AXILITEGPIOREAD_BASE 0x43C00000

#define GPIO_DEVICE_ID  XPAR_AXI_GPIO_0_DEVICE_ID		/* GPIO device that switches are connected to */
#define SW_CHANNEL 1									/* GPIO port for switches */
#define RM_CHOICE_MASK					0x02			/* this switch(1) defines which RM will be configured to RP */
#define RM_CHOICE_SHIFT					0x01
#define IRQ_SWITCH_MASK					0x01			/* this switch(0) is the switch that will initiate a DPR */ 
#define IRQ_SWITCH_SHIFT				0x00


#define SLCR_LOCK	0xF8000004 /**< SLCR Write Protection Lock */
#define SLCR_UNLOCK	0xF8000008 /**< SLCR Write Protection Unlock */
#define SLCR_LVL_SHFTR_EN 0xF8000900 /**< SLCR Level Shifters Enable */
#define SLCR_PCAP_CLK_CTRL XPAR_PS7_SLCR_0_S_AXI_BASEADDR + 0x168 /**< SLCR
					* PCAP clock control register address
					*/

#define SLCR_PCAP_CLK_CTRL_EN_MASK 0x1
#define SLCR_LOCK_VAL	0x767B
#define SLCR_UNLOCK_VAL	0xDF0D

#define A_MASK 			0x000000FF
#define A_SHIFT			0
#define B_MASK			0x0000FF00
#define B_SHIFT			8
#define P_MASK			0x0000FFFF
#define P_SHIFT			0

/*
 * ONLY CHOOSE ONE OF THE BELOW DEFINITIONS AT ONE TIME
 */
#define IRQ_USED		1			//btn[0] (according to HW specs) triggers IRQ (and DPR). sw[1] chooses RM to reconfigure
//#define SWITCHES_USED	1			//sw[0]  triggers a DPR. sw[1] chooses RM to reconfigure
//#define IRQ_NOT_USED 	1			//automatically run a predetermined sequence of test values and DPRs

//u8 *in_dat4, *in_dat8;
//u32 BitstreamSize4, BitstreamSize8;

XScuGic GicInstance;
volatile static int InterruptProcessed = FALSE;

int load_bit_to_pcap (XDcfg *DevcfgInstPtr , u8 *dataPtr, UINT BitstreamLength, u8 flags);
void smult_test (u32 baseaddr);
void GpioInit(void);
int loadRmInit(void);
void print_bin(unsigned int integer);
int SetupInterruptSystem(XScuGic *GicPtr);
void DeviceDriverHandler(void *CallbackRef);
u32 AxiLite_ReadGpio(void);


u32 Status;
u8 *in_dat4, *in_dat8;
u32 BitstreamSize4, BitstreamSize8;
FRESULT mystat;
XDcfg Instdevcfg;


/*
 * main function that is compiled when either IRQ_USED or SWITCHES_USED is defined
 */
#if defined(IRQ_USED) || defined(SWITCHES_USED)
int main()
{
    u32 baseaddr = XPAR_MYSMULT_STATIC_0_S00_AXI_BASEADDR; //  baseaddr = 0x7AA00000; // fixed in Vivado 2016.2!
	u32 switchValue;
	u8 rmValue, fakeIrqSwValue;

    xil_printf ("\nSD + SMULT Test:\n************************\n");

    // Setup the Interrupt System: GIC (General Interrupt Controller)
    // ***************************************************************
	#if defined(IRQ_USED)
    Status = SetupInterruptSystem(&GicInstance);
    if (Status != XST_SUCCESS) { xil_printf ("Setup Interrupt System failed!\n"); return XST_FAILURE; }
	#endif

    /*
     * Load partial bitstreams from SD card into memory
     * 2C and SM partial bitstreams are loaded in
     */
    loadRmInit();

    xil_printf("smult_test\n");
	smult_test(baseaddr);		// Testing write/read on AXI-4 Full Peripheral - SMULT

	switchValue = ( AxiLite_ReadGpio() );
	xil_printf("start loop\n");
	for(;;) {
		#if defined(IRQ_USED)
		if (InterruptProcessed==TRUE) { // return value from the ISR
			InterruptProcessed = FALSE;	//clear flag
			dprTrigger();
		}
		#endif

		#if defined(SWITCHES_USED)
		//TODO change this so this only enters when IRQ sets flag
		if( (AxiLite_ReadGpio() & IRQ_SWITCH_MASK) != (switchValue & IRQ_SWITCH_MASK) ) {
			dprTrigger();
		}
		#endif
	}
		
	/*
	 * Program should not reach here
	 * free memory and return if this occurs
	 */
    free(in_dat4); free(in_dat8);
    //Xil_DCacheDisable(); Xil_ICacheDisable();
    return 0;
}
#endif

/*
 * main function that is compiled when either IRQ_NOT_USED is defined
 */
#ifdef IRQ_NOT_USED
int main()
{

    u32 baseaddr = XPAR_MYSMULT_FULL_TEST_0_S00_AXI_BASEADDR; //  baseaddr = 0x7AA00000; // fixed in Vivado 2016.2!

    xil_printf ("\nSD + SMULT Test:\n************************\n");

   	smult_test(baseaddr); // Testing write/read on AXI-4 Full Peripheral - Pixel Processor: Initial Configuration

   	/*
   	 * Load partial bitstreams from SD card into memory
   	 * 2C and SM partial bitstreams are loaded in
   	 */
   	loadRmInit();

    // Performing DPR:  Load 8x8 DCT
    Status = load_bit_to_pcap (&Instdevcfg , in_dat8, BitstreamSize8, 0x00); // Assumption: Bitstreamsize is multiple of 4
    if (Status != XST_SUCCESS) { xil_printf("(main) Error performing DPR!"); return -1; }

    // We must reset the RP and FIFOs after each partial reconfiguration
    xil_printf ("Asserting PR_reset. \n"); // Address: 1011 00 (11*4)
    MYSMULT_STATIC_mWriteMemory(baseaddr + 11*4, (0xAA995577));
    xil_printf ("PR_Reset complete. \n"); // Address: 1011 00 (11*4)

    smult_test(baseaddr); // Testing write/read on AXI-4 Full Peripheral - Pixel Processor: Second Configuration

	// Performing DPR: Load 4x4 DCT
	Status = load_bit_to_pcap (&Instdevcfg , in_dat4, BitstreamSize4, 0x00); // Assumption: Bitstreamsize is multiple of 4
    if (Status != XST_SUCCESS) { xil_printf("(main) Error performing DPR!"); return -1; }

    // We must reset the RP and FIFOs after each partial reconfiguration
    xil_printf ("Asserting PR_reset. \n"); // Address: 1011 00 (11*4)
    MYSMULT_STATIC_mWriteMemory(baseaddr + 11*4, (0xAA995577));
    xil_printf ("PR_Reset complete. \n"); // Address: 1011 00 (11*4)

    smult_test(baseaddr); // Testing write/read on AXI-4 Full Peripheral - Pixel Processor: Second Configuration

    xil_printf ("End \n");
    free(in_dat4); free(in_dat8);
    //Xil_DCacheDisable(); Xil_ICacheDisable();
    return 0;
}
#endif

/*
 * when an interrupt (btn[0]) in IRQ_USED or a switch flip (sw[0]) in SWITCHES_USED mode
 * is detected, this sequence is run to reconfigure the RP based on the value of sw[1]
 */
inline int dprTrigger() {
	u32 baseaddr = XPAR_MYSMULT_STATIC_0_S00_AXI_BASEADDR; //  baseaddr = 0x7AA00000; // fixed in Vivado 2016.2!
	u32 switchValue;
	u8 rmValue, fakeIrqSwValue;

	switchValue = ( AxiLite_ReadGpio() );
	rmValue = ((switchValue & RM_CHOICE_MASK) >> RM_CHOICE_SHIFT);
	fakeIrqSwValue = ((switchValue & IRQ_SWITCH_MASK) >> IRQ_SWITCH_SHIFT);

	switch(rmValue) {
	case 0:
		// Performing DPR:  Load SMULT_2C
		Status = load_bit_to_pcap (&Instdevcfg , in_dat8, BitstreamSize8, 0x00); // Assumption: Bitstreamsize is multiple of 4
		if (Status != XST_SUCCESS) { xil_printf("(main) Error performing DPR!"); return -1; }
		xil_printf("-------------------\n");xil_printf("SMULT_2C CONFIGURED\n");xil_printf("-------------------\n");
		break;
	case 1:
		// Performing DPR: Load SMULT_SM
		Status = load_bit_to_pcap (&Instdevcfg , in_dat4, BitstreamSize4, 0x00); // Assumption: Bitstreamsize is multiple of 4
		if (Status != XST_SUCCESS) { xil_printf("(main) Error performing DPR!"); return -1; }
		xil_printf("-------------------\n");xil_printf("SMULT_SM CONFIGURED\n");xil_printf("-------------------\n");
		break;
	default:
		break;
	}

	// We must reset the RP and FIFOs after each partial reconfiguration
	xil_printf ("Asserting PR_reset. \n"); // Address: 1011 00 (11*4)
	MYSMULT_STATIC_mWriteMemory(baseaddr + 11*4, (0xAA995577));

	smult_test(baseaddr);		// Testing write/read on AXI-4 Full Peripheral - SMULT
}


/*
 * Tests the functionality of the current RP
 * Sends and receives three test values and will get different results based on current circuit in RP
 */
void smult_test (u32 baseaddr)
{
	u32 Mem32Value, P;
	int i;

	xil_printf("(smult_test) Signed Mult AXI4-Full Peripheral Test\n");

	MYSMULT_STATIC_mWriteMemory(baseaddr, (0x00000406));
	MYSMULT_STATIC_mWriteMemory(baseaddr, (0x0000FD03));
	MYSMULT_STATIC_mWriteMemory(baseaddr, (0x0000FDFD));


	// Reading data: Again, here using baseaddr+4*Index or 'baseaddr' does not matter.
	 for (i = 0; i < 3; i++ )
	{

		u16 p;
		P = MYSMULT_STATIC_mReadMemory(baseaddr);
		p = ( (P & P_MASK) >> P_SHIFT);


		xil_printf ("Product = %04X\n", p);
	}
	xil_printf("\n\r");
}

/*
 * Load partial bitstreams from SD card into memory
 * 2C and SM partial bitstreams are loaded in
 */
int loadRmInit(void) {
	FRESULT mystat;

	in_dat4 = (u8 *) calloc (1500000,sizeof(u8));
    if (in_dat4 == NULL) {xil_printf("(main): not enough memory\r\n"); return -1;}

    in_dat8 = (u8 *) calloc (1500000,sizeof(u8));
    if (in_dat8 == NULL) {xil_printf("(main): not enough memory\r\n"); return -1;}

    // Stream partial bitstream to PCAP: Transfer Bitfile using DEVCFG/PCAP
    XDcfg Instdevcfg;

    // Mounting SD Drive
	mystat = f_mount(&FatFs, "0:/", 1); // register work area to the default drive ("0:/")
	if (mystat != FR_OK) { xil_printf("f_mount: Error!\n"); return XST_FAILURE; };

    // Read partial bitstream files from SD and place them in memory
    Status = load_sd_to_memory ("mult_sm.bin", in_dat4, &BitstreamSize4, 1);
    if (Status != XST_SUCCESS) { xil_printf ("(main) Error loading file from SD to memory!\n"); return -1; }

    Status = load_sd_to_memory ("mult_2c.bin", in_dat8, &BitstreamSize8, 1);
    if (Status != XST_SUCCESS) { xil_printf ("(main) Error loading file from SD to memory!\n"); return -1; }

	Xil_DCacheFlush(); // either disable or flush! (VERY IMPORTANT)
	return 1;
}

/**
 * Prints binary value of integer to terminal
 *
 * requires <stdio.h> and <limits.h>
 */
void print_bin(unsigned int integer) {
	int i = 32;
	int var = 0;
	while(i--) {
		//putchar('0' + ((integer >> i) & 1));
		var = ((integer >> i) & 1);
		printf("%x", var);
	}
	printf("\n\r");
}

int load_bit_to_pcap (XDcfg *DevcfgInstPtr, u8 *dataPtr, UINT BitstreamLength, u8 flags)
// We load partial bitstreams (.bin format) to PCAP:
//    Usually, we would use a function to read the header of a .bit file and extract size. Now (7 Series), apparently we can't. We have to use .bin files
//    we could try to parse the header (manually, we discovered in one example the header to be 125 bytes) and get the bitstream size, but Xilinx does not provide
//    any help on this
// this only does PArtial REconfiguration. For full reconf,. details, see devcfg_polled_example.c
// ASSUMPTION: Bitstreamlength is multiple of 4
// BitstreamLength: Size of bitstream (bytes): It has to be a multiple of 4
// flags: various options:
//  flags = 0x?E: We print registers at the end
//  flags = 0xA?: Order of bytes is swapped (this is when the .bin was generated by write_bitstream)

// This can be very useful. For example: flags=0xAE: swap byte order and print registers at the end.
{
	u32 IntrStsReg = 0;
    XDcfg_Config *ConfigPtr;
    int Status;
    int i;
    u8 ta, tb, tc, td;

    // In a .bit file, the header is included. If the header is 125 bytes, we can do this:
      // in_dat = in_dat + 0x0000007D; // used to skip the header in a .bit file.
      // BitstreamLength = BitstreamLenght-125;
    // Also note that for a .bit file, we need to swap the byte order.

    if ( (flags & 0xF0) == 0xA0) {
       // Little-endian: the .bin generated by write_bitstream. We need to swap the byte order in a 32-bit word
       xil_printf ("(load_bit_to_pcap): Swapping bytes in a 32-bit word\n");

       for (i=0; i< BitstreamLength/4; i++)
       {
    	   ta = dataPtr[4*i]; tb = dataPtr[4*i+1]; tc = dataPtr[4*i+2]; td = dataPtr[4*i+3];
    	   dataPtr[4*i] = td; dataPtr[4*i+1] = tc; dataPtr[4*i+2] = tb; dataPtr[4*i+3] = ta;
       }
    }

    // Use XMD%mrd to see data in memory (32-bit words, byte at 0 is the LSByte).
    // To see data byte-wise, use:
    // for ( i = 0; i < BitstreamLength; i++ ) xil_printf("Received data: %d: 0x%02X\n", i,*(in_dat + i) );

	//XDcfg Instpcap;
	u16 DeviceId = XPAR_PS7_DEV_CFG_0_DEVICE_ID;

	// Performing DPR:
	ConfigPtr = XDcfg_LookupConfig(DeviceId);
	if (ConfigPtr == NULL) {xil_printf ("(load_bit_to_pcap) XDcfg_LookupConfig failed\n"); return XST_FAILURE;}

	// Using Physical Address to initialize Devcfg
	Status = XDcfg_CfgInitialize(DevcfgInstPtr, ConfigPtr, ConfigPtr->BaseAddr);
	if (Status != XST_SUCCESS) { xil_printf ("(load_bit_to_pcap) XDcfg_CfgInitiliaze failed!\n"); return XST_FAILURE; }
	XDcfg_SetLockRegister(DevcfgInstPtr, XDCFG_UNLOCK_DATA); //0x757BDF0D);

	// Check 1st time configuration or not. If it is not, this is likely a Partial Reconfiguration.
	//  But even if it is the 1st, we can also do Partial Reconfiguration
	IntrStsReg = XDcfg_IntrGetStatus(DevcfgInstPtr); xil_printf ("(load_bit_to_pcap) IntrStsReg: %08X: \n",IntrStsReg);
	if (IntrStsReg & XDCFG_IXR_DMA_DONE_MASK) xil_printf("PartialCfg = 1 (i.e., not 1st configuration)!\n");
	   // First time Configuration: understood as if the entire chip is programmed. we are not doing this here!.

	// enable PCAP clock:
	Status = Xil_In32(SLCR_PCAP_CLK_CTRL);
	if (!(Status & SLCR_PCAP_CLK_CTRL_EN_MASK)) {
			Xil_Out32(SLCR_UNLOCK, SLCR_UNLOCK_VAL);
			Xil_Out32(SLCR_PCAP_CLK_CTRL, (Status | SLCR_PCAP_CLK_CTRL_EN_MASK));
			Xil_Out32(SLCR_UNLOCK, SLCR_LOCK_VAL);
	}

	// Enable PCAP interface for Partial Reconfiguration: Configure muxes so that the PCAP Path is enabled to write on PL Conf. Module
	XDcfg_SetControlRegister(DevcfgInstPtr, XDCFG_CTRL_PCAP_MODE_MASK); // Setting control register for PCAP mode --> this is also done by XDcfg_EnablePCAP(DevcfgInstPtr)
	XDcfg_SetControlRegister(DevcfgInstPtr, XDCFG_CTRL_PCAP_PR_MASK);  // Setting PR mode
     // We should probably go back to the orig. state when done)

	// Clear Interrupt Status Bits: DMA and PCAP Done Interrupts
	XDcfg_IntrClear(DevcfgInstPtr, (XDCFG_IXR_PCFG_DONE_MASK | XDCFG_IXR_DMA_DONE_MASK | XDCFG_IXR_D_P_DONE_MASK));

    xil_printf ("(load_bit_to_pcap) Interrupt Status bits cleared! IntrStsReg: %08X\n", XDcfg_IntrGetStatus(DevcfgInstPtr));

    // Check if DMA command queue is full:
	Status = XDcfg_ReadReg(ConfigPtr->BaseAddr, XDCFG_STATUS_OFFSET); // sometimes they use Inspcap->Config.BaseAddr
	if ((Status & XDCFG_STATUS_DMA_CMD_Q_F_MASK) == XDCFG_STATUS_DMA_CMD_Q_F_MASK) {
	    xil_printf("DMA command queue is full.\n\r"); return XST_FAILURE; }

	xil_printf ("(load_bit_to_pcap) DPR: Transfer to start: Source Address: %08X...\n", dataPtr);

	// Download bitstream to PL in nonsecure more:
	Status = XDcfg_Transfer(DevcfgInstPtr, dataPtr, BitstreamLength/4, (u8 *) XDCFG_DMA_INVALID_ADDRESS, 0, XDCFG_NON_SECURE_PCAP_WRITE);
	if (Status != XST_SUCCESS) { xil_printf ("XDcfg_Transfer: failure: %d\n",Status); return XST_FAILURE; }

	xil_printf ("(load_bit_to_pcap) DPR: Transfer completed!\n");

	IntrStsReg = XDcfg_IntrGetStatus(DevcfgInstPtr);
	// Poll DMA Done Interrupt
	while ((IntrStsReg & XDCFG_IXR_DMA_DONE_MASK) != XDCFG_IXR_DMA_DONE_MASK) IntrStsReg = XDcfg_IntrGetStatus(DevcfgInstPtr);

	// Poll PCAP Done Interrupt
	while ((IntrStsReg & XDCFG_IXR_D_P_DONE_MASK) != XDCFG_IXR_D_P_DONE_MASK) IntrStsReg = XDcfg_IntrGetStatus(DevcfgInstPtr);

	if ( (flags & 0x0F) == 0x0E ) {
		xil_printf ("\nINS_STS: Interrupt Status Register: %08X: \n",IntrStsReg);

		Status = XDcfg_ReadReg(ConfigPtr->BaseAddr, XDCFG_STATUS_OFFSET);
		xil_printf ("STATUS Register: %08X: \n",Status);

		Status = XDcfg_ReadReg(ConfigPtr->BaseAddr, XDCFG_CTRL_OFFSET);
		xil_printf ("CONTROL register: %08X: \n",Status);

		Status = XDcfg_ReadReg(ConfigPtr->BaseAddr, XDCFG_CFG_OFFSET);
		xil_printf ("CONFIGURATION Register: %08X: \n",Status);

		Status = XDcfg_ReadReg(ConfigPtr->BaseAddr, XDCFG_DMA_SRC_ADDR_OFFSET);
		xil_printf ("SRC ADDRESS register: %08X: \n",Status);

		Status = XDcfg_ReadReg(ConfigPtr->BaseAddr, XDCFG_DMA_DEST_ADDR_OFFSET);
		xil_printf ("DEST ADDRESS register: %08X: \n",Status);

		Status = XDcfg_ReadReg(ConfigPtr->BaseAddr, XDCFG_DMA_SRC_LEN_OFFSET);
		xil_printf ("SRC LENGTH register: %08X: \n",Status);

		Status = XDcfg_ReadReg(ConfigPtr->BaseAddr, XDCFG_DMA_DEST_LEN_OFFSET);
		xil_printf ("DEST LENGTH register: %08X: \n",Status);
	}
	return XST_SUCCESS;
	}

/******************************************************************************/
/**
 *
 * This function connects the interrupt handler of the interrupt controller to
 * the processor.  This function is separate to allow it to be customized for
 * each application. Each processor or RTOS may require unique processing to
 * connect the interrupt handler.
 *
 * @param	GicPtr is the GIC instance pointer.
 * @param	DmaPtr is the DMA instance pointer.
 *
 * @return	None.
 *
 * @note	None.
 *
 ****************************************************************************/
int SetupInterruptSystem(XScuGic *GicPtr)
{
	int Status;
	XScuGic_Config *GicConfig;

	Xil_ExceptionInit();

	/*
	 * Initialize the interrupt controller driver so that it is ready to
	 * use.
	 */
	GicConfig = XScuGic_LookupConfig(0);
	if (NULL == GicConfig) {
		return XST_FAILURE;
	}

	Status = XScuGic_CfgInitialize(GicPtr, GicConfig,
				       GicConfig->CpuBaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Perform a self-test to ensure that the hardware was built
	 * correctly
	 */
	Status = XScuGic_SelfTest(GicPtr);
	if (Status != XST_SUCCESS) {return XST_FAILURE;}

	//XScuGic_CPUWriteReg(GicPtr, XSCUGIC_EOI_OFFSET, 0x3D); // ?????
	/*
	 * Connect the interrupt controller interrupt handler to the hardware
	 * interrupt handling logic in the processor.
	 */
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_IRQ_INT,
			     (Xil_ExceptionHandler)XScuGic_InterruptHandler,
			     GicPtr);
	//Xil_ExceptionEnable();

	Status = XScuGic_Connect (GicPtr, XPS_FPGA0_INT_ID, (Xil_ExceptionHandler) DeviceDriverHandler, (void *) GicPtr);
	if (Status != XST_SUCCESS) {xil_printf("\nError connecting IRQ from PL");return XST_FAILURE;}

	/*
	 * Enable the interrupts for the device
	 */

	XScuGic_Enable(GicPtr, XPS_FPGA0_INT_ID);

	Xil_ExceptionEnable();
	return XST_SUCCESS;
}

void DeviceDriverHandler(void *CallbackRef)
{
	u32 switchValue;
	u8 rmValue, fakeIrqSwValue;
	/*
	 * Indicate the interrupt has been processed using a shared variable
	 */
	int a;

	InterruptProcessed = TRUE;
	xil_printf("(ISR) PL Interrupt occurred!\n");
	MYSMULT_STATIC_mWriteMemory(0x7AA00000, (0x00000406));

	// we can also configure stuff here so that only rising edge works
	// So, it is here that we must de-assert the interrupt source.
	a = MYSMULT_STATIC_mReadMemory(0x7AA00000 + 13*4); // to de-assert interrupt source
	xil_printf ("isr done\n");
    //xil_printf ("(DeviceDriverHandler): Word Read: %08X\n",a);
}

u32 AxiLite_ReadGpio(void) {
	u32 value, sw0, sw1;
	AXILITEGPIOREAD_mWriteReg (AXILITEGPIOREAD_BASE, 0, 0x008C0009); // Writing on Register 0

    value = AXILITEGPIOREAD_mReadReg (AXILITEGPIOREAD_BASE,4); // Reading from Register 1

    //sw0 = value&0x00000001;   sw1 = value&0x00000002;
    //xil_printf ("sw0 = %04X, sw1 = %04X\r\n", sw0, sw1);
    return value;
}
