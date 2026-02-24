pipeline {
    agent none
    environment {
        DOCKER_HUB_USER = credentials('docker-hub-login')
    }

    stages{
        // worker
        stage("[worker] build") {
            when {
                anyOf {
                    changeset "**/worker/**"
                }
            }
            agent {
                docker {
                    image "maven:3-sapmachine-21"
                    args '-v $HOME/.m2:/root/.m2'
                }
            }
            steps {
                echo "Building worker app"
                dir("worker") {
                    sh "mvn compile"
                }
            }
        }
        stage("[worker] test") {
            when {
                anyOf {
                    changeset "**/worker/**"
                }
            }
            agent {
                docker {
                    image "maven:3-sapmachine-21"
                    args '-v $HOME/.m2:/root/.m2'
                }
            }
            steps {
                echo "Running tests"
                dir("worker") {
                    sh "mvn clean test"
                }
            }
        }
        stage("[worker] package") {
            when {
                changeset "**/worker/**"
            }
            agent {
                docker {
                    image "maven:3-sapmachine-21"
                    args '-v $HOME/.m2:/root/.m2'
                }
            }
            steps {
                echo "Packaging worker app into a jarfile"
                dir("worker") {
                    sh "mvn package"
                    archiveArtifacts artifacts: "**/target/*.jar", fingerprint: true
                }
            }
        }
        stage("[worker] docker-package") {
            agent any
            when {
                allOf {
                    branch 'master'
                    changeset "**/worker/**"
                }
            }
            steps {
                echo "Packaging worker app with docker"
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'docker-hub-credentials') {
                        def image = docker.build("${DOCKER_HUB_USER}/worker:v${env.BUILD_ID}", "./worker")
                        image.push()
                        image.push("latest")
                    }
                }
            }
        }

        // result
        stage("[result] build") {
            when {
                anyOf {
                    changeset "**/result/**"
                }
            }
            agent {
                docker {
                    image "node:lts-alpine"
                    args '-v $HOME/.npm:/root/.npm'
                }
            }
            steps {
                echo 'Compiling result app'
                dir('result') {
                    sh 'npm install'
                    sh 'npm ls'
                }
            }
        }
        stage("[result] test") {
            when {
                anyOf {
                    changeset "**/result/**"
                }
            }
            agent {
                docker {
                    image "node:lts-alpine"
                    args '-v $HOME/.npm:/root/.npm'
                }
            }
            steps {
                echo 'Running tests'
                dir('result') {
                    sh 'npm install'
                    sh 'npm test'
                }
            }
        }
        stage("[result] docker-package") {
            when {
                allOf {
                    branch "master"
                    changeset "**/result/**"
                }
            }
            agent any
            steps {
                echo 'Building Docker image'
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'docker-hub-credentials') {
                        def image = docker.build("${DOCKER_HUB_USER}/result:v${env.BUILD_ID}", "./result")

                        try {
                            image.push()
                            image.push("latest")
                        } finally {
                            sh "docker rmi ${DOCKER_HUB_USER}/result:v${env.BUILD_ID}"
                            sh "docker rmi ${DOCKER_HUB_USER}/result:latest"
                        }
                    }
                }
            }
        }

        // vote
        stage('[vote] build') {
            when {
                anyOf {
                    changeset '**/vote/**'
                }
            }

            agent {
                docker {
                    image 'python:3.11-slim'
                    args '--user root'
                }
            }

            steps {
                echo 'Compiling vote app.'
                dir('vote') {
                        sh 'pip install -r requirements.txt'
                }
            }
        }
        stage('[vote] test') {
            when {
                anyOf {
                    changeset '**/vote/**'
                }
            }

            agent {
                docker {
                    image 'python:3.11-slim'
                    args '--user root'
                }
            }
            steps {
                echo 'Running Unit Tests on vote app.'
                dir('vote') {
                        sh 'pip install -r requirements.txt'
                        sh 'nosetests -v'
                }
            }
        }
        stage('[vote] integration') {
            when {
                allOf {
                    branch 'master'
                    changeset '**/vote/**'
                }
            }

            agent any

            steps {
                echo'Running Integration Tests'
                dir('vote') {
                        sh 'sh integration_test.sh'
                }
            }
        }
        stage('[vote] docker-package') {
            when {
                allOf {
                    branch 'master'
                    changeset '**/vote/**'
                }
            }

            agent any

            steps {
                echo 'Building Docker image'
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'docker-hub-credentials') {
                        def image = docker.build("${DOCKER_HUB_USER}/vote:v${env.BUILD_ID}", './vote')

                        try {
                            image.push()
                            image.push('latest')
                        } finally {
                            sh "docker rmi ${DOCKER_HUB_USER}/vote:v${env.BUILD_ID}"
                            sh "docker rmi ${DOCKER_HUB_USER}/vote:latest"
                        }
                    }
                }
            }
        }

        // sonarqube analysis
        stage('Sonarqube') {
            when {
                branch 'master'
            }

            agent any

            environment {
                sonarpath = tool 'SonarScanner'
            }

            steps {
                echo 'Running sonarqube analysis'
                withSonarQubeEnv('sonar-instavote') {
                    sh "${sonarpath}/bin/sonar-scanner -Dproject.settings=sonar-project.properties -Dorg.jenkinsci.plugins.durabletask.BourneShellScript.HEARTBEAT_CHECK_INTERVAL=86400"
                }
            }
        }

        stage("QualityGate") {
            when {
                branch 'master'
            }

            agent any

            steps {
                timeout(time:1,unit:'HOURS') {
                    //Parameter indicates whether to set pipeline to UNSTABLE if Quality Gate fails
                    // true = set pipeline to UNSTABLE, false = don't
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        // deploy to dev
        stage('deploy to dev') {
            agent any
            when {
                branch 'master'
            }
            steps {
                echo 'Deploying instavote app with docker compose'
                sh 'docker compose up -d'
            }
        }
    }

    post{
        always{
            echo 'Building mono pipeline for voting app is completed.'
        }
        failure{
            slackSend (channel: "#ci-cd", message: "Build Failed: ${env.JOB_NAME} ${env.BUILD_NUMBER}")
        }
        success{
            slackSend (channel: "#ci-cd", message: "Build Success: ${env.JOB_NAME} ${env.BUILD_NUMBER}")
        }
    }
}
