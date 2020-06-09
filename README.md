# Partially Reconfigurable Signed Multiplier
Implementation of a dynamic partially reconfigurable (DPR) signed multiplier on Zynq-7000 SoC

This project follows steps created by Xilinx to perform DPR of the PL (FPGA fabric) controlled by the PS (ARM uP). The PL and PS communicate via a custom AXI4-Full peripheral, including input and output FIFO's. 

The reconfigurable portion of this system allows to switch between a 2C (2's Complement) and SM (Sign and Magnitude) multiplier.
