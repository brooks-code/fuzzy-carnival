#!/bin/bash
######################################################################
# Script:       daily_bashrc.sh
#
# Description:  This script is sourced during user login via the bash
#               configuration to update and display the daily message.
#
#               Its functionality includes:
#                 - Checking if the daily message file (~/.dailyword) exists
#                   or is outdated (based on the current date) and regenerating
#                   it by executing the main dailyword script.
#                 - Appending a "# last_displayed <date>" marker to the file to
#                   indicate when the message was last displayed.
#                 - Providing a command alias ("oogf") and a function to display
#                   the daily message without the marker line.
#
# Usage:        The script is intended to be sourced from the user’s .bashrc
#               file during shell startup. The alias "oogf" is made available
#               for manual message refresh.
#
# Caution:      Ensure that /opt/dailyword/dailyword.sh exists and is executable.
#
# Author:       github.com/brooks-code
# Date:         2025-04-15
#
######################################################################

MSG_FILE="$HOME/.dailyword"

# Regenerate the daily message if needed.
if [ ! -f "$MSG_FILE" ] || [ "$(date +%Y%m%d)" != "$(date +%Y%m%d -r "$MSG_FILE")" ]; then
  /opt/dailyword/dailyword.sh >"$MSG_FILE"
fi

# Check if marker is present.
if ! grep -q "^# last_displayed $(date +%Y%m%d)$" "$MSG_FILE"; then
  grep -v "^# last_displayed" "$MSG_FILE"
  echo "# last_displayed $(date +%Y%m%d)" >>"$MSG_FILE"
fi

# Function and alias for manual daily message refresh.
display_daily_message() {
  grep -v "^# last_displayed" "$MSG_FILE"
}

alias oogf='display_daily_message'
