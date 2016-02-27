#!/usr/bin/env bash

let "PID = $$ - 1"
TEST=$(swift active_windows.swift | grep $PID)
while [ $? -ne 0 ]; do
  printf '.'
  TEST=$(swift active_windows.swift | grep $PID)
done
focus "$(echo "$TEST" | grep -Eo 'kCGWindowOwnerName": [0-9a-zA-Z]+' | cut -d: -f2)"
