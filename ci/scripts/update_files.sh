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

set -ux -o pipefail;

PARENT_REPO_PATH="$1"
IMAGE_FULL_NAME_PREFIX="$2"
CHANGED_FILES_BOBVAR_FILE="$3"

# Absolute filepath to this script
SCRIPT_LOCATION=$(realpath "$0")
# Directory of this script
SCRIPT_DIR=$(dirname "$SCRIPT_LOCATION")
# Absolute path to the root of the repository
REPOROOT=$(realpath "$SCRIPT_DIR/../..")

# Set the relative path to the Model LCM fragments and fossa config files (Destination)
PRODUCT_INFO_FILE="charts/eric-aiml-model-lcm/eric-product-info.yaml"

# derive 
# dockerRegistry=$(echo "$IMAGE_FULL_NAME_PREFIX" | awk -F/ '{print $1}')  ## not used
imageRepo=$(echo "$IMAGE_FULL_NAME_PREFIX" | awk -F/ '{print $2}')
imageNamePrefix=$(echo "$IMAGE_FULL_NAME_PREFIX" | awk -F/ '{print $3}' | awk -F: '{print $1}')
imageVersion=$(echo "$IMAGE_FULL_NAME_PREFIX" | awk -F/ '{print $3}' | awk -F: '{print $2}')

imageIds=(  
            "kserve-mlserver-base" 
            "kserve-mlserver-sklearn" 
            "kserve-mlserver-xgboost" 
            "kserve-mlserver-catboost"
            #"kserve-mlserver-huggingface"
            "kserve-mlserver-lightgbm"
            "kserve-mlserver-mlflow"
            "kserve-mlserver-mllib"
            "mlserver-tensorflow"
            "mlserver-pytorch"
        )
filesToSync=()

for imageId in "${imageIds[@]}"
do 
    echo "Set ${imageNamePrefix}-${imageId} docker repo to ${imageRepo}"
    image=$imageNamePrefix-${imageId} repoPath=$imageRepo yq e -i '.images[env(image)].repoPath = env(repoPath)' "${PARENT_REPO_PATH}/$PRODUCT_INFO_FILE"
    echo "Set ${imageNamePrefix}-${imageId} docker image version to ${imageVersion}"
    image=$imageNamePrefix-${imageId} tag=$imageVersion yq e -i '.images[env(image)].tag = env(tag)' "${PARENT_REPO_PATH}/$PRODUCT_INFO_FILE"
done 

changedFiles=("$PRODUCT_INFO_FILE")

# Add new line after license header. It is lost due to yq manipulation
sed -i '/^productName:.*/i \ ' "${PARENT_REPO_PATH}/$PRODUCT_INFO_FILE"

#TODO dependency files are commented below, uncomment them after foss analysis is complete and files are ready
filesToSync=(
    "config/fossa/dependencies.mlserver-build-2pp.yaml"
    "config/fossa/dependencies.mlserver-3pp.yaml"
    "config/fossa/dependencies.mlserver.yaml"
    "config/fossa/dependencies.sklearn.yaml"
    "config/fossa/dependencies.xgboost.yaml"
    "config/fossa/dependencies.catboost.yaml"
    # "config/fossa/dependencies.mlserver-huggingface.yaml"
    "config/fossa/dependencies.lightgbm.yaml"
    "config/fossa/dependencies.mlflow.yaml"
    "config/fossa/dependencies.mllib.yaml"
    "config/fossa/dependencies.mlserver-tensorflow.yaml"
    "config/fossa/dependencies.mlserver-pytorch.yaml"
    # "config/fossa/foss.usage.mlserver-3pp.yaml"
    # "config/fossa/foss.usage.mlserver-base.yaml"
    # "config/fossa/foss.usage.mlserver-sklearn.yaml"
    # "config/fossa/foss.usage.mlserver-xgboost.yaml"
    # "config/fossa/foss.usage.mlserver-catboost.yaml"
    # "config/fossa/foss.usage.mlserver-huggingface.yaml"
    # "config/fossa/foss.usage.mlserver-lightgbm.yaml"
    # "config/fossa/foss.usage.mlserver-tensorflow.yaml"
    # "config/fossa/foss.usage.mlserver-mlflow.yaml"
    # "config/fossa/foss.usage.mlserver-mllib.yaml"
    # "config/fragments/mlserver-build-license-agreement.json"
)

createParentDir(){
    local fileName=$1
    local parentDir
    parentDir=$(dirname "$fileName")
    if [ ! -d "$PARENT_REPO_PATH/$parentDir" ]; then
        mkdir -p "$PARENT_REPO_PATH/$parentDir"
    fi
}


for file in "${filesToSync[@]}"; do
    createParentDir "$file"
    sourceFile="$REPOROOT/$file"
    destinationFile="$PARENT_REPO_PATH/$file"
    echo "Syncing file from $sourceFile to $destinationFile"
    
    echo "Check if there are changes in $file"
    if [ -f "$destinationFile" ]
    then
        diff "$sourceFile" "$destinationFile"
        diffStatus=$?
    else 
        diffStatus=1
    fi
    if [ $diffStatus -eq 0 ]; then
        echo "No changes in $file"
    else
        echo "Detected changes in $file"
        changedFiles+=("$file")
        echo "Copy $sourceFile to $destinationFile"
        cp "$sourceFile" "$destinationFile"
    fi
done

printf '%s\n' "${changedFiles[@]}" > "$CHANGED_FILES_BOBVAR_FILE"

