pipeline {
    agent any
    options { timestamps () }
    
     parameters {
        choice(name: 'service_name', choices: 'te-dashboard-service\nte-dataset-publish-service\nte-notification-service\nte-ruleengine-server\nte-user-accounts-personalization-service\nte-cloud-config-server\nte-denodo-batch-application', description: 'Select Service')
        choice(name: 'tomcat_ip', choices: '10.168.15.164\n10.168.15.247', description: 'Select IP')
    }

 

    environment {
        user_name = "jenkins_deploy"
        
        temp_dir_1 = "/home/jenkins_deploy/"
        temp_dir_2 = "/home/jenkins_deploy/*.war"
        tomcat_dir_1 = "/opt/tomcat/jenkins-tomcat/webapps/"
        tomcat_dir_2 = "/opt/tomcat/jenkins-tomcat/webapps/*.war"
        tomcat_dir = "/opt/tomcat/jenkins-tomcat"
        bucket_name='te-corp18650-control-tower-artifacts'
        def service_name = "${params.service_name}"
        def tomcat_ip = "${params.tomcat_ip}"
    }

    stages {
           
        stage ('Deploy Artifact'){
            steps{
                sh '''
                
                set +x
                source /etc/profile
                set -x
                sshpass -e ssh -o "StrictHostKeyChecking=no" "$user_name"@"$tomcat_ip" "sudo rm -rf *.war"
                
                set +x
                source /etc/profile
                set -x
                sshpass -e ssh -o "StrictHostKeyChecking=no" "$user_name"@"$tomcat_ip" "sudo aws s3 cp s3://$bucket_name/$service_name/$service_name.war . --include "*.war""
                
                # Stop Tomcat Process
                set +x
                source /etc/profile
                set -x
                sshpass -e ssh -o "StrictHostKeyChecking=no" "$user_name"@"$tomcat_ip" "sudo "$tomcat_dir"/bin/shutdown.sh"
                
                set +x
                source /etc/profile
                set -x
                sshpass -e ssh -o "StrictHostKeyChecking=no" "$user_name"@"$tomcat_ip" "sudo sleep 30"
                
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
                sshpass -e ssh -o "StrictHostKeyChecking=no" "$user_name"@"$tomcat_ip" "sudo "$tomcat_dir"/bin/startup.sh"
                '''
            }
        }
    }
}