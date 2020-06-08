package baseband

import chisel3._
import chisel3.util.log2Ceil
import freechips.rocketchip.amba.axi4.AXI4RegisterNode
import freechips.rocketchip.amba.axi4stream.{AXI4StreamBundlePayload, AXI4StreamIdentityNode}
import freechips.rocketchip.config.Parameters
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.regmapper.RegField

import ofdm.GlobalCycleCounter

class TimeGate(
  addressSet: AddressSet,
  beatBytes: Int = 4,
  counter: Option[GlobalCycleCounter] = None) extends LazyModule()(Parameters.empty) {

  val streamNode = AXI4StreamIdentityNode()

  val mem = AXI4RegisterNode(address = addressSet, beatBytes = beatBytes)

  lazy val module = new LazyModuleImp(this) {
    val en = RegInit(false.B)
    val globalCycleCounter = counter.getOrElse(GlobalCycleCounter(64, "tx"))
    val counterVal = globalCycleCounter()
    val gateTime = RegInit(0.U(64.W))

    val go = !en || (counterVal >= gateTime)

    val in = streamNode.in.head._1
    val out = streamNode.out.head._1

    out.bits := in.bits
    out.valid := in.valid && go
    in.ready := out.ready && go

    mem.regmap(
      0 * beatBytes -> Seq(RegField(1, en)),
      1 * beatBytes -> Seq(RegField(32, gateTime)),
    )
  }
}
