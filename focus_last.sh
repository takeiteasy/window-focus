#!/bin/bash

FOCUS="/Users/lain/._/focus_blur/."

PID=$(ps | grep -Eo '[0-9]{5}' | sed '3!d')
TEST=$(swift active_windows.swift | grep $PID)
while [ $? -ne 0 ]; do
  printf '.'
  TEST=$(swift active_windows.swift | grep $PID)
done
electron $FOCUS$(echo "$TEST" | grep -Eo 'kCGWindowOwnerName": [0-9a-zA-Z]+' | cut -d: -f2)
