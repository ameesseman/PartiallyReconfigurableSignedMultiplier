# Partially Reconfigurable Signed Multiplier
Implementation of a dynamic partially reconfigurable (DPR) signed multiplier on Zynq-7000 SoC.
The reconfigurable portion of this system allows to switch between a 2C (2's Complement) and SM (Sign and Magnitude) multiplier, the two reconfigurable modules (RM), on-the-fly.  

This project follows steps created by Xilinx to perform DPR of the PL (FPGA fabric) controlled by the PS (ARM uP). 

The PS communicates via an AXI-Interconnect peripheral to the (2) AXI slave IP's in the PL. The main IP that was created includes the reconfigurable partition (RP) that is able to switch between the 2C and SM multipliers. It is a custom AXI4-Full peripheral, including input and output FIFO's. A second IP was created in order to allow the PS to poll the values of inputs. It is an AXI4-Lite peripheral.

The software allows the circuit to be interacted with in several ways:
1. The processor can execute a program that automatically reconfigures the RP and automatically sends inputs and receives processed data
2. The processor can poll I/O values to determine when to perform a DPR and which RM to then reconfigure
3. The processor can receive an interrupt to determine when to perform a DPR and use an I/O to determine which RM to then reconfigure

# Repository File Structure
- hdl-resources: 
Includes all HDL resources used in the creation of this system. Subfolders are used to section off which IP the resources belong to

- my_dynsmult: 
The Xilinx compliant file structure used to create the reconfigurable resources for the project

- resources:
Contains the Tcl commands used to generate the DPR resources used for the system

- software: 
Includes all software resources used

- mysmult_dr, mysmult_dr_static: 
Obsolete
