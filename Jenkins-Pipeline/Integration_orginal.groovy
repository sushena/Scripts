pipeline {
  agent any
  environment {
    RELEASE_VERSION = "1.1"
    AMPLE_BUILD_VERSION="${RELEASE_VERSION}.${BUILD_NUMBER}"
    ARTIFACTORY_URL = "http://artifactory1.sfo.sentient-energy.com:8081/artifactory"
    ARTIFACTORY_TARGET_PATH = "se-server-allison/SGW-APP/"
    ARTIFACTORY_CREDENTIAL_ID = "artifactory-credentials"
  }
  stages {
    stage('checkout ample-anduril repo'){
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
          sh "mvn clean install -Ddeploy.conf -DskipTests  -Dbuild.number=${AMPLE_BUILD_VERSION} -Dversion=${AMPLE_BUILD_VERSION}" 
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
    stage('Archive Artifacts'){
      steps{
        archiveArtifacts '*/devops/rpm/RPMS/noarch/*.rpm, devops/ample-shared/RPMS/noarch/*.rpm'
        }
    }
    stage ( 'Uninstall parallel' ) {
	  parallel {
        stage('Uninstall ample-UI') {
		  steps{
		    script {
			  sshPublisher(
    	      continueOnError: false, failOnError: true,
      		  publishers: [
      		  sshPublisherDesc(
      		  configName: "qa-smoke-ample.sqa.sentient-energy.com",
          	  verbose: true,
      		  transfers: [
          	  sshTransfer(
              sourceFiles: "",
  			  removePrefix: "",
  			  remoteDirectory: "",
  			  execCommand: "sudo service tomcat stop;\
  			  sudo service httpd stop; \
  			  sudo rabbitmqctl -n rabbit@qa-smoke-ample delete_user ample; \
  			  sudo rabbitmqctl -n rabbit@qa-smoke-ample delete_vhost ample; \
  		      sudo yum remove -y rabbitmq-server; \
  			  sudo rm -rf /var/log/ample; \
  			  sudo systemctl disable tomcat.service; \
  			  sudo rm -rf /opt/ample-share/; \
  			  sudo yum remove -y tomcat; \
  			  sudo yum remove -y httpd; \
  			  sudo yum -y remove ample-csclient ample-devicemanagement ample-disturbance ample-faults ample-powerquality ample-usermanagement;"
		      )
              ])
              ])
            }
          }
        }
        stage('Uninstall ample and SGW DB') {
	      steps {
		    script {
			  sshPublisher(
              continueOnError: false, failOnError: true,
              publishers: [
              sshPublisherDesc(
              configName: "qa-smoke-db.sqa.sentient-energy.com",
        	  verbose: true,
        	  transfers: [
        	  sshTransfer(
          	  sourceFiles: "",
          	  removePrefix: "",
          	  remoteDirectory: "",
          	  execCommand: "sudo yum remove -y ample-db;\
          	  mysql -uroot -pAmpacity123! --execute='DROP DATABASE ample'; \
          	  mysql -uroot -pAmpacity123! --execute='DROP DATABASE IF EXISTS sensor_gateway'; \
              sudo yum remove -y sensor-gateway-db;"
			  )
              ])
              ])
            }
          }
        }
        stage('Uninstall Gateway1/GCD1') {
          steps {
            script {
              sshPublisher(
              continueOnError: false, failOnError: true,
              publishers: [
              sshPublisherDesc(
              configName: "qa-smoke-sgw1.sqa.sentient-energy.com",
              verbose: true,
              transfers: [
              sshTransfer(
              sourceFiles: "",
              removePrefix: "",
              remoteDirectory: "",
              execCommand: "sudo rabbitmqctl -n rabbit@qa-smoke-sgw1 delete_user ample;\
              sudo rabbitmqctl -n rabbit@qa-smoke-sgw1 delete_vhost ample; \
              sudo systemctl stop sensor-gateway; \
      		  sudo systemctl disable sensor-gateway; \
      		  sudo systemctl stop gcd; \
              sudo yum remove -y rabbitmq-server; \
      		  sudo systemctl disable sensor-gateway; \
      		  sudo yum remove -y gcd; \
      		  sudo rm -fR /usr/share/sentient/{logi,otap,waveform,disturbanceReport,healthReport,zm1Config,los,security};"
              )
              ])
              ])
            }
          }
        }
        stage('Uninstall Gateway2/GCD2') {
          steps {
            script {
              sshPublisher(
              continueOnError: false, failOnError: true,
              publishers: [
              sshPublisherDesc(
              configName: "qa-smoke-sgw2.sqa.sentient-energy.com",
              verbose: true,
              transfers: [
              sshTransfer(
              sourceFiles: "",
              removePrefix: "",
              remoteDirectory: "",
              execCommand: "sudo rabbitmqctl -n rabbit@qa-smoke-sgw1 delete_user ample;\
              sudo rabbitmqctl -n rabbit@qa-smoke-sgw1 delete_vhost ample; \
              sudo systemctl stop sensor-gateway; \
        	  sudo systemctl disable sensor-gateway; \
        	  sudo systemctl stop gcd; \
              sudo yum remove -y rabbitmq-server; \
        	  sudo systemctl disable sensor-gateway; \
        	  sudo yum remove -y gcd; \
        	  sudo rm -fR /usr/share/sentient/{logi,otap,waveform,disturbanceReport,healthReport,zm1Config,los,security};"
              )
              ])
              ])
            }
          }
        }
      }
    }
    stage ('Copying RPMs to slave node') {
      agent {
		    label 'qa-smoke-ample'
      }
      steps {
        sh '''
        set +x
        source /etc/profile
        set -x
		sshpass -e scp ampleadmin@jenkins-alpha.sfo.sentient-energy.com:/var/lib/jenkins/workspace/smoke_sandbox/devops/ample-shared/RPMS/noarch/*.rpm /home/ampleadmin/RPM/
		sshpass -e scp ampleadmin@jenkins-alpha.sfo.sentient-energy.com:/var/lib/jenkins/workspace/smoke_sandbox/*/devops/rpm/RPMS/noarch/*.rpm /home/ampleadmin/RPM/
        '''
		}
    }
    stage('Install ample and SGW DB') {
      steps {
	    script {
	      sshPublisher(
          continueOnError: false, failOnError: true,
          publishers: [
          sshPublisherDesc(
          configName: "qa-smoke-db.sqa.sentient-energy.com",
          verbose: true,
          transfers: [
          sshTransfer(
          sourceFiles: "",
          removePrefix: "",
          remoteDirectory: "",
          execCommand: "sudo yum makecache fast;\
          sudo sentient-configure; \
          sudo yum -y install ample-db; \
    	  sudo yum -y install sensor-gateway-db;"
          )
          ])
          ])
        }
      } 
    }
    stage('Install ample UI') {
      steps {
	    script {
		  sshPublisher(
          continueOnError: false, failOnError: true,
          publishers: [
      	  sshPublisherDesc(
          configName: "qa-smoke-ample.sqa.sentient-energy.com",
          verbose: true,
          transfers: [
          sshTransfer(
          sourceFiles: "",
          removePrefix: "",
          remoteDirectory: "",
          execCommand: "sudo yum makecache fast;\
          sudo yum -y install java-1.8.0-openjdk.x86_64; \
          sudo yum -y install java-1.8.0-openjdk-headless.x86_64; \
      	  sudo sentient-configure; \
      	  sudo ample-setup; \
          sudo ample-mq-setup; \
      	  sudo yum -y install /home/ampleadmin/RPM/ample-shared-*.rpm; \
      	  sudo yum -y install /home/ampleadmin/RPM/ample-csclient-*.rpm; \
      	  sudo yum -y install /home/ampleadmin/RPM/ample-devicemanagement-*.rpm; \
      	  sudo yum -y install /home/ampleadmin/RPM/ample-disturbance-*.rpm; \
          sudo yum -y install /home/ampleadmin/RPM/ample-faults-*.rpm; \
          sudo yum -y install /home/ampleadmin/RPM/ample-powerquality-*.rpm; \
          sudo yum -y install /home/ampleadmin/RPM/ample-usermanagement-*.rpm; \
      	  sudo yum -y install ample-ui; \
      	  sudo service tomcat restart; \
      	  echo 'removing all RPM'; \
      	  rm -rf /home/ampleadmin/RPM/ample-*.rpm; \
      	  echo 'Sleeping for 60 seconds'; \
      	  sleep 60;"
          )
         ])
         ])
        }
      }
    }
    stage('Install Gateway1/GCD1') {
      steps {
	    script {
          sshPublisher(
          continueOnError: false, failOnError: true,
          publishers: [
		  sshPublisherDesc(
          configName: "qa-smoke-sgw1.sqa.sentient-energy.com",
          verbose: true,
          transfers: [
          sshTransfer(
          sourceFiles: "",
          removePrefix: "",
          remoteDirectory: "",
          execCommand: "sudo yum makecache fast;\
          sudo sentient-configure; \
          sudo yum -y install sensor-gateway; \
  		  sudo yum -y install gcd;"
          )
         ])
         ])
        }
      }
    }	
    stage('Install Gateway2/GCD2') {
      steps {
        script {
          sshPublisher(
          continueOnError: false, failOnError: true,
          publishers: [
      	  sshPublisherDesc(
          configName: "qa-smoke-sgw2.sqa.sentient-energy.com",
          verbose: true,
          transfers: [
          sshTransfer(
          sourceFiles: "",
          removePrefix: "",
          remoteDirectory: "",
          execCommand: "sudo yum makecache fast;\
          sudo sentient-configure; \
          sudo yum -y install sensor-gateway; \
      	  sudo yum -y install gcd;"
          )
         ])
         ])
        }
      }
    }
    stage('Clone Git branch and set preliminary in slave node') {
      steps {
        script {
          sshPublisher(
          continueOnError: false, failOnError: true,
          publishers: [
          sshPublisherDesc(
          configName: "qa-smoke-ample.sqa.sentient-energy.com",
          verbose: true,
          transfers: [
          sshTransfer(
          sourceFiles: "",
          removePrefix: "",
          remoteDirectory: "",
          execCommand: "sudo rm -rf /home/ampleadmin/smoke/;\
          sudo mkdir /home/ampleadmin/smoke/; \
    	  sudo git clone https://gjprasad:Dasarp%405@github.com/sentient-energy/emsw-qa.git -b RestAPI /home/ampleadmin/smoke/; \
		  sudo mkdir /home/ampleadmin/smoke/log/; \
		  echo 'Replacing CRON properties for LOGI and WAVEFORM'; \
		  sudo cp /home/ampleadmin/shared.scheduler.properties /usr/share/tomcat/conf/conf.d/shared/dist/shared.scheduler.properties; \
          sudo chmod 775 /usr/share/tomcat/conf/conf.d/shared/dist/shared.scheduler.properties; \
    	  sudo service tomcat stop; \
    	  sudo service tomcat start; \
    	  echo 'Waiting for Ample to start (60 sec)'; \
    	  sudo sleep 90;"
          )
         ])
         ])
        }
      }
    }
    stage('Copying DIR for smoke test') {
      steps {
        script {
          sshPublisher(
          continueOnError: false, failOnError: true,
          publishers: [
          sshPublisherDesc(
          configName: "qa-smoke-ample.sqa.sentient-energy.com",
          verbose: true,
          transfers: [
          sshTransfer(
          sourceFiles: "",
          removePrefix: "",
          remoteDirectory: "",
          execCommand: "echo `sudo cp -Rfr /etc/smoke-config/* /home/ampleadmin/smoke/`;"
          )
         ])
         ])
        }
      }
    }
    stage('Initiate SMOKE test') {
      steps {
        script {
          sshPublisher(
          continueOnError: false, failOnError: true,
          publishers: [
          sshPublisherDesc(
          configName: "qa-smoke-ample.sqa.sentient-energy.com",
          verbose: true,
          transfers: [
          sshTransfer(
          sourceFiles: "",
          removePrefix: "",
          remoteDirectory: "",
          execCommand: "echo 'Initiating SMOKE test';\
		  sudo su - <<eos \n whoami \n cd /home/ampleadmin/smoke/ \n pwd \n sudo python RestAPI/Main.py ConfigFiles/config.json ConfigFiles/connection_server_rc4.json Source/usermanagement.json Source/schema.csv \n eos; \
		  pwd;"
          )
         ])
         ])
        }
      }
    }
    stage ('Copying logs to /var/log/ and check smoke results') {
      agent {
		    label 'qa-smoke-ample'
      }
      steps {
        sh '''
        set +x
        sudo cp /home/ampleadmin/smoke/log/full.log /var/log/RESTapi_smoke_log/run_$(date +"%Y_%m_%d_%I_%M_%p").log
        sudo cp /home/ampleadmin/smoke/log/test_report.csv /var/log/RESTapi_smoke_log/Test_Report_$(date +"%Y_%m_%d_%I_%M_%p").log
        AppPro=`sudo grep -w "ApplyProfile" /home/ampleadmin/smoke/log/test_report.csv | grep 'FAIL' | wc -l`
        OtUp=`sudo grep -w "OtapUpgrade" /home/ampleadmin/smoke/log/test_report.csv | grep 'FAIL' | wc -l`
        DownWave=`sudo grep -w "DownloadWaveforms" /home/ampleadmin/smoke/log/test_report.csv | grep 'FAIL' | wc -l`
        if [ ${AppPro} -gt 0 ];
        then
          echo "Config Profile API test FAILED"
        fi
        
        if [ ${OtUp} -gt 0 ]; 
        then
          echo "Ontap upgrade API test FAILED"
        fi
        
        if [ ${DownWave} -gt 0 ]; 
        then
          echo "WaveForm Download API test FAILED"
        fi
        if [[ ${AppPro} -gt 0 || ${OtUp} -gt 0 || ${DownWave} -gt 0 ]]
        then
          echo "**** Exit execution ****"
          set -x
          exit 1
        fi
        '''
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
      to: 'psushena@sentient-energy.com, gjprasad@sentient-energy.com'
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
      to: 'psushena@sentient-energy.com, gjprasad@sentient-energy.com'
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
      subject: '$PROJECT_NAME - Build # $BUILD_NUMBER - FAILED!', to: 'psushena@sentient-energy.com, gjprasad@sentient-energy.com'
  }
 }
}

plot csvFileName: 'plot-547abe31-7e47-43ab-969e-b5c9555cd411.csv', csvSeries: [[displayTableFlag: false, exclusionValues: '', file: '/home/ampleadmin/log/test_report.csv', inclusionFlag: 'OFF', url: '']], group: 'Testing', numBuilds: '10', style: 'line', title: 'Smoke test'
plot csvFileName: 'plot-1a27d057-5f4a-4aa2-8006-95f038e79353.csv', csvSeries: [[displayTableFlag: false, exclusionValues: '', file: 'test_report.csv', inclusionFlag: 'OFF', url: '']], group: '', style: 'line'

10.199.24.13