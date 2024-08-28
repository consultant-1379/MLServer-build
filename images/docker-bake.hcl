group "default" {
    targets = [ 
                "mlserver-base", 
                "mlserver-catboost-runtime", 
                "mlserver-huggingface-runtime",
                "mlserver-lightgbm-runtime", 
                "mlserver-mlflow-runtime",
                "mlserver-sklearn-runtime", 
                "mlserver-xgboost-runtime", 
                "mlserver-mllib-runtime",
                "mlserver-customruntime-tensorflow",
                "mlserver-customruntime-pytorch",
                "mlserver-base-with-fossa",
                "mlserver-tensorflow-with-fossa",
                "mlserver-pytorch-with-fossa"
            ]
}

#################################################################################################################################################################
# Common Variables 
#################################################################################################################################################################

variable "CBOS_VERSION" {
    default = "notset"
}

variable "STDOUT_REDIRECT_VERSION" {
    default = "notset"
}

variable "COMMIT" {
    default = "notset"
}

variable "BUILD_DATE" {
    default = "notset"
}

variable "VERSION" {
    default = "notset"
}

variable "RSTATE" {
    default = "notset"
}

variable "IMAGE_PRODUCT_TITLE_PREFIX" {
    default = "notset"
}

variable "MLSERVER_VERSION" {
    default = "notset"
}

variable "PWD" {
    default = "notset"
}

variable "INTERNAL_IMAGE_PREFIX" {
    default = "notset"
}

variable "DROP_IMAGE_PREFIX" {
    default = "notset"
}

variable "CUSTOM_PYTHON_PACKAGE_VERSION" {
    default = "notset"
}

#################################################################################################################################################################
# Export constraints file
# done manually during development
# constraints file should be used to install dependencies in every custom runtime image
#################################################################################################################################################################

target "mlserver-constraints" {
    context = "${PWD}/.bob/3pps/mlserver"
    contexts = {
        additional-scripts-context = "${PWD}/images/mlserver"
    }
    dockerfile = "${PWD}/images/mlserver/Dockerfile"
    target = "export-constraints-file"
    args = {
        CBOS_VERSION = "${CBOS_VERSION}"
    }
    output = [
        ".bob/"
    ]
}

#################################################################################################################################################################
# ML Server Installer (Builder)
# common parent for all the images
# build this first, and reference it in the other images as additional context
# so that mlserver-installer stage is reused instead of being built every time
#################################################################################################################################################################

target "mlserver-installer"{
    context = "${PWD}/.bob/3pps/mlserver"
    contexts = {
        additional-scripts-context = "${PWD}/images/mlserver"
        custom-runtimes-context = "${PWD}/src/"
    }
    dockerfile = "${PWD}/images/mlserver/Dockerfile"
    target = "mlserver-installer"
    args = {
        CBOS_VERSION = "${CBOS_VERSION}"
        PACKAGE_VERSION = "${CUSTOM_PYTHON_PACKAGE_VERSION}"
    }
}


#################################################################################################################################################################
# ML Server Base 
#################################################################################################################################################################

variable "MLSERVER_BASE_IMAGE_PRODUCT_NUMBER" {
    default = "notset"
}

variable "MLSERVER_BASE_IMAGE_USER_ID" {
    default = "notset"
}

