@Library("dst-shared") _

def containerNamePrefix = "ipxe-boot-builder"
def uuid = UUID.randomUUID().toString()
def imageName = "ipxe-boot"

pipeline {

  agent { node { label 'dstbuild' } }

  stages {

    stage('Prep') {
      steps {
        sh "docker run -d --name ${containerNamePrefix}-${uuid} -v ${env.WORKSPACE}:/src -w /src dtr.dev.cray.com/craypc/node-image-builder:latest tail -f /dev/null"
      }
    }

    stage('Unit Tests/Validation') {
      steps {
        sh "echo 'Nothing to test/validate yet'"
      }
    }

    stage('Build & Publish') {
      when { branch 'master' }
      steps {
        withCredentials([file(credentialsId: 'google-cloud-image-builder', variable: 'google_cloud_builder_key_file')]) {
          sh "cp \$google_cloud_builder_key_file ./key.json"
          sh "docker exec ${containerNamePrefix}-${uuid} gcloud auth activate-service-account --key-file ./key.json"
          sh """
            docker exec \
              -e NODE_IMAGES_BUILDER_DESTINATION_IMAGE_PROJECT_ID=vshasta-cray \
              -e NODE_IMAGES_BUILDER_SUBNETWORK=default-network-us-central1 \
              -e NODE_IMAGES_BUILDER_ZONE=us-central1-a \
              ${containerNamePrefix}-${uuid} ./build.sh
          """
        }
        slackSend channel: "#vshasta-ci-alerts", color: '#61CE18', message: "Node image: ${imageName} build success: ${env.BUILD_URL}", tokenCredentialId: "vshasta-ci-alerts-token"
      }
    }

  }

  post {
    failure {
      slackSend channel: "#vshasta-ci-alerts", color: '#D2231B', message: "Node image: ${imageName} build failure: ${env.BUILD_URL}", tokenCredentialId: "vshasta-ci-alerts-token"
    }
    always {
      sh "docker stop ${containerNamePrefix}-${uuid} || true"
      sh "docker rm -f ${containerNamePrefix}-${uuid} || true"
    }
  }

}
