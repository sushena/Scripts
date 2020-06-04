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
-Dsonar.jacoco.itReportPath=${WORKSPACE}/com.sentient.portal/coverage/jacoco.exec \
-Dsonar.jacoco.reportPaths=${WORKSPACE}/com.sentient.portal/jacocoreport/ \
-Dsonar.junit.reportPaths=${WORKSPACE}/com.sentient.portal/junitReport/xml \
-Dsonar.dynamicAnalysis=reuseReports \
-Dsonar.java.coveragePlugin=jacoco \
'''
}
stage("Quality Gate") {
    steps {
        sh '''
        echo y|keytool -import -trustcacerts -keystore /usr/java/latest/jre/lib/security/cacerts -storepass changeit -alias SonarQube1 -import -file /tmp/sonar1.cer
        echo y|keytool -import -trustcacerts -keystore /usr/java/latest/jre/lib/security/cacerts -storepass changeit -alias SonarQube -import -file /tmp/sonar.cer
        '''
        timeout(time: 1, unit: 'HOURS') {
        //waitForQualityGate abortPipeline: true
        script{
            env.WORKSPACE = pwd()
            def myFile = readFile "$workspace/.scannerwork/report-task.txt"
            def taskStatus = ""
            def analysisId=""
            while ( !analysisId?.trim() ) {  
                println "Sonar results not generated yet. Lets retry after a minute"
                sleep(60)  
                def taskUrl=StringUtils.substringAfter(myFile.readLines().get(6), '=')
                println ("taskUrl is "+taskUrl)
                //def result = taskUrl.toURL().text
                def result = [ 'bash', '-c', "curl -v -k -X GET -H \"Content-Type: application/json\" ${taskUrl}" ].execute().text
                println("result is "+result)
                def taskSlurper = new groovy.json.JsonSlurper().parseText(result)
                
                taskStatus=taskSlurper.task.status
                analysisId=taskSlurper.task.analysisId
                def branchName=taskSlurper.task.branch
                def projectKey=taskSlurper.task.componentKey
                println("Task Status="+taskStatus)
                println("Analysis ID="+analysisId)
        }
        def analysisUrl= 'http://alm-sonar2:9000/api/qualitygates/project_status?analysisId='+analysisId
        println ("Analysis Url="+analysisUrl)
        /*getting the response from the above step*/
        def analysisResult = analysisUrl.toURL().text
        println ("Analysis Result="+analysisResult)
        def qualityGateResSlurper = new groovy.json.JsonSlurper().parseText(analysisResult)
        def qualityGateResStatus=qualityGateResSlurper.projectStatus
        println("Status of SonarAnalysis is "+qualityGateResStatus.status)
        assert qualityGateResStatus.status != "ERROR" : "Build fail because sonar project status is FAILED"
        println "Huraaaah! You made it  Sonar Results are good"
        }
    }
}




