#!/bin/bash
MODDIR=${0%/*}
LOCK_FILE="$MODDIR/mpid.txt"
if [ -f "$LOCK_FILE" ]; then
  rm -f "$LOCK_FILE"
fi