#!/bin/bash

display_alert() {
    local message="$1"
    local status="$2"  # "failed" or other
    local level="$3"   # "wrn" or "info"
    printf "%s [%s] %s\n" "$level" "$status" "$message" # Simple console output
}

extract_subject_from_patch() {
    local patch_file=$1
    awk '/^Subject: / {
        in_subject = 1;
        gsub(/^Subject: \[[^]]*\] /, "", $0);
        gsub(/^Subject: /, "", $0);
        subject_line = $0;
        next;
    }
    in_subject && /^ / {
        gsub(/^ /, "", $0);
        subject_line = subject_line " " $0;
        next;
    }
    in_subject {
        print subject_line;
        in_subject = 0;
    }' "$patch_file"
}

process_patch_file() {
    local patch=$1
    local status=$2

    # Detect and remove files which the patch will create
    lsdiff -s --strip=1 "${patch}" | grep '^+' | awk '{print $2}' | xargs -I % sh -c 'rm -f %'

    echo "Processing file $patch"
    patch --batch --silent -p1 -N < "${patch}"

    if [ $? -ne 0 ]; then
        display_alert "* $status $(basename "${patch}")" "failed" "wrn"
        exit 1
    else
        display_alert "* $status $(basename "${patch}")" "" "info"

        # Add new files created by the patch to Git
        new_files=$(lsdiff -s --strip=1 "${patch}" | grep '^+' | awk '{print $2}')
        if [ -n "$new_files" ]; then
                        echo $new_files
            git add $new_files
        fi

        # Extract the commit message from the patch file's subject
        commit_message=$(extract_subject_from_patch "$patch")

        # Commit the changes to Git using the extracted subject if not empty
        if [ -n "$commit_message" ]; then
                        display_alert "Subject: $commit_message" "info"
            git commit . -m "$commit_message"
                        display_alert "Check status ..." "info"
                        git status .
        else
            display_alert "No commit message found in patch subject; skipping commit." "info" ""
        fi
    fi
}

# Ensure a patch file is provided as an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <patch-file>"
    exit 1
fi

# Call the process_patch_file function with arguments
process_patch_file "$1" "Applying"

