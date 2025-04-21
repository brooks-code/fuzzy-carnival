#!/bin/bash
#########################################################################
# Script Name:   dailyword.sh
# Description:   Reads word definitions from a CSV file, selects a random
#                candidate (that hasn't been shown yet) and displays it
#                with a gradient. Furthermore, the CSV is updated to
#                mark the shown candidate as displayed.
#
# Author:        AE5 .C432 1728
# Created:       2025-04-15
# Last Updated:  2025-04-15
#
# Usage:
#   ./dailyword.sh
#
# Requirements:
#   - Bash shell
#   - CSV file at data/daily_words.csv with expected columns:
#       field 1: word (mot in french)
#       field 2: genre code (e.g. m, f)
#       ...
#       field 6: definitions
#       field 7: last shown date
#
# License:       The Unlicense (see https://unlicense.org/)
#
#########################################################################

# --- CONFIGURATION & CONSTANTS ---
# Define the directory where the script is located
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# Define the CSV file path relative to the script's location
CSV_FILE="$SCRIPT_DIR/data/daily_words.csv"

# Define the temporary file path
TEMP_FILE="$(mktemp /tmp/temp.XXXX.csv)"

ASCII_ART="   _      _ _ _                     ___           
 _//     ' ) ) )   _/_      /      (   /          
 /   _    / / / __ /     __/        __/___     __ 
