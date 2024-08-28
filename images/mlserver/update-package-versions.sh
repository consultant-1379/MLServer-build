#!/usr/bin/env bash 


set -ex 
# This script is used to uplift ESW4 packages to stable version 


# below steps will upgrade protobuf from 3.20.3 to 4.25.3

 poetry remove grpcio-tools --group dev
 poetry add "protobuf@4.25.3" --group=docker
 poetry add "grpcio-tools@1.50.0" --group=dev