target "mlserver-base"{
    context = "${PWD}/.bob/3pps/mlserver"
    contexts = {
        additional-scripts-context = "${PWD}/images/mlserver"
        custom-runtimes-context = "${PWD}/src/"
        mlserver-installer = "target:mlserver-installer"
    }
    dockerfile = "${PWD}/images/mlserver/Dockerfile"
    tags = [ "${INTERNAL_IMAGE_PREFIX}-kserve-mlserver-base:${VERSION}", "${DROP_IMAGE_PREFIX}-kserve-mlserver-base:${VERSION}" ]
    target = "mlserver-base"
    secret = ["type=env,id=ARM_API_TOKEN"]
    args = {
        CBOS_VERSION = "${CBOS_VERSION}"
        STDOUT_REDIRECT_VERSION = "${STDOUT_REDIRECT_VERSION}"
        COMMIT = "${COMMIT}"
        BUILD_DATE = "${BUILD_DATE}"
        APP_VERSION = "${VERSION}"
        RSTATE = "${RSTATE}"
        IMAGE_PRODUCT_NUMBER = "${MLSERVER_BASE_IMAGE_PRODUCT_NUMBER}"
        IMAGE_PRODUCT_TITLE_PREFIX = "${IMAGE_PRODUCT_TITLE_PREFIX} MLServer Base Image"
        MLSERVER_VERSION = "${MLSERVER_VERSION}"
        MLSERVER_BASE_USER_ID = "${MLSERVER_BASE_IMAGE_USER_ID}"
        MLSERVER_BASE_CONTAINER_NAME = "eric-aiml-model-lcm-kserve-mlserver-base"
    }
}

#################################################################################################################################################################
# ML Server Catboost Runtime
#################################################################################################################################################################
variable "MLSERVER_CATBOOST_RUNTIME_IMAGE_PRODUCT_NUMBER" {
    default = "notset"
}

variable "MLSERVER_CATBOOST_RUNTIME_IMAGE_USER_ID" {
    default = "notset"
}

target "mlserver-catboost-runtime"{
    context = "${PWD}/.bob/3pps/mlserver"
    contexts = {
        additional-scripts-context = "${PWD}/images/mlserver"
        custom-runtimes-context = "${PWD}/src/"
        mlserver-installer = "target:mlserver-installer"
    }
    dockerfile = "${PWD}/images/mlserver/Dockerfile"
    tags = [ "${INTERNAL_IMAGE_PREFIX}-kserve-mlserver-catboost:${VERSION}", "${DROP_IMAGE_PREFIX}-kserve-mlserver-catboost:${VERSION}" ]
    target = "mlserver-runtime"
    secret = ["type=env,id=ARM_API_TOKEN"]
    args= {
        CBOS_VERSION = "${CBOS_VERSION}"
        STDOUT_REDIRECT_VERSION = "${STDOUT_REDIRECT_VERSION}"
        COMMIT = "${COMMIT}"
        BUILD_DATE = "${BUILD_DATE}"
        APP_VERSION = "${VERSION}"
        RSTATE = "${RSTATE}"
        IMAGE_PRODUCT_NUMBER = "${MLSERVER_CATBOOST_RUNTIME_IMAGE_PRODUCT_NUMBER}"
        IMAGE_PRODUCT_TITLE = "${IMAGE_PRODUCT_TITLE_PREFIX} MLServer Catboost Runtime Image"
        RUNTIME = "catboost"
        MLSERVER_VERSION = "${MLSERVER_VERSION}"
        MLSERVER_RUNTIME_CONTAINER_NAME="eric-aiml-model-lcm-kserve-mlserver-catboost"
        MLSERVER_RUNTIME_USER_ID="${MLSERVER_CATBOOST_RUNTIME_IMAGE_USER_ID}"
    }
}

#################################################################################################################################################################
# ML Server Huggingface Runtime
#################################################################################################################################################################
variable "MLSERVER_HUGGINGFACE_RUNTIME_IMAGE_PRODUCT_NUMBER" {
    default = "notset"
}

variable "MLSERVER_HUGGINGFACE_RUNTIME_IMAGE_USER_ID" {
    default = "notset"
}

