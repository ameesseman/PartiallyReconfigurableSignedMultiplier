#include <stdio.h>
#include "xil_types.h"
#include "mydctfull.h"
#include "xparameters.h"
#include "stdio.h"
#include "xil_io.h"
#include "xil_cache.h"
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
     This project has been tested to work with: Heap: 3.89 MB  Stack: 51.75 KB. Bitstream size: 1194704 bytes
*/
FATFS FatFs; // work area (file system object) for logical drive

#define SLCR_LOCK	0xF8000004 /**< SLCR Write Protection Lock */
#define SLCR_UNLOCK	0xF8000008 /**< SLCR Write Protection Unlock */
#define SLCR_LVL_SHFTR_EN 0xF8000900 /**< SLCR Level Shifters Enable */
#define SLCR_PCAP_CLK_CTRL XPAR_PS7_SLCR_0_S_AXI_BASEADDR + 0x168 /**< SLCR
					* PCAP clock control register address
					*/

#define SLCR_PCAP_CLK_CTRL_EN_MASK 0x1
#define SLCR_LOCK_VAL	0x767B
#define SLCR_UNLOCK_VAL	0xDF0D

int load_bit_to_pcap (XDcfg *DevcfgInstPtr , u8 *dataPtr, UINT BitstreamLength, u8 flags);
void dctfull_test (u32 baseaddr, u32 tsize);

// TODO: - group reading SD files

