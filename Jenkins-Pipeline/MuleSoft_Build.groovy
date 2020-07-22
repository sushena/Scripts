pipeline {
    agent any
    options { timestamps () }
 
parameters {
         string defaultValue: 'master', description: 'Enter Release Branch', name: 'branch', trim: true
         choice(name: 'service_name', choices: 'te-ct-mule-apigateway', description: 'Select Service')
         }
   
    environment {
        def svc_name = "${params.service_name}"
        def working_dir =  "$svc_name/target/"
        }
 
    stages {
        stage ('Git Checkout') {
            steps {
                deleteDir()
                checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'Git', url: 'https://github.tycoelectronics.net/HappiestMindControlTower/muleApiGateway.git']]])
            
        
            }
        }
        stage ('Maven Test and Build') {
            steps {
                    script {
                        sh '''
                        cd "$svc_name"/
                        /var/lib/jenkins/tools/hudson.tasks.Maven_MavenInstallation/maven_latest/bin/mvn clean package -U  -Dmaven.test.skip=true
                        '''
                    }
                }
           }
        
        stage ('Publish Artifactory to S3'){
            steps {
            s3Upload(bucket:"te-corp18650-control-tower-artifacts", path: params.service_name, includePathPattern:'**/*.jar', workingDir: "$working_dir")          
            }
        }
    }
}