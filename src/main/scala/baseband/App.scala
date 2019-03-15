package baseband

import freechips.rocketchip.diplomacy.LazyModule

object BasebandApp extends App {
  chisel3.Driver.execute(
    args ++ Array[String](),
    () => LazyModule(new Baseband).module
  )
}
