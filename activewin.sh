#!/bin/sh
osascript -e "set front_app to (path to frontmost application as Unicode text)
 set AppleScript's text item delimiters to \":\"
 set front_app to front_app's text items
 set AppleScript's text item delimiters to {\"\"}
 set item_num to (count of front_app) - 1
 set app_name to item item_num of front_app
 set AppleScript's text item delimiters to \".\"
 set app_name to app_name's text items
 set AppleScript's text item delimiters to {\"\"}
 log item 1 of app_name"
