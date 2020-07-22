pipeline {
    agent any
	
	parameters {
		string defaultValue: 'c544f035-4a48-430f-abc9-240023471c2e', description: 'Enter Organization ID', name: 'orgId', trim: true
        choice(name: 'Environment', choices: 'Production\nQA\nDev\nStage', description: 'Select Deployment Environment')
	 	string defaultValue: 'te-controltower-api-gateway', description: 'Enter artifactName ', name: 'artifactName', trim: true   
		}
    
    environment {
        def orgId = "${params.orgId}"
		def Denv = "${params.Environment}"
		def artifactName = "${params.artifactName}"
        }
	
    stages {
        stage ('Deploy Mule App'){
            steps{
                
                    sh '''
					set +x
                    data=`cat /var/lib/jenkins/.mulepwd/.passwd`
                    set -x

					### Generate Access Token and Bearer Type
					echo "Generating Token"
					access_token=$(curl -s --proxy 'restrictedproxy.tycoelectronics.com:80' -X POST https://anypoint.mulesoft.com/accounts/login -H 'cache-control: no-cache' -H 'content-type: application/json' -d "$data" | grep 'access_token' | awk -F ":" '{print $NF}' | cut -d ',' -f1 | tr -d '"' | tr -d ' ')

					echo "Generating Bearer Type"
					token_type=$(curl -s --proxy 'restrictedproxy.tycoelectronics.com:80' -X POST https://anypoint.mulesoft.com/accounts/login -H 'cache-control: no-cache' -H 'content-type: application/json' -d "$data" | grep 'token_type' | awk -F ":" '{print $NF}' | cut -d ',' -f1 | tr -d '"' | tr -d ' ')

					### Get Environment ID
					echo "Get environment id"
					curl -s --proxy 'restrictedproxy.tycoelectronics.com:80' -X GET https://anypoint.mulesoft.com/accounts/api/organizations/$orgId -H "authorization:${token_type} ${access_token}" -H 'cache-control: no-cache' | jq '.environments' > envId.json

					### Filter Environment ID from JSON
					counter=`cat envId.json | jq '.[] .name' | wc -l`
					count=0
					while [ $count -le $counter ]
					do
							env=`cat envId.json | jq ".[$count] .name" | tr -d '"'`
							if [[ "$env" == *"$Denv"* ]]
							then
							{
							envId=`cat envId.json | jq ".[$count] .id" | tr -d '"'`
							#echo "Env ID is:" $envid
							}
							fi
					count=`expr $count + 1`
					done
					###echo "Environment ID is: $envId"
					###echo "Access Token is : $access_token"
					###echo "Token Type is: $token_type"

					### Get Server ID
					curl -s --proxy 'restrictedproxy.tycoelectronics.com:80' -X GET https://anypoint.mulesoft.com/hybrid/api/v1/servers -H "authorization:${token_type} ${access_token}" -H 'X-ANYPNT-ORG-ID: '$orgId'' -H 'X-ANYPNT-ENV-ID: '$envId'' -H 'cache-control: no-cache' > serverId1.json
					###cat serverId1.json

					### Get Server Group
					curl -s --proxy 'restrictedproxy.tycoelectronics.com:80' -X GET https://anypoint.mulesoft.com/hybrid/api/v1/serverGroups -H "authorization:${token_type} ${access_token}" -H 'X-ANYPNT-ORG-ID: '$orgId'' -H 'X-ANYPNT-ENV-ID: '$envId'' -H 'cache-control: no-cache' > serverId.json

					### Filter Server ID from JSON
					counter=`cat serverId.json |jq '.data[] .name'| wc -l`
					count1=0
					cat /dev/null > serverid.txt
					while [ $count1 -le $counter ]
					do
							serverGroup=`cat serverId.json | jq " .data[$count1] .name" | tr -d '"'`
							echo $serverGroup
							if [[ "$serverGroup" == "dcs-aws-qa" ]]
							then
									echo `cat serverId.json | jq " .data[$count1] .servers[] .id"` >> serverid.txt
							fi
					count1=`expr $count1 + 1`
					done
					#cat serverid.txt

					### Get Artifact ID Of Existing Application 
					curl -s --proxy 'restrictedproxy.tycoelectronics.com:80' -X GET https://anypoint.mulesoft.com/hybrid/api/v1/applications -H "authorization:${token_type} ${access_token}" -H 'X-ANYPNT-ORG-ID: '${orgId}'' -H 'X-ANYPNT-ENV-ID: '${envId}'' -H 'cache-control: no-cache' > output.json

					### Filter APPID from JSON
					cat /dev/null > temp.json
			    	appid=$(cat output.json | jq --arg artifactName ${artifactName} '.data[]| select(.name==$artifactName) | .id ')
			    	echo " ##### APP ID is: $appid ####"

					###appid=`cat temp.json | jq '.serverArtifacts[] .deploymentId ' | uniq`
					###echo "Application Id is: $appid"
					###appid=`cat output.json | jq '.data[] .serverArtifacts[0] .artifactName' | grep 'te-ct-mule-api-gateway' | tr -d '"'`

					### Deploy Artifact to Server
					if [ ! -z "$appid" ]
					then 
						###Update/Deploy on Existing Application
							cat serverid.txt |  tr " " "\n" >> serverid1.txt
							while IFS= read -r line; do
									echo "Updating Deployment on Server: $line"
									curl -s --proxy 'restrictedproxy.tycoelectronics.com:80' -X PATCH  https://anypoint.mulesoft.com/hybrid/api/v1/applications/$appid -H 'authorization: '${token_type}' '${access_token}'' -H 'X-ANYPNT-ORG-ID: '$orgId'' -H 'X-ANYPNT-ENV-ID: '$envId'' -F 'file=@'/var/lib/jenkins/dependency/te-ct-mule-api-gateway.jar'' -F 'artifactName='$artifactName'' -F 'targetId='$line''
									echo "Deployment Completed"
							done < serverid1.txt
					else
							cat serverid.txt |  tr " " "\n" >> serverid1.txt
							while IFS= read -r line; do
									###Deploy New Application
									echo "Deploying New Application on Server: $line"
									curl -s --proxy 'restrictedproxy.tycoelectronics.com:80' -X POST https://anypoint.mulesoft.com/hybrid/api/v1/applications -H 'authorization: '${token_type}' '${access_token}'' -H 'X-ANYPNT-ORG-ID: '$orgId'' -H 'X-ANYPNT-ENV-ID: '$envId'' -F 'file=@'/var/lib/jenkins/dependency/te-ct-mule-api-gateway.jar'' -F 'artifactName='$artifactName'' -F 'targetId='$line''
									echo "Deployment Completed"
							done < serverid1.txt
					fi
                    '''
            }
        }
    }
}