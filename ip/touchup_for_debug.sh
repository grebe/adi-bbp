#!/bin/bash

function die()
{
  echo "$*" 1>&2
  exit 1
}

usage()
{
  echo "touchup_for_debug.sh <filename>:"
  echo "  filename: a verilog file to modify for ILA debug attributes"
}

# check for arguments
[ -n "$1" ] || die "$(usage)"
[ -f "$1" ] || die "File $1 not found"

# add ILA signals
sed -i 's/\(output.*auto_stream_in.*ready\)/(\* MARK_DEBUG = "TRUE", DONT_TOUCH = "TRUE" \*)\n  \1/' $1
sed -i 's/\(input.*auto_stream_in.*valid\)/(\* MARK_DEBUG = "TRUE", DONT_TOUCH = "TRUE" \*)\n  \1/' $1
sed -i 's/\(input.*auto_stream_out.*ready\)/(\* MARK_DEBUG = "TRUE", DONT_TOUCH = "TRUE" \*)\n  \1/' $1
sed -i 's/\(output.*auto_stream_out.*valid\)/(\* MARK_DEBUG = "TRUE", DONT_TOUCH = "TRUE" \*)\n  \1/' $1
