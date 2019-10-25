pipeline {
  agent any
  environment {
    RELEASE_VERSION = "10.1"
    AMPLE_BUILD_VERSION="${RELEASE_VERSION}.${BUILD_NUMBER}"
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
        wget -P /home/ampleadmin/RPM/unzi http://jenkins-alpha.sfo.sentient-energy.com:8080/job/smoke_sandbox/lastSuccessfulBuild/artifact/csclient/devops/rpm/RPMS/noarch/*zip*/noarch.zip
        unzip -j /home/ampleadmin/RPM/unzi/noarch.zip -d /home/ampleadmin/RPM/
        rm -rf /home/ampleadmin/RPM/unzi/noarch.zip
             
        wget -P /home/ampleadmin/RPM/unzi http://jenkins-alpha.sfo.sentient-energy.com:8080/job/smoke_sandbox/lastSuccessfulBuild/artifact/devicemanagement/devops/rpm/RPMS/noarch/*zip*/noarch.zip
        unzip -j /home/ampleadmin/RPM/unzi/noarch.zip -d /home/ampleadmin/RPM/
        rm -rf /home/ampleadmin/RPM/unzi/noarch.zip
         
        wget -P /home/ampleadmin/RPM/unzi http://jenkins-alpha.sfo.sentient-energy.com:8080/job/smoke_sandbox/lastSuccessfulBuild/artifact/devops/ample-shared/RPMS/noarch/*zip*/noarch.zip
        unzip -j /home/ampleadmin/RPM/unzi/noarch.zip -d /home/ampleadmin/RPM/
        rm -rf /home/ampleadmin/RPM/unzi/noarch.zip
         
        wget -P /home/ampleadmin/RPM/unzi http://jenkins-alpha.sfo.sentient-energy.com:8080/job/smoke_sandbox/lastSuccessfulBuild/artifact/disturbance/devops/rpm/RPMS/noarch/*zip*/noarch.zip
        unzip -j /home/ampleadmin/RPM/unzi/noarch.zip -d /home/ampleadmin/RPM/
        rm -rf /home/ampleadmin/RPM/unzi/noarch.zip
         
        wget -P /home/ampleadmin/RPM/unzi http://jenkins-alpha.sfo.sentient-energy.com:8080/job/smoke_sandbox/lastSuccessfulBuild/artifact/faults/devops/rpm/RPMS/noarch/*zip*/noarch.zip
        unzip -j /home/ampleadmin/RPM/unzi/noarch.zip -d /home/ampleadmin/RPM/
        rm -rf /home/ampleadmin/RPM/unzi/noarch.zip
          
        wget -P /home/ampleadmin/RPM/unzi http://jenkins-alpha.sfo.sentient-energy.com:8080/job/smoke_sandbox/lastSuccessfulBuild/artifact/powerquality/devops/rpm/RPMS/noarch/*zip*/noarch.zip
        unzip -j /home/ampleadmin/RPM/unzi/noarch.zip -d /home/ampleadmin/RPM/
        rm -rf /home/ampleadmin/RPM/unzi/noarch.zip
          
        wget -P /home/ampleadmin/RPM/unzi http://jenkins-alpha.sfo.sentient-energy.com:8080/job/smoke_sandbox/lastSuccessfulBuild/artifact/usermanagement/devops/rpm/RPMS/noarch/*zip*/noarch.zip
        unzip -j /home/ampleadmin/RPM/unzi/noarch.zip -d /home/ampleadmin/RPM/
        rm -rf /home/ampleadmin/RPM/unzi/noarch.zip
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
      	  rm -rf /home/ampleadmin/RPM//*.rpm; \
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
  }
}