target "mlserver-huggingface-runtime"{
    context = "${PWD}/.bob/3pps/mlserver"
    contexts = {
        additional-scripts-context = "${PWD}/images/mlserver"
        custom-runtimes-context = "${PWD}/src/"
        mlserver-installer = "target:mlserver-installer"
    }
    dockerfile = "${PWD}/images/mlserver/Dockerfile"
    tags = [ "${INTERNAL_IMAGE_PREFIX}-kserve-mlserver-huggingface:${VERSION}", "${DROP_IMAGE_PREFIX}-kserve-mlserver-huggingface:${VERSION}" ]
    target = "mlserver-runtime"
    secret = ["type=env,id=ARM_API_TOKEN"]
    args= {
        CBOS_VERSION = "${CBOS_VERSION}"
        STDOUT_REDIRECT_VERSION = "${STDOUT_REDIRECT_VERSION}"
        COMMIT = "${COMMIT}"
        BUILD_DATE = "${BUILD_DATE}"
        APP_VERSION = "${VERSION}"
        RSTATE = "${RSTATE}"
        IMAGE_PRODUCT_NUMBER = "${MLSERVER_HUGGINGFACE_RUNTIME_IMAGE_PRODUCT_NUMBER}"
        IMAGE_PRODUCT_TITLE = "${IMAGE_PRODUCT_TITLE_PREFIX} MLServer Huggingface Runtime Image"
        RUNTIME = "huggingface"
        MLSERVER_VERSION = "${MLSERVER_VERSION}"
        MLSERVER_RUNTIME_CONTAINER_NAME="eric-aiml-model-lcm-kserve-mlserver-huggingface"
        MLSERVER_RUNTIME_USER_ID="${MLSERVER_HUGGINGFACE_RUNTIME_IMAGE_USER_ID}"
    }
}

#################################################################################################################################################################
# ML Server SKLearn Runtime
#################################################################################################################################################################

variable "MLSERVER_SKLEARN_RUNTIME_IMAGE_PRODUCT_NUMBER" {
    default = "notset"
}

variable "MLSERVER_SKLEARN_RUNTIME_IMAGE_USER_ID" {
    default = "notset"
}

target "mlserver-sklearn-runtime"{
    context = "${PWD}/.bob/3pps/mlserver"
    contexts = {
        additional-scripts-context = "${PWD}/images/mlserver"
        custom-runtimes-context = "${PWD}/src/"
        mlserver-installer = "target:mlserver-installer"
    }
    dockerfile = "${PWD}/images/mlserver/Dockerfile"
    tags = [ "${INTERNAL_IMAGE_PREFIX}-kserve-mlserver-sklearn:${VERSION}", "${DROP_IMAGE_PREFIX}-kserve-mlserver-sklearn:${VERSION}" ]
    target = "mlserver-runtime"
    secret = ["type=env,id=ARM_API_TOKEN"]
    args= {
        CBOS_VERSION = "${CBOS_VERSION}"
        STDOUT_REDIRECT_VERSION = "${STDOUT_REDIRECT_VERSION}"
        COMMIT = "${COMMIT}"
        BUILD_DATE = "${BUILD_DATE}"
        APP_VERSION = "${VERSION}"
        RSTATE = "${RSTATE}"
        IMAGE_PRODUCT_NUMBER = "${MLSERVER_SKLEARN_RUNTIME_IMAGE_PRODUCT_NUMBER}"
        IMAGE_PRODUCT_TITLE = "${IMAGE_PRODUCT_TITLE_PREFIX} MLServer SKLearn Runtime Image"
        RUNTIME = "sklearn"
        MLSERVER_VERSION = "${MLSERVER_VERSION}"
        MLSERVER_RUNTIME_CONTAINER_NAME="eric-aiml-model-lcm-kserve-mlserver-sklearn"
        MLSERVER_RUNTIME_USER_ID="${MLSERVER_SKLEARN_RUNTIME_IMAGE_USER_ID}"
    }
}

#################################################################################################################################################################
# ML Server XGBoost Runtime
#################################################################################################################################################################
variable "MLSERVER_XGBOOST_RUNTIME_IMAGE_PRODUCT_NUMBER" {
    default = "notset"
}


variable "MLSERVER_XGBOOST_RUNTIME_IMAGE_USER_ID" {
    default = "notset"
}