int main()
{
    u32 Status;
	u8 *in_dat4, *in_dat8;
	u32 BitstreamSize4, BitstreamSize8;
    u32 baseaddr = XPAR_MYDCTFULL_0_S00_AXI_BASEADDR; //  baseaddr = 0x7AA00000; // fixed in Vivado 2016.2!
    FRESULT mystat;

    xil_printf ("\nSD + DPR Test:\n************************\n");

    //Xil_DCacheEnable(); Xil_ICacheEnable();

    // Initial Configuration: 4x4
   	dctfull_test(baseaddr,4); // Testing write/read on AXI-4 Full Peripheral - Pixel Processor: Initial Configuration

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
    Status = load_sd_to_memory ("dct_4o.bin", in_dat4, &BitstreamSize4, 1);
    if (Status != XST_SUCCESS) { xil_printf ("(main) Error loading file from SD to memory!\n"); return -1; }

    Status = load_sd_to_memory ("dct_8o.bin", in_dat8, &BitstreamSize8, 1);
    if (Status != XST_SUCCESS) { xil_printf ("(main) Error loading file from SD to memory!\n"); return -1; }

	Xil_DCacheFlush(); // either disable or flush! (VERY IMPORTANT)

    // Performing DPR:  Load 8x8 DCT
    Status = load_bit_to_pcap (&Instdevcfg , in_dat8, BitstreamSize8, 0x00); // Assumption: Bitstreamsize is multiple of 4
    if (Status != XST_SUCCESS) { xil_printf("(main) Error performing DPR!"); return -1; }

    // We must reset the RP and FIFOs after each partial reconfiguration
    xil_printf ("Asserting PR_reset. \n"); // Address: 1011 00 (11*4)
    MYDCTFULL_mWriteMemory(baseaddr + 11*4, (0xAA995577));

    dctfull_test(baseaddr, 8); // Testing write/read on AXI-4 Full Peripheral - Pixel Processor: Second Configuration

	// Performing DPR: Load 4x4 DCT
	Status = load_bit_to_pcap (&Instdevcfg , in_dat4, BitstreamSize4, 0x00); // Assumption: Bitstreamsize is multiple of 4
    if (Status != XST_SUCCESS) { xil_printf("(main) Error performing DPR!"); return -1; }

	// We must reset the RP and FIFOs after each partial reconfiguration
       xil_printf ("Asserting PR_reset. \n"); // Address: 1011 00 (11*4)
	   MYDCTFULL_mWriteMemory(baseaddr + 11*4, (0xAA995577));

    dctfull_test(baseaddr, 4); // Testing write/read on AXI-4 Full Peripheral - Pixel Processor: Second Configuration

    free(in_dat4); free(in_dat8);
    //Xil_DCacheDisable(); Xil_ICacheDisable();
    return 0;
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

void dctfull_test (u32 baseaddr, u32 tsize)
{
    u32 Mem32Value;
    int i;

    xil_printf("(dctfull_test) DCT 2D AXI4-Full Peripheral Test - TRANSFORM SIZE: %dx%d\n", tsize, tsize);

    if (tsize == 4)
    {
    	// Input data: 4x4 Block (bit-width: 8): Data is entered column-wise. Each column is a 32-bit word
    	// Address: baseaddr + 0. AXI4-Full Peripheral was built so that writes/read occur in any of the 64-byte memory range.
    	// Output Data: 4x4 Block (bit-width: 16): Data is received row-wise. Each row is a 64-bit word
		xil_printf ("First block...");
		MYDCTFULL_mWriteMemory(baseaddr, (0xDEADBEEF));
		MYDCTFULL_mWriteMemory(baseaddr, (0xBEBEDEAD));
		MYDCTFULL_mWriteMemory(baseaddr, (0xFADEBEAD));
		MYDCTFULL_mWriteMemory(baseaddr, (0xCAFEBEDF));
		xil_printf(" Data written !!\n");

		for ( i = 0; i < 8; i++ ) {
		  Mem32Value = MYDCTFULL_mReadMemory(baseaddr); // we get the same results here (as expected, by reading anything on the 64-bytes we read the same)
		  xil_printf("\tReceived data: 0x%08x\n", Mem32Value); }

		xil_printf ("Second block...");
		MYDCTFULL_mWriteMemory(baseaddr, (0xCFC7C9C7)); // same thing, the index does not make a difference, it seems
		MYDCTFULL_mWriteMemory(baseaddr, (0xCAC4C6C3));
		MYDCTFULL_mWriteMemory(baseaddr, (0xC6C3C7C3));
		MYDCTFULL_mWriteMemory(baseaddr, (0xBEBDC2BD));

		xil_printf(" Data written !!\n");
		for ( i = 0; i < 8; i++ ) {
		  Mem32Value = MYDCTFULL_mReadMemory(baseaddr); // we get the same results here (as expected, by reading anything on the 64-bytes we read the same)
		  xil_printf("\tReceived data: 0x%08x\n", Mem32Value); }
    }
    else if (tsize == 8)
    {
    	// Input data: 8x8 Block (bit-width: 8): Data is entered column-wise. Each column is a 64-bit word
    	// Address: baseaddr + 0. AXI4-Full Peripheral was built so that writes/read occur in any of the 64-byte memory range.
    	// Output Data: 8x8 Block (bit-width: 16): Data is received row-wise. Each row is a 128-bit word
        xil_printf ("First Block..."); // data is entered column-wise
        MYDCTFULL_mWriteMemory(baseaddr, (0x7d807e79)); MYDCTFULL_mWriteMemory(baseaddr, (0x7c7e7d77));
        MYDCTFULL_mWriteMemory(baseaddr, (0x7c7a7a82)); MYDCTFULL_mWriteMemory(baseaddr, (0x7d787c81));
        MYDCTFULL_mWriteMemory(baseaddr, (0x7f7c7b81)); MYDCTFULL_mWriteMemory(baseaddr, (0x7c797d7f));
        MYDCTFULL_mWriteMemory(baseaddr, (0x827e7b7f)); MYDCTFULL_mWriteMemory(baseaddr, (0x7b7a7d7c));

        MYDCTFULL_mWriteMemory(baseaddr, (0x807e7b7e)); MYDCTFULL_mWriteMemory(baseaddr, (0x7a7b7d7a));
        MYDCTFULL_mWriteMemory(baseaddr, (0x7c7c7b7e)); MYDCTFULL_mWriteMemory(baseaddr, (0x7a7b7c79));
        MYDCTFULL_mWriteMemory(baseaddr, (0x7b7d7c7e)); MYDCTFULL_mWriteMemory(baseaddr, (0x7c797b7b));
        MYDCTFULL_mWriteMemory(baseaddr, (0x7f807d7d)); MYDCTFULL_mWriteMemory(baseaddr, (0x7d78797d));

    	xil_printf("Data written!!\n"); // data is read column-wise as well (remember that we read the row of Y', i.e. col of Y)
    	for ( i = 0; i < 32; i++ ) {
    	  Mem32Value = MYDCTFULL_mReadMemory(baseaddr); // we get the same results here (as expected, by reading anything on the 64-bytes we read the same)
    	  xil_printf("Received data: 0x%08x\n", Mem32Value); }
    }
    else
    	xil_printf ("Invalid Transform size (only 4 and 8 are supported!\n");
}

