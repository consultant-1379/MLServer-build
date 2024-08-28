#!/usr/bin/env bash 
# This script builds custom runtimes for MLServer

set -ex

ROOT_DIR="$(realpath "$(dirname "${0}")/..")"
OUTPUT_DIR="$1"

_buildWheel(){
    local src_path="$1"
    local output_dir="$2"
    local runtime
    runtime=$(basename "$src_path")
    local constraints_file="$src_path/constraints.txt"
    if [ ! -f "$constraints_file" ]; then
        echo "constraints.txt file not found in $src_path"
        exit 1
    fi
    
    cd "$src_path"
    python -m build --wheel --outdir "$output_dir"
    cd "$OLDPWD"
    # Remove the extras from the constraints file and copy it to the output directory
    sed -i 's/\[.*\]//g' "$src_path/constraints.txt"
    cp "$src_path/constraints.txt" "$output_dir/${runtime}-constraints.txt"
    # copy the requirements.txt for foss analysis
    cp "$src_path/requirements.txt" "$output_dir/${runtime}-requirements.txt"
}

mkdir -p "$OUTPUT_DIR"

for custom_runtime in "$ROOT_DIR/custom-runtimes/"*; do
    echo "Building MLServer custom runtime: $(basename $custom_runtime)"
    _runtimeOutputDir="$OUTPUT_DIR/$(basename $custom_runtime)"
    mkdir -p "$_runtimeOutputDir"
    _buildWheel "$custom_runtime" "$_runtimeOutputDir"
done