target "mlserver-xgboost-runtime"{
    context = "${PWD}/.bob/3pps/mlserver"
    contexts = {
        additional-scripts-context = "${PWD}/images/mlserver"
        custom-runtimes-context = "${PWD}/src/"
        mlserver-installer = "target:mlserver-installer"
    }
    dockerfile = "${PWD}/images/mlserver/Dockerfile"
    tags = [ "${INTERNAL_IMAGE_PREFIX}-kserve-mlserver-xgboost:${VERSION}", "${DROP_IMAGE_PREFIX}-kserve-mlserver-xgboost:${VERSION}" ]
    target = "mlserver-runtime"
    secret = ["type=env,id=ARM_API_TOKEN"]
    args= {
        CBOS_VERSION = "${CBOS_VERSION}"
        STDOUT_REDIRECT_VERSION = "${STDOUT_REDIRECT_VERSION}"
        COMMIT = "${COMMIT}"
        BUILD_DATE = "${BUILD_DATE}"
        APP_VERSION = "${VERSION}"
        RSTATE = "${RSTATE}"
        IMAGE_PRODUCT_NUMBER = "${MLSERVER_XGBOOST_RUNTIME_IMAGE_PRODUCT_NUMBER}"
        IMAGE_PRODUCT_TITLE = "${IMAGE_PRODUCT_TITLE_PREFIX} MLServer XGBoost Runtime Image"
        RUNTIME = "xgboost"
        MLSERVER_VERSION = "${MLSERVER_VERSION}"
        MLSERVER_RUNTIME_CONTAINER_NAME="eric-aiml-model-lcm-kserve-mlserver-xgboost"
        MLSERVER_RUNTIME_USER_ID="${MLSERVER_XGBOOST_RUNTIME_IMAGE_USER_ID}"
    }
}
#################################################################################################################################################################
# MLServer LightGBM Runtime
#################################################################################################################################################################
variable "MLSERVER_LIGHTGBM_RUNTIME_IMAGE_PRODUCT_NUMBER" {
    default = "notset"
}

variable "MLSERVER_LIGHTGBM_RUNTIME_IMAGE_USER_ID" {
    default = "notset"
}

target "mlserver-lightgbm-runtime"{
    context = "${PWD}/.bob/3pps/mlserver"
    contexts = {
        additional-scripts-context = "${PWD}/images/mlserver"
        custom-runtimes-context = "${PWD}/src/"
        mlserver-installer = "target:mlserver-installer"
    }
    dockerfile = "${PWD}/images/mlserver/Dockerfile"
    tags = [ "${INTERNAL_IMAGE_PREFIX}-kserve-mlserver-lightgbm:${VERSION}", "${DROP_IMAGE_PREFIX}-kserve-mlserver-lightgbm:${VERSION}" ]
    target = "mlserver-runtime"
    secret = ["type=env,id=ARM_API_TOKEN"]
    args= {
        CBOS_VERSION = "${CBOS_VERSION}"
        STDOUT_REDIRECT_VERSION = "${STDOUT_REDIRECT_VERSION}"
        COMMIT = "${COMMIT}"
        BUILD_DATE = "${BUILD_DATE}"
        APP_VERSION = "${VERSION}"
        RSTATE = "${RSTATE}"
        IMAGE_PRODUCT_NUMBER = "${MLSERVER_LIGHTGBM_RUNTIME_IMAGE_PRODUCT_NUMBER}"
        IMAGE_PRODUCT_TITLE = "${IMAGE_PRODUCT_TITLE_PREFIX} MLServer LightGBM Runtime Image"
        RUNTIME = "lightgbm"
        MLSERVER_VERSION = "${MLSERVER_VERSION}"
        MLSERVER_RUNTIME_CONTAINER_NAME="eric-aiml-model-lcm-kserve-mlserver-lightgbm"
        MLSERVER_RUNTIME_USER_ID="${MLSERVER_LIGHTGBM_RUNTIME_IMAGE_USER_ID}"
    }
}

