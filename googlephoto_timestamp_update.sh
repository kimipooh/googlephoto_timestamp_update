#!/bin/bash

# Version 1.1

# Default settings
TARGET_DIR=""
TIMEZONE_OFFSET="+09:00"

# Define the list of image file extensions to process as an array
IMAGE_EXTENSIONS=("jpg" "jpeg" "png" "gif" "tiff" "heic" "mp4" "mov", "webp", "hevc", "avi")

# Help message definition
HELP_MESSAGE="
Usage: $0 [option] file/directory

Options:
  -h                      Displays this help message.
  --timezone <offset>     Specifies the time zone offset (e.g., +09:00, -05:00).
                          If not specified, the default is +09:00.

Arguments:
  file/directory          Specifies the directory to process.

Example:
  $0 -h
  $0 /path/to/photos
  $0 /path/to/photos/file1.jpg
  $0 /path/to/photos/*.jpg
  $0 --timezone -05:00 /path/to/photos
  $0 --timezone +16:00 /path/to/photos
"

if [ -z "$1" ]; then
    echo "$HELP_MESSAGE"
    exit 0
fi

# 引数の解析
while [ "$#" -gt 0 ]; do
    case "$1" in
        -h)
            echo "$HELP_MESSAGE"
            exit 0
            ;;
        --timezone)
            if [ -n "$2" ]; then
                TIMEZONE_OFFSET="$2"
                shift 2
            else
                echo "Error: --timezone option requires a value."
                exit 1
            fi
            if [ -n "$1" ]; then
                TARGET_DIR="$1"
                shift 1
            else
                echo "$HELP_MESSAGE"
                exit 1
            fi
            ;;
        -*)
            echo "Error: Unknown option: $1"
            echo "$HELP_MESSAGE"
            exit 1
            ;;
        *)
            TARGET_DIR="$1"
            shift 1
            ;;
    esac
done

echo "The timezone offset to use: $TIMEZONE_OFFSET"
echo "Processing target directory: $TARGET_DIR"
echo "---"

# Checking the existence of ExifTool and jq
if ! command -v exiftool &> /dev/null
then
    echo "ExifTool is not installed."
    echo "Install it using Homebrew: brew install exiftool"
    exit 1
fi

if ! command -v jq &> /dev/null
then
    echo "jq is not installed."
    echo "Install it using Homebrew: brew install jq"
    exit 1
fi

# Generate search criteria string for find command from array
FIND_PATTERN=""
for ext in "${IMAGE_EXTENSIONS[@]}"; do
    FIND_PATTERN+=" -o -iname \"*.$ext\""
done
FIND_PATTERN=${FIND_PATTERN:3}

FIND_COMMAND="find \"$TARGET_DIR\" -type f \\( $FIND_PATTERN \\)"

# Extract timezone hour and minute for date command
# 例: +09:00 -> +9H, -05:30 -> -5H -30M
TIMEZONE_HOUR=$(echo "$TIMEZONE_OFFSET" | cut -d':' -f1 | sed 's/^+/+/; s/^-/-/')
TIMEZONE_MINUTE=$(echo "$TIMEZONE_OFFSET" | cut -d':' -f2 | sed 's/^0+//')

if [ "$TIMEZONE_HOUR" == "+" ]; then
  TIMEZONE_HOUR_MOD="+"
elif [ "$TIMEZONE_HOUR" == "-" ]; then
  TIMEZONE_HOUR_MOD="-"
else
  TIMEZONE_HOUR_MOD="$TIMEZONE_HOUR"
fi

TIMEZONE_MINUTE_MOD=""
if [ -n "$TIMEZONE_MINUTE" ] && [ "$TIMEZONE_MINUTE" -ne 0 ]; then
  TIMEZONE_MINUTE_MOD=" -v${TIMEZONE_HOUR_MOD}${TIMEZONE_MINUTE}M"
fi

eval "$FIND_COMMAND" | while read -r image_file
do
    echo "---"
    echo "処理中: $image_file"

    json_file="${image_file}.supplemental-metadata.json"

    if [ -f "$json_file" ]; then
        datetime_utc=$(jq -r '.photoTakenTime.formatted' "$json_file")

        if [ -n "$datetime_utc" ] && [ "$datetime_utc" != "null" ]; then
            export LANG=C
            
            datetime_no_tz=$(echo "$datetime_utc" | sed 's/ UTC//')
            
            # Convert to local time using the `date` command and format as required by ExifTool
            timestamp_local=$(date -j -v"${TIMEZONE_HOUR}H" ${TIMEZONE_MINUTE_MOD} -f "%Y/%m/%d %H:%M:%S" "$datetime_no_tz" "+%Y:%m:%d %H:%M:%S")
            
            # Extract sub-second precision (e.g. `.987`)
            sub_sec=$(echo "$datetime_utc" | grep -o '\.[0-9]\+')

            if [ -n "$timestamp_local" ]; then
                echo "Original capture date and time (UTC): $datetime_utc"
                echo "Corrected shooting date and time ($TIMEZONE_OFFSET): $timestamp_local"

                # Update Metadata with ExifTool
                # Add SubSecTimeOriginal
                exiftool -AllDates="$timestamp_local" -OffsetTimeOriginal="$TIMEZONE_OFFSET" -OffsetTime="$TIMEZONE_OFFSET" -SubSecTimeOriginal="${sub_sec}" -overwrite_original_in_place "$image_file"

                # Generate format for touch command
                touch_datetime=$(echo "$timestamp_local" | awk '{print $1,$2}' | sed 's/:/ /g' | awk '{printf "%s%s%s%s%s.00\n",$1,$2,$3,$4,$5}')
                
                touch -t "$touch_datetime" "$image_file"

                if [ $? -eq 0 ]; then
                    echo "Success!"
                else
                    echo "Failed to run ExifTool."
                fi
            else
                echo "Date conversion failed."
            fi
        else
            echo "photoTakenTime was not found in the JSON file."
        fi
    else
        echo "No corresponding JSON file found: $json_file"
    fi
done

echo "---"
echo "All files have been processed."
