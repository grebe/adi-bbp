#!/bin/bash

TARGETS="riscv64-unknown-elf arm-linux-gnueabihf x86_64-redhat-linux"

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

BUILD_DIR="${DIR}/build"


for TARGET in $TARGETS; do
  mkdir -p "${BUILD_DIR}/${TARGET}"
  cd "${BUILD_DIR}/${TARGET}"
  cmake -DCMAKE_C_COMPILER=${TARGET}-gcc -DCMAKE_CXX_COMPILER=${TARGET}-g++ "${DIR}"
  cd -
done
