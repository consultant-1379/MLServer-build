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

# This script generates the constraints for the custom runtimes.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(realpath "${SCRIPT_DIR}"/../..)"

# Generate custom runtime specific constraints
custom_runtimes=("tensorflow" "pytorch")

pytorch_extra_index_url="https://download.pytorch.org/whl/cpu"

for runtime in "${custom_runtimes[@]}"; do
    extra_args=""
    cd "${ROOT_DIR}/src/$runtime"
    cp "${ROOT_DIR}/.bob/mlserver_constraints.txt" .
    if [[ $runtime =~ "pytorch" ]]
    then 
        extra_args="--extra-index-url $pytorch_extra_index_url"
    fi
    pip-compile --constraint=mlserver_constraints.txt --output-file=constraints.txt pyproject.toml $extra_args
    # remove extras like package[someOtherPackage]
    sed -i 's/\[.*\]//g' constraints.txt
    # remove extra-index-url line as it is not required
    sed -i '/^--extra-index-url/d' "constraints.txt"
    cd "${OLDPWD}"
done
    