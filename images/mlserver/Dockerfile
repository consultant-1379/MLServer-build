
ARG CBOS_VERSION
ARG CBO_IMAGE_URL=armdocker.rnd.ericsson.se/proj-ldc/common_base_os_release/sles

############################################################################################

FROM ${CBO_IMAGE_URL}:${CBOS_VERSION} as cbos
ARG CBOS_VERSION

############################################################################################

FROM armdockerhub.rnd.ericsson.se/ubuntu:latest as stdout-downloader

WORKDIR /workspace

RUN apt-get update && apt-get install --no-install-recommends -y curl ca-certificates && update-ca-certificates
SHELL ["/bin/bash", "-l", "-c"]

ARG STDOUT_REDIRECT_VERSION
ARG STDOUT_REDIRECT_PACKAGE_URL=https://arm.seli.gic.ericsson.se/artifactory/proj-adp-log-release/com/ericsson/bss/adp/log/stdout-redirect/${STDOUT_REDIRECT_VERSION}/eric-log-libstdout-redirect-golang-cxa30176-${STDOUT_REDIRECT_VERSION}.x86_64.tar
RUN --mount=type=secret,id=ARM_API_TOKEN \
    set -eux \
    && if [ -z "${STDOUT_REDIRECT_VERSION}" ]; then echo "STDOUT_REDIRECT_VERSION is not set"; exit 1; fi \
    && API_TOKEN=$(cat /run/secrets/ARM_API_TOKEN) \
    && if [ -z "${API_TOKEN}" ]; then echo "ARM_API_TOKEN secret is not set"; exit 1; fi \
    && curl -O -H "X-JFrog-Art-Api: ${API_TOKEN}" "${STDOUT_REDIRECT_PACKAGE_URL}" \
    && tar xvf *.tar \
    && rm -f *.tar 

############################################################################################

FROM cbos as mlserver-base-builder
ARG CBOS_VERSION
ARG CBO_REPO_URL=https://arm.sero.gic.ericsson.se/artifactory/proj-ldc-repo-rpm-local/common_base_os/sles/${CBOS_VERSION}
ARG CBO_HEADERS=https://arm.sero.gic.ericsson.se/artifactory/proj-ldc-repo-rpm-local/common_base_os/sles/${CBOS_VERSION}_devel
ARG CBO_DEVEL=https://arm.sero.gic.ericsson.se/artifactory/proj-ldc-repo-rpm-local/adp-dev/adp-build-env/${CBOS_VERSION}

SHELL ["/bin/bash", "-l", "-c"]

ARG POETRY_VERSION="1.8.1"

RUN set -ex \
    && zypper ar -C -G -f $CBO_REPO_URL?ssl_verify=no     COMMON_BASE_OS_SLES_REPO \
    && zypper ar -C -G -f $CBO_HEADERS?ssl_verify=no CBO_HEADERS \
    && zypper ar -C -G -f $CBO_DEVEL?ssl_verify=no CBO_DEVEL \
    && zypper install --no-confirm python311 python311-pip \
        libgomp1  Mesa-libGL1   glib2-devel   shadow wget \
    && ln -s /usr/bin/python3.11 /usr/bin/python \
    && python -m pip install --no-cache-dir --upgrade pip \
    && python -m pip install --no-cache-dir --upgrade pipenv setuptools wheel \
    && python -m pip install --no-cache-dir --upgrade ffmpeg \
    && update-ca-certificates \
    && zypper clean --all \
    && zypper rr COMMON_BASE_OS_SLES_REPO CBO_HEADERS CBO_DEVEL \
    && pip install --no-cache-dir poetry==$POETRY_VERSION

############################################################################################

FROM mlserver-base-builder as wheel-builder-base

COPY --from=additional-scripts-context ./build-wheels.sh ./update-package-versions.sh ./hack/
COPY ./mlserver ./mlserver
COPY ./openapi ./openapi
COPY ./runtimes ./runtimes
COPY \
    pyproject.toml \
    poetry.lock \
    README.md \
    ./

# Install Poetry, export constraints.txt file
RUN set -eux -o pipefail \
    && ./hack/update-package-versions.sh \
    && mkdir -p /opt/mlserver/dist \
    && poetry export --with all-runtimes \
        --without-hashes \
        --format constraints.txt \
        -o /opt/mlserver/dist/constraints.txt \
    && sed -i 's/\[.*\]//g' /opt/mlserver/dist/constraints.txt

############################################################################################

FROM scratch as export-constraints-file
COPY --from=wheel-builder-base /opt/mlserver/dist/constraints.txt /mlserver_constraints.txt

