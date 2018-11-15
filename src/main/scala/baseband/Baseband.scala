package baseband

import chisel3._
import chisel3.experimental.MultiIOModule

class Baseband extends MultiIOModule {
  val adcWidth = 16
  val dacWidth = 16

  // adc inputs
  val adc_valid_i0 = IO(Input(Bool()))
  // val adc_en_i0 = IO(Input(Bool()))
  val adc_data_i0 = IO(Input(UInt(adcWidth.W)))
  val adc_valid_q0 = IO(Input(Bool()))
  // val adc_en_q0 = IO(Input(Bool()))
  val adc_data_q0 = IO(Input(UInt(adcWidth.W)))
  val adc_valid_i1 = IO(Input(Bool()))
  // val adc_en_i1 = IO(Input(Bool()))
  val adc_data_i1 = IO(Input(UInt(adcWidth.W)))
  val adc_valid_q1 = IO(Input(Bool()))
  // val adc_en_q1 = IO(Input(Bool()))
  val adc_data_q1 = IO(Input(UInt(adcWidth.W)))

  // dac outputs
  val dac_valid_i0 = IO(Input(Bool()))
  val dac_enable_i0 = IO(Input(Bool()))
  val dac_data_i0 = IO(Output(UInt(dacWidth.W)))
  val dac_valid_q0 = IO(Input(Bool()))
  val dac_enable_i1 = IO(Input(Bool()))
  val dac_data_q0 = IO(Output(UInt(dacWidth.W)))
  val dac_valid_i1 = IO(Input(Bool()))
  val dac_enable_q0 = IO(Input(Bool()))
  val dac_data_i1 = IO(Output(UInt(dacWidth.W)))
  val dac_valid_q1 = IO(Input(Bool()))
  val dac_enable_q1 = IO(Input(Bool()))
  val dac_data_q1 = IO(Output(UInt(dacWidth.W)))
  
  // dma -> dac IOs
  val dma_valid_i0 = IO(Output(Bool()))
  val dma_enable_i0 = IO(Output(Bool()))
  val dma_data_i0 = IO(Input(UInt(dacWidth.W)))
  val dma_valid_out_i0 = IO(Input(Bool()))
  val dma_valid_i1 = IO(Output(Bool()))
  val dma_enable_i1 = IO(Output(Bool()))
  val dma_data_i1 = IO(Input(UInt(dacWidth.W)))
  val dma_valid_out_i1 = IO(Input(Bool()))
  val dma_valid_q0 = IO(Output(Bool()))
  val dma_enable_q0 = IO(Output(Bool()))
  val dma_data_q0 = IO(Input(UInt(dacWidth.W)))
  val dma_valid_out_q0 = IO(Input(Bool()))
  val dma_valid_q1 = IO(Output(Bool()))
  val dma_enable_q1 = IO(Output(Bool()))
  val dma_data_q1 = IO(Input(UInt(dacWidth.W)))
  val dma_valid_out_q1 = IO(Input(Bool()))

  val dma_dunf = IO(Input(Bool()))
  val dac_dunf = IO(Output(Bool()))

  // axi interface
  val s_axi_aclk = IO(Input(Clock()))
  val s_axi_aresetn = IO(Input(Bool()))
  val s_axi_awvalid = IO(Input(Bool()))
  val s_axi_awaddr = IO(Input(UInt(32.W)))
  val s_axi_awprot = IO(Input(UInt(3.W)))
  val s_axi_awready = IO(Output(Bool()))
  val s_axi_wvalid = IO(Input(Bool()))
  val s_axi_wdata = IO(Input(UInt(32.W)))
  val s_axi_wstrb = IO(Input(UInt(4.W)))
  val s_axi_wready = IO(Output(Bool()))
  val s_axi_bvalid = IO(Output(Bool()))
  val s_axi_bresp = IO(Output(UInt(2.W)))
  val s_axi_bready = IO(Input(Bool()))
  val s_axi_arvalid = IO(Input(Bool()))
  val s_axi_araddr = IO(Input(UInt(32.W)))
  val s_axi_arprot = IO(Input(UInt(3.W)))
  val s_axi_arready = IO(Output(Bool()))
  val s_axi_rvalid = IO(Output(Bool()))
  val s_axi_rdata = IO(Output(UInt(32.W)))
  val s_axi_rresp = IO(Output(UInt(2.W)))
  val s_axi_rready = IO(Input(Bool()))

  dac_data_i0 := dma_data_i0
  dac_data_q0 := dma_data_q0
  dac_data_i1 := dma_data_i1
  dac_data_q1 := dma_data_q1

  dac_dunf := dma_dunf

  dma_valid_i0 := dac_valid_i0
  dma_enable_i0 := dac_enable_i0
  dma_valid_i1 := dac_valid_i1
  dma_enable_i1 := dac_enable_i1
  dma_valid_q0 := dac_valid_q0
  dma_enable_q0 := dac_enable_q0
  dma_valid_q1 := dac_valid_q1
  dma_enable_q1 := dac_enable_q1

  s_axi_awready := false.B
  s_axi_wready := false.B
  s_axi_bvalid := false.B
  s_axi_bresp := 0.U
  s_axi_arready := false.B
  s_axi_rvalid := false.B
  s_axi_rdata := 0.U
  s_axi_rresp := 0.U
}
