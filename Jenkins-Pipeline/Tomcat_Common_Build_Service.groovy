pipeline {
    agent any
    options { timestamps () }
	
	 parameters {
        choice(name: 'service_name', choices: 'te-dashboard-service\nte-dataset-publish-service\nte-notification-service\nte-ruleengine-server\nte-user-accounts-personalization-service\nte-cloud-config-server\nte-denodo-batch-application', description: 'Select Service')
    }
    
    environment {
        def svc_name = "${params.service_name}"
        def working_dir =  "$svc_name/target/"
        }

    stages {
        stage ('Git Checkout') {
            steps {
                deleteDir()
                checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'Git', url: 'https://github.tycoelectronics.net/HappiestMindControlTower/backendService.git']]])
            }
        }
        stage ('Maven Test and Build') {
			
            steps {
				script {
					if ("$svc_name" == 'te-denodo-batch-application'){
						sh '''
						 /var/lib/jenkins/tools/hudson.tasks.Maven_MavenInstallation/maven_latest/bin/mvn install:install-file -Dfile=/var/lib/jenkins/dependency/DenodoTest.jar -DgroupId=com.denodo -DartifactId=denodo-vdp-jdbcdriver -Dversion=6.0.3 -Dpackaging=jar -DgeneratePom=true
						 cd "$svc_name"/
						/var/lib/jenkins/tools/hudson.tasks.Maven_MavenInstallation/maven_latest/bin/mvn clean package -U  -Dmaven.test.skip=true
						'''
						}
					else {
						 sh '''
						 cd "$svc_name"/
						/var/lib/jenkins/tools/hudson.tasks.Maven_MavenInstallation/maven_latest/bin/mvn clean package -U  -Dmaven.test.skip=true
						'''
						}
				}
			}	
        }
        stage ('Publish Artifactory to S3'){
            steps {
            s3Upload(bucket:"te-corp18650-control-tower-artifacts", path: params.service_name, includePathPattern:'**/*.war', workingDir: "$working_dir")          
            }
        }
    }
}