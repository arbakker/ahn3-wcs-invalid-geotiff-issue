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

function get_nr_files(){
    local input_file
    local sep
    local count
    input_file="$1"
    sep="$2"
    count=0
    while read -r LINE; do
        if [[ "$LINE" == $sep* ]];then
            count=$((count+1))
        fi
    done<"$input_file"
    echo $(("$count"-1))
}


function get_filename(){
    local input_file
    local index
    local output_folder
    input_file="$1"
    index="$2"
    output_folder="$3"
    filename=$(grep -m "$index" -a -oP '^Content-ID:\s+\K\S+' "$input_file" | tail -n 1)
    if [[ -z "$output_folder" ]];then
        echo "$filename"
    else
        echo "$output_folder/$filename"
    fi
}

function get_start_pos(){
    local input_file
    local sep
    local index
    local line_count
    local count
    input_file="$1"
    sep="$2"
    index="$3"
    line_count=0
    count=0
    while read -r LINE; do
        line_count=$((line_count+1))
        if [[ "$LINE" == $sep* ]];then
            count=$((count+1))
            if [[ "$count" -eq "$index" ]];then
                echo "$line_count"
                return
            fi
        fi
    done<"$input_file"
}


function get_end_pos(){
    local input_file
    local sep
    local index
    local line_count
    local count
    input_file="$1"
    sep="$2"
    index="$3"
    line_count=0
    count=0
    while read -r LINE; do
        line_count=$((line_count+1))
        if [[ "$LINE" == $sep* ]];then
            count=$((count+1))
            if [[ "$count" -eq $(("$index"+1)) ]];then
                echo "$line_count"
                return
            fi
        fi
    done<"$input_file"
}

function split_multipart_file(){
    local input_file="$1"
    local output_file="$2"
    local sep
    local files_in_multipart
    local folder_in_multipart
    local output_folder=$(mktemp -d)

    sep=$(get_seperator "$input_file")
    if [[ -z $sep ]];then
        echo "error: unable to find multipart seperator in ${input_file}"
        exit 1
    fi
    files_in_multipart=$(get_nr_files "$input_file" "$sep")
    folder_in_multipart=$(get_filename "$input_file" 1 "$output_folder" | xargs dirname)
    
    for ((n=1;n<="$files_in_multipart";n++)); do
        start_pos=$(get_start_pos "$input_file" "$sep" "$n")
        end_pos=$(get_end_pos "$input_file" "$sep" "$n")
        out_file=$(get_filename "$input_file" "$n" "$output_folder")
        out_dir=$(dirname "$out_file")
        mkdir -p "$out_dir"
        sed -n "$(("$start_pos"+7)),$(("$end_pos"-1)) p" "$input_file" > "$out_file"
    done
    cp "${folder_in_multipart}/out.tif" "$output_file"
    # echo "tif saved in $(realpath "$output_file")"
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
