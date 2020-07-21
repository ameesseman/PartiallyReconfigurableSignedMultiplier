Contains HDL resources for the GPIO IP that was used in the system

Improvements:
Need to make GPIO peripheral so that it can make use of parameters to be able to handle more than 2 GPIO's. As it is an AXI-Lite peripheral, it should theoretically be able to keep track of up to 32 GPIO'swith the current AXI setup (as the data bus is 32 bits)