#################################################################################################################################################################
# MLServer MLFlow Runtime
#################################################################################################################################################################

variable "MLSERVER_MLFLOW_RUNTIME_IMAGE_PRODUCT_NUMBER" {
    default = "notset"
}

variable "MLSERVER_MLFLOW_RUNTIME_IMAGE_USER_ID" {
    default = "notset"
}

target "mlserver-mlflow-runtime"{
    context = "${PWD}/.bob/3pps/mlserver"
    contexts = {
        additional-scripts-context = "${PWD}/images/mlserver"
        custom-runtimes-context = "${PWD}/src/"
        mlserver-installer = "target:mlserver-installer"
    }
    dockerfile = "${PWD}/images/mlserver/Dockerfile"
    tags = [ "${INTERNAL_IMAGE_PREFIX}-kserve-mlserver-mlflow:${VERSION}", "${DROP_IMAGE_PREFIX}-kserve-mlserver-mlflow:${VERSION}" ]
    target = "mlserver-runtime"
    secret = ["type=env,id=ARM_API_TOKEN"]
    args= {
        CBOS_VERSION = "${CBOS_VERSION}"
        STDOUT_REDIRECT_VERSION = "${STDOUT_REDIRECT_VERSION}"
        COMMIT = "${COMMIT}"
        BUILD_DATE = "${BUILD_DATE}"
        APP_VERSION = "${VERSION}"
        RSTATE = "${RSTATE}"
        IMAGE_PRODUCT_NUMBER = "${MLSERVER_MLFLOW_RUNTIME_IMAGE_PRODUCT_NUMBER}"
        IMAGE_PRODUCT_TITLE = "${IMAGE_PRODUCT_TITLE_PREFIX} MLServer MLFlow Runtime Image"
        RUNTIME = "mlflow"
        MLSERVER_VERSION = "${MLSERVER_VERSION}"
        MLSERVER_RUNTIME_CONTAINER_NAME="eric-aiml-model-lcm-kserve-mlserver-mlflow"
        MLSERVER_RUNTIME_USER_ID="${MLSERVER_MLFLOW_RUNTIME_IMAGE_USER_ID}"
    }
}

#################################################################################################################################################################
# MLServer MLlib Runtime
#################################################################################################################################################################

variable "MLSERVER_MLLIB_RUNTIME_IMAGE_PRODUCT_NUMBER" {
    default = "notset"
}

variable "MLSERVER_MLLIB_RUNTIME_IMAGE_USER_ID" {
    default = "notset"
}

target "mlserver-mllib-runtime"{
    context = "${PWD}/.bob/3pps/mlserver"
    contexts = {
        additional-scripts-context = "${PWD}/images/mlserver"
        custom-runtimes-context = "${PWD}/src/"
        mlserver-installer = "target:mlserver-installer"
    }
    dockerfile = "${PWD}/images/mlserver/Dockerfile"
    tags = [ "${INTERNAL_IMAGE_PREFIX}-kserve-mlserver-mllib:${VERSION}", "${DROP_IMAGE_PREFIX}-kserve-mlserver-mllib:${VERSION}" ]
    target = "mlserver-runtime"
    secret = ["type=env,id=ARM_API_TOKEN"]
    args= {
        CBOS_VERSION = "${CBOS_VERSION}"
        STDOUT_REDIRECT_VERSION = "${STDOUT_REDIRECT_VERSION}"
        COMMIT = "${COMMIT}"
        BUILD_DATE = "${BUILD_DATE}"
        APP_VERSION = "${VERSION}"
        RSTATE = "${RSTATE}"
        IMAGE_PRODUCT_NUMBER = "${MLSERVER_MLLIB_RUNTIME_IMAGE_PRODUCT_NUMBER}"
        IMAGE_PRODUCT_TITLE = "${IMAGE_PRODUCT_TITLE_PREFIX} MLServer MLlib Runtime Image"
        RUNTIME = "mllib"
        MLSERVER_VERSION = "${MLSERVER_VERSION}"
        MLSERVER_RUNTIME_CONTAINER_NAME="eric-aiml-model-lcm-kserve-mlserver-mllib"
        MLSERVER_RUNTIME_USER_ID="${MLSERVER_MLLIB_RUNTIME_IMAGE_USER_ID}"
    }
}

