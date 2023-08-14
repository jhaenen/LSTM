library ieee;
use ieee.std_logic_1164.all;

entity ddr4_tb is
end entity ddr4_tb;

architecture sim of ddr4_tb is
    component hbm is
        port (
            ddr4_sdram_c0_act_n : out STD_LOGIC;
            ddr4_sdram_c0_adr : out STD_LOGIC_VECTOR ( 16 downto 0 );
            ddr4_sdram_c0_ba : out STD_LOGIC_VECTOR ( 1 downto 0 );
            ddr4_sdram_c0_bg : out STD_LOGIC_VECTOR ( 1 downto 0 );
            ddr4_sdram_c0_ck_c : out STD_LOGIC;
            ddr4_sdram_c0_ck_t : out STD_LOGIC;
            ddr4_sdram_c0_cke : out STD_LOGIC;
            ddr4_sdram_c0_cs_n : out STD_LOGIC;
            ddr4_sdram_c0_dq : inout STD_LOGIC_VECTOR ( 71 downto 0 );
            ddr4_sdram_c0_dqs_c : inout STD_LOGIC_VECTOR ( 17 downto 0 );
            ddr4_sdram_c0_dqs_t : inout STD_LOGIC_VECTOR ( 17 downto 0 );
            ddr4_sdram_c0_odt : out STD_LOGIC;
            ddr4_sdram_c0_par : out STD_LOGIC;
            ddr4_sdram_c0_reset_n : out STD_LOGIC;
            c0_init_calib_complete : out STD_LOGIC;
            resetn : in STD_LOGIC;
            sysclk0_clk_n : in STD_LOGIC;
            sysclk0_clk_p : in STD_LOGIC;
            DDR4_S_AXI_araddr : in STD_LOGIC_VECTOR ( 33 downto 0 );
            DDR4_S_AXI_arburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
            DDR4_S_AXI_arcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
            DDR4_S_AXI_arid : in STD_LOGIC_VECTOR ( 3 downto 0 );
            DDR4_S_AXI_arlen : in STD_LOGIC_VECTOR ( 7 downto 0 );
            DDR4_S_AXI_arlock : in STD_LOGIC_VECTOR ( 0 to 0 );
            DDR4_S_AXI_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
            DDR4_S_AXI_arqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
            DDR4_S_AXI_arready : out STD_LOGIC;
            DDR4_S_AXI_arsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
            DDR4_S_AXI_arvalid : in STD_LOGIC;
            DDR4_S_AXI_awaddr : in STD_LOGIC_VECTOR ( 33 downto 0 );
            DDR4_S_AXI_awburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
            DDR4_S_AXI_awcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
            DDR4_S_AXI_awid : in STD_LOGIC_VECTOR ( 3 downto 0 );
            DDR4_S_AXI_awlen : in STD_LOGIC_VECTOR ( 7 downto 0 );
            DDR4_S_AXI_awlock : in STD_LOGIC_VECTOR ( 0 to 0 );
            DDR4_S_AXI_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
            DDR4_S_AXI_awqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
            DDR4_S_AXI_awready : out STD_LOGIC;
            DDR4_S_AXI_awsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
            DDR4_S_AXI_awvalid : in STD_LOGIC;
            DDR4_S_AXI_bid : out STD_LOGIC_VECTOR ( 3 downto 0 );
            DDR4_S_AXI_bready : in STD_LOGIC;
            DDR4_S_AXI_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
            DDR4_S_AXI_bvalid : out STD_LOGIC;
            DDR4_S_AXI_rdata : out STD_LOGIC_VECTOR ( 511 downto 0 );
            DDR4_S_AXI_rid : out STD_LOGIC_VECTOR ( 3 downto 0 );
            DDR4_S_AXI_rlast : out STD_LOGIC;
            DDR4_S_AXI_rready : in STD_LOGIC;
            DDR4_S_AXI_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
            DDR4_S_AXI_rvalid : out STD_LOGIC;
            DDR4_S_AXI_wdata : in STD_LOGIC_VECTOR ( 511 downto 0 );
            DDR4_S_AXI_wlast : in STD_LOGIC;
            DDR4_S_AXI_wready : out STD_LOGIC;
            DDR4_S_AXI_wstrb : in STD_LOGIC_VECTOR ( 63 downto 0 );
            DDR4_S_AXI_wvalid : in STD_LOGIC;
            DDR4_S_AXI_CTRL_araddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
            DDR4_S_AXI_CTRL_arready : out STD_LOGIC;
            DDR4_S_AXI_CTRL_arvalid : in STD_LOGIC;
            DDR4_S_AXI_CTRL_awaddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
            DDR4_S_AXI_CTRL_awready : out STD_LOGIC;
            DDR4_S_AXI_CTRL_awvalid : in STD_LOGIC;
            DDR4_S_AXI_CTRL_bready : in STD_LOGIC;
            DDR4_S_AXI_CTRL_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
            DDR4_S_AXI_CTRL_bvalid : out STD_LOGIC;
            DDR4_S_AXI_CTRL_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
            DDR4_S_AXI_CTRL_rready : in STD_LOGIC;
            DDR4_S_AXI_CTRL_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
            DDR4_S_AXI_CTRL_rvalid : out STD_LOGIC;
            DDR4_S_AXI_CTRL_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
            DDR4_S_AXI_CTRL_wready : out STD_LOGIC;
            DDR4_S_AXI_CTRL_wvalid : in STD_LOGIC
        );
    end component hbm;

    constant clk_period : time := 10 ns;
    

    -- Create signals to map to the hbm ip
    signal ddr4_sdram_c0_act_n : std_logic;
    signal ddr4_sdram_c0_adr : std_logic_vector(16 downto 0);
    signal ddr4_sdram_c0_ba : std_logic_vector(1 downto 0);
    signal ddr4_sdram_c0_bg : std_logic_vector(1 downto 0);
    signal ddr4_sdram_c0_ck_c : std_logic;
    signal ddr4_sdram_c0_ck_t : std_logic;
    signal ddr4_sdram_c0_cke : std_logic;
    signal ddr4_sdram_c0_cs_n : std_logic;
    signal ddr4_sdram_c0_dq : std_logic_vector(71 downto 0) := (others => 'X');
    signal ddr4_sdram_c0_dqs_c : std_logic_vector(17 downto 0) := (others => 'X');
    signal ddr4_sdram_c0_dqs_t : std_logic_vector(17 downto 0) := (others => 'X');
    signal ddr4_sdram_c0_odt : std_logic;
    signal ddr4_sdram_c0_par : std_logic;
    signal ddr4_sdram_c0_reset_n : std_logic;

    signal c0_init_calib_complete : std_logic;

    signal resetn : std_logic := '0';
    signal clk : std_logic := '0';
    signal clk_n : std_logic := '0';

    -- AXI 4 signals
    signal ddr4_s_axi_araddr : std_logic_vector(33 downto 0) := (others => '0');
    signal ddr4_s_axi_arburst : std_logic_vector(1 downto 0) := (others => '0');
    signal ddr4_s_axi_arcache : std_logic_vector(3 downto 0) := (others => '0');
    signal ddr4_s_axi_arid : std_logic_vector(3 downto 0) := (others => '0');
    signal ddr4_s_axi_arlen : std_logic_vector(7 downto 0) := (others => '0');
    signal ddr4_s_axi_arlock : std_logic_vector(0 to 0) := (others => '0');
    signal ddr4_s_axi_arprot : std_logic_vector(2 downto 0) := (others => '0');
    signal ddr4_s_axi_arqos : std_logic_vector(3 downto 0) := (others => '0');
    signal ddr4_s_axi_arready : std_logic;
    signal ddr4_s_axi_arsize : std_logic_vector(2 downto 0) := (others => '0');
    signal ddr4_s_axi_arvalid : std_logic := '0';
    signal ddr4_s_axi_awaddr : std_logic_vector(33 downto 0) := (others => '0');
    signal ddr4_s_axi_awburst : std_logic_vector(1 downto 0) := (others => '0');
    signal ddr4_s_axi_awcache : std_logic_vector(3 downto 0) := (others => '0');
    signal ddr4_s_axi_awid : std_logic_vector(3 downto 0) := (others => '0');
    signal ddr4_s_axi_awlen : std_logic_vector(7 downto 0) := (others => '0');
    signal ddr4_s_axi_awlock : std_logic_vector(0 to 0) := (others => '0');
    signal ddr4_s_axi_awprot : std_logic_vector(2 downto 0) := (others => '0');
    signal ddr4_s_axi_awqos : std_logic_vector(3 downto 0) := (others => '0');
    signal ddr4_s_axi_awready : std_logic;
    signal ddr4_s_axi_awsize : std_logic_vector(2 downto 0) := (others => '0');
    signal ddr4_s_axi_awvalid : std_logic := '0';

    signal ddr4_s_axi_bid : std_logic_vector(3 downto 0);
    signal ddr4_s_axi_bready : std_logic := '0';
    signal ddr4_s_axi_bresp : std_logic_vector(1 downto 0);
    signal ddr4_s_axi_bvalid : std_logic;

    signal ddr4_s_axi_rdata : std_logic_vector(511 downto 0);
    signal ddr4_s_axi_rid : std_logic_vector(3 downto 0);
    signal ddr4_s_axi_rlast : std_logic;
    signal ddr4_s_axi_rready : std_logic := '0';
    signal ddr4_s_axi_rresp : std_logic_vector(1 downto 0);
    signal ddr4_s_axi_rvalid : std_logic;

    signal ddr4_s_axi_wdata : std_logic_vector(511 downto 0) := (others => '0');
    signal ddr4_s_axi_wlast : std_logic := '0';
    signal ddr4_s_axi_wstrb : std_logic_vector(63 downto 0) := (others => '0');
    signal ddr4_s_axi_wready : std_logic;
    signal ddr4_s_axi_wvalid : std_logic := '0';

    -- AXI 4 Lite signals
    signal ddr4_s_axi_ctrl_araddr : std_logic_vector(31 downto 0) := (others => '0');
    signal ddr4_s_axi_ctrl_arready : std_logic;
    signal ddr4_s_axi_ctrl_arvalid : std_logic := '0';

    signal ddr4_s_axi_ctrl_awaddr : std_logic_vector(31 downto 0) := (others => '0');
    signal ddr4_s_axi_ctrl_awready : std_logic;
    signal ddr4_s_axi_ctrl_awvalid : std_logic := '0';

    signal ddr4_s_axi_ctrl_bready : std_logic := '0';
    signal ddr4_s_axi_ctrl_bresp : std_logic_vector(1 downto 0);
    signal ddr4_s_axi_ctrl_bvalid : std_logic;

    signal ddr4_s_axi_ctrl_rdata : std_logic_vector(31 downto 0);
    signal ddr4_s_axi_ctrl_rready : std_logic := '0';
    signal ddr4_s_axi_ctrl_rresp : std_logic_vector(1 downto 0);
    signal ddr4_s_axi_ctrl_rvalid : std_logic;

    signal ddr4_s_axi_ctrl_wdata : std_logic_vector(31 downto 0) := (others => '0');
    signal ddr4_s_axi_ctrl_wready : std_logic;
    signal ddr4_s_axi_ctrl_wvalid : std_logic := '0';
