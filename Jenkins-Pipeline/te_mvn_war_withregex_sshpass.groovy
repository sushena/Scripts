pipeline {
    agent any
    options { timestamps () }

    parameters {
        
        string defaultValue: '10.0.3.39', description: 'Enter Tomcat IP', name: 'tomcat_ip', trim: true
        string defaultValue: '/home/jenkins_deploy/', description: 'Enter Temp Dir where war files need to be copied', name: 'temp_dir_1', trim: true
        string defaultValue: '/home/jenkins_deploy/*.war', description: 'temp_dir_1/*.war', name: 'temp_dir_2', trim: true
        string defaultValue: '/opt/tomcat/apache-tomcat-9.0.35/', description: 'Enter Tomcat Home directory', name: 'tomcat_dir', trim: true
        string defaultValue: '/opt/tomcat/apache-tomcat-9.0.35/webapps', description: 'Enter Tomcat webapps directory', name: 'tomcat_dir_1', trim: true
        string defaultValue: '/opt/tomcat/apache-tomcat-9.0.35/webapps/*.war', description: 'tomcat_dir_1/*.war', name: 'tomcat_dir_2', trim: true
        
    }
     
    environment {
        user_name = "jenkins_deploy"
        def tomcat_ip = "${params.tomcat_ip}"
        def temp_dir_1 = "${params.temp_dir_1}"
        def temp_dir_2 = "${params.temp_dir_2}"
        def tomcat_dir = "${params.tomcat_dir}"
        def tomcat_dir_1 = "${params.tomcat_dir_1}"
        def tomcat_dir_2 = "${params.tomcat_dir_2}"
        EMAIL_TO = 'shaswath.m@gmail.com'
    }

    tools {
        maven 'M2_HOME' 
        }

    stages {
        stage ('Git Checkout') {
            steps {
                script {
                    try {
                         deleteDir()
                         checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'git', url: 'https://github.com/shashwath-m/hello-world-war.git']]])
                    }
                    catch(Exception err){
                        echo "Git Clone Failed"
                        currentBuild.result = 'FAILURE'
                        throw err
                    }
                }
                
            }
        }
        stage ('Maven Test and Build') {
            steps {
                script {
                    try {
                         sh '''
                         mvn clean package -U  -Dmaven.test.skip=true
                         '''
                    }
                catch(Exception err){
                    echo "Build Failed"
                    currentBuild.result = 'FAILURE'
                    throw err
                }

                }               
               
            }
        }
        stage ('Code Analysis Using SonarQube'){
            steps {
                 withSonarQubeEnv('sonarqube') {
                     sh 'mvn sonar:sonar'
                 }
                }
            }
        stage("Quality Gate") {
            steps {
              timeout(time: 1, unit: 'HOURS') {
                waitForQualityGate abortPipeline: true
              }
            }
          }
        stage ('Publish Artifactory to S3'){
            steps {
                      s3Upload consoleLogLevel: 'INFO', dontSetBuildResultOnFailure: false, dontWaitForConcurrentBuildCompletion: false, entries: [[bucket: 'jenkins-artifacts-storage', excludedFile: '', flatten: false, gzipFiles: false, keepForever: false, managedArtifacts: true, noUploadOnFailure: true, selectedRegion: 'eu-west-1', showDirectlyInBrowser: false, sourceFile: 'target/*.war', storageClass: 'STANDARD', uploadFromSlave: false, useServerSideEncryption: false]], pluginFailureResultConstraint: 'FAILURE', profileName: 'Artifact_S3Upload', userMetadata: []
                    }
                }
              
        stage ('Deploy Artifact'){
            steps{
                sh '''
                sudo chown -v $USER ~/.ssh/known_hosts
                # Copy Build Files
                set +x
                source /etc/profile
                set -x
                sshpass -e scp -o "StrictHostKeyChecking=no" /var/lib/jenkins/workspace/java-project/target/*.war "$user_name"@"$tomcat_ip":"$temp_dir_1"
                
                # Stop Tomcat Process
                set +x
                source /etc/profile
                set -x
                sshpass -e ssh -o "StrictHostKeyChecking=no" "$user_name"@"$tomcat_ip" "sudo $tomcat_dir/bin/shutdown.sh"
                
                set +x
                source /etc/profile
                set -x
                sshpass -e ssh -o "StrictHostKeyChecking=no" "$user_name"@"$tomcat_ip" "sudo sleep 30"
                
                set +x
                source /etc/profile
                set -x
                sshpass -e ssh -o "StrictHostKeyChecking=no" "$user_name"@"$tomcat_ip" "sudo rm -rf  $tomcat_dir_2"

                # Copy New War Files
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

                # Start Tomcat Process
                set +x
                source /etc/profile
                set -x
                sshpass -e ssh -o "StrictHostKeyChecking=no" "$user_name"@"$tomcat_ip" "sudo $tomcat_dir/bin/startup.sh"
                
                set +x
                source /etc/profile
                set -x
                sshpass -e ssh -o "StrictHostKeyChecking=no" "$user_name"@"$tomcat_ip" "sudo sleep 30"
                
                '''
            }
        }

    }
    
    post {
                
        success {
            script {
                emailext (
                        to: "${EMAIL_TO}",
                        subject: "Job '${env.JOB_NAME}' (${env.BUILD_NUMBER}) success.",
                        body: """ <p> Job: ${env.JOB_NAME} with Build No:  ${env.BUILD_NUMBER} executed successfully. Please visit ${env.BUILD_URL} for further information.</p>
                                    <p>SonarQube URL: <hr><pre>\${BUILD_LOG_REGEX , regex=".*ANALYSIS SUCCESSFUL, you can browse (.*)",showTruncatedLines=false, substText="\$1"}</pre></p>"""
                    );
                }
        }
        failure {
            script {
                emailext (
                        to: "${EMAIL_TO}",
                        subject: "Job '${env.JOB_NAME}' (${env.BUILD_NUMBER}) failed.",
                        body: """ <p> Job: ${env.JOB_NAME} with Build No:  ${env.BUILD_NUMBER} failed .Please refer below console output for more information.</p> 
                                    <p>Console output (last 250 lines):<hr><pre>\${BUILD_LOG}</pre></p>"""
                    );
                }
            }

        aborted {
            script {
                emailext (
                        to: "${EMAIL_TO}",
                        subject: "Job: '${env.JOB_NAME}' with Build No: (${env.BUILD_NUMBER}) aborted.",
                        body: """ <p> Job ${env.JOB_NAME} with Build No  ${env.BUILD_NUMBER} aborted. Please refer below console output for more information.</p>
                                    <p>Console output (last 250 lines):<hr><pre>\${BUILD_LOG}</pre></p>"""
                );
            }
        }       
    }
}