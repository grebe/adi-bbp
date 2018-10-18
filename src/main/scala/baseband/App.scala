package baseband

object BasebandApp extends App {
  chisel3.Driver.execute(
    args ++ Array[String](),
    () => new Baseband
  )
}
