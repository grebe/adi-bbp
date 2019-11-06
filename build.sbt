name := "baseband"
organization := "edu.berkeley.cs"
version := "0.1-SNAPSHOT"
scalaVersion := "2.12.10"
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

resolvers += Resolver.sonatypeRepo("snapshots")

libraryDependencies += "edu.berkeley.cs" %% "ofdm-rocket" % "0.1-SNAPSHOT"