############################################################################################

FROM wheel-builder-base as wheel-builder

# package version for custom runtimes
ARG PACKAGE_VERSION="0.1.0"
ENV PACKAGE_VERSION=${PACKAGE_VERSION}

# Copy custom runtimes and its build script
COPY --from=custom-runtimes-context ./ ./custom-runtimes

COPY --from=additional-scripts-context build-custom-runtimes.sh ./hack/build-custom-runtimes.sh

# Install Poetry, build wheels and export constraints.txt file
# NOTE: Poetry outputs extras within the constraints, which are not supported
# by pip:
# https://github.com/python-poetry/poetry-plugin-export/issues/210
RUN set -eux -o pipefail \
    && ./hack/build-wheels.sh /opt/mlserver/dist \
    && ./hack/build-custom-runtimes.sh /opt/mlserver/dist \
    && ls -lrth /opt/mlserver/dist/* 

############################################################################################

FROM mlserver-base-builder as mlserver-installer
ARG MLSERVER_PATH=/opt/mlserver

WORKDIR ${MLSERVER_PATH}
COPY --from=wheel-builder /opt/mlserver/dist/mlserver /opt/mlserver/dist/constraints.txt  ./dist/
RUN pip install --no-cache-dir $(ls "./dist/"*.whl) --constraint ./dist/constraints.txt

############################################################################################

FROM mlserver-installer as mlserver-base 

ARG MLSERVER_PATH=/opt/mlserver
ARG MLSERVER_BASE_USER_ID=1000 
ARG MLSERVER_BASE_CONTAINER_NAME=eric-aiml-model-lcm-kserve-mlserver-base
ARG COMMIT
ARG BUILD_DATE
ARG APP_VERSION
ARG RSTATE
ARG IMAGE_PRODUCT_NUMBER
ARG IMAGE_PRODUCT_TITLE
ARG MLSERVER_VERSION

LABEL \
    org.opencontainers.image.title=$IMAGE_PRODUCT_TITLE \
    org.opencontainers.image.created=$BUILD_DATE \
    org.opencontainers.image.revision=$COMMIT \
    org.opencontainers.image.vendor=Ericsson \
    org.opencontainers.image.version=$APP_VERSION \
    com.ericsson.product-revision=$RSTATE \
    com.ericsson.product-number=$IMAGE_PRODUCT_NUMBER \
    com.ericsson.product-3pp-name="SeldonIO/MLServer" \
    com.ericsson.product-3pp-version=${MLSERVER_VERSION}

ENV MLSERVER_MODELS_DIR=/mnt/models \
    MLSERVER_PATH=${MLSERVER_PATH} \
    NUMBA_CACHE_DIR=${MLSERVER_PATH}/.cache \ 
    HF_HOME=${MLSERVER_PATH}/.cache \
    PATH=${MLSERVER_PATH}/.local/bin:$PATH \
    LD_LIBRARY_PATH=/usr/local/nvidia/lib64:/usr/lib/python3.11/site-packages/nvidia/cuda_runtime/lib:$LD_LIBRARY_PATH

WORKDIR ${MLSERVER_PATH}

RUN echo "$MLSERVER_BASE_USER_ID:!::0:::::" >>/etc/shadow \
    && echo "$MLSERVER_BASE_USER_ID:x:$MLSERVER_BASE_USER_ID:0:An Identity for $MLSERVER_BASE_CONTAINER_NAME:/nonexistent:/bin/false" >>/etc/passwd \
    && chown -R $MLSERVER_BASE_USER_ID:0 $MLSERVER_PATH \
    && chmod -R 776 $MLSERVER_PATH \
    && rm -rf ./dist

COPY --chown=$MLSERVER_BASE_USER_ID --from=stdout-downloader /workspace/stdout-redirect /opt/stdout-redirect
COPY --from=additional-scripts-context --chown=$MLSERVER_BASE_USER_ID entrypoint.sh ${MLSERVER_PATH}/entrypoint.sh

USER $MLSERVER_BASE_USER_ID

ENTRYPOINT ["catatonit", "--"]
CMD ["./entrypoint.sh"]

############################################################################################
FROM mlserver-installer as mlserver-runtime

ARG RUNTIME
ARG MLSERVER_PATH=/opt/mlserver
ARG MLSERVER_RUNTIME_USER_ID=1000
ARG COMMIT
ARG BUILD_DATE
ARG APP_VERSION
ARG RSTATE
ARG IMAGE_PRODUCT_NUMBER
ARG IMAGE_PRODUCT_TITLE
ARG MLSERVER_VERSION
ARG MLSERVER_RUNTIME_CONTAINER_NAME

LABEL \
    org.opencontainers.image.title=$IMAGE_PRODUCT_TITLE \
    org.opencontainers.image.created=$BUILD_DATE \
    org.opencontainers.image.revision=$COMMIT \
    org.opencontainers.image.vendor=Ericsson \
    org.opencontainers.image.version=$APP_VERSION \
    com.ericsson.product-revision=$RSTATE \
    com.ericsson.product-number=$IMAGE_PRODUCT_NUMBER \
    com.ericsson.product-3pp-name="SeldonIO/MLServer" \
    com.ericsson.product-3pp-version=${MLSERVER_VERSION}

# docker does not preserve the environment variables from the parent stage
# so we need to set them again
ENV MLSERVER_MODELS_DIR=/mnt/models \
    MLSERVER_PATH=${MLSERVER_PATH} \
    NUMBA_CACHE_DIR=${MLSERVER_PATH}/.cache \ 
    HF_HOME=${MLSERVER_PATH}/.cache \
    PATH=${MLSERVER_PATH}/.local/bin:$PATH \
    LD_LIBRARY_PATH=/usr/local/nvidia/lib64:/usr/lib/python3.11/site-packages/nvidia/cuda_runtime/lib:$LD_LIBRARY_PATH

WORKDIR ${MLSERVER_PATH}

COPY --from=wheel-builder /opt/mlserver/dist/${RUNTIME} ./dist/
COPY --chown=$MLSERVER_RUNTIME_USER_ID --from=stdout-downloader /workspace/stdout-redirect /opt/stdout-redirect
COPY --from=additional-scripts-context --chown=$MLSERVER_RUNTIME_USER_ID entrypoint.sh ${MLSERVER_PATH}/entrypoint.sh

# install runtime whl and create user for running the container
RUN set -eux -o pipefail \
    && _whl="./dist/"*.whl \
    && echo "--> Installing $_whl..." \
    && pip install --no-cache-dir $_whl --constraint ./dist/constraints.txt \
    && rm -f /usr/lib/python3.11/site-packages/spacy/tests/package/requirements.txt \
    && rm -rf /root/.cache/pip \
    && rm -rf ./dist \
    && echo "Done installing $RUNTIME" \
    && echo "$MLSERVER_RUNTIME_USER_ID:!::0:::::" >>/etc/shadow \
    && echo "$MLSERVER_RUNTIME_USER_ID:x:$MLSERVER_RUNTIME_USER_ID:0:An Identity for $MLSERVER_RUNTIME_CONTAINER_NAME:/nonexistent:/bin/false" >>/etc/passwd \
    && chown -R $MLSERVER_RUNTIME_USER_ID:0 $MLSERVER_PATH \
    && chmod -R 776 $MLSERVER_PATH \ 
    && chmod +x ${MLSERVER_PATH}/entrypoint.sh

USER ${MLSERVER_RUNTIME_USER_ID}

ENTRYPOINT ["catatonit", "--"]
CMD ["./entrypoint.sh"]

############################################################################################

FROM mlserver-installer as mlserver-custom-runtimes

ARG RUNTIME
ARG MLSERVER_PATH=/opt/mlserver
ARG MLSERVER_CUSTOM_RUNTIME_USER_ID=1000
ARG COMMIT
ARG BUILD_DATE
ARG APP_VERSION
ARG RSTATE
ARG IMAGE_PRODUCT_NUMBER
ARG IMAGE_PRODUCT_TITLE
ARG MLSERVER_VERSION
ARG MLSERVER_CUSTOM_RUNTIME_CONTAINER_NAME
ARG PYTORCH_EXTRAINDEX_URL=https://download.pytorch.org/whl/cpu

LABEL \
    org.opencontainers.image.title=$IMAGE_PRODUCT_TITLE \
    org.opencontainers.image.created=$BUILD_DATE \
    org.opencontainers.image.revision=$COMMIT \
    org.opencontainers.image.vendor=Ericsson \
    org.opencontainers.image.version=$APP_VERSION \
    com.ericsson.product-revision=$RSTATE \
    com.ericsson.product-number=$IMAGE_PRODUCT_NUMBER \
    com.ericsson.product-3pp-name="SeldonIO/MLServer" \
    com.ericsson.product-3pp-version=${MLSERVER_VERSION}

# docker does not preserve the environment variables from the parent stage
# so we need to set them again
ENV MLSERVER_MODELS_DIR=/mnt/models \
    MLSERVER_PATH=${MLSERVER_PATH} \
    NUMBA_CACHE_DIR=${MLSERVER_PATH}/.cache \ 
    HF_HOME=${MLSERVER_PATH}/.cache \
    PATH=${MLSERVER_PATH}/.local/bin:$PATH \
    LD_LIBRARY_PATH=/usr/local/nvidia/lib64:/usr/lib/python3.11/site-packages/nvidia/cuda_runtime/lib:$LD_LIBRARY_PATH

WORKDIR ${MLSERVER_PATH}

COPY --from=wheel-builder /opt/mlserver/dist/${RUNTIME} /opt/mlserver/dist/constraints.txt ./dist/
COPY --chown=$MLSERVER_CUSTOM_RUNTIME_USER_ID --from=stdout-downloader /workspace/stdout-redirect /opt/stdout-redirect
COPY --from=additional-scripts-context --chown=$MLSERVER_CUSTOM_RUNTIME_USER_ID entrypoint.sh ${MLSERVER_PATH}/entrypoint.sh

RUN set -eux -o pipefail \
    && _wheelName=$(echo $RUNTIME | tr '-' '_') \
    && _wheel="./dist/"*.whl \
    && echo "--> Installing $_wheel..." \
    && if [[ "${RUNTIME}" == "pytorch" ]]; then \
        pip install --no-cache-dir $_wheel --constraint "./dist/${RUNTIME}-constraints.txt" --extra-index-url "${PYTORCH_EXTRAINDEX_URL}"; \
    else \
        pip install --no-cache-dir $_wheel --constraint "./dist/${RUNTIME}-constraints.txt"; \
    fi \
    && rm -f /usr/lib/python3.11/site-packages/spacy/tests/package/requirements.txt \
    && rm -rf /root/.cache/pip \
    && rm -rf dist \
    && echo "$MLSERVER_CUSTOM_RUNTIME_USER_ID:!::0:::::" >>/etc/shadow \
    && echo "$MLSERVER_CUSTOM_RUNTIME_USER_ID:x:$MLSERVER_CUSTOM_RUNTIME_USER_ID:0:An Identity for $MLSERVER_CUSTOM_RUNTIME_CONTAINER_NAME:/nonexistent:/bin/false" >>/etc/passwd \
    && chown -R $MLSERVER_CUSTOM_RUNTIME_USER_ID:0 $MLSERVER_PATH \
    && chmod -R 776 $MLSERVER_PATH \ 
    && chmod +x ${MLSERVER_PATH}/entrypoint.sh
    
USER ${MLSERVER_CUSTOM_RUNTIME_USER_ID}
    
ENTRYPOINT ["catatonit", "--"]
CMD ["./entrypoint.sh"]
    

############################################################################################

FROM armdocker.rnd.ericsson.se/proj-adp-cicd-drop/bob-adp-release-auto:latest as adp-release-auto

WORKDIR /fossa-cli
RUN cp /opt/fossa-cli/${FOSSA_CLI_VERSION}/fossa ./

############################################################################################

# used as bob builder image for fossa scanning
FROM mlserver-base as mlserver-fossa-scanner

USER root

WORKDIR /fossa/
ARG FOSSA_BINARY_LOCATION=/fossa-cli

COPY --chown=root --from=adp-release-auto ${FOSSA_BINARY_LOCATION}/fossa ${FOSSA_BINARY_LOCATION}/

ENV PATH=${PATH}:${FOSSA_BINARY_LOCATION}

# fossa treats all entries in requirements.txt as direct dependencies
# it determines transitive dependencies using python -m pip list & python -m pip show
# so we need to export the direct dependencies alone to requirements.txt so that fossa can scan them
# and report the transitive dependencies correctly
RUN set -eux \
    && pip --no-cache-dir install pipdeptree \
    && pipdeptree -p mlserver -d1 -f | tail -n +2 > requirements.txt

ENTRYPOINT [ "" ]
CMD [""]

############################################################################################

FROM mlserver-custom-runtime as mlserver-custom-runtimes-fossa

ARG RUNTIME

USER root

WORKDIR /fossa/
ARG FOSSA_BINARY_LOCATION=/fossa-cli

COPY --chown=root --from=adp-release-auto ${FOSSA_BINARY_LOCATION}/fossa ${FOSSA_BINARY_LOCATION}/
COPY --from=wheel-builder /opt/mlserver/dist/${RUNTIME}/${RUNTIME}-requirements.txt ./requirements.txt

ENV PATH=${PATH}:${FOSSA_BINARY_LOCATION}

RUN ls -lrth ./

ENTRYPOINT [ "" ]
CMD [""]