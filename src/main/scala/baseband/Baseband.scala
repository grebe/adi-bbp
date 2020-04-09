package baseband

import chisel3._
import chisel3.experimental.FixedPoint
import dsptools.DspContext
import dsptools.numbers._
import freechips.rocketchip.amba.axi4._
import freechips.rocketchip.amba.axi4stream._
import freechips.rocketchip.config.Parameters
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.interrupts.{IntSinkNode, IntSinkParameters, IntSinkPortParameters, IntXbar}
import freechips.rocketchip.subsystem.CrossingWrapper
import ofdm._

class Baseband(
  val adcWidth: Int = 16,
  val dacWidth: Int = 16,
  val csrAddress: AddressSet = AddressSet(0x79040000L, 0xFF),
  val alignAddress: AddressSet = AddressSet(0x79040100L, 0xFF),
  val skidAddress: AddressSet = AddressSet(0x79040200L, 0xFF),
  val streamOutMuxAddress: AddressSet = AddressSet(0x79040300L, 0xFF),
  val mstAddress: AddressSet = AddressSet(0x0, 0x3FFFFFFFL),
  val ramAddress: AddressSet = AddressSet(0x79044000L, 0x3FFF),
) extends LazyModule()(Parameters.empty) {
  val beatBytes = 4
  val protoIn = DspComplex(FixedPoint(16.W, 14.BP), FixedPoint(16.W, 14.BP))
  val rxParams = RXParams(
    protoADC = protoIn,
    protoAngle = FixedPoint(20.W, 17.BP),
    // protoFFTIn = DspComplex(FixedPoint(20.W, 14.BP), FixedPoint(20.W, 14.BP)),
    protoFFTIn = DspComplex(FixedPoint(16.W, 10.BP), FixedPoint(16.W, 10.BP)),
    protoTwiddle = DspComplex(FixedPoint(20.W, 14.BP), FixedPoint(20.W, 14.BP)),
    protoLLR = FixedPoint(6.W, 2.BP),
    maxNumPeaks = 256,
    timeStampWidth = 32,
    nFFT = 64,
    autocorrParams = AutocorrParams(
      protoIn = protoIn,
      protoOut = Some(DspComplex(FixedPoint(24.W, 15.BP))),
      maxApart = 256,
      maxOverlap = 256,
    ),
    ncoParams = NCOParams(
      phaseWidth = 16,
      tableSize = 64,
      phaseConv = u => u.asTypeOf(FixedPoint(20.W, 17.BP)),
      protoFreq = FixedPoint(16.W, 8.BP),
      protoOut = FixedPoint(16.W, 14.BP),
    ),
  )
  val context = DspContext.current.copy(
    numAddPipes = 1,
    numMulPipes = 3,
  )

  val sAxiIsland = LazyModule(new CrossingWrapper(AsynchronousCrossing(safe=true)) with HasAXI4StreamCrossing)
  val dma = sAxiIsland { LazyModule(new StreamingAXI4DMAWithCSR(csrAddress = csrAddress, beatBytes = beatBytes)) }
  val timeRx = sAxiIsland { LazyModule(new AXI4TimeDomainRXBlock(rxParams, AddressSet(0x400, 0x3FF))) }
  val freqRx = DspContext.alter(context) {
    sAxiIsland { LazyModule(new AXI4FreqDomainRXBlock(rxParams)) }
  }
  val (inputStreamMux, inputStreamMuxMem) = sAxiIsland { StreamMux.axi(AddressSet(0x300, 0xFF), beatBytes = 4) }
  val (splitter, splitterMem) = sAxiIsland { StreamMux.axi(AddressSet(0x900, 0xFF), beatBytes = 4) }

  val (skidStream, skidMem, skidIntSource) = sAxiIsland { AXI4SkidBuffer(skidAddress, depth = 512, beatBytes = 4) }
  val intSink =
    IntSinkNode(Seq(IntSinkPortParameters(Seq(IntSinkParameters()))))
    // sAxiIsland { IntSinkNode(Seq(IntSinkPortParameters(Seq(IntSinkParameters())))) }
  val intXbar = sAxiIsland { IntXbar(Parameters.empty) }

  val axiMasterNode = AXI4MasterNode(Seq(AXI4MasterPortParameters(Seq(AXI4MasterParameters(
    "baseband",
  )))))
  val axiSlaveNode = AXI4SlaveNode(Seq(AXI4SlavePortParameters(Seq(AXI4SlaveParameters(
    address = mstAddress.subtract(ramAddress),
    supportsWrite = TransferSizes(4, 512),
    supportsRead = TransferSizes(4, 512),
  )), beatBytes = beatBytes)))

  val streamNodeMaster = AXI4StreamMasterNode(AXI4StreamMasterParameters(n = 4, u = 0, numMasters = 1))
  val streamNodeSlave = AXI4StreamSlaveNode(AXI4StreamSlaveParameters(numEndpoints = 1, hasStrb = false))

  val (alignerStream, alignerAXI) = StreamAligner(addressSet = alignAddress, beatBytes = beatBytes)
  val xbar = sAxiIsland { AXI4Xbar() }

  // val gold = GoldSequence(n = beatBytes)
  // val streamOutMux = StreamMux(streamOutMuxAddress, beatBytes = beatBytes)

  // sAxiIsland.crossAXI4StreamIn(dma.streamNode := skidStream) :=
  // sAxiIsland.crossAXI4StreamIn(dma.streamNode := skidStream) :=
  sAxiIsland.crossAXI4StreamIn(splitter) :=
    // AXI4StreamBuffer() :=
    alignerStream :=
    // AXI4StreamBuffer() :=
    streamNodeMaster
  //inputStreamMux := streamNodeMaster
  //inputStreamMux := freqRx.streamNode := timeRx.streamNode

  streamNodeSlave :=
    AXI4StreamBuffer() :=
    // streamOutMux.streamNode
    sAxiIsland.crossAXI4StreamOut(dma.streamNode)
  // streamOutMux.streamNode := sAxiIsland.crossAXI4StreamOut(dma.streamNode)
  // streamOutMux.streamNode := gold

  alignerAXI := sAxiIsland.crossAXI4Out(xbar)
  // streamOutMux.axiNode := sAxiIsland.crossAXI4Out(xbar)
  sAxiIsland {
    // val scheduler = LazyModule(new AXI4_StreamScheduler(
    //   AddressSet(0x800, 0xFF),
    //   beatBytes = 4,
    //   counterOpt = None // Some(timeRx.module.rx.globalCycleCounter)
    // ))
    // scheduler.mem.get := xbar
    // scheduler.hardCoded := timeRx.schedule

    dma.streamNode := inputStreamMux
    inputStreamMux :=
      AXI4StreamWidthAdapter.oneToN(4) :=
      // AXI4StreamWidthAdapter.nToOne(13) :=
      // AXI4StreamWidthAdapter.oneToN(5) :=
      // AXI4StreamWidthAdapter.nToOne(4) :=
      freqRx.streamNode :=
      // scheduler.streamNode :=
      timeRx.streamNode :=
      splitter
    intSink := intXbar
    intXbar := timeRx.intnode
    inputStreamMux := skidStream := splitter
    intXbar := skidIntSource
    dma.axiSlaveNode := xbar
    skidMem := xbar
    timeRx.mem.get := xbar
    inputStreamMuxMem := xbar
    splitterMem := xbar
    xbar := axiMasterNode
    val ramXbar = AXI4Xbar()
    val masterXbar = AXI4Xbar()
    axiSlaveNode := masterXbar
    ramXbar := masterXbar
    masterXbar := dma.axiMasterNode
    AXI4RAM(ramAddress, beatBytes = beatBytes) :=
      AXI4Fragmenter() :=
      ramXbar
    ramXbar := xbar
  }

  lazy val module = DspContext.alter(context) { new LazyModuleImp(this) {
    val axiSlave = axiMasterNode.out.head._1
    val axiMaster = axiSlaveNode.in.head._1
    val streamIn = streamNodeMaster.out.head._1
    val streamOut = streamNodeSlave.in.head._1
    val intOut = intSink.in.head._1

    // adc inputs
    val adc_0_valid = IO(Input(Bool()))
    // I and Q concatenated
    val adc_0_data = IO(Input(UInt((2 * adcWidth).W)))
    val adc_0_ready = IO(Output(Bool()))
    // each bit indicates if I and/or Q is enabled
    val adc_0_user = IO(Input(UInt(2.W)))
    val adc_1_valid = IO(Input(Bool()))
    // I and Q concatenated
    val adc_1_data = IO(Input(UInt((2 * adcWidth).W)))
    val adc_1_ready = IO(Output(Bool()))
    // each bit indicates if I and/or Q is enabled
    val adc_1_user = IO(Input(UInt(2.W)))

    // dac outputs
    val dac_0_valid = IO(Output(Bool()))
    val dac_0_ready = IO(Input(Bool()))
    val dac_0_data  = IO(Output(UInt((2 * dacWidth).W)))
    // each bit indicates if I and/or Q is enabled
    val dac_0_user  = IO(Output(UInt(2.W)))
    val dac_1_valid = IO(Output(Bool()))
    val dac_1_ready = IO(Input(Bool()))
    val dac_1_data  = IO(Output(UInt((2 * dacWidth).W)))
    // each bit indicates if I and/or Q is enabled
    val dac_1_user  = IO(Output(UInt(2.W)))

    // dma -> dac IOs
    val dma_0_ready = IO(Output(Bool()))
    val dma_0_valid = IO(Input(Bool()))
    val dma_0_data = IO(Input(UInt((2 * dacWidth).W)))
    // each bit indicates if I and/or Q is enabled
    val dma_0_user = IO(Input(UInt(2.W)))
    val dma_1_ready = IO(Output(Bool()))
    val dma_1_valid = IO(Input(Bool()))
    val dma_1_data = IO(Input(UInt((2 * dacWidth).W)))
    // each bit indicates if I and/or Q is enabled
    val dma_1_user = IO(Input(UInt(2.W)))

    val dma_dunf = IO(Input(Bool()))
    val dac_dunf = IO(Output(Bool()))

    // axi master interface
    val m_axi_aresetn = IO(Output(Reset()))
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
    val m_axi_rlast = IO(Input(Bool()))
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

    val skid_ints = IO(Output(Vec(intOut.length, Bool())))
    skid_ints := intOut

    val axireset = WireInit(!s_axi_aresetn.asBool)

    sAxiIsland.module.clock := s_axi_aclk
    sAxiIsland.module.reset := axireset // !s_axi_aresetn

    adc_0_ready := streamIn.ready
    streamIn.valid := adc_0_valid
    streamIn.bits.data := adc_0_data
    streamIn.bits.user := adc_0_user
    streamIn.bits.last := false.B
    streamIn.bits.dest := 0.U
    streamIn.bits.id := 0.U
    streamIn.bits.keep := 0.U

    adc_1_ready := false.B // TODO

    streamOut.ready := dac_0_ready
    dac_0_data := streamOut.bits.data
    dac_0_user := streamOut.bits.user
    dac_0_valid := streamOut.valid

    dma_0_ready := true.B

    dma_1_ready := dac_1_ready
    dac_1_data := dma_1_data
    dac_1_user := dma_1_user
    dac_1_valid := dma_1_valid

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
    m_axi_wstrb := axiMaster.w.bits.strb
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
    axiMaster.r.bits.last := m_axi_rlast
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
  } }
}
