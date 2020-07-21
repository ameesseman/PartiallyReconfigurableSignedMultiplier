library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity myAXI_IP is
	generic (
		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH	: integer	:= 6
	);
	port (
	--user defined
	    done_irq : out std_logic;
	    
	    switch: in std_logic;
	    pr_int: out std_logic;
	     
	    -- Global Clock Signal
        S_AXI_ACLK    : in std_logic;
        -- Global Reset Signal. This Signal is Active LOW
        S_AXI_ARESETN : in std_logic;	
		-- Write valid. This signal indicates that valid write data and strobes are available.
        S_AXI_WVALID  : in std_logic;
        -- Write strobes. This signal indicates which byte lanes hold valid data. There is one write strobe
        -- bit for each eight bits of the write data bus.
        S_AXI_WSTRB    : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);        
	    -- Write ready. This signal indicates that the slave can accept the write data.
        S_AXI_WREADY    : in std_logic;
        
        -- Read ready. This signal indicates that the master can accept the read data and response information.
        S_AXI_RREADY    : in std_logic;
		-- Read valid. This signal indicates that the channel is signaling the required read data.
        S_AXI_RVALID  : out std_logic;
    	-- Read response. This signal indicates the status of the read transfer.
        S_AXI_RRESP    : out std_logic_vector(1 downto 0);
                                
	    -- Write Data
        S_AXI_WDATA   : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Read Data
        S_AXI_RDATA   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);  
        
        S_AXI_ARREADY	: in std_logic;          
        
	    -- The axi_awv_awr_flag flag marks the presence of write address valid
        axi_awv_awr_flag : in std_logic;
        --The axi_arv_arr_flag flag marks the presence of read address valid
        axi_arv_arr_flag : in std_logic;        
	    axi_awaddr, axi_araddr	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0)
	);
end myAXI_IP;

architecture arch_imp of myAXI_IP is

    component my_AXIfifo
        generic (
            -- Width of S_AXI data bus
            C_S_AXI_DATA_WIDTH	: integer	:= 32;
            -- Width of S_AXI address bus
            C_S_AXI_ADDR_WIDTH	: integer	:= 6
        );
        port (
        --user defined
	       done_irq : out std_logic;
	    
	       switch: in std_logic;
	       pr_int: out std_logic;
	       
            -- Global Clock Signal
            S_AXI_ACLK    : in std_logic;
            -- Global Reset Signal. This Signal is Active LOW
            S_AXI_ARESETN : in std_logic;	
            -- Write valid. This signal indicates that valid write data and strobes are available.
            S_AXI_WVALID  : in std_logic;
            -- Write strobes. This signal indicates which byte lanes hold valid data. There is one write strobe
            -- bit for each eight bits of the write data bus.
            S_AXI_WSTRB    : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);        
            -- Write ready. This signal indicates that the slave can accept the write data.
            S_AXI_WREADY    : in std_logic;

            -- Read ready. This signal indicates that the master can accept the read data and response information.
            S_AXI_RREADY    : in std_logic;
            -- Read valid. This signal indicates that the channel is signaling the required read data.
            S_AXI_RVALID  : out std_logic;
    		-- Read response. This signal indicates the status of the read transfer.
            S_AXI_RRESP    : out std_logic_vector(1 downto 0);
                                        
            -- Write Data
            S_AXI_WDATA   : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            -- Read Data
            S_AXI_RDATA   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);  
            
            S_AXI_ARREADY	: in std_logic;              
            
            -- The axi_awv_awr_flag flag marks the presence of write address valid
            axi_awv_awr_flag : in std_logic;
            --The axi_arv_arr_flag flag marks the presence of read address valid
            axi_arv_arr_flag : in std_logic;
            axi_awaddr, axi_araddr	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0)
        );
    end component;

begin

        th: my_AXIfifo generic map (C_S_AXI_DATA_WIDTH, C_S_AXI_ADDR_WIDTH)
            port map (done_irq, switch, pr_int, S_AXI_ACLK, S_AXI_ARESETN, S_AXI_WVALID, S_AXI_WSTRB, S_AXI_WREADY, S_AXI_RREADY, S_AXI_RVALID, S_AXI_RRESP, S_AXI_WDATA, S_AXI_RDATA, 
                      S_AXI_ARREADY, axi_awv_awr_flag, axi_arv_arr_flag, axi_awaddr, axi_araddr);        
        
end arch_imp;
