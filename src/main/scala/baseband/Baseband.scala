package baseband

import chisel3._
import freechips.rocketchip.amba.axi4._
import freechips.rocketchip.amba.axi4stream._
import freechips.rocketchip.config.Parameters
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.subsystem.CrossingWrapper

class Baseband(
  val adcWidth: Int = 16,
  val dacWidth: Int = 16,
  val csrAddress: AddressSet = AddressSet(0x0, 0xFFFF),
  val mstAddress: Seq[AddressSet] = Seq(AddressSet(0x0, 0xFFFF)),
) extends LazyModule()(Parameters.empty) {
  val sAxiIsland = LazyModule(new CrossingWrapper(AsynchronousCrossing(safe=false)) with HasAXI4StreamCrossing)

  val dma = sAxiIsland { LazyModule(new StreamingAXI4DMAWithCSR(csrAddress = csrAddress)) }

  val axiMasterNode = AXI4MasterNode(Seq(AXI4MasterPortParameters(Seq(AXI4MasterParameters(
    "baseband",
  )))))
  val axiSlaveNode = AXI4SlaveNode(Seq(AXI4SlavePortParameters(Seq(AXI4SlaveParameters(
    address = mstAddress,
    supportsWrite = TransferSizes(4, 512),
    supportsRead = TransferSizes(4, 512),
  )), beatBytes = 4)))

  val axiMasterIslandNode = AXI4IdentityNode()
  val axiSlaveIslandNode = AXI4IdentityNode()

  axiMasterIslandNode := axiMasterNode
  axiSlaveNode := axiSlaveIslandNode

  val streamNodeMaster = AXI4StreamMasterNode(AXI4StreamMasterParameters(n = 4, u=1, numMasters = 2))
  val streamNodeSlave = AXI4StreamSlaveNode(AXI4StreamSlaveParameters(numEndpoints = 2, hasStrb = true))

  val aligner = StreamAligner(addressSet = AddressSet(0x10000, 0xFFFF))
  val xbar = sAxiIsland { AXI4Xbar() }

  sAxiIsland { axiSlaveIslandNode := dma.axiMasterNode }
  sAxiIsland.crossAXI4StreamIn(dma.streamNode) := aligner._1 := streamNodeMaster
  streamNodeSlave := sAxiIsland.crossAXI4StreamOut(dma.streamNode)

  aligner._2 := sAxiIsland.crossAXI4Out(xbar)
  sAxiIsland {
    dma.axiSlaveNode := xbar
    xbar := axiMasterIslandNode
  }

  lazy val module = new LazyModuleImp(this) {
    val axiSlave = axiMasterNode.out.head._1
    val axiMaster = axiSlaveNode.in.head._1
    val streamIn = streamNodeMaster.out.head._1
    val streamOut = streamNodeSlave.in.head._1

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

    // axi master interface
    val m_axi_aclk = IO(Input(Clock()))
    val m_axi_aresetn = IO(Output(Bool()))
    val m_axi_awvalid = IO(Output(Bool()))
    val m_axi_awaddr = IO(Output(UInt(32.W)))
    val m_axi_awprot = IO(Output(UInt(3.W)))
    val m_axi_awready = IO(Input(Bool()))
    val m_axi_wvalid = IO(Output(Bool()))
    val m_axi_wdata = IO(Output(UInt(32.W)))
    val m_axi_wstrb = IO(Output(UInt(4.W)))
    val m_axi_wready = IO(Input(Bool()))
    val m_axi_bvalid = IO(Input(Bool()))
    val m_axi_bresp = IO(Input(UInt(2.W)))
    val m_axi_bready = IO(Output(Bool()))
    val m_axi_arvalid = IO(Output(Bool()))
    val m_axi_araddr = IO(Output(UInt(32.W)))
    val m_axi_arprot = IO(Output(UInt(3.W)))
    val m_axi_arready = IO(Input(Bool()))
    val m_axi_rvalid = IO(Input(Bool()))
    val m_axi_rdata = IO(Input(UInt(32.W)))
    val m_axi_rresp = IO(Input(UInt(2.W)))
    val m_axi_rready = IO(Output(Bool()))

    // axi slave interface
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

    sAxiIsland.module.clock := s_axi_aclk
    sAxiIsland.module.reset := !s_axi_aresetn

    streamIn.valid := adc_valid_i0 && adc_valid_q0
    streamIn.bits.data := util.Cat(adc_data_i0, adc_data_q0)
    streamIn.bits.dest := 1.U
    streamIn.bits.id := 1.U
    streamIn.bits.keep := 1.U

    streamOut.ready := dac_enable_i0 && dac_enable_q0
    dac_data_i0 := streamOut.bits.data(15, 0)
    dac_data_q0 := streamOut.bits.data(31, 16)

    dac_data_i1 := 0.U
    dac_data_q1 := 0.U

    m_axi_awvalid := axiMaster.aw.valid
    m_axi_awaddr := axiMaster.aw.bits.addr
    m_axi_awprot := axiMaster.aw.bits.prot
    axiMaster.aw.ready := m_axi_awready

    m_axi_wvalid := axiMaster.w.valid
    m_axi_wdata := axiMaster.w.bits.data
    m_axi_wstrb := axiMaster.w.bits.strb
    axiMaster.w.ready := m_axi_wready

    axiMaster.b.valid := m_axi_bvalid
    axiMaster.b.bits.resp := m_axi_bresp
    m_axi_bready := axiMaster.b.ready

    m_axi_arvalid := axiMaster.ar.valid
    m_axi_araddr := axiMaster.ar.bits.addr
    m_axi_arprot := axiMaster.ar.bits.prot
    axiMaster.ar.ready := m_axi_arready

    axiMaster.r.valid := m_axi_rvalid
    axiMaster.r.bits.data := m_axi_rdata
    axiMaster.r.bits.resp := m_axi_rresp
    m_axi_rready := axiMaster.r.ready

    axiSlave.aw.valid := s_axi_awvalid
    axiSlave.aw.bits.addr := s_axi_awaddr
    axiSlave.aw.bits.prot := s_axi_awprot
    s_axi_awready := axiSlave.aw.ready

    axiSlave.w.valid := s_axi_wvalid
    axiSlave.w.bits.data := s_axi_wdata
    axiSlave.w.bits.strb := s_axi_wstrb
    s_axi_wready := axiSlave.w.ready

    s_axi_bvalid := axiSlave.b.valid
    s_axi_bresp := axiSlave.b.bits.resp
    axiSlave.b.ready := s_axi_bready

    axiSlave.ar.valid := s_axi_arvalid
    axiSlave.ar.bits.addr := s_axi_araddr
    axiSlave.ar.bits.prot := s_axi_arprot
    s_axi_arready := axiSlave.ar.ready

    s_axi_rvalid := axiSlave.r.valid
    s_axi_rdata := axiSlave.r.bits.data
    s_axi_rresp := axiSlave.r.bits.resp
    axiSlave.r.ready := s_axi_rready
  }
}
