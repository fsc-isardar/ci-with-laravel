pipeline {

    options { disableConcurrentBuilds() }
    
    agent any

    stages {
        stage('test') {
            steps {
                echo 'Testing pipelines out...'
            }
        }
        stage('clean') {
            steps {
                echo 'Cleaning up...'
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
        }
        unstable {
            echo 'Ran Unstabley.'
        }
        changed {
            echo 'Changed.'
        }
    }
}