#! /usr/bin/env bash
#
# COPYRIGHT Ericsson 2024
#
#
#
# The copyright to the computer program(s) herein is the property of
#
# Ericsson Inc. The programs may be used and/or copied only with written
#
# permission from Ericsson Inc. or in accordance with the terms and
#
# conditions stipulated in the agreement/contract under which the
#
# program(s) have been supplied.
#

set -eux;

PARENT_REPO_PATH="$1"
CHANGED_FILES_BOBVAR_FILE="$2"
IMAGE_VERSION="$3"
BRANCH="$4"
CHANGE_FILE="$5"

SCRIPT_DIR=$(realpath "$(dirname "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")

LOG_DIR="$ROOT_DIR/.bob/logs"
LOG_FILE="$LOG_DIR/create_change.log"

mkdir -p "$LOG_DIR"

mapfile -t changedFiles < "$CHANGED_FILES_BOBVAR_FILE"

cd "$PARENT_REPO_PATH"

gerrit create-patch --file "${changedFiles[@]}" \
    --message "[NoJira] Update MLServer Build images to $IMAGE_VERSION" \
    --git-repo-local . \
    --wait-label "Verified"="+1" \
    --branch "$BRANCH" \
    --debug \
    --email "${EMAIL}" \
    --timeout 7200 \
    --abandon-on-failure  2>&1 | tee "$LOG_FILE"
    #--submit

changeStatus=${PIPESTATUS[0]} 

changeURL=$(grep "Change is:" "$LOG_FILE" | awk '{print $NF}')
echo "Change URL: $changeURL"

if [ -z "$changeURL" ]; then
    changeURL="unknown"
fi

echo "$changeURL" > "$CHANGE_FILE"

if [ "$changeStatus" -eq 0 ]; then
        echo "Change verification is successful"
else
    echo "Change failed verification and has been abandoned"
    exit 1
fi 