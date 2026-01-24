# ============================================================
# bd.tcl
# Block Design: IIR1 Stereo IIR + AXI DMA
# Target Board: Kria KV260
# ============================================================

proc create_root_design { parentCell } {

  if { $parentCell eq "" } {
    set parentCell [get_bd_cells /]
  }

  current_bd_instance $parentCell

  # ------------------------------------------------------------
  # IP INSTANTIATION
  # ------------------------------------------------------------

  set stereo_iir_filter_0 [create_bd_cell -type ip -vlnv xilinx.com:Audio_DSP:stereo_iir_filter:1.0 stereo_iir_filter_0]

  set zynq_ultra_ps_e_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.5 zynq_ultra_ps_e_0]
  set_property -dict [list \
    CONFIG.PSU__PRESET_APPLIED {1} \
    CONFIG.PSU__FPGA_PL0_ENABLE {1} \
    CONFIG.PSU__USE__M_AXI_GP0 {1} \
    CONFIG.PSU__USE__S_AXI_GP2 {1} \
    CONFIG.PSU__USE__S_AXI_GP3 {1} \
  ] $zynq_ultra_ps_e_0

  # NOTE:
  # Full PSU configuration preserved as exported by Vivado.
  # (DDR, clocks, MIO, protection, etc.)
  # ------------------------------------------------------------
  # >>> PASTE FULL PSU CONFIG BLOCK HERE (UNMODIFIED) <<<
  # ------------------------------------------------------------

  set axi_dma_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_0]
  set_property -dict [list \
    CONFIG.c_include_sg {0} \
    CONFIG.c_sg_length_width {26} \
  ] $axi_dma_0

  set ps8_0_axi_periph [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 ps8_0_axi_periph]
  set_property CONFIG.NUM_MI {2} $ps8_0_axi_periph

  set rst_ps8_0_99M [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps8_0_99M]

  set axi_smc   [create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc]
  set_property CONFIG.NUM_SI {1} $axi_smc

  set axi_smc_1 [create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc_1]
  set_property CONFIG.NUM_SI {1} $axi_smc_1

  # ------------------------------------------------------------
  # INTERFACE CONNECTIONS
  # ------------------------------------------------------------

  connect_bd_intf_net [get_bd_intf_pins stereo_iir_filter_0/s_axis]       [get_bd_intf_pins axi_dma_0/M_AXIS_MM2S]
  connect_bd_intf_net [get_bd_intf_pins stereo_iir_filter_0/m_axis]       [get_bd_intf_pins axi_dma_0/S_AXIS_S2MM]

  connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXI_MM2S]             [get_bd_intf_pins axi_smc/S00_AXI]
  connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]             [get_bd_intf_pins axi_smc_1/S00_AXI]

  connect_bd_intf_net [get_bd_intf_pins axi_smc/M00_AXI]                  [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP0_FPD]
  connect_bd_intf_net [get_bd_intf_pins axi_smc_1/M00_AXI]                [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP1_FPD]

  connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM0_FPD]  [get_bd_intf_pins ps8_0_axi_periph/S00_AXI]
  connect_bd_intf_net [get_bd_intf_pins ps8_0_axi_periph/M00_AXI]         [get_bd_intf_pins axi_dma_0/S_AXI_LITE]
  connect_bd_intf_net [get_bd_intf_pins ps8_0_axi_periph/M01_AXI]         [get_bd_intf_pins stereo_iir_filter_0/s_axi]

  # ------------------------------------------------------------
  # CLOCK & RESET
  # ------------------------------------------------------------

  connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] \
                 [get_bd_pins ps8_0_axi_periph/ACLK] \
                 [get_bd_pins axi_dma_0/s_axi_lite_aclk] \
                 [get_bd_pins axi_dma_0/m_axi_mm2s_aclk] \
                 [get_bd_pins axi_dma_0/m_axi_s2mm_aclk] \
                 [get_bd_pins stereo_iir_filter_0/aclk] \
                 [get_bd_pins axi_smc/aclk] \
                 [get_bd_pins axi_smc_1/aclk] \
                 [get_bd_pins rst_ps8_0_99M/slowest_sync_clk]

  connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] \
                 [get_bd_pins rst_ps8_0_99M/ext_reset_in]

  connect_bd_net [get_bd_pins rst_ps8_0_99M/peripheral_aresetn] \
                 [get_bd_pins axi_dma_0/axi_resetn] \
                 [get_bd_pins stereo_iir_filter_0/aresetn] \
                 [get_bd_pins ps8_0_axi_periph/ARESETN] \
                 [get_bd_pins axi_smc/aresetn] \
                 [get_bd_pins axi_smc_1/aresetn]

  # ------------------------------------------------------------
  # ADDRESS MAP
  # ------------------------------------------------------------

  assign_bd_address -offset 0xA0000000 -range 0x00010000 \
    [get_bd_addr_segs axi_dma_0/S_AXI_LITE/Reg] \
    [get_bd_addr_spaces zynq_ultra_ps_e_0/Data]

  assign_bd_address -offset 0xA0010000 -range 0x00001000 \
    [get_bd_addr_segs stereo_iir_filter_0/s_axi/reg0] \
    [get_bd_addr_spaces zynq_ultra_ps_e_0/Data]

  assign_bd_address -offset 0x00000000 -range 0x80000000 \
    [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_LOW] \
    [get_bd_addr_spaces axi_dma_0/Data_MM2S]

  assign_bd_address -offset 0x00000000 -range 0x80000000 \
    [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP3/HP1_DDR_LOW] \
    [get_bd_addr_spaces axi_dma_0/Data_S2MM]

  # ------------------------------------------------------------
  validate_bd_design
  save_bd_design
}

create_root_design ""
