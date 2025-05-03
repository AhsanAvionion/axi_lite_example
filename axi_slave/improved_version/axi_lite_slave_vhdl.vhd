

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity axi_lite_slave_vhdl is
    generic (
    	-- Users to add parameters here
    
    	-- User parameters ends
    	-- Do not modify the parameters beyond this line
    
    	-- Width of S_AXI data bus
    	S00_AXI_DATA_WIDTH	: integer	:= 32;
    	-- Width of S_AXI address bus
    	S00_AXI_ADDR_WIDTH	: integer	:= 12
    );
    port (
        -- Users to add ports here
        -- User ports ends
        -- Do not modify the ports beyond this line
        S00_AXI_ACLK	: in std_logic;
        S00_AXI_ARESETN	: in std_logic;
        S00_AXI_AWADDR	: in std_logic_vector(S00_AXI_ADDR_WIDTH-1 downto 0);
        S00_AXI_AWPROT	: in std_logic_vector(2 downto 0);
        S00_AXI_AWVALID	: in std_logic;
        S00_AXI_AWREADY	: out std_logic;
        S00_AXI_WDATA	: in std_logic_vector(S00_AXI_DATA_WIDTH-1 downto 0);
        S00_AXI_WSTRB	: in std_logic_vector((S00_AXI_DATA_WIDTH/8)-1 downto 0);
        S00_AXI_WVALID	: in std_logic;
        S00_AXI_WREADY	: out std_logic;
        S00_AXI_BRESP	: out std_logic_vector(1 downto 0);
        S00_AXI_BVALID	: out std_logic;
        S00_AXI_BREADY	: in std_logic;
        S00_AXI_ARADDR	: in std_logic_vector(S00_AXI_ADDR_WIDTH-1 downto 0);
        S00_AXI_ARPROT	: in std_logic_vector(2 downto 0);
        S00_AXI_ARVALID	: in std_logic;
        S00_AXI_ARREADY	: out std_logic;
        S00_AXI_RDATA	: out std_logic_vector(S00_AXI_DATA_WIDTH-1 downto 0);
        S00_AXI_RRESP	: out std_logic_vector(1 downto 0);
        S00_AXI_RVALID	: out std_logic;
        S00_AXI_RREADY	: in std_logic
        
        -- debug
--        slaveReg0	: out std_logic_vector(S00_AXI_DATA_WIDTH-1 downto 0);
--        slaveReg1	: out std_logic_vector(S00_AXI_DATA_WIDTH-1 downto 0)

    );
    
    attribute verilog_name : string;
    attribute verilog_name of axi_lite_slave_vhdl : entity is "axi_lite_slave_vhdl";
end axi_lite_slave_vhdl;

