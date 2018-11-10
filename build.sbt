name := "baseband"
organization := "edu.berkeley.cs"
version := "0.1-SNAPSHOT"
scalaVersion := "2.12.7"
scalacOptions ++= Seq(
  "-Xsource:2.11",
  "-deprecation",
  "-explaintypes",
  "-feature",
  "-language:reflectiveCalls",
  "-Xcheckinit",
  "-Xlint:infer-any",
  "-Xlint:missing-interpolator",
  "-Ywarn-unused:imports",
  "-Ywarn-unused:locals",
  "-Ywarn-value-discard",
)
libraryDependencies += "edu.berkeley.cs" %% "chisel3" % "3.1.3"

// libraryDependencies += "edu.berkeley.cs" %% "rocket-dsptools" % "1.2-SNAPSHOT"
