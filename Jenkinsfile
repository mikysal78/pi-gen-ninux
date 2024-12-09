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
          catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
            // Flash to a SD card connected on /dev/sda
            sh "sudo dd bs=4M if=nightly-Raspbian-Ninux.img of=/dev/sda conv=sync"
            sh "sudo zip image_nightly-Raspbian-Ninux.zip nightly-Raspbian-Ninux.img"
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