#################################################################################################################################################################
# MLServer Tensorflow Custom Runtime
#################################################################################################################################################################

variable "MLSERVER_TENSORFLOW_RUNTIME_IMAGE_USER_ID" {
    default = "notset"
}

variable "MLSERVER_TENSORFLOW_RUNTIME_IMAGE_PRODUCT_NUMBER" {
    default = "notset"
}

target "mlserver-customruntime-tensorflow" {
    context = "${PWD}/.bob/3pps/mlserver"
    contexts = {
        additional-scripts-context = "${PWD}/images/mlserver"
        custom-runtimes-context = "${PWD}/src/"
        mlserver-installer = "target:mlserver-installer"
    }
    dockerfile = "${PWD}/images/mlserver/Dockerfile"
    tags = [ "${INTERNAL_IMAGE_PREFIX}-mlserver-tensorflow:${VERSION}", "${DROP_IMAGE_PREFIX}-mlserver-tensorflow:${VERSION}" ]
    target = "mlserver-custom-runtimes"
    secret = ["type=env,id=ARM_API_TOKEN"]
    args = {
        CBOS_VERSION = "${CBOS_VERSION}"
        STDOUT_REDIRECT_VERSION = "${STDOUT_REDIRECT_VERSION}"
        COMMIT = "${COMMIT}"
        BUILD_DATE = "${BUILD_DATE}"
        APP_VERSION = "${VERSION}"
        RSTATE = "${RSTATE}"
        IMAGE_PRODUCT_NUMBER = "${MLSERVER_TENSORFLOW_RUNTIME_IMAGE_PRODUCT_NUMBER}"
        IMAGE_PRODUCT_TITLE = "${IMAGE_PRODUCT_TITLE_PREFIX} MLServer Tensorflow Runtime Image"
        RUNTIME = "tensorflow"
        MLSERVER_VERSION = "${MLSERVER_VERSION}"
        MLSERVER_CUSTOM_RUNTIME_CONTAINER_NAME = "eric-aiml-model-lcm-kserve-mlserver-tensorflow"
        MLSERVER_RUNTIME_USER_ID = "${MLSERVER_TENSORFLOW_RUNTIME_IMAGE_USER_ID}"
        PACKAGE_VERSION = "${CUSTOM_PYTHON_PACKAGE_VERSION}"
    }
}

#################################################################################################################################################################
# MLServer Pytorch Custom Runtime
#################################################################################################################################################################

variable "MLSERVER_PYTORCH_RUNTIME_IMAGE_USER_ID" {
    default = "notset"
}

variable "MLSERVER_PYTORCH_RUNTIME_IMAGE_PRODUCT_NUMBER" {
    default = "notset"
}

