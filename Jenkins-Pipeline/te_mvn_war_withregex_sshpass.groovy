pipeline {
    agent any
    options { timestamps () }

    environment {
        user_name = "jenkins_deploy"
        tomcat_ip = "10.0.3.39"
        temp_dir_1 = "/home/jenkins_deploy/"
        temp_dir_2 = "/home/jenkins_deploy/*.war"
        tomcat_dir_1 = "/opt/tomcat/apache-tomcat-9.0.35/webapps/"
        tomcat_dir_2 = "/opt/tomcat/apache-tomcat-9.0.35/webapps/*war"
    }

     tools {
        maven 'M2_HOME' 
        }

    stages {
        stage ('Git Checkout') {
            steps {
                checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'git', url: 'https://github.com/shashwath-m/java-junit-sample.git']]])
            }
        }
        stage ('Maven Test and Build') {
            steps {
                sh '''
                mvn clean package -U  -Dmaven.test.skip=true
                '''
            }
        }
        stage ('Publish Artifactory to S3'){
            steps {
               s3Upload consoleLogLevel: 'INFO', dontSetBuildResultOnFailure: false, dontWaitForConcurrentBuildCompletion: false, entries: [[bucket: 'jenkins-artifacts-storage', excludedFile: '', flatten: false, gzipFiles: false, keepForever: false, managedArtifacts: true, noUploadOnFailure: true, selectedRegion: 'eu-west-1', showDirectlyInBrowser: false, sourceFile: 'target/*', storageClass: 'STANDARD', uploadFromSlave: false, useServerSideEncryption: false]], pluginFailureResultConstraint: 'FAILURE', profileName: 'Artifact_S3Upload', userMetadata: []           
            }
        }
        stage ('Deploy Artifact'){
            steps{
                sh '''
                sudo chown -v $USER ~/.ssh/known_hosts
                set +x
                source /etc/profile
                set -x
                sshpass -e scp -o "StrictHostKeyChecking=no" /var/lib/jenkins/workspace/java-project/target/*.war "$user_name"@"$tomcat_ip":"$temp_dir_1"
                
                set +x
                source /etc/profile
                set -x
                sshpass -e ssh -o "StrictHostKeyChecking=no" "$user_name"@"$tomcat_ip" "sudo mv $temp_dir_2 $tomcat_dir_1"
                
                set +x
                source /etc/profile
                set -x
                sshpass -e ssh -o "StrictHostKeyChecking=no" "$user_name"@"$tomcat_ip" "sudo chown root:root $tomcat_dir_2"
                
                set +x
                source /etc/profile
                set -x
                sshpass -e ssh -o "StrictHostKeyChecking=no" "$user_name"@"$tomcat_ip" "sudo chmod 755 $tomcat_dir_2"
                
                '''
            }
        }
    }
}