begin
    
    -- Clock process
    process
    begin
        clk <= '0';
        clk_n <= '1';
        wait for clk_period/2;
        clk <= '1';
        clk_n <= '0';
        wait for clk_period/2;
    end process;
    
    dut: hbm
        port map (
            -- Clocks and resets
            sysclk0_clk_p => clk,
            sysclk0_clk_n => clk_n,
            resetn => resetn,
            -- DDR4_S_AXI_CTRL
            DDR4_S_AXI_CTRL_araddr => ddr4_s_axi_ctrl_araddr,
            DDR4_S_AXI_CTRL_arready => ddr4_s_axi_ctrl_arready,
            DDR4_S_AXI_CTRL_arvalid => ddr4_s_axi_ctrl_arvalid,
            DDR4_S_AXI_CTRL_awaddr => ddr4_s_axi_ctrl_awaddr,
            DDR4_S_AXI_CTRL_awready => ddr4_s_axi_ctrl_awready,
            DDR4_S_AXI_CTRL_awvalid => ddr4_s_axi_ctrl_awvalid,
            DDR4_S_AXI_CTRL_bready => ddr4_s_axi_ctrl_bready,
            DDR4_S_AXI_CTRL_bresp => ddr4_s_axi_ctrl_bresp,
            DDR4_S_AXI_CTRL_bvalid => ddr4_s_axi_ctrl_bvalid,
            DDR4_S_AXI_CTRL_rdata => ddr4_s_axi_ctrl_rdata,
            DDR4_S_AXI_CTRL_rready => ddr4_s_axi_ctrl_rready,
            DDR4_S_AXI_CTRL_rresp => ddr4_s_axi_ctrl_rresp,
            DDR4_S_AXI_CTRL_rvalid => ddr4_s_axi_ctrl_rvalid,
            DDR4_S_AXI_CTRL_wdata => ddr4_s_axi_ctrl_wdata,
            DDR4_S_AXI_CTRL_wready => ddr4_s_axi_ctrl_wready,
            DDR4_S_AXI_CTRL_wvalid => ddr4_s_axi_ctrl_wvalid,
            -- DDR4_S_AXI
            DDR4_S_AXI_araddr => ddr4_s_axi_araddr,
            DDR4_S_AXI_arburst => ddr4_s_axi_arburst,
            DDR4_S_AXI_arcache => ddr4_s_axi_arcache,
            DDR4_S_AXI_arid => ddr4_s_axi_arid,
            DDR4_S_AXI_arlen => ddr4_s_axi_arlen,
            DDR4_S_AXI_arlock => ddr4_s_axi_arlock,
            DDR4_S_AXI_arprot => ddr4_s_axi_arprot,
            DDR4_S_AXI_arqos => ddr4_s_axi_arqos,
            DDR4_S_AXI_arready => ddr4_s_axi_arready,
            DDR4_S_AXI_arsize => ddr4_s_axi_arsize,
            DDR4_S_AXI_arvalid => ddr4_s_axi_arvalid,
            DDR4_S_AXI_awaddr => ddr4_s_axi_awaddr,
            DDR4_S_AXI_awburst => ddr4_s_axi_awburst,
            DDR4_S_AXI_awcache => ddr4_s_axi_awcache,
            DDR4_S_AXI_awid => ddr4_s_axi_awid,
            DDR4_S_AXI_awlen => ddr4_s_axi_awlen,
            DDR4_S_AXI_awlock => ddr4_s_axi_awlock,
            DDR4_S_AXI_awprot => ddr4_s_axi_awprot,
            DDR4_S_AXI_awqos => ddr4_s_axi_awqos,
            DDR4_S_AXI_awready => ddr4_s_axi_awready,
            DDR4_S_AXI_awsize => ddr4_s_axi_awsize,
            DDR4_S_AXI_awvalid => ddr4_s_axi_awvalid,
            DDR4_S_AXI_bready => ddr4_s_axi_bready,
            DDR4_S_AXI_bresp => ddr4_s_axi_bresp,
            DDR4_S_AXI_bvalid => ddr4_s_axi_bvalid,
            DDR4_S_AXI_rdata => ddr4_s_axi_rdata,
            DDR4_S_AXI_rid => ddr4_s_axi_rid,
            DDR4_S_AXI_rlast => ddr4_s_axi_rlast,
            DDR4_S_AXI_rready => ddr4_s_axi_rready,
            DDR4_S_AXI_rresp => ddr4_s_axi_rresp,
            DDR4_S_AXI_rvalid => ddr4_s_axi_rvalid,
            DDR4_S_AXI_wdata => ddr4_s_axi_wdata,
            DDR4_S_AXI_wlast => ddr4_s_axi_wlast,
            DDR4_S_AXI_wready => ddr4_s_axi_wready,
            DDR4_S_AXI_wstrb => ddr4_s_axi_wstrb,
            DDR4_S_AXI_wvalid => ddr4_s_axi_wvalid,
            -- DDR4 
            ddr4_sdram_c0_act_n => ddr4_sdram_c0_act_n,
            ddr4_sdram_c0_ba => ddr4_sdram_c0_ba,
            ddr4_sdram_c0_bg => ddr4_sdram_c0_bg,
            ddr4_sdram_c0_ck_c => ddr4_sdram_c0_ck_c,
            ddr4_sdram_c0_ck_t => ddr4_sdram_c0_ck_t,
            ddr4_sdram_c0_cke => ddr4_sdram_c0_cke,
            ddr4_sdram_c0_cs_n => ddr4_sdram_c0_cs_n,
            ddr4_sdram_c0_dq => ddr4_sdram_c0_dq,
            ddr4_sdram_c0_dqs_c => ddr4_sdram_c0_dqs_c,
            ddr4_sdram_c0_dqs_t => ddr4_sdram_c0_dqs_t,
            ddr4_sdram_c0_odt => ddr4_sdram_c0_odt,
            ddr4_sdram_c0_par => ddr4_sdram_c0_par,
            ddr4_sdram_c0_reset_n => ddr4_sdram_c0_reset_n,
            c0_init_calib_complete => c0_init_calib_complete
        );
end architecture sim;