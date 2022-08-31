#!/usr/bin/env bash
#
# Bash script for splitting multipart response files in seperate files. Useful for splitting multipart WCS response.
#
# Author: anton.bakker@kadaster.nl
# Date: 29/06/2022
#
# MIT License
#
# Copyright (c) 2022 Anton Bakker
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

PROGRAM_NAME="$0"
INPUT_FILE="$1"
OUTPUT_FILE="$2"

function usage {
    echo "usage: $(basename $PROGRAM_NAME) <multipart_file> <output_file>"
    exit 1
}


if [[ -z "$INPUT_FILE" ]] || [[ -z "$OUTPUT_FILE" ]]; then
    usage
fi


set -euo pipefail


function get_seperator(){
    local input_file
    input_file="$1"
    set +e
    result="$(grep -m 1  -a -oP '^--\S+' "$input_file")"
    set -e
    echo "$result"
}


function split_multipart_file(){
    local input_file="$1"
    local output_file="$2"
    sep=$(get_seperator $input_file)
    sep=$(sed 's|-|\\-|g' <<< $sep) # escape seperator to prevent interpreting as cli flag
    
      end_tif=$(tac "$input_file" | \
        grep -n --text  "$sep" | \
        tail -n +2 | \
        head -n1 | \
        cut -d: -f1) # start searching from end for second separator to find end of tif response
    start_tif=$(cat "$input_file" | grep -n --text  "$sep" | head -n1 | cut -d: -f1) # search for first occurence separator
    start_tif=$((start_tif + 7)) # add 7 to account for response headers in multipart response
    echo end_tif $end_tif
    echo start_tif $start_tif

    head -n "-${end_tif}" "$input_file" | tail -n "+${start_tif}" > "$output_file"
}


if [[ $INPUT_FILE == "-" ]];then    
    if [ -t 0 ]; then
    # if do not allow interactive tty
        usage
    fi
    INPUT_FILE=$(mktemp)
    cp /dev/stdin $INPUT_FILE
fi

split_multipart_file "$INPUT_FILE" "$OUTPUT_FILE"
