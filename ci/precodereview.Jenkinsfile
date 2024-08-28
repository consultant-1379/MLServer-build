#!/usr/bin/env groovy

def bob = "./bob/bob"

def LOCKABLE_RESOURCE_LABEL = "bob-ci-patch-lcm"

def SLAVE_NODE = null
def SERVICE_OWNERS="senthil.raja.chermapandian@ericsson.com, raman.n@ericsson.com"
def MAIL_TO='d386f28a.ericsson.onmicrosoft.com@emea.teams.ms, PDLMMECIMM@pdl.internal.ericsson.com'

node(label: 'docker') {
    stage('Nominating build node') {
        SLAVE_NODE = "${NODE_NAME}"
        echo "Executing build on ${SLAVE_NODE}"
    }
}

pipeline {
    agent {
        node {
            label "${SLAVE_NODE}"
        }
    }

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '50', artifactNumToKeepStr: '50'))
    }

    environment {
        TEAM_NAME = "${teamName}"
        KUBECONFIG = "${WORKSPACE}/.kube/config"
        DOCKER_CONFIG_FILE = "${WORKSPACE}"
        MAVEN_CLI_OPTS = "-Duser.home=${env.HOME} -B -s ${env.SETTINGS_CONFIG_FILE_NAME}"
        GIT_AUTHOR_NAME = "mxecifunc"
        GIT_AUTHOR_EMAIL = "PDLMMECIMM@pdl.internal.ericsson.com"
        GIT_COMMITTER_NAME = "${USER}"
        GIT_COMMITTER_EMAIL = "${GIT_AUTHOR_EMAIL}"
        GIT_SSH_COMMAND = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GSSAPIAuthentication=no -o PubKeyAuthentication=yes"
        GERRIT_CREDENTIALS_ID = 'gerrit-http-password-mxecifunc'
        DOCKER_CONFIG = "${WORKSPACE}"
        FOSSA_ENABLED = "true"
        DEPENDENCY_VALIDATE_ENABLED = "false"
        MIMER_CHECK_ENABLED = "false"
    }

    // Stage names (with descriptions) taken from ADP Microservice CI Pipeline Step Naming Guideline: https://confluence.lmera.ericsson.se/pages/viewpage.action?pageId=122564754
    stages {
        stage('Commit Message Check') {
            steps {
                script {
                    def final commitMessage = new String(env.GERRIT_CHANGE_COMMIT_MESSAGE.decodeBase64())
                    if (commitMessage ==~ /(?ms)((Revert)|(\[MEE\-[0-9]+\])|(\[MXE\-[0-9]+\])|(\[MXESUP\-[0-9]+\])|(\[NoJira\]))+\s\S.*/) {
                        gerritReview labels: ['Commit-Message': 1]
                    } else {
                        def final message = 'Commit message check has failed'
                        def final link = 'https://confluence.lmera.ericsson.se/display/MXE/Code+review+WoW'
                        addWarningBadge text: message, link: link
                        addShortText text: 'malformed commit-msg', link: link, border: 0
                        gerritReview labels: ['Commit-Message': -1], message: message + ', see ' + link
                    }
                }
            }
        }

        stage('Submodule Init'){
            steps{
                sshagent(credentials: ['ssh-key-mxecifunc']) {
                    sh 'git clean -xdff'
                    sh 'git submodule sync'
                    sh 'git submodule update --init --recursive'
                }
            }
        }

        stage('Clean') {
            steps {
                script{
                    sh "${bob} clean"
                }
            }
        }

        stage('Init') {
            steps {
                sh "${bob} init-precodereview"
                script {
                    env.AUTHOR_NAME = sh(returnStdout: true, script: 'git show -s --pretty=%an')
                    currentBuild.displayName = currentBuild.displayName + ' / ' + env.AUTHOR_NAME
                    withCredentials([file(credentialsId: 'ARM_DOCKER_CONFIG', variable: 'DOCKER_CONFIG_FILE')]) {
                        writeFile file: 'config.json', text: readFile(DOCKER_CONFIG_FILE)
                    }
                }
            }
        }

        stage('Lint') {
            steps {
                sh "${bob} build.lint-license-check"
            }
            post {
                success {
                    gerritReview labels: ['Code-Format': 1]
                }
                unsuccessful {
                    gerritReview labels: ['Code-Format': -1]
                }
            }
        }

        stage('Images') {
            environment{
                ARM_API_TOKEN = credentials('arm-api-token-mxecifunc')
                SERO_ARM_TOKEN = credentials ('SERO_ARM_TOKEN')
            }
            steps {
                    sshagent(credentials: ['ssh-key-mxecifunc']) {
                        sh "${bob} build.build-images"
                        sh "${bob} build.image-push-internal"
                    }
            }
            post {
                always {
                    archiveArtifacts allowEmptyArchive: true, artifacts: '**/image-design-rule-check-report*'
                    script{
                        sh "${bob} build.delete-images"
                    }
                }
            }
        }
        
        stage('FOSSA Scan'){
            when {
                expression {  env.FOSSA_ENABLED == "true" }
            }
            environment{
                FOSSA_API_KEY = credentials('FOSSA_API_KEY_PROD')
            }
            stages{
                stage('FOSSA Server Status Check') {
                    steps {
                        sh "${bob} 3pp.fossa-server-check"
                    }
                }

                stage('FOSSA Analyze') {
                    when {
                        expression { readFile('.bob/var.fossa-available').trim() == "true" }
                    }
                    steps {
                        parallel (
                            "Analyze MLServer Base": {
                                script {
                                    sh "${bob} 3pp.fossa-mlserver-base-analyze"
                                }
                            },
                            "Analyze MLServer Catboost Runtime" : {
                                script {
                                    sh "${bob} 3pp.fossa-catboost-runtime-analyze"
                                }
                            },
                            "Analyze MLServer Huggingface Runtime" : {
                                script {
                                    sh "${bob} 3pp.fossa-huggingface-runtime-analyze"
                                }
                            },
                            "Analyze MLServer LightGBM Runtime" : {
                                script {
                                    sh "${bob} 3pp.fossa-lightgbm-runtime-analyze"
                                }
                            },
                            "Analyze MLServer MLFlow Runtime" : {
                                script {
                                    sh "${bob} 3pp.fossa-mlflow-runtime-analyze"
                                }
                            },
                            "Analyze MLServer Sklearn Runtime" : {
                                script {
                                    sh "${bob} 3pp.fossa-sklearn-runtime-analyze"
                                }
                            },
                            "Analyze MLServer XGBoost Runtime" : {
                                script {
                                    sh "${bob} 3pp.fossa-xgboost-runtime-analyze"
                                }
                            },
                            "Analyze MLServer MLlib Runtime" : {
                                script {
                                    sh "${bob} 3pp.fossa-mllib-runtime-analyze"
                                }
                            },
                            "Analyze MLServer Tensorflow Runtime" : {
                                script {
                                    sh "${bob} 3pp.fossa-tensorflow-runtime-analyze"
                                }
                            },
                            "Analyze MLServer Pytorch Runtime" : {
                                script {
                                    sh "${bob} 3pp.fossa-pytorch-runtime-analyze"
                                }
                            },
                        )
                    }
                }

                stage('Fossa Scan Status Check'){
                    when {
                        expression { readFile('.bob/var.fossa-available').trim() == "true" }
                    }
                    steps {
                        parallel(
                            "MLServer Base Scan Status Check": {
                                script {
                                    sh "${bob} 3pp.fossa-mlserver-base-scan-status-check"
                                }
                            },
                            "MLServer Catboost Runtime Scan Status Check": {
                                script {
                                    sh "${bob} 3pp.fossa-catboost-runtime-scan-status-check"
                                }
                            },
                            "MLServer Huggingface Runtime Scan Status Check": {
                                script {
                                    sh "${bob} 3pp.fossa-huggingface-runtime-scan-status-check"
                                }
                            },
                            "MLServer LightGBM Runtime Scan Status Check": {
                                script {
                                    sh "${bob} 3pp.fossa-lightgbm-runtime-scan-status-check"
                                }
                            },
                            "MLServer MLFlow Runtime Scan Status Check": {
                                script {
                                    sh "${bob} 3pp.fossa-mlflow-runtime-scan-status-check"
                                }
                            },
                            "MLServer Sklearn Runtime Scan Status Check": {
                                script {
                                    sh "${bob} 3pp.fossa-sklearn-runtime-scan-status-check"
                                }
                            },
                            "MLServer XGBoost Runtime Scan Status Check": {
                                script {
                                    sh "${bob} 3pp.fossa-xgboost-runtime-scan-status-check"
                                }
                            },
                            "MLServer MLlib Runtime Scan Status Check": {
                                script {
                                    sh "${bob} 3pp.fossa-mllib-runtime-scan-status-check"
                                }
                            },
                            "MLServer Tensorflow Runtime Scan Status Check": {
                                script {
                                    sh "${bob} 3pp.fossa-tensorflow-runtime-scan-status-check"
                                }
                            },
                            "MLServer Pytorch Runtime Scan Status Check": {
                                script {
                                    sh "${bob} 3pp.fossa-pytorch-runtime-scan-status-check"
                                }
                            },
                        )
                    }
                }

                stage('FOSSA Fetch Report') {
                    when {
                        expression {  readFile('.bob/var.fossa-available').trim() == "true" }
                    }
                    steps {
                        parallel(
                            "Fetch MLServer Base Report": {
                                script {
                                    sh "${bob} 3pp.fossa-mlserver-base-fetch-scan-report"
                                }
                            },
                            "Fetch MLServer Catboost Runtime Report": {
                                script {
                                    sh "${bob} 3pp.fossa-catboost-runtime-fetch-scan-report"
                                }
                            },
                            "Fetch MLServer Huggingface Runtime Report": {
                                script {
                                    sh "${bob} 3pp.fossa-huggingface-runtime-fetch-scan-report"
                                }
                            },
                            "Fetch MLServer LightGBM Runtime Report": {
                                script {
                                    sh "${bob} 3pp.fossa-lightgbm-runtime-fetch-scan-report"
                                }
                            },
                            "Fetch MLServer MLFlow Runtime Report": {
                                script {
                                    sh "${bob} 3pp.fossa-mlflow-runtime-fetch-scan-report"
                                }
                            },
                            "Fetch MLServer Sklearn Runtime Report": {
                                script {
                                    sh "${bob} 3pp.fossa-sklearn-runtime-fetch-scan-report"
                                }
                            },
                            "Fetch MLServer XGBoost Runtime Report": {
                                script {
                                    sh "${bob} 3pp.fossa-xgboost-runtime-fetch-scan-report"
                                }
                            },
                            "Fetch MLServer MLlib Runtime Report": {
                                script {
                                    sh "${bob} 3pp.fossa-mllib-runtime-fetch-scan-report"
                                }
                            },
                            "Fetch MLServer Tensorflow Runtime Report": {
                                script {
                                    sh "${bob} 3pp.fossa-tensorflow-runtime-fetch-scan-report"
                                }
                            },
                            "Fetch MLServer Pytorch Runtime Report": {
                                script {
                                    sh "${bob} 3pp.fossa-pytorch-runtime-fetch-scan-report"
                                }
                            },
                        )
                    }
                }
            }
            post {
                always {
                    archiveArtifacts allowEmptyArchive: true, artifacts: 'config/fossa/**'
                }
            }
        }

        stage('FOSSA Dependency Validate') {
            when {
                expression {  env.DEPENDENCY_VALIDATE_ENABLED == "true" }
            }
            steps {
                parallel(
                    "Dependency Validate MLServer Base": {
                        script {
                            sh "${bob} 3pp.fossa-mlserver-base-dependency-validate"
                        }
                    },
                    "Dependency Validate MLServer Catboost Runtime": {
                        script {
                            sh "${bob} 3pp.fossa-catboost-runtime-dependency-validate"
                        }
                    },
                    "Dependency Validate MLServer Huggingface Runtime": {
                        script {
                            sh "${bob} 3pp.fossa-huggingface-runtime-dependency-validate"
                        }
                    },
                    "Dependency Validate MLServer LightGBM Runtime": {
                        script {
                            sh "${bob} 3pp.fossa-lightgbm-runtime-dependency-validate"
                        }
                    },
                    "Dependency Validate MLServer MLFlow Runtime": {
                        script {
                            sh "${bob} 3pp.fossa-mlflow-runtime-dependency-validate"
                        }
                    },
                    "Dependency Validate MLServer Sklearn Runtime": {
                        script {
                            sh "${bob} 3pp.fossa-sklearn-runtime-dependency-validate"
                        }
                    },
                    "Dependency Validate MLServer XGBoost Runtime": {
                        script {
                            sh "${bob} 3pp.dependency-validate-xgboost-runtime"
                        }
                    },
                    "Dependency Validate MLServer MLlib Runtime": {
                        script {
                            sh "${bob} 3pp.fossa-mllib-runtime-dependency-validate"
                        }
                    },
                    "Dependency Validate MLServer Tensorflow Runtime": {
                        script {
                            sh "${bob} 3pp.fossa-mlserver-tensorflow-dependency-validate"
                        }
                    },
                    "Dependency Validate MLServer Pytorch Runtime": {
                        script {
                            sh "${bob} 3pp.fossa-mlserver-pytorch-dependency-validate"
                        }
                    },
                    "Dependency Validate 2pps":{
                        script {
                            sh "${bob} 3pp.fossa-2pp-dependency-validate"
                        }
                    },
                    "Dependency Validate 3pps":{
                        script {
                            sh "${bob} 3pp.fossa-3pp-dependency-validate"
                        }
                    }
                )
            }
        }

        stage('Mimer Check') {
            when {
                expression {  env.MIMER_CHECK_ENABLED == "true" }
            }
            environment{
                MUNIN_TOKEN = credentials('MUNIN_TOKEN')
            }
            steps {
                parallel(
                    "MLServer Base": {
                        script {
                            sh "${bob} mimer.check-foss-in-mimer-mlserver-base"
                        }
                    },
                    "Catboost Runtime": {
                        script {
                            sh "${bob} mimer.check-foss-in-mimer-catboost-runtime"
                        }
                    },
                    "Huggingface Runtime": {
                        script {
                            sh "${bob} mimer.check-foss-in-mimer-huggingface-runtime"
                        }
                    },
                    "LightGBM Runtime": {
                        script {
                            sh "${bob} mimer.check-foss-in-mimer-lightgbm-runtime"
                        }
                    },
                    "MLFlow Runtime": {
                        script {
                            sh "${bob} mimer.check-foss-in-mimer-mlflow-runtime"
                        }
                    },
                    "Sklearn Runtime": {
                        script {
                            sh "${bob} mimer.check-foss-in-mimer-sklearn-runtime"
                        }
                    },
                    "XGBoost Runtime": {
                        script {
                            sh "${bob} mimer.check-foss-in-mimer-xgboost-runtime"
                        }
                    },
                    "MLlib Runtime": {
                        script {
                            sh "${bob} mimer.check-foss-in-mimer-mllib-runtime"
                        }
                    },
                    "Tensorflow Runtime": {
                        script {
                            sh "${bob} mimer.check-foss-in-mimer-tensorflow-runtime"
                        }
                    },
                    "Pytorch Runtime": {
                        script {
                            sh "${bob} mimer.check-foss-in-mimer-pytorch-runtime"
                        }
                    },
                    "3pps Dependencies": {
                        script {
                            sh "${bob} mimer.check-foss-in-mimer-3pp"
                        }
                    }
                )
            }
        }
    }
    post {
        success {
            script {
                modifyBuildDescription()
                cleanWs()
            }
        }
        always {
            script {
                sh "${bob} build.cleanup-temp-images"
            }
        }
    }
}

def modifyBuildDescription() {
    def VERSION = readFile('.bob/var.version').trim()
    def desc = "Version:${VERSION} <br>"
    desc+="Gerrit: <a href=${env.GERRIT_CHANGE_URL}>${env.GERRIT_CHANGE_URL}</a> <br>"
    currentBuild.description = desc
}

