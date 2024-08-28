#!/usr/bin/env bash
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


set -eux -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_DIR="$( cd "${SCRIPT_DIR}/../.." && pwd )"
TEMP_DIR="${REPO_DIR}/temp"
OUTPUT_FILE="${TEMP_DIR}/uid.txt"

# This script is used to generate a unique UID for Argo Images

generate_uid(){
local cntr="$1"
local outputFile="$2"
h=$( sha256sum <<< "${cntr}" | cut -f1 -d ' ' ) 
printf -- '%s : %d\n' "${cntr}" "$( bc -q <<< "scale=0;obase=10;ibase=16;(${h^^}%30D41)+186A0" )" >> "${outputFile}"
}

images=(
    eric-aiml-model-lcm-kserve-mlserver-base
    eric-aiml-model-lcm-kserve-mlserver-catboost
    eric-aiml-model-lcm-kserve-mlserver-huggingface
    eric-aiml-model-lcm-kserve-mlserver-lightgbm
    eric-aiml-model-lcm-kserve-mlserver-mlflow
    eric-aiml-model-lcm-kserve-mlserver-mllib
    eric-aiml-model-lcm-kserve-mlserver-sklearn
    eric-aiml-model-lcm-kserve-mlserver-xgboost
    eric-aiml-model-lcm-mlserver-tensorflow
    eric-aiml-model-lcm-mlserver-pytorch
)

if [ -f "${OUTPUT_FILE}" ]
then 
    rm -f "${OUTPUT_FILE}" || true
fi

if [ ! -d "${TEMP_DIR}" ]
then
    mkdir -p "${TEMP_DIR}"
fi

for image in "${images[@]}"; do
    generate_uid "${image}" "${OUTPUT_FILE}"
done

