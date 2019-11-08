package baseband

import chisel3._
import freechips.rocketchip.amba.axi4._
import freechips.rocketchip.amba.axi4stream._
import freechips.rocketchip.config.Parameters
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.regmapper.{RegField, RegFieldDesc}

class StreamMux(
  addressSet: AddressSet,
  beatBytes: Int = 4,
) extends LazyModule()(Parameters.empty) {
  val streamNode = AXI4StreamNexusNode(
    masterFn = params => {
      require(params.length > 0)
      params.foreach { p =>
        require(p.masters.size == params.head.masters.size)
      }
      params.reduce( (x, y) =>
          AXI4StreamMasterPortParameters(
            x.masters.zip(y.masters).map({ case (x, y) => x.union(y)}) )
      )
    },
    slaveFn = params => {
      require(params.length > 0)
      params.foreach { p =>
        require(p.slaves.size == params.head.slaves.size)
      }
      params.reduce( (x, y) =>
          AXI4StreamSlavePortParameters(
            x.slaves.zip(y.slaves).map({ case (x, y) => x.union(y)}) )
      )
    }
  )

  val axiNode = AXI4RegisterNode(address = addressSet, beatBytes = beatBytes)

  lazy val module = new LazyModuleImp(this) {
    val streamIns = streamNode.in.map(_._1)
    print(streamIns)
    val streamOut = streamNode.out.head._1

    val sel = RegInit(0.U((beatBytes * 8).W))

    streamOut.bits := streamIns.head.bits
    for ((in, idx) <- streamIns.zipWithIndex) {
      in.ready := Mux(sel === idx.U, streamOut.ready, false.B)
      when (sel === idx.U) {
        streamOut.bits := in.bits
        streamOut.valid := in.valid
      }
    }

    axiNode.regmap(
      0 -> Seq(RegField(beatBytes * 8, sel,
        RegFieldDesc("sel", "select which output to use"))),
    )
  }
}

object StreamMux {
  def apply(addressSet: AddressSet, beatBytes: Int = 4)(implicit valName: ValName): StreamMux = {
    LazyModule(new StreamMux(addressSet = addressSet, beatBytes = beatBytes))
  }
}
