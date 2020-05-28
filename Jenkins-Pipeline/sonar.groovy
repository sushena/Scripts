stage('Sonar Analysis'){
					
					environment {
						sonarqubeScannerHome = tool name: 'SonarQube Scanner 4.2', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
					}
					steps {
						withSonarQubeEnv('ALM_SONAR') {
						sh '''
						ls -al ${sonarqubeScannerHome}
						export SONAR_SCANNER_OPTS="-Xmx1536m -XX:MaxPermSize=1024m  -XX:+UseParNewGC"
						${sonarqubeScannerHome}/bin/sonar-scanner \
						-Dsonar.projectKey=FCC_V5.5 \
-Dsonar.projectName=FCC_V5.5 \
-Dsonar.projectVersion=5.5.6.0 \
-Dsonar.branch.name=master \
-Dsonar.sources=src  \
-Dsonar.java.binaries=. \
'''
}

