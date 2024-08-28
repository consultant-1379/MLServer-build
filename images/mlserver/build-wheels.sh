#!/usr/bin/env bash

# Modified 3PP script to put each whl in different directories so that only those can be copied while building image

set -ex
set -o nounset
set -o errexit
set -o pipefail

ROOT_FOLDER="$(realpath "$(dirname "${0}")/..")"

if [ "$#" -ne 1 ]; then
  echo 'Invalid number of arguments'
  echo "Usage: ./build-wheels.sh <outputPath>"
  exit 1
fi

_buildWheel() {
  local _srcPath=$1
  local _outputPath=$2

  # Poetry doesn't let us send the output to a separate folder so we'll `cd`
  # into the folder and them move the wheels out
  # https://github.com/python-poetry/poetry/issues/3586
  pushd $_srcPath
  poetry build
  # Only copy files if destination is different from source
  local _currentDistPath=$PWD/dist
  if ! [[ "$_currentDistPath" = "$_outputPath" ]]; then
    cp $_currentDistPath/* $_outputPath
  fi
  popd
}

_main() {
  # Convert any path into an absolute path
  local _outputPath=$1
  mkdir -p $_outputPath
  if ! [[ "$_outputPath" = /* ]]; then
    pushd $_outputPath
    _outputPath="$PWD"
    popd
  fi

  _mlServerOutputPath="$_outputPath/mlserver"
  mkdir -p $_mlServerOutputPath
  # Build MLServer
  echo "---> Building MLServer wheel"
  _buildWheel . $_mlServerOutputPath

  for _runtime in "$ROOT_FOLDER/runtimes/"*; do
    echo "---> Building MLServer runtime: $(basename $_runtime)"
    _runtimeOutputPath="$_outputPath/$(basename $_runtime)"
    mkdir -p $_runtimeOutputPath
    _buildWheel $_runtime $_runtimeOutputPath
  done
}

_main $1
