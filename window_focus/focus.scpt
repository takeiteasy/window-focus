tell application "%s"
  if it is running then
    activate
  else
    tell application "System Events"
      set frontmost of process "%s" to true
    end tell
  end if
end tell
