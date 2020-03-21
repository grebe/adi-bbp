#!/bin/bash

function die()
{
  echo "$*" 1>&2
  exit 1
}

usage()
{
  echo "touchup_for_icarus.sh <filename>:"
  echo "  filename: a verilog file to modify for icarus"
}

# check for arguments
[ -n "$1" ] || die "$(usage)"
[ -f "$1" ] || die "File $1 not found"

# add timescale to top (icarus needs this)
sed -i '1s/^/`timescale 1ns\/1ps\n\n/' $1

# add vcd dump
sed -i '$s/^/ initial begin\n/' $1
sed -i '$s/^/   \$dumpfile\(\"dump\.vcd\"\);\n/' $1
sed -i '$s/^/   \$dumpvars;\n/' $1
sed -i '$s/^/ end\n/' $1
