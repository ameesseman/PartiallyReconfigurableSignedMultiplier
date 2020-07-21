LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.std_logic_arith.all;
 
 
ENTITY tb_mysmult_staticAXI4Full IS
    generic (
    -- Users to add parameters here

    -- User parameters ends
    -- Do not modify the parameters beyond this line


    -- Parameters of Axi Slave Bus Interface S00_AXI
    C_S00_AXI_ID_WIDTH    : integer    := 1;
    C_S00_AXI_DATA_WIDTH    : integer    := 32;
    C_S00_AXI_ADDR_WIDTH    : integer    := 6;
    C_S00_AXI_AWUSER_WIDTH    : integer    := 0; -- Use '1' when doing Post-Synthesis/Post-Route Simulation
    C_S00_AXI_ARUSER_WIDTH    : integer    := 0;
    C_S00_AXI_WUSER_WIDTH    : integer    := 0;
    C_S00_AXI_RUSER_WIDTH    : integer    := 0;
    C_S00_AXI_BUSER_WIDTH    : integer    := 0
    );

END tb_mysmult_staticAXI4Full;
 
ARCHITECTURE behavior OF tb_mysmult_staticAXI4Full IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
component mysmult_rp_test_v1_0
        port (
            -- Users to add ports here
    
            -- User ports ends
            -- Do not modify the ports beyond this line
    
    
            -- Ports of Axi Slave Bus Interface S00_AXI
            s00_axi_aclk    : in std_logic;
            s00_axi_aresetn    : in std_logic;
            s00_axi_awid    : in std_logic_vector(C_S00_AXI_ID_WIDTH-1 downto 0);
            s00_axi_awaddr    : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
            s00_axi_awlen    : in std_logic_vector(7 downto 0);
            s00_axi_awsize    : in std_logic_vector(2 downto 0);
            s00_axi_awburst    : in std_logic_vector(1 downto 0);
            s00_axi_awlock    : in std_logic;
            s00_axi_awcache    : in std_logic_vector(3 downto 0);
            s00_axi_awprot    : in std_logic_vector(2 downto 0);
            s00_axi_awqos    : in std_logic_vector(3 downto 0);
            s00_axi_awregion    : in std_logic_vector(3 downto 0);
            s00_axi_awuser    : in std_logic_vector(C_S00_AXI_AWUSER_WIDTH-1 downto 0);
            s00_axi_awvalid    : in std_logic;
            s00_axi_awready    : out std_logic;
            s00_axi_wdata    : in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
            s00_axi_wstrb    : in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
            s00_axi_wlast    : in std_logic;
            s00_axi_wuser    : in std_logic_vector(C_S00_AXI_WUSER_WIDTH-1 downto 0);
            s00_axi_wvalid    : in std_logic;
            s00_axi_wready    : out std_logic;
            s00_axi_bid    : out std_logic_vector(C_S00_AXI_ID_WIDTH-1 downto 0);
            s00_axi_bresp    : out std_logic_vector(1 downto 0);
            s00_axi_buser    : out std_logic_vector(C_S00_AXI_BUSER_WIDTH-1 downto 0);
            s00_axi_bvalid    : out std_logic;
            s00_axi_bready    : in std_logic;
            s00_axi_arid    : in std_logic_vector(C_S00_AXI_ID_WIDTH-1 downto 0);
            s00_axi_araddr    : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
            s00_axi_arlen    : in std_logic_vector(7 downto 0);
            s00_axi_arsize    : in std_logic_vector(2 downto 0);
            s00_axi_arburst    : in std_logic_vector(1 downto 0);
            s00_axi_arlock    : in std_logic;
            s00_axi_arcache    : in std_logic_vector(3 downto 0);
            s00_axi_arprot    : in std_logic_vector(2 downto 0);
            s00_axi_arqos    : in std_logic_vector(3 downto 0);
            s00_axi_arregion    : in std_logic_vector(3 downto 0);
            s00_axi_aruser    : in std_logic_vector(C_S00_AXI_ARUSER_WIDTH-1 downto 0);
            s00_axi_arvalid    : in std_logic;
            s00_axi_arready    : out std_logic;
            s00_axi_rid    : out std_logic_vector(C_S00_AXI_ID_WIDTH-1 downto 0);
            s00_axi_rdata    : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
            s00_axi_rresp    : out std_logic_vector(1 downto 0);
            s00_axi_rlast    : out std_logic;
            s00_axi_ruser    : out std_logic_vector(C_S00_AXI_RUSER_WIDTH-1 downto 0);
            s00_axi_rvalid    : out std_logic;
            s00_axi_rready    : in std_logic
        );
    end component;
    
    -- Inputs
    signal s00_axi_aclk    : std_logic:= '0';
    signal s00_axi_aresetn : std_logic:= '0';
    signal s00_axi_awid    : std_logic_vector(C_S00_AXI_ID_WIDTH-1 downto 0):= (others => '0');
    signal s00_axi_awaddr  : std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0):= (others => '0');
    signal s00_axi_awlen   : std_logic_vector(7 downto 0):= (others => '0');
    signal s00_axi_awsize  : std_logic_vector(2 downto 0):= (others => '0');
    signal s00_axi_awburst : std_logic_vector(1 downto 0):= (others => '0');
    signal s00_axi_awlock  : std_logic:= '0';
    signal s00_axi_awcache : std_logic_vector(3 downto 0):= (others => '0');
    signal s00_axi_awprot  : std_logic_vector(2 downto 0):= (others => '0');
    signal s00_axi_awqos   : std_logic_vector(3 downto 0):= (others => '0');
    signal s00_axi_awregion: std_logic_vector(3 downto 0):= (others => '0');
    signal s00_axi_awuser  : std_logic_vector(C_S00_AXI_AWUSER_WIDTH-1 downto 0):= (others => '0');
    signal s00_axi_awvalid : std_logic:='0';
    signal s00_axi_wdata   : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0):= (others => '0');
    signal s00_axi_wstrb   : std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0):= (others => '0');
    signal s00_axi_wlast   : std_logic:='0';
    signal s00_axi_wuser   : std_logic_vector(C_S00_AXI_WUSER_WIDTH-1 downto 0):= (others => '0');
    signal s00_axi_wvalid  : std_logic:='0';
    signal s00_axi_bready  : std_logic:='0';
    signal s00_axi_arid    : std_logic_vector(C_S00_AXI_ID_WIDTH-1 downto 0):= (others => '0');
    signal s00_axi_araddr  : std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0):= (others => '0');
    signal s00_axi_arlen   : std_logic_vector(7 downto 0):= (others => '0');
    signal s00_axi_arsize  : std_logic_vector(2 downto 0):= (others => '0');
    signal s00_axi_arburst : std_logic_vector(1 downto 0):= (others => '0');
    signal s00_axi_arlock  : std_logic:= '0';
    signal s00_axi_arcache : std_logic_vector(3 downto 0):= (others => '0');
    signal s00_axi_arprot  : std_logic_vector(2 downto 0):= (others => '0');
    signal s00_axi_arqos   : std_logic_vector(3 downto 0):= (others => '0');
    signal s00_axi_arregion: std_logic_vector(3 downto 0):= (others => '0');
    signal s00_axi_aruser  : std_logic_vector(C_S00_AXI_ARUSER_WIDTH-1 downto 0):= (others => '0');
    signal s00_axi_arvalid : std_logic:='0';
    signal s00_axi_rready  : std_logic:='0';

    -- Outputs:    
    signal s00_axi_awready  : std_logic;
    signal s00_axi_wready   : std_logic;
    signal s00_axi_bid      : std_logic_vector(C_S00_AXI_ID_WIDTH-1 downto 0);
    signal s00_axi_bresp    : std_logic_vector(1 downto 0);
    signal s00_axi_buser    : std_logic_vector(C_S00_AXI_BUSER_WIDTH-1 downto 0);
    signal s00_axi_bvalid   : std_logic;
    signal s00_axi_arready  : std_logic;
    signal s00_axi_rid      : std_logic_vector(C_S00_AXI_ID_WIDTH-1 downto 0);
    signal s00_axi_rdata    : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal s00_axi_rresp    : std_logic_vector(1 downto 0);
    signal s00_axi_rlast    : std_logic;
    signal s00_axi_ruser    : std_logic_vector(C_S00_AXI_RUSER_WIDTH-1 downto 0);
    signal s00_axi_rvalid   : std_logic;

   -- Clock period definitions
   constant T: time := 10 ns;
   constant MAX_B: INTEGER:= 100; -- 100 bursts maximum (simulation wise). In reality, only 16 maximum
    
   type chunkB is array (0 to MAX_B - 1) of std_logic_vector (31 downto 0);
   signal AXI_WDATA_IN: chunkB;

    procedure WRITE_DATA (
        constant axi_addr_offset: in std_logic_vector (5 downto 0); -- based on 6-bit address.
        constant axi_burst_length: in std_logic_vector(7 downto 0);
        constant axi_burst_type: in std_logic_vector(1 downto 0); -- "00": FIXED, "01": INCR, "10": WRAP                
        signal AXI_WDATA_IN: in chunkB;
        signal axi_awaddr: out std_logic_vector (5 downto 0);
        signal axi_awlen: out std_logic_vector (7 downto 0);
        signal axi_awsize: out std_logic_vector (2 downto 0);
        signal axi_awburst: out std_logic_vector (1 downto 0);
        signal axi_awvalid: out std_logic;
        signal axi_awready: in std_logic;
        signal axi_wdata: out std_logic_vector (31 downto 0); -- this procedure generates the data to be written
        signal axi_wstrb: out std_logic_vector (3 downto 0);
        signal axi_wlast: out std_logic;
        signal axi_wready: in std_logic;
        signal axi_wvalid: out std_logic;
        signal axi_bready: out std_logic;
        signal axi_bvalid: in std_logic;
        signal axi_aclk: in std_logic       ) is
        
        variable BL: integer;     
    begin
     -- WRITE ADDRESS Channel: Send Write Address
        axi_awaddr <= axi_addr_offset; -- "000000": Write on Address 0, "000100": Write on Address 1, ...
        axi_awlen <= axi_burst_length;
        axi_awsize <= "010"; -- A word is 32-bits wide
        axi_awburst <= axi_burst_type;        
        axi_awvalid <= '1'; -- When this is detected by the Slave and it is ready to receive data, 
        --  'S_AXI_AWREADY' is asserted for one cycle
        -- When this happens, the value of 'awaddr' is stored (along with other control values)
                                    
        -- Here, we double-check that AXI_AWREADY was in fact asserted by the Slave
        -- When S_AXI_AWREADY becomes 1 for one cycle and then 0, the Slaves de-asserts AWVALID (1 -> 0)
        wait until axi_awready = '1'; wait until axi_awready='0'; -- we could've checked the clock tick too
        axi_awaddr <= (others => '0');
        axi_awvalid <= '0';
                                    
     -- WRITE DATA Channel: Send Data
        -- we place data (on falling edge) right after Address is captured. We only transmit one 32-bit word here.
        --  This is unlike AXI4-Lite where data and address are captured at the same time
        wait until (axi_aclk = '0' and axi_aclk'event);
        axi_wstrb <= "1111";
        
        -- Sending bursts of Data:
        BL := conv_integer(unsigned(axi_burst_length)); -- Burst Length. BL = 3 --> we have 4 bursts
        -- We are going to index the bursts:
        --   Bursts indices are from 0 to BL-1. There are a total of 'BL+1' bursts
        --  Example: if BL=3 --> Bursts indices go from 0 to 3. There are a total of 4 bursts.
        if BL = 0 then -- Only one word
            axi_wdata <= AXI_WDATA_IN(0); axi_wvalid <= '1'; axi_wlast <= '1'; -- First and last burst.
        else
            axi_wdata <= AXI_WDATA_IN(0); axi_wvalid <= '1'; --wait for 2*T; -- Burst 0 is sent
                wait until (axi_wready = '1' and axi_aclk'event and axi_aclk ='1'); -- wait until wready is asserted (on clock tick)
                wait until (axi_aclk'event and axi_aclk ='0'); -- on falling edge, we allow the next 32-bit word to be written

            for i in 1 to BL - 1 loop -- Burst 1 to second-to-last is sent
                axi_wdata <= AXI_WDATA_IN(i); axi_wvalid <= '1'; wait for T;
            end loop;
            axi_wdata <= AXI_WDATA_IN(BL); axi_wvalid <= '1'; axi_wlast <= '1'; -- Last Burst is sent
        end if; 
                                            
        -- We wait for wready to be '1' and then '0'. Right after this, we make wvalid = 0.
        wait until (axi_wready = '1' and axi_aclk'event and axi_aclk ='1'); -- check that wready ='1' on clock tick (last word in burst)
        wait until axi_wready = '0';
        axi_wdata <= (others => '0'); axi_wlast <= '0'; axi_wvalid <= '0';
                                                  
     -- WRITE RESPONSE Channel: Acknowledge data receipt
        wait until (axi_aclk = '0' and axi_aclk'event); -- wait until falling edge to place data
        axi_bready <= '1'; -- Assert BREADY (0 -> 1)
                                            
        wait until (axi_bvalid='1' and axi_aclk='1' and axi_aclk'event); -- check that bvalid and bready are '1' on clock tick
        axi_bready <= '0';
        wait until (axi_aclk = '0' and axi_aclk'event); -- wait until falling edge
                                              
        wait for 2*T; -- not sure.
    end WRITE_DATA;

    procedure READ_DATA (
        constant axi_addr_offset: in std_logic_vector (5 downto 0);
        constant axi_burst_length: in std_logic_vector(7 downto 0);
        constant axi_burst_type: in std_logic_vector(1 downto 0); -- "00": FIXED, "01": INCR, "10": WRAP
        signal axi_araddr: out std_logic_vector (5 downto 0);
        signal axi_arlen: out std_logic_vector (7 downto 0); -- Burst Length
        signal axi_arsize: out std_logic_vector (2 downto 0); 
        signal axi_arburst: out std_logic_vector (1 downto 0); -- Burst Type
        signal axi_arvalid: out std_logic;
        signal axi_arready: in std_logic;
        signal axi_rdata: in std_logic_vector (31 downto 0); -- this procedure reads the data.
        signal axi_rready: out std_logic;
        signal axi_rvalid: in std_logic;
        signal axi_rlast: in std_logic;
        signal axi_aclk: in std_logic       ) is
                                                   
    begin   
     -- READ ADDRESS Channel: Send Read Address
        axi_araddr <= axi_addr_offset; -- Last 2 bits are 00 because they are used to address 8-bit data.
        axi_arlen <= axi_burst_length;
        axi_arsize <= "010"; -- a word is 32-bits wide.
        axi_arburst <= axi_burst_type;
        axi_arvalid <= '1';  -- When this is detected by the Slave and it is ready to receive data, 
                             -- 'S_AXI_ARREADY' is asserted for one cycle
                             -- When this happens, the value of 'araddr' is stored (along with other control values)
                                    
        -- Here, we double-check that AXI_ARREADY was in fact asserted by the Slave
        -- When S_AXI_ARREADY becomes 1 for one cycle and then 0, the Slaves de-asserts ARVALID (1 -> 0)
        wait until axi_arready = '1'; wait until axi_arready='0'; -- we could've checked the clock tick too
        axi_araddr <= (others => '0');
        axi_arvalid <= '0';
                                              
     -- READ DATA Channel: Read Data
        wait until (axi_aclk = '0' and axi_aclk'event); -- wait until falling edge to place data
        axi_rready <= '1'; -- Assert RREADY (0 -> 1)
                                               
        wait until (axi_rvalid='1' and axi_rlast = '1' and axi_aclk='1' and axi_aclk'event); -- check for rvalid on the clock tick
        -- Note that we also check for 'axi_rlast=1' -> this is asserted even if only one word was transmitted.                
        wait until axi_rvalid = '0'; -- wait for rvalid to be '0' before rready is 0
        axi_rready <= '0';            
                                              
        wait until (axi_aclk = '0' and axi_aclk'event); -- wait until falling edge
        
        -- Note: for one transfer (32 bits), the Xilinx AXI4-Peripheral asserts 'axi_rlast' many times until it is read.
        --       For more than 1 transfer, 'axi_rlast' is only asserted last, because the first word would not have axi_rlast='1' anyway.
    end READ_DATA;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: mysmult_rp_test_v1_0 PORT MAP ( s00_axi_aclk, s00_axi_aresetn, s00_axi_awid, s00_axi_awaddr, s00_axi_awlen, s00_axi_awsize, s00_axi_awburst, s00_axi_awlock, s00_axi_awcache,
                                     s00_axi_awprot, s00_axi_awqos, s00_axi_awregion, s00_axi_awuser, s00_axi_awvalid, s00_axi_awready,
                                   s00_axi_wdata, s00_axi_wstrb, s00_axi_wlast, s00_axi_wuser, s00_axi_wvalid, s00_axi_wready, 
                                   s00_axi_bid, s00_axi_bresp, s00_axi_buser, s00_axi_bvalid, s00_axi_bready,
                                   s00_axi_arid, s00_axi_araddr, s00_axi_arlen, s00_axi_arsize, s00_axi_arburst, s00_axi_arlock, s00_axi_arcache, s00_axi_arprot, s00_axi_arqos,
                                     s00_axi_arregion, s00_axi_aruser, s00_axi_arvalid, s00_axi_arready,
                                   s00_axi_rid, s00_axi_rdata, s00_axi_rresp, s00_axi_rlast, s00_axi_ruser, s00_axi_rvalid, s00_axi_rready);
   -- Clock process definitions
   clock_process :process
   begin
		s00_axi_aclk <= '0'; wait for T/2;
		s00_axi_aclk <= '1'; wait for T/2;
   end process;
 
   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		s00_axi_aresetn <= '0'; wait for 100 ns;
		s00_axi_aresetn <= '1';
        wait for 16*T; -- we MUST wait for the FIFO reset to transition from 1 to 0.

		
		-- ============
        -- First Input:    
        -- ============
        -- 2 32-bit words: Transmission and reception
        -- *************        
        AXI_WDATA_IN(0) <= x"00000406";
        --   axi_awlen <= "00000001"; -- 2 transfers
        --   axi_awburst <= "00"; -- "FIXED" (address remains constant during transmission        
        -- We write on Address 10, but in this FIFO configuration, the address does not matter.
        WRITE_DATA ("101000", "00000000", "00", AXI_WDATA_IN,
                    s00_axi_awaddr, s00_axi_awlen, s00_axi_awsize, s00_axi_awburst, s00_axi_awvalid, s00_axi_awready,
                    s00_axi_wdata, s00_axi_wstrb, s00_axi_wlast, s00_axi_wready, s00_axi_wvalid,
                    s00_axi_bready, s00_axi_bvalid, s00_axi_aclk);

        --   axi_arlen <= "00000000"; -- 1 transfer
        --   axi_arburst <= "00"; -- "FIXED" (all data intended for the same address)
        READ_DATA ("101000", "00000000", "01", -- Expected Results: 
                    s00_axi_araddr, s00_axi_arlen, s00_axi_arsize, s00_axi_arburst, s00_axi_arvalid, s00_axi_arready,
                    s00_axi_rdata, s00_axi_rready, s00_axi_rvalid, s00_axi_rlast, s00_axi_aclk);
					
		-- ============
        -- Second Input:    
        -- ============
        -- 2 32-bit words: Transmission and reception
        -- *************        
        AXI_WDATA_IN(0) <= x"0000FD03";
        --   axi_awlen <= "00000001"; -- 2 transfers
        --   axi_awburst <= "00"; -- "FIXED" (address remains constant during transmission        
        -- We write on Address 10, but in this FIFO configuration, the address does not matter.
        WRITE_DATA ("101000", "00000000", "00", AXI_WDATA_IN,
                    s00_axi_awaddr, s00_axi_awlen, s00_axi_awsize, s00_axi_awburst, s00_axi_awvalid, s00_axi_awready,
                    s00_axi_wdata, s00_axi_wstrb, s00_axi_wlast, s00_axi_wready, s00_axi_wvalid,
                    s00_axi_bready, s00_axi_bvalid, s00_axi_aclk);

        --   axi_arlen <= "00000000"; -- 1 transfer
        --   axi_arburst <= "00"; -- "FIXED" (all data intended for the same address)
        READ_DATA ("101000", "00000000", "01", -- Expected Results: 
                    s00_axi_araddr, s00_axi_arlen, s00_axi_arsize, s00_axi_arburst, s00_axi_arvalid, s00_axi_arready,
                    s00_axi_rdata, s00_axi_rready, s00_axi_rvalid, s00_axi_rlast, s00_axi_aclk);
                    
        -- ============
        -- Third Input:    
        -- ============
        -- 2 32-bit words: Transmission and reception
        -- *************        
        AXI_WDATA_IN(0) <= x"0000FDFD";
        --   axi_awlen <= "00000001"; -- 2 transfers
        --   axi_awburst <= "00"; -- "FIXED" (address remains constant during transmission        
        -- We write on Address 10, but in this FIFO configuration, the address does not matter.
        WRITE_DATA ("101000", "00000000", "00", AXI_WDATA_IN,
                    s00_axi_awaddr, s00_axi_awlen, s00_axi_awsize, s00_axi_awburst, s00_axi_awvalid, s00_axi_awready,
                    s00_axi_wdata, s00_axi_wstrb, s00_axi_wlast, s00_axi_wready, s00_axi_wvalid,
                    s00_axi_bready, s00_axi_bvalid, s00_axi_aclk);

        --   axi_arlen <= "00000000"; -- 1 transfer
        --   axi_arburst <= "00"; -- "FIXED" (all data intended for the same address)
        READ_DATA ("101000", "00000000", "01", -- Expected Results: 
                    s00_axi_araddr, s00_axi_arlen, s00_axi_arsize, s00_axi_arburst, s00_axi_arvalid, s00_axi_arready,
                    s00_axi_rdata, s00_axi_rready, s00_axi_rvalid, s00_axi_rlast, s00_axi_aclk);


      wait;
   end process;

END;
