pipeline {
  agent any
  environment {
    RELEASE_VERSION = "${G_GAS_RELEASE_VERSION}"
    AMPLE_BUILD_VERSION="${RELEASE_VERSION}.${BUILD_NUMBER}"
    ARTIFACTORY_URL = "http://artifactory1.sfo.sentient-energy.com:8081/artifactory"
    ARTIFACTORY_TARGET_PATH = "se-server-experimental/AMPLE/${AMPLE_BUILD_VERSION}/"
    ARTIFACTORY_CREDENTIAL_ID = "artifactory-credentials"
  }
  stages {
    stage('checkout'){
      steps {
        deleteDir()
        git branch: 'master', url: 'git@github.com:sentient-energy/ample-anduril.git'
      }
    }
    stage('Update pom.xml'){
      steps{
        sh 'sed -i "s|{workspace}|$WORKSPACE|g" pom.xml'
      }
    }
    stage('Build Ample Anduril') {
      steps {
        withMaven(maven: 'Default') { 
          sh "mvn clean install sonar:sonar -Ddeploy.conf -DskipTests  -Dbuild.number=${AMPLE_BUILD_VERSION} -Dversion=${AMPLE_BUILD_VERSION}" 
	}
      }
    }
    stage('Build Ample Shared RPM') {
      steps {
        sh label: '', script: '''cd devops/ample-shared
        ./build-ample-shared-rpm.sh -m $RELEASE_VERSION -n $BUILD_NUMBER'''    
      }
    }
    stage('Build Ample Device Management RPM') {
      steps {
        sh label: '', script: '''cd devicemanagement/devops/rpm
        ./build-ample-devicemanagement-rpm.sh -m $RELEASE_VERSION -n $BUILD_NUMBER'''    
      }
    }
    stage('Build Ample User Management RPM') {
      steps {
        sh label: '', script: '''cd usermanagement/devops/rpm
        ./build-ample-usermanagement-rpm.sh -m $RELEASE_VERSION -n $BUILD_NUMBER'''    
      }
    }
    stage('Build Disturbance RPM') {
      steps {
        sh label: '', script: '''cd disturbance/devops/rpm
        ./build-ample-disturbance-rpm.sh -m $RELEASE_VERSION -n $BUILD_NUMBER'''    
      }
    }
    stage('Build Faults RPM') {
      steps {
        sh label: '', script: '''cd faults/devops/rpm
        ./build-ample-faults-rpm.sh -m $RELEASE_VERSION -n $BUILD_NUMBER'''    
      }
    }
    stage('Build Power Quality RPM') {
      steps {
        sh label: '', script: '''cd powerquality/devops/rpm
        ./build-ample-powerquality-rpm.sh -m $RELEASE_VERSION -n $BUILD_NUMBER'''    
      }
    }
    stage('Build CS Client RPM') {
      steps {
        sh label: '', script: '''cd csclient/devops/rpm
        ./build-ample-csclient-rpm.sh -m $RELEASE_VERSION -n $BUILD_NUMBER'''    
      }
    }
    stage('Publish to Artifactory') {
      steps {
        rtServer (
          id: "Artifactory-1",
    	  url: "${ARTIFACTORY_URL}",
	  credentialsId: "${ARTIFACTORY_CREDENTIAL_ID}"
        )
        rtUpload (
          serverId: "Artifactory-1",
          spec:'''{
            "files": [
             {
               "pattern": "./*/devops/rpm/RPMS/noarch/ample-*-$AMPLE_BUILD_VERSION-1.el7.noarch.rpm",
               "target": "${ARTIFACTORY_TARGET_PATH}"
             },
             {
               "pattern": "devops/ample-shared/RPMS/noarch/ample-shared-$AMPLE_BUILD_VERSION-1.el7.noarch.rpm",
               "target": "${ARTIFACTORY_TARGET_PATH}"
             }
             ]
          }'''
        )
      }
    }    
  }
  post {
    success {
      archiveArtifacts artifacts: '**/*.rpm', fingerprint: true
      emailext body: '''
      Build URL: 
      ${BUILD_URL}
    
      ================================================================================
    
      Git Changes:
      ${CHANGES, showPaths=true}
    
      ================================================================================
      ================================================================================
      Build cause/trigger:
      ${CAUSE}
      ================================================================================
      ================================================================================
      
      Build log tail:
      ${BUILD_LOG}
    
      ================================================================================
      ================================================================================
    
      Build Environment:
      ${ENV_VERSION}
      ''',
      recipientProviders: [[$class: 'DevelopersRecipientProvider'],[$class: 'RequesterRecipientProvider']],
      subject: '$PROJECT_NAME - Build # $BUILD_NUMBER - SUCCESSFUL!',
      to: '$DEFAULT_RECIPIENTS'
    }
    failure {
      emailext body: '''
      Build URL: 
      ${BUILD_URL}
    
      ================================================================================
      ================================================================================
    
      Git Changes:
      ${CHANGES, showPaths=true}
    
      ================================================================================
      ================================================================================
      Build cause/trigger:
    
      ${CAUSE}
      ================================================================================
      ================================================================================
      Build log tail:
    
      ${BUILD_LOG}
    
    
      ================================================================================
      ================================================================================
      Build Environment:
    
      ${ENV_VERSION}
      ''',
      recipientProviders: [[$class: 'DevelopersRecipientProvider'],[$class: 'RequesterRecipientProvider']],
      subject: '$PROJECT_NAME - Build # $BUILD_NUMBER - FAILED!',
      to: '$DEFAULT_RECIPIENTS'
    }
    aborted {
      emailext body: '''
      Build URL: 
      ${BUILD_URL}
    
      ================================================================================
      ================================================================================
    
      Git Changes:
      ${CHANGES, showPaths=true}
    
      ================================================================================
      ================================================================================
      Build cause/trigger:
    
      ${CAUSE}
      ================================================================================
      ================================================================================
      Build log tail:
    
      ${BUILD_LOG}
    
    
      ================================================================================
      ================================================================================
      Build Environment:
    
      ${ENV_VERSION}
      ''',
      recipientProviders: [[$class: 'DevelopersRecipientProvider'],[$class: 'RequesterRecipientProvider']],
      subject: '$PROJECT_NAME - Build # $BUILD_NUMBER - FAILED!',
      to: '$DEFAULT_RECIPIENTS'
    }
  }
}