architecture arch_imp of axi_lite_slave_vhdl is

    -- AXI4LITE signals    
    signal s00_axi_awaddr_reg   : std_logic_vector(S00_AXI_ADDR_WIDTH-1 downto 0);
    signal s00_axi_awready_reg  : std_logic;
    signal s00_axi_wready_reg   : std_logic;
    signal s00_axi_bresp_reg    : std_logic_vector(1 downto 0);
    signal s00_axi_bvalid_reg   : std_logic;
    signal s00_axi_araddr_reg   : std_logic_vector(S00_AXI_ADDR_WIDTH-1 downto 0);
    signal s00_axi_arready_reg  : std_logic;
    signal s00_axi_rdata_reg    : std_logic_vector(S00_AXI_DATA_WIDTH-1 downto 0);
    signal s00_axi_rresp_reg    : std_logic_vector(1 downto 0);
    signal s00_axi_rvalid_reg   : std_logic;
    
    -- Example-specific design signals
    ------------------------------------------------
    ---- Signals for user logic register space example
    --------------------------------------------------
    ---- Slave Registers
    signal slv_reg0	:std_logic_vector(S00_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg1	:std_logic_vector(S00_AXI_DATA_WIDTH-1 downto 0);
    
    -- write axi-lite transaction
    signal s00_axi_awaddr_pending  : std_logic;
    signal s00_axi_wdata_pending  : std_logic;
    signal s00_axi_wdata_done  : std_logic;
    signal s00_axi_bresp_pending  : std_logic;
    signal s00_axi_bresp_done  : std_logic;
    signal gen_timer_saxi_rd :std_logic_vector(3 downto 0);
    
    -- read axi-lite transaction    
    signal s00_axi_rdata_pending  : std_logic;
    signal s00_axi_rdata_done  : std_logic;
    type state_type is (IDLE, PROC);
    signal axird_state : state_type;
    signal gen_timer_saxi_wr :std_logic_vector(3 downto 0);
    
    
    constant CONN_TEST1_MMAP : std_logic_vector(S00_AXI_ADDR_WIDTH-1 downto 0) := x"000";
    constant CONN_TEST2_MMAP : std_logic_vector(S00_AXI_ADDR_WIDTH-1 downto 0) := x"004";

begin
    -- I/O Connections assignments
    
    S00_AXI_AWREADY	<= s00_axi_awready_reg;
    S00_AXI_WREADY	<= s00_axi_wready_reg;
    S00_AXI_BRESP	<= s00_axi_bresp_reg;
    S00_AXI_BVALID	<= s00_axi_bvalid_reg;
    S00_AXI_ARREADY	<= s00_axi_arready_reg;
    S00_AXI_RDATA	<= s00_axi_rdata_reg;
    S00_AXI_RRESP	<= s00_axi_rresp_reg;
    S00_AXI_RVALID	<= s00_axi_rvalid_reg;

    process (S00_AXI_ACLK)
    begin
      if rising_edge(S00_AXI_ACLK) then 
        if S00_AXI_ARESETN = '0' then
          s00_axi_awready_reg <= '0';
          s00_axi_awaddr_pending <= '0';
        else
          if (s00_axi_awready_reg = '0' and S00_AXI_AWVALID = '1' and s00_axi_awaddr_pending = '0') then
               s00_axi_awready_reg <= '1';
               s00_axi_awaddr_pending <= '1';
          elsif (S00_AXI_BREADY = '1' and s00_axi_bvalid_reg = '1') then
               s00_axi_awready_reg <= '0';
               s00_axi_awaddr_pending <= '0';
          else
            s00_axi_awready_reg <= '0';
          end if;
        end if;
      end if;
    end process;


    process (S00_AXI_ACLK)
    begin
      if rising_edge(S00_AXI_ACLK) then 
        if S00_AXI_ARESETN = '0' then
          s00_axi_awaddr_reg <= (others => '0');
          s00_axi_wdata_pending <= '0';
        else
          if (s00_axi_awready_reg = '1' and S00_AXI_AWVALID = '1' and s00_axi_awaddr_pending = '1') then
            -- Write Address latching
            s00_axi_awaddr_reg <= S00_AXI_AWADDR;
            s00_axi_wdata_pending <= '1';
          else
            if(s00_axi_wdata_done = '1') then
              s00_axi_wdata_pending <= '0';
            end if;
          end if;
        end if;
      end if;                   
    end process; 
    

    
    process (S00_AXI_ACLK)
        variable loc_addr : std_logic_vector(S00_AXI_ADDR_WIDTH-1 downto 0);
    begin
        if rising_edge(S00_AXI_ACLK) then 
            if S00_AXI_ARESETN = '0' then
              s00_axi_wdata_done <= '0';
              s00_axi_wready_reg <= '0';
              gen_timer_saxi_wr <= (others => '0');
              slv_reg0 <= x"deadbeef";
              slv_reg1 <= x"beeffeed";
              s00_axi_bresp_pending <= '0';
            else
                loc_addr := s00_axi_awaddr_reg(S00_AXI_ADDR_WIDTH-1 downto 0);
                if (s00_axi_wdata_pending = '1' and s00_axi_wready_reg = '0' and S00_AXI_WVALID = '1') then
                    case loc_addr is
                        when CONN_TEST1_MMAP =>
                            slv_reg0 <= S00_AXI_WDATA;
                            s00_axi_wready_reg <= '1';
                            s00_axi_wdata_done <= '1';
                            s00_axi_bresp_pending <= '1';
                        when CONN_TEST2_MMAP =>
                            if(gen_timer_saxi_wr = x"0") then
                                gen_timer_saxi_wr <= x"1";
                                slv_reg1 <= S00_AXI_WDATA;    -- can be here
                            elsif(gen_timer_saxi_wr = x"1") then
                                gen_timer_saxi_wr <= x"2";
                                slv_reg1 <= S00_AXI_WDATA;    -- also can be here
                            elsif(gen_timer_saxi_wr = x"2") then
                                gen_timer_saxi_wr <= x"3";
                                slv_reg1 <= S00_AXI_WDATA;    -- also can be here
                            elsif(gen_timer_saxi_wr = x"3") then
                                gen_timer_saxi_wr <= x"0";
                                slv_reg1 <= S00_AXI_WDATA;    -- also can be here
                                s00_axi_wready_reg <= '1';
                                s00_axi_wdata_done <= '1';
                                s00_axi_bresp_pending <= '1';
                            end if;
                        when others =>  -- avoid any hang on axi_master side
--                            slv_reg0 <= X"12345678";    -- debug
                            s00_axi_wready_reg <= '1';
                            s00_axi_wdata_done <= '1';
                            s00_axi_bresp_pending <= '1';
                    end case;
                else
                    if(s00_axi_wready_reg = '1' and s00_axi_wdata_done = '1') then
                        s00_axi_wready_reg <= '0';
                        s00_axi_wdata_done <= '0';
                    end if;
                    if(s00_axi_bresp_done = '1') then
                        s00_axi_bresp_pending <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;
--    slaveReg0 <= slv_reg0;
--    slaveReg1 <= slv_reg1;


    process (S00_AXI_ACLK)
    begin
      if rising_edge(S00_AXI_ACLK) then 
        if S00_AXI_ARESETN = '0' then
          s00_axi_bvalid_reg  <= '0';
          s00_axi_bresp_reg   <= "00"; --need to work more on the responses
          s00_axi_bresp_done <= '0';
        else
          if (S00_AXI_BREADY = '1' and s00_axi_bvalid_reg = '0'  ) then
            if(s00_axi_bresp_pending = '1') then
                s00_axi_bvalid_reg <= '1';
                s00_axi_bresp_reg  <= "00";
                s00_axi_bresp_done <= '1';
            end if;
          else
            if (S00_AXI_BREADY = '1' and s00_axi_bvalid_reg = '1') then
                s00_axi_bvalid_reg <= '0';
            end if;
            s00_axi_bresp_done <= '0';
          end if;
        end if;
      end if;                   
    end process; 
    
    
    process (S00_AXI_ACLK)
    begin
        if rising_edge(S00_AXI_ACLK) then 
            if S00_AXI_ARESETN = '0' then
                s00_axi_arready_reg <= '0';
                s00_axi_araddr_reg  <= (others => '1');
                s00_axi_rdata_pending <= '0';
            else
                if (s00_axi_arready_reg = '0' and S00_AXI_ARVALID = '1') then
                    -- indicates that the slave has acceped the valid read address
                    s00_axi_arready_reg <= '1';
                    -- Read Address latching 
                    s00_axi_araddr_reg  <= S00_AXI_ARADDR;     
                    s00_axi_rdata_pending <= '1';      
                else
                    s00_axi_arready_reg <= '0';
                    if (s00_axi_rdata_done = '1') then
                        s00_axi_rdata_pending <= '0';
                    end if;
                end if;
            end if;
        end if;                   
    end process; 

    process (S00_AXI_ACLK)
        variable loc_addr : std_logic_vector(S00_AXI_ADDR_WIDTH-1 downto 0);
    begin
        if rising_edge(S00_AXI_ACLK) then
            if S00_AXI_ARESETN = '0' then
                s00_axi_rvalid_reg <= '0';
                s00_axi_rresp_reg  <= "00";
                axird_state <= IDLE;
                s00_axi_rdata_done <= '0';
                gen_timer_saxi_rd <= (others => '0');
            else
                loc_addr := s00_axi_araddr_reg(S00_AXI_ADDR_WIDTH-1 downto 0);
                case axird_state is
                    when IDLE =>
                        if (s00_axi_rdata_pending = '1') then
                            axird_state <= PROC;
                        end if;
                        s00_axi_rvalid_reg <= '0';
                    when PROC =>
                        -- Define behavior for START state
                        if (S00_AXI_RREADY = '1' and s00_axi_rvalid_reg = '0') then
                            -- Handle mmap here
                            case loc_addr is
                                when CONN_TEST1_MMAP =>
                                    s00_axi_rdata_reg <= slv_reg0;
                                    s00_axi_rvalid_reg <= '1';     -- This function Xil_In32(XPAR_PCIE_1553_0_BASEADDR+XX) stucks until axi_rvalid is high
                                    s00_axi_rresp_reg  <= "00"; -- OKAY response
                                    s00_axi_rdata_done <= '1';
                                when CONN_TEST2_MMAP =>
                                    if(gen_timer_saxi_rd = x"0") then
                                        gen_timer_saxi_rd <= x"1";
                                    elsif(gen_timer_saxi_rd = x"1") then
                                        gen_timer_saxi_rd <= x"2";
                                    elsif(gen_timer_saxi_rd = x"2") then
                                        gen_timer_saxi_rd <= x"3";
                                        s00_axi_rdata_reg(15 downto 0) <= slv_reg1(15 downto 0);    -- can be separately loaded
                                    elsif(gen_timer_saxi_rd = x"3") then
                                        gen_timer_saxi_rd <= x"0";
                                        s00_axi_rdata_reg(31 downto 16) <= slv_reg1(31 downto 16);    -- can be separately loaded
                                        -- s00_axi_rdata_reg <= slv_reg1;  -- can be loaded simultanously
                                        s00_axi_rvalid_reg <= '1';     -- This function Xil_In32(XPAR_PCIE_1553_0_BASEADDR+XX) stucks until axi_rvalid is high
                                        s00_axi_rresp_reg  <= "00"; -- OKAY response
                                        s00_axi_rdata_done <= '1';
                                    end if;
                                when others =>  -- to avoid CPU to hang when trying to access unavailable MMAP Address
                                    s00_axi_rdata_reg <= (others => '0');
                                    s00_axi_rvalid_reg <= '1';     -- This function Xil_In32(XPAR_PCIE_1553_0_BASEADDR+XX) stucks until axi_rvalid is high
                                    s00_axi_rresp_reg  <= "00"; -- OKAY response
                                    s00_axi_rdata_done <= '1';
                            end case;
                        else
                            s00_axi_rdata_reg <= (others => '0');
                            s00_axi_rvalid_reg <= '0';
                            axird_state <= IDLE;
                            s00_axi_rdata_done <= '0';
                        end if;                                
                end case;        
            end if;
        end if;
    end process;


end arch_imp;
