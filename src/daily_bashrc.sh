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
#                 - Appending a "# displayed <date>" marker to the file to
#                   indicate when the message was last displayed that helps..
#		  - .. avoiding the message display being consumed during boot process
#		    by displaying it only when the user is about to see the prompt
#		    in an interactive shell.
#                 - Providing a command alias ("oogf") and a function to recall
#                   the daily message.
#
# Usage:        The script is intended to be sourced from the user’s .bashrc
#               file during shell startup. The alias "oogf" is made available
#               for manual message refresh.
#
# Caution:      Ensure that /opt/dailyword/dailyword.sh exists and is executable.
#
# Author:       github.com/brooks-code
# Date:         2025-04-25
# Version:      1.0.1
#
######################################################################

# File to store the daily message and track display date.
MSG_FILE="$HOME/.dailyword"
TODAY=$(date +%Y%m%d)

# Regenerate the daily message if the file doesn't exist or is not from today.
if [ ! -f "$MSG_FILE" ] || [ "$(date +%Y%m%d -r "$MSG_FILE")" != "$TODAY" ]; then
  /opt/dailyword/dailyword.sh > "$MSG_FILE"
fi

# Function to handle the message display if it hasn't been shown today.
display_daily_if_needed() {
  # If today's marker is not found in the file, then display message and update marker.
  if ! grep -q "^# displayed $TODAY" "$MSG_FILE"; then
    # Display the message (ignoring any marker lines).
    grep -v "^# displayed" "$MSG_FILE"
    # Remove existing marker lines (if any) from MSG_FILE.
    sed -i '/^# displayed/d' "$MSG_FILE"
    # Write the new marker to the file.
    echo "# displayed $TODAY" >> "$MSG_FILE"
    # Remove this function from PROMPT_COMMAND so it runs only once.
    PROMPT_COMMAND=""
  fi
}

# Set PROMPT_COMMAND so the message is shown when the prompt is ready.
PROMPT_COMMAND="display_daily_if_needed; $PROMPT_COMMAND"

# Function and alias for manual daily message refresh.
display_daily_message() {
  grep -v "^# displayed" "$MSG_FILE"
}
alias oogf='display_daily_message'