/___|/_  /   (_(_)/__   (_/ (_/    / / (_)(_/_/ (_  
                                  (_/             "
ASCII_COLOR="184;115;51" # Copper color

TODAY_DATE=$(date +"%Y-%m-%d")
TODAY_QUOTED="\"$TODAY_DATE\""

# Color gradient configuration.
readonly SCALE=1000
GRADIENT_START=(0 128 128) # Teal color start: R=0, G=128, B=128
GRADIENT_END=(255 140 0)   # Dark Orange color end: R=255, G=140, B=0

# --- UTILITY FUNCTIONS ---

#########################################################################
# Function: clean_field
# Description: Removes surrounding quotes from a string.
# Example:
#         Original: "Hello, World!"
#         Cleaned: Hello, World!
#
# Parameters:
#   $1 - The string (field) to be cleaned.
# Returns:
#   The cleaned field.
#########################################################################
clean_field() {
  local field="$1"
  field="${field%\"}"
  field="${field#\"}"
  echo "$field"
}

#########################################################################
# Function: map_genre
# Description: Maps a short genre code to its full descriptive label.
#
# Parameters:
#   $1 - The genre code (e.g., m, f).
# Returns:
#   The full label for the genre (e.g., "nom masculin", "nom féminin").
#########################################################################
map_genre() {
  local code
  code=$(clean_field "$1")
  case "$code" in
  m) echo "nom masculin" ;;
  f) echo "nom féminin" ;;
  *) echo "" ;;
  esac
}

#########################################################################
# Function: gradient_print
# Description: Prints a given text with a smooth gradient transition from
#              GRADIENT_START to GRADIENT_END with integer scale precision.
# Parameters:
#   $1 - The text string to be printed.
#########################################################################
gradient_print() {
  local text="$1"
  local len=${#text} i char ratio r g b
  for ((i = 0; i < len; i++)); do
    char="${text:$i:1}"
    if [ $((len - 1)) -gt 0 ]; then
      ratio=$((i * SCALE / (len - 1)))
    else
      ratio=0
    fi
    r=$((GRADIENT_START[0] + ((GRADIENT_END[0] - GRADIENT_START[0]) * ratio) / SCALE))
    g=$((GRADIENT_START[1] + ((GRADIENT_END[1] - GRADIENT_START[1]) * ratio) / SCALE))
    b=$((GRADIENT_START[2] + ((GRADIENT_END[2] - GRADIENT_START[2]) * ratio) / SCALE))
    printf "\033[38;2;%d;%d;%dm%s\033[0m" "$r" "$g" "$b" "$char"
  done
  echo ""
}

#########################################################################
# Function: gradient_print_multiline
# Description: Prints multi-line text using gradient_print for each line.
# Parameters:
#   $1 - The multi-line text to be printed.
#########################################################################
gradient_print_multiline() {
  while IFS= read -r line; do
    gradient_print "$line"
  done <<<"$1"
}

#########################################################################
# Function: process_definition
# Description: Cleans a candidate definition, and if it contains '|'
#              separators, splits it into numbered parts.
# Example :
# input: "definition 1 | definition 2"
# output: 1. definition 1
#         2. definition 2

# Parameters:
#   $1 - The raw candidate definition.
# Returns:
#   The processed definition string.
#########################################################################
process_definition() {
  local def
  def=$(clean_field "$1")
  if [[ "$def" == *"|"* ]]; then
    IFS="|" read -ra parts <<<"$def"
    local output=""
    local i=1
    for part in "${parts[@]}"; do
      # Remove leading/trailing whitespace.
      part=$(echo "$part" | sed 's/^[ \t]*//;s/[ \t]*$//')
      output+="$i. $part"$'\n'
      ((i++))
    done
    echo -n "$output"
  else
    echo "$def"
  fi
}

# --- MAIN SCRIPT ---

# Check the CSV file exists.
if [ ! -f "$CSV_FILE" ]; then
  echo "Error: CSV file not found: $CSV_FILE"
  exit 1
fi

#########################################################################
# Step: Extract Candidate Definition
# Description: Uses AWK to extract and randomly select a candidate
#              definition (field 6) and its associated word/genre pairs.

# Output Format: <candidate_definition>|||<word1,genre1>;;<word2,genre2>;;...
#########################################################################
AWK_OUTPUT=$(awk -v today="$TODAY_QUOTED" '
BEGIN {
  FPAT = "([^,]+)|(\"[^\"]+\")"
  srand()   # Seed random generator
}
NR > 1 {
  candidate_def = $6
  shown_date    = $7
  # Build an array of pairs for every candidate.
  words[candidate_def] = (candidate_def in words ? words[candidate_def] ";;" : "") $1 "," $2

  # Only accumulate candidates that have never been shown.
  if (shown_date == "\"\"") {
    candidate_list[++count] = candidate_def
  }
}
END {
  if (count == 0) { exit }
  idx = int(rand() * count) + 1
  print candidate_list[idx] "|||" words[candidate_list[idx]]
}' "$CSV_FILE")

if [ -z "$AWK_OUTPUT" ]; then
  echo "No more definitions to display."
  exit 0
fi

# Parse AWK output into candidate definition and word/genre pairs.
CANDIDATE_DEF="${AWK_OUTPUT%%|||*}"
WORDS_GENRES="${AWK_OUTPUT#*|||}"

#########################################################################
# Step: Build displayed string from Word/Genre Pairs
# Description: Constructs the definition string from the WORDS_GENRES data.
#########################################################################
DEFINITION=""
IFS=';;' read -ra pairs <<<"$WORDS_GENRES"
for pair in "${pairs[@]}"; do
  IFS=',' read -r word genre <<<"$pair"
  word_clean=$(clean_field "$word")
  # Skip empty words to avoid redundant commas.
  if [ -z "$word_clean" ]; then
    continue
  fi
  genre_label=$(map_genre "$genre")
  if [ -n "$genre_label" ]; then
    DEFINITION+="${word_clean} (${genre_label}), "
  else
    DEFINITION+="${word_clean}, "
  fi
done
DEFINITION=$(echo "$DEFINITION" | sed 's/,\s*$//')
DEFINITION="$DEFINITION :"

#########################################################################
# Step: Process and display Candidate definition with gradients.
#########################################################################
FORMATTED_DEF=$(process_definition "$CANDIDATE_DEF")
printf "\033[38;2;%sm%s\033[0m\n" "$ASCII_COLOR" "$ASCII_ART"
gradient_print "$DEFINITION"
gradient_print_multiline "$FORMATTED_DEF"

#########################################################################
# Step: Update CSV
# Description: Update the CSV file entry of the selected candidate
#              definition by marking it with today's date.
#########################################################################
awk -v today="\"$TODAY_DATE\"" -v candidate="$CANDIDATE_DEF" '
BEGIN { FPAT = "([^,]+)|(\"[^\"]+\")"; OFS = "," }
NR == 1 { print; next }
{
  if ($6 == candidate && $7 != today) { $7 = today }
  print
}
' "$CSV_FILE" >"$TEMP_FILE" && mv "$TEMP_FILE" "$CSV_FILE" && chmod --reference="$CSV_FILE" "$CSV_FILE" || {
  echo "Error: CSV file was not updated."
  rm -f "$TEMP_FILE"
}
