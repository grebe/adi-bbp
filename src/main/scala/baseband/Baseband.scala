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
  val csrAddress: AddressSet = AddressSet(0, 0xFF),
  val mstAddress: Seq[AddressSet] = Seq(AddressSet(0x0, BigInt("FF" * 4, 16))),
) extends LazyModule()(Parameters.empty) {
  val beatBytes = 4
  val sAxiIsland = LazyModule(new CrossingWrapper(AsynchronousCrossing(safe=false)) with HasAXI4StreamCrossing)

  val dma = sAxiIsland { LazyModule(new StreamingAXI4DMAWithCSR(csrAddress = csrAddress, beatBytes = beatBytes)) }

  val axiMasterNode = AXI4MasterNode(Seq(AXI4MasterPortParameters(Seq(AXI4MasterParameters(
    "baseband",
  )))))
  val axiSlaveNode = AXI4SlaveNode(Seq(AXI4SlavePortParameters(Seq(AXI4SlaveParameters(
    address = mstAddress,
    supportsWrite = TransferSizes(4, 512),
    supportsRead = TransferSizes(4, 512),
  )), beatBytes = beatBytes)))

  // val axiMasterIslandNode = AXI4IdentityNode()
  // val axiSlaveIslandNode = AXI4IdentityNode()

  // axiMasterIslandNode := axiMasterNode
  // axiSlaveNode := axiSlaveIslandNode

  val streamNodeMaster = AXI4StreamMasterNode(AXI4StreamMasterParameters(n = 4, u=1, numMasters = 1))
  val streamNodeSlave = AXI4StreamSlaveNode(AXI4StreamSlaveParameters(numEndpoints = 1, hasStrb = true))

  val (alignerStream, alignerAXI) = StreamAligner(addressSet = AddressSet(0x100, 0xFF), beatBytes = beatBytes)
  val xbar = sAxiIsland { AXI4Xbar() }

  sAxiIsland.crossAXI4StreamIn(dma.streamNode) :=
    // AXI4StreamWidthAdapter.nToOne(2) :=
    AXI4StreamBuffer() :=
    alignerStream :=
    AXI4StreamBuffer() :=
    streamNodeMaster

  streamNodeSlave :=
    AXI4StreamBuffer() :=
    // AXI4StreamWidthAdapter.oneToN(2) :=
    sAxiIsland.crossAXI4StreamOut(dma.streamNode)

  alignerAXI := sAxiIsland.crossAXI4Out(xbar)
  sAxiIsland {
    dma.axiSlaveNode := xbar
    xbar := axiMasterNode // axiMasterIslandNode
    // axiSlaveIslandNode := dma.axiMasterNode
    axiSlaveNode := dma.axiMasterNode
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
    val m_axi_awid = IO(Output(Bool()))
    val m_axi_awaddr = IO(Output(UInt((beatBytes * 8).W)))
    val m_axi_awlen = IO(Output(UInt(8.W)))
    val m_axi_awsize = IO(Output(UInt(4.W)))
    val m_axi_awburst = IO(Output(UInt(3.W)))
    val m_axi_awlock = IO(Output(UInt(2.W)))
    val m_axi_awcache = IO(Output(UInt(4.W)))
    val m_axi_awprot = IO(Output(UInt(3.W)))
    val m_axi_awready = IO(Input(Bool()))
    val m_axi_wvalid = IO(Output(Bool()))
    val m_axi_wdata = IO(Output(UInt((beatBytes * 8).W)))
    val m_axi_wstrb = IO(Output(UInt(beatBytes.W)))
    val m_axi_wlast = IO(Output(Bool()))
    val m_axi_wready = IO(Input(Bool()))
    val m_axi_bvalid = IO(Input(Bool()))
    val m_axi_bid = IO(Input(Bool()))
    val m_axi_bresp = IO(Input(UInt(2.W)))
    val m_axi_bready = IO(Output(Bool()))
    val m_axi_arvalid = IO(Output(Bool()))
    val m_axi_arid = IO(Output(Bool()))
    val m_axi_araddr = IO(Output(UInt((beatBytes * 8).W)))
    val m_axi_arlen = IO(Output(UInt(8.W)))
    val m_axi_arsize = IO(Output(UInt(4.W)))
    val m_axi_arburst = IO(Output(UInt(3.W)))
    val m_axi_arlock = IO(Output(UInt(2.W)))
    val m_axi_arcache = IO(Output(UInt(4.W)))
    val m_axi_arprot = IO(Output(UInt(3.W)))
    val m_axi_arready = IO(Input(Bool()))
    val m_axi_rvalid = IO(Input(Bool()))
    val m_axi_rid = IO(Input(Bool()))
    val m_axi_rdata = IO(Input(UInt((beatBytes * 8).W)))
    val m_axi_rresp = IO(Input(UInt(2.W)))
    val m_axi_rready = IO(Output(Bool()))

    // axi slave interface
    val s_axi_aclk = IO(Input(Clock()))
    val s_axi_aresetn = IO(Input(Bool()))
    val s_axi_awvalid = IO(Input(Bool()))
    val s_axi_awaddr = IO(Input(UInt((beatBytes * 8).W)))
    val s_axi_awprot = IO(Input(UInt(3.W)))
    val s_axi_awready = IO(Output(Bool()))
    val s_axi_wvalid = IO(Input(Bool()))
    val s_axi_wdata = IO(Input(UInt((beatBytes * 8).W)))
    val s_axi_wstrb = IO(Input(UInt(beatBytes.W)))
    val s_axi_wready = IO(Output(Bool()))
    val s_axi_bvalid = IO(Output(Bool()))
    val s_axi_bresp = IO(Output(UInt(2.W)))
    val s_axi_bready = IO(Input(Bool()))
    val s_axi_arvalid = IO(Input(Bool()))
    val s_axi_araddr = IO(Input(UInt((beatBytes * 8).W)))
    val s_axi_arprot = IO(Input(UInt(3.W)))
    val s_axi_arready = IO(Output(Bool()))
    val s_axi_rvalid = IO(Output(Bool()))
    val s_axi_rdata = IO(Output(UInt((beatBytes * 8).W)))
    val s_axi_rresp = IO(Output(UInt(2.W)))
    val s_axi_rready = IO(Input(Bool()))

    sAxiIsland.module.clock := s_axi_aclk
    sAxiIsland.module.reset := !s_axi_aresetn

    streamIn.valid := adc_valid_i0 && adc_valid_q0
    streamIn.bits.data := util.Cat(adc_data_i0, adc_data_q0)
    streamIn.bits.dest := 0.U
    streamIn.bits.id := 0.U
    streamIn.bits.keep := 0.U

    streamOut.ready := true.B
    dac_data_i0 := streamOut.bits.data(15, 0)
    dac_data_q0 := streamOut.bits.data(31, 16)

    dac_data_i1 := dma_data_i1
    dac_data_q1 := dma_data_q1

    dma_valid_i0 := streamOut.valid
    dma_valid_q0 := streamOut.valid

    dma_valid_i1 := dma_valid_out_i1
    dma_valid_q1 := dma_valid_out_q1

    dma_enable_i0 := dac_enable_i0
    dma_enable_q0 := dac_enable_q0
    dma_enable_i1 := dac_enable_i1
    dma_enable_q1 := dac_enable_q1

    dac_dunf := dma_dunf

    m_axi_aresetn := s_axi_aresetn

    m_axi_awvalid := axiMaster.aw.valid
    m_axi_awid := axiMaster.aw.bits.id
    m_axi_awaddr := axiMaster.aw.bits.addr
    m_axi_awlen := axiMaster.aw.bits.len
    m_axi_awsize := axiMaster.aw.bits.size
    m_axi_awburst := axiMaster.aw.bits.burst
    m_axi_awlock := axiMaster.aw.bits.lock
    m_axi_awcache := axiMaster.aw.bits.cache
    m_axi_awprot := axiMaster.aw.bits.prot
    axiMaster.aw.ready := m_axi_awready

    m_axi_wvalid := axiMaster.w.valid
    m_axi_wdata := axiMaster.w.bits.data
    m_axi_wstrb := 0xFFFFFFFFL.U // axiMaster.w.bits.strb
    m_axi_wlast := axiMaster.w.bits.last
    axiMaster.w.ready := m_axi_wready

    axiMaster.b.valid := m_axi_bvalid
    axiMaster.b.bits.id := m_axi_bid
    axiMaster.b.bits.resp := m_axi_bresp
    m_axi_bready := axiMaster.b.ready

    m_axi_arvalid := axiMaster.ar.valid
    m_axi_arid := axiMaster.ar.bits.id
    m_axi_araddr := axiMaster.ar.bits.addr
    m_axi_arlen := axiMaster.ar.bits.len
    m_axi_arsize := axiMaster.ar.bits.size
    m_axi_arburst := axiMaster.ar.bits.burst
    m_axi_arlock := axiMaster.ar.bits.lock
    m_axi_arcache := axiMaster.ar.bits.cache
    m_axi_arprot := axiMaster.ar.bits.prot
    axiMaster.ar.ready := m_axi_arready

    axiMaster.r.valid := m_axi_rvalid
    axiMaster.r.bits.id := m_axi_rid
    axiMaster.r.bits.data := m_axi_rdata
    axiMaster.r.bits.resp := m_axi_rresp
    m_axi_rready := axiMaster.r.ready

    axiSlave.aw.valid := s_axi_awvalid
    s_axi_awready := axiSlave.aw.ready
    axiSlave.aw.bits.id := 0.U
    axiSlave.aw.bits.addr := s_axi_awaddr
    axiSlave.aw.bits.len := 0.U
    axiSlave.aw.bits.size := 2.U
    axiSlave.aw.bits.burst := 1.U
    axiSlave.aw.bits.lock := 0.U
    axiSlave.aw.bits.cache := 3.U
    axiSlave.aw.bits.prot := s_axi_awprot

    axiSlave.w.valid := s_axi_wvalid
    axiSlave.w.bits.data := s_axi_wdata
    axiSlave.w.bits.strb := s_axi_wstrb
    axiSlave.w.bits.last := true.B
    s_axi_wready := axiSlave.w.ready

    s_axi_bvalid := axiSlave.b.valid
    s_axi_bresp := axiSlave.b.bits.resp
    axiSlave.b.ready := s_axi_bready

    axiSlave.ar.valid := s_axi_arvalid
    s_axi_arready := axiSlave.ar.ready
    axiSlave.ar.bits.id := 0.U
    axiSlave.ar.bits.addr := s_axi_araddr
    axiSlave.ar.bits.len := 0.U
    axiSlave.ar.bits.size := 2.U
    axiSlave.ar.bits.burst := 1.U
    axiSlave.ar.bits.lock := 0.U
    axiSlave.ar.bits.cache := 3.U
    axiSlave.ar.bits.prot := s_axi_arprot

    s_axi_rvalid := axiSlave.r.valid
    s_axi_rdata := axiSlave.r.bits.data
    s_axi_rresp := axiSlave.r.bits.resp
    axiSlave.r.ready := s_axi_rready
  }
}
