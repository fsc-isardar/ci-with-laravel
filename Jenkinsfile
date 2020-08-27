def TESTS_FAILED = false
pipeline {

    options { disableConcurrentBuilds() }
    
    agent any

    environment {
        GIT_REPO_CREDENTIALS = credentials('ce677137-6f5d-48d3-b6a4-5a7c6d5a6550')
        COMPOSER_AUTH = """{
            "http-basic": {
                "github.com": {
                    "username": "${env.GIT_REPO_CREDENTIALS_USR}",
                    "password": "${env.GIT_REPO_CREDENTIALS_PSW}"
                }
            }
        }"""
    }

    stages {
        stage('trigger') {
            steps {
                echo 'Merge detected into integrate branch.'
            }
        }
        stage('build') {
            steps {
                echo 'Building...'
                sshagent(credentials : ['jenkins-at-fsc-learning-ssh-creds']) {
                    sh 'ssh -v jenkins@68.183.24.172 "docker-compose up" '
                }
            }
        }
        stage('test') {
            steps {
                echo 'Continuous integration testing...'
                error('force die!')
                sh 'php artisan test --group=ci'
                script {
                    def result = sh(script: "\$?", returnStatus: true)
                    if (result != 0) {
                        sh("echo Integration tests failed. Rolling back merge on integrate...")
                        sh("git checkout origin/integrate")
                        sh("git revert -m 1")
                        sh('git push')
                        TESTS_FAILED = true
                        error("integrate branch rolled back.")
                    }
                }
                sh "echo Integration tests passed."
            }
        }
        stage('copy') {
            steps {
                echo 'Copying integrate to development branch...'
                sh 'git checkout origin/development'
                sh 'git merge -v --no-commit origin/integrate'
                telegramSend 'Merge ready to inspect before commiting/aborting in Jenkins @ http://68.183.24.172:8080/job/ci-with-laravel/'
                script {
                    println 'Merge ready to inspect. Press "f" to abort merge, otherwise press any other key to commit the merge.'
                    def choice = System.in.newReader().readLine()
                    if (choice == 'f') {
                        sh('git merge --abort')
                        error('Merge aborted.')
                    }
                }
                sh 'git add -a'
                sh 'git commit'
                sh 'git push'
            }
        }
        stage('clean') {
            steps {
                echo 'Cleaning up...'
                sh 'docker-compose down'
            }
        }
    }
    
    post {
        always {
            echo 'Ran.'
            deleteDir() /* clean up our workspace */
        }
        success {
            echo 'Passed.'
        }
        failure {
            echo 'Failed.'
            sh 'docker-compose down'
            script {
                if (TESTS_FAILED == true) {
                    telegramSend 'Integration tests have failed in Jenkins @ http://68.183.24.172:8080/job/ci-with-laravel/'
                }
            }
        }
        unstable {
            echo 'Ran Unstabley.'
            sh 'docker-compose down'
        }
        changed {
            echo 'Changed.'
        }
    }
}
