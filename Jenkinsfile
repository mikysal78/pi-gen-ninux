pipeline {
  agent any
  environment {
    IMG_NAME              = 'Raspbian-Ninux'
    IMG_DATE              = 'nightly'
    ENABLE_SSH            = '1'
    FIRST_USER_PASS       = 'ninux'
    TARGET_HOSTNAME       = 'ninux-pi'
    PI_GEN_REPO           = 'https://github.com/mikysal78/pi-gen-ninux'
    DEPLOY_ZIP            = '0'
    PUBKEY_SSH_FIRST_USER = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMuoHflKC6z/hH9l5qqinpQ5gNgmFI+r9c8Xu3kHnN9s mikysal78@gmail.com'
    CLEAN                 = '1'
    // ninux/EXPORT_IMAGE sets IMG_SUFFIX="-lite", so build.sh writes
    // deploy/${IMG_DATE}-${IMG_NAME}${IMG_SUFFIX}.img
    IMG_FILE              = "${IMG_DATE}-${IMG_NAME}-lite.img"
  }
  stages {
    stage('Build') {
      steps {
        sh 'sudo -E ./build.sh'
      }
    }
    stage('Deploy') {
      steps {
        dir('deploy') {
          sh "test -f '${IMG_FILE}'"
          sh "sudo zip 'image_${IMG_DATE}-${IMG_NAME}-lite.zip' '${IMG_FILE}'"
          catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
            // Flash to a SD card connected on /dev/sda, when one is plugged in
            sh """
              if [ -b /dev/sda ]; then
                sudo dd bs=4M if='${IMG_FILE}' of=/dev/sda conv=fsync
                sudo sync
              else
                echo 'No block device on /dev/sda, skipping flash' >&2
                exit 1
              fi
            """
          }
        }
      }
    }
  }
  post {
    success {
      archiveArtifacts artifacts: 'deploy/*', fingerprint: true
    }
  }
}
