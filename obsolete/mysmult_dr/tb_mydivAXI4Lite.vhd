LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.std_logic_arith.all;
 
 
ENTITY tb_gpioReadAXI4Lite IS
    generic (
    -- Users to add parameters here

    -- User parameters ends
    -- Do not modify the parameters beyond this line
    -- Parameters of Axi Slave Bus Interface S00_AXI
      C_S00_AXI_DATA_WIDTH    : integer    := 32;
      C_S00_AXI_ADDR_WIDTH    : integer    := 4 -- 2 for 2 registers. the other 2 LSBs are because we point to each byte in a 32-bit word.
    );

END tb_gpioReadAXI4Lite;
 
ARCHITECTURE behavior OF tb_gpioReadAXI4Lite IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
    component axiLiteGpioRead_v1_0
        port (
            -- Users to add ports here
            switch0, switch1: in std_logic;
            -- User ports ends
            -- Do not modify the ports beyond this line
    
    
            -- Ports of Axi Slave Bus Interface S00_AXI
            s00_axi_aclk    : in std_logic;
            s00_axi_aresetn    : in std_logic;
            s00_axi_awaddr    : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
            s00_axi_awprot    : in std_logic_vector(2 downto 0);
            s00_axi_awvalid    : in std_logic;
            s00_axi_awready    : out std_logic;
            s00_axi_wdata    : in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
            s00_axi_wstrb    : in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
            s00_axi_wvalid    : in std_logic;
            s00_axi_wready    : out std_logic;
            s00_axi_bresp    : out std_logic_vector(1 downto 0);
            s00_axi_bvalid    : out std_logic;
            s00_axi_bready    : in std_logic;
            s00_axi_araddr    : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
            s00_axi_arprot    : in std_logic_vector(2 downto 0);
            s00_axi_arvalid    : in std_logic;
            s00_axi_arready    : out std_logic;
            s00_axi_rdata    : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
            s00_axi_rresp    : out std_logic_vector(1 downto 0);
            s00_axi_rvalid    : out std_logic;
            s00_axi_rready    : in std_logic
        );
    end component;
    
    -- Inputs
    signal s00_axi_aclk    : std_logic:= '0';
    signal s00_axi_aresetn : std_logic:= '0';
    signal s00_axi_awaddr  : std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0):= (others => '0');
    signal s00_axi_awprot  : std_logic_vector(2 downto 0):= (others => '0');
    signal s00_axi_awvalid : std_logic:='0';
    signal s00_axi_wdata   : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0):= (others => '0');
    signal s00_axi_wstrb   : std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0):= (others => '0');
    signal s00_axi_wvalid  : std_logic:='0';
    signal s00_axi_bready  : std_logic:='0';
    signal s00_axi_araddr  : std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0):= (others => '0');
    signal s00_axi_arprot  : std_logic_vector(2 downto 0):= (others => '0');
    signal s00_axi_arvalid : std_logic:='0';
    signal s00_axi_rready  : std_logic:='0';
    signal switch0, switch1: std_logic:='0';

    -- Outputs:    
    signal s00_axi_awready  : std_logic;
    signal s00_axi_wready   : std_logic;
    signal s00_axi_bresp    : std_logic_vector(1 downto 0);
    signal s00_axi_bvalid   : std_logic;
    signal s00_axi_arready  : std_logic;
    
    signal s00_axi_rdata    : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal s00_axi_rresp    : std_logic_vector(1 downto 0);
    signal s00_axi_rvalid   : std_logic;

   -- Clock period definitions
   constant T: time := 10 ns;
 
   procedure WRITE_REG (
        constant AXI_WDATA_IN: in std_logic_vector (31 downto 0);
        constant axi_addr_offset: in std_logic_vector (3 downto 0);
        signal axi_awaddr: out std_logic_vector (3 downto 0);
        signal axi_awvalid: out std_logic;
        signal axi_awready: in std_logic;
        signal axi_wdata: out std_logic_vector (31 downto 0); -- this procedure generates the data to be written
        signal axi_wstrb: out std_logic_vector (3 downto 0);
        signal axi_wready: in std_logic;
        signal axi_wvalid: out std_logic;
        signal axi_bready: out std_logic;
        signal axi_bvalid: in std_logic;
        signal axi_aclk: in std_logic       ) is
        
   begin
          -- Send Write Address on WRITE ADDRESS Channel:
          axi_awaddr <= axi_addr_offset; -- "0000" Write on Register 0
          axi_awvalid <= '1'; -- As soon as this is detected and we are aready to capture data, 'S_AXI_AWREADY' is asserted for one cycle
          -- As soon as this happens, the value of 'awaddr' is stored (along with other control values)
    
          -- Send Data via WRITE DATA Channel:
          axi_wvalid <= '1'; axi_wdata <= AXI_WDATA_IN; axi_wstrb <= "1111"; 
                     
          -- When S_AXI_AWREADY and S_AXI_WREADY become 1 for one cycle and then 0, this is when AWVALID becomes 0
          wait until (axi_awready = '1' and axi_wready = '1' and axi_aclk'event and axi_aclk = '1'); wait until axi_awready='0';
          
          axi_wdata <= x"00000000"; axi_awaddr <= (others => '0');
          axi_awvalid <= '0'; axi_wvalid <= '0';
    
          wait until (axi_aclk = '0' and axi_aclk'event); -- wait until falling edge
       
       -- Having BREADY='1'
          axi_bready <= '1';
       
       -- Acknowlege data receipt via WRITE RESPONSE Channel
          wait until (axi_bvalid='1' and axi_aclk='1' and axi_aclk'event);      
          axi_bready <= '0';
          wait until (axi_aclk = '0' and axi_aclk'event); -- wait until falling edge to place data
          
          wait for 2*T;
   end WRITE_REG;   
   
   procedure READ_REG (
           constant axi_addr_offset: in std_logic_vector (3 downto 0);
           variable AXI_RDATA_OUT: out std_logic_vector (31 downto 0);
           
           signal axi_araddr: out std_logic_vector (3 downto 0);
           signal axi_arvalid: out std_logic;
           signal axi_arready: in std_logic;
           signal axi_rdata: in std_logic_vector (31 downto 0); -- this procedure reads the data.
           signal axi_rready: out std_logic;
           signal axi_rvalid: in std_logic;
           signal axi_aclk: in std_logic       ) is
           
      begin   
       -- Send Read Address on READ ADDRESS Channel:
          axi_araddr <= axi_addr_offset; -- Read from Register 3. Last 2 bits are 00 because they are used to address 8-bit data.
          axi_arvalid <= '1'; -- As soon as this is detected and we are aready to capture data, 'S_AXI_ARREADY' is asserted for one cycle
    
          -- When S_AXI_ARREADY becomes 1 for one cycle and then 0, this is when ARVALID becomes 0
          wait until axi_arready = '1'; wait until axi_arready='0'; -- this should happen on the rising clock edge
          axi_araddr <= (others => '0');
          axi_arvalid <= '0'; 
    
          -- For some reason, this instruction causes rready to always stay at 1 (it didn't happen for bready). Somehow the Read DATA Channel is special...
          --    wait until (s00_axi_aclk = '0' and s00_axi_aclk'event); -- wait until falling edge to place any data
          
       -- Read Data via READ DATA Channel
          axi_rready <= '1';
          
             -- Capturing 32-bit data on falling edge
                wait until (axi_rvalid='1' and axi_aclk = '0' and axi_aclk'event);
                AXI_RDATA_OUT := axi_rdata;
          
          wait until (axi_rvalid='1' and axi_aclk='1' and axi_aclk'event);                
          wait until axi_rvalid = '0'; -- to make sure rvalid is 0 before rready is 0
          axi_rready <= '0';               
          
          wait until (axi_aclk = '0' and axi_aclk'event); -- wait until falling edge to place any data on the bus
     end READ_REG;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: axiLiteGpioRead_v1_0 PORT MAP ( switch0, switch1, s00_axi_aclk, s00_axi_aresetn, s00_axi_awaddr, s00_axi_awprot, s00_axi_awvalid, s00_axi_awready,
                              s00_axi_wdata, s00_axi_wstrb, s00_axi_wvalid, s00_axi_wready, 
                              s00_axi_bresp, s00_axi_bvalid, s00_axi_bready,
                              s00_axi_araddr, s00_axi_arprot,  s00_axi_arvalid, s00_axi_arready,
                              s00_axi_rdata, s00_axi_rresp, s00_axi_rvalid, s00_axi_rready);
   -- Clock process definitions
   clock_process :process
   begin
		s00_axi_aclk <= '0'; wait for T/2;
		s00_axi_aclk <= '1'; wait for T/2;
   end process;
 
   -- Stimulus process
   stim_proc: process
        variable odata: std_logic_vector (31 downto 0);
   begin		
      -- Slave Reg 0: A&B
      -- Slave Reg 1: Q&R
      -- Slave Reg 2:   v
      -- hold reset state for 100 ns.      
		s00_axi_aresetn <= '0'; odata := x"00000000";
        wait for 100 ns; s00_axi_aresetn <= '1';
        wait for 10*T;
        
        
        WRITE_REG (x"008C0009", "0000", s00_axi_awaddr, s00_axi_awvalid, s00_axi_awready,
                                        s00_axi_wdata, s00_axi_wstrb, s00_axi_wready, s00_axi_wvalid,
                                        s00_axi_bready, s00_axi_bvalid, s00_axi_aclk); -- 0*4
                    

        READ_REG ("0100", odata, s00_axi_araddr, s00_axi_arvalid, s00_axi_arready, -- Register 1 (1*4 = 0100)
                                 s00_axi_rdata, s00_axi_rready, s00_axi_rvalid, s00_axi_aclk);
                                 
        
        switch0 <= '1';
        WRITE_REG (x"008C0009", "0000", s00_axi_awaddr, s00_axi_awvalid, s00_axi_awready,
                                        s00_axi_wdata, s00_axi_wstrb, s00_axi_wready, s00_axi_wvalid,
                                        s00_axi_bready, s00_axi_bvalid, s00_axi_aclk); -- 0*4
                    

        READ_REG ("0100", odata, s00_axi_araddr, s00_axi_arvalid, s00_axi_arready, -- Register 1 (1*4 = 0100)
                                 s00_axi_rdata, s00_axi_rready, s00_axi_rvalid, s00_axi_aclk);
        
      
        
        switch1 <= '1';
        WRITE_REG (x"00BB000A", "0000", s00_axi_awaddr, s00_axi_awvalid, s00_axi_awready,
                                        s00_axi_wdata, s00_axi_wstrb, s00_axi_wready, s00_axi_wvalid,
                                        s00_axi_bready, s00_axi_bvalid, s00_axi_aclk); -- 0*4

         READ_REG ("0100", odata, s00_axi_araddr, s00_axi_arvalid, s00_axi_arready, -- Register 1 (1*4 = 0100)
                                 s00_axi_rdata, s00_axi_rready, s00_axi_rvalid, s00_axi_aclk);       
                                                                                               

        

        switch0 <= '0';
        WRITE_REG (x"0FEA0371", "0000", s00_axi_awaddr, s00_axi_awvalid, s00_axi_awready,
                                        s00_axi_wdata, s00_axi_wstrb, s00_axi_wready, s00_axi_wvalid,
                                        s00_axi_bready, s00_axi_bvalid, s00_axi_aclk); -- 0*4

        READ_REG ("0100", odata, s00_axi_araddr, s00_axi_arvalid, s00_axi_arready, -- Register 1 (1*4 = 0100)
                                 s00_axi_rdata, s00_axi_rready, s00_axi_rvalid, s00_axi_aclk);
                                               
        wait;
   end process;

END;
