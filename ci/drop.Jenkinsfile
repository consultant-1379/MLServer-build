#!/usr/bin/env groovy

def bob = "./bob/bob"

def LOCKABLE_RESOURCE_LABEL = "bob-ci-patch-lcm"

def SLAVE_NODE = null
def MAIL_BODY = ""
def CHANGE_URL = "unknown"

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
        RELEASE = "true"
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
    }

    // Stage names (with descriptions) taken from ADP Microservice CI Pipeline Step Naming Guideline: https://confluence.lmera.ericsson.se/pages/viewpage.action?pageId=122564754
    stages {
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
                sh "${bob} init-drop"
                script {
                    authorName = sh(returnStdout: true, script: 'git show -s --pretty=%an')
                    currentBuild.displayName = currentBuild.displayName + ' / ' + authorName
                    withCredentials([file(credentialsId: 'ARM_DOCKER_CONFIG', variable: 'DOCKER_CONFIG_FILE')]) {
                        writeFile file: 'config.json', text: readFile(DOCKER_CONFIG_FILE)
                    }
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
                }
            }
        }

        stage('Publish'){
            steps{
                sh "${bob} build.image-push"
            }
            post {
                always {
                    script{
                        sh "${bob} build.delete-images"
                    }
                }
            }
        }

        stage('Create drop Git tag'){
            steps{
                    sshagent(credentials: ['ssh-key-mxecifunc']) {
                        sh "${bob} create-drop-git-tag"
                }
            }
        }

        stage('Push to model-lcm'){
            steps{
                withCredentials([usernamePassword(credentialsId: 'gerrit-http-password-mxecifunc', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                    sshagent(credentials: ['ssh-key-mxecifunc']) {
                        sh "${bob} build.update-mlserver-in-model-lcm"
                    }
                }
            }
            post {
                always{
                    script{
                        // this file is created by above stage in the script
                        // ci/scripts/create-change.sh
                        def CHANGE_FILE = "${WORKSPACE}/.bob/change-url.txt"
                        if (fileExists("${CHANGE_FILE}")) {
                            CHANGE_URL = readFile("${CHANGE_FILE}").trim()
                        }
                        
                        MAIL_BODY = "<b>Refer:</b> ${env.BUILD_URL} <br><br>" +
                                    "<b>Note:</b> This mail was automatically sent as part of ${env.JOB_NAME} jenkins job. <br><br>"
                        if (CHANGE_URL != "unknown") {
                            MAIL_BODY += "<b>URL of the Gerrit Change raised:</b> ${CHANGE_URL}"
                        }
                    }
                }
                success {
                    script {
                            mail to: SERVICE_OWNERS,
                            cc: MAIL_TO,
                            subject: "[model-lcm-mlserver] Changeset verified successfully in model-lcm for mlserver image updation",
                            body: MAIL_BODY,
                            mimeType: 'text/html'
                        }
                }
                unsuccessful {
                    script {
                            mail to: MAIL_TO,
                            subject: "[model-lcm-mlserver] Changeset verification failed in model-lcm for mlserver image updation",
                            body: MAIL_BODY,
                            mimeType: 'text/html'
                    }
                }
            }
        }
    }
    post {
        success {
            script {
                modifyBuildDescription(CHANGE_URL)
                cleanWs()
            }
        }
    }
}

def modifyBuildDescription(String changeUrl) {

    def VERSION = readFile('.bob/var.version').trim()
    def desc = "Version:${VERSION} <br>"
    if (changeUrl != "unknown") {
        desc += "URL of the Gerrit Change raised: ${changeUrl} <br>"
    }
    currentBuild.description = desc
}