target "mlserver-customruntime-pytorch" {
    context = "${PWD}/.bob/3pps/mlserver"
    contexts = {
        additional-scripts-context = "${PWD}/images/mlserver"
        custom-runtimes-context = "${PWD}/src/"
        mlserver-installer = "target:mlserver-installer"
    }
    dockerfile = "${PWD}/images/mlserver/Dockerfile"
    tags = [ "${INTERNAL_IMAGE_PREFIX}-mlserver-pytorch:${VERSION}", "${DROP_IMAGE_PREFIX}-mlserver-pytorch:${VERSION}" ]
    target = "mlserver-custom-runtimes"
    secret = ["type=env,id=ARM_API_TOKEN"]
    args = {
        CBOS_VERSION = "${CBOS_VERSION}"
        STDOUT_REDIRECT_VERSION = "${STDOUT_REDIRECT_VERSION}"
        COMMIT = "${COMMIT}"
        BUILD_DATE = "${BUILD_DATE}"
        APP_VERSION = "${VERSION}"
        RSTATE = "${RSTATE}"
        IMAGE_PRODUCT_NUMBER = "${MLSERVER_PYTORCH_RUNTIME_IMAGE_PRODUCT_NUMBER}"
        IMAGE_PRODUCT_TITLE = "${IMAGE_PRODUCT_TITLE_PREFIX} MLServer Pytorch Runtime Image"
        RUNTIME = "pytorch"
        MLSERVER_VERSION = "${MLSERVER_VERSION}"
        MLSERVER_CUSTOM_RUNTIME_CONTAINER_NAME = "eric-aiml-model-lcm-kserve-mlserver-pytorch"
        MLSERVER_RUNTIME_USER_ID = "${MLSERVER_PYTORCH_RUNTIME_IMAGE_USER_ID}"
        PACKAGE_VERSION = "${CUSTOM_PYTHON_PACKAGE_VERSION}"
    }
}

#################################################################################################################################################################
# MLServer Base with FOSSA
#################################################################################################################################################################

variable MLSERVER_FOSSA_IMAGE {
    default = "notset"
}

target "mlserver-base-with-fossa"{
    context = "${PWD}/.bob/3pps/mlserver"
    contexts = {
        mlserver-base = "target:mlserver-base"
        additional-scripts-context = "${PWD}/images/mlserver"
        custom-runtimes-context = "${PWD}/src/"
    }
    dockerfile = "${PWD}/images/mlserver/Dockerfile"
    tags = [ "${MLSERVER_FOSSA_IMAGE}" ]
    target = "mlserver-fossa-scanner"
    args = {
        CBOS_VERSION = "${CBOS_VERSION}"
        STDOUT_REDIRECT_VERSION = "${STDOUT_REDIRECT_VERSION}"
    }

}

#################################################################################################################################################################
# MLServer Tensorflow Custom Runtime Fossa
#################################################################################################################################################################

variable MLSERVER_TENSORFLOW_FOSSA_IMAGE {
    default = "notset"
}

target "mlserver-tensorflow-with-fossa"{
    context = "${PWD}/.bob/3pps/mlserver"
    contexts = {
        mlserver-custom-runtime = "target:mlserver-customruntime-tensorflow"
        additional-scripts-context = "${PWD}/images/mlserver"
        custom-runtimes-context = "${PWD}/src/"
    }
    dockerfile = "${PWD}/images/mlserver/Dockerfile"
    tags = [ "${MLSERVER_TENSORFLOW_FOSSA_IMAGE}" ]
    target = "mlserver-custom-runtimes-fossa"
    args = {
        CBOS_VERSION = "${CBOS_VERSION}"
        STDOUT_REDIRECT_VERSION = "${STDOUT_REDIRECT_VERSION}"
        RUNTIME = "tensorflow"
    }

}

#################################################################################################################################################################
# MLServer Pytorch Custom Runtime Fossa
#################################################################################################################################################################

variable MLSERVER_PYTORCH_FOSSA_IMAGE {
    default = "notset"
}

target "mlserver-pytorch-with-fossa"{
    context = "${PWD}/.bob/3pps/mlserver"
    contexts = {
        mlserver-custom-runtime = "target:mlserver-customruntime-pytorch"
        additional-scripts-context = "${PWD}/images/mlserver"
        custom-runtimes-context = "${PWD}/src/"
    }
    dockerfile = "${PWD}/images/mlserver/Dockerfile"
    tags = [ "${MLSERVER_PYTORCH_FOSSA_IMAGE}" ]
    target = "mlserver-custom-runtimes-fossa"
    args = {
        CBOS_VERSION = "${CBOS_VERSION}"
        STDOUT_REDIRECT_VERSION = "${STDOUT_REDIRECT_VERSION}"
        RUNTIME = "pytorch"
    }

}