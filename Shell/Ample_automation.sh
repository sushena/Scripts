#!/usr/bin/env bash

if ! grep -w -q 'se-server-experimental' -f /etc/yum.repos.d/*.*
then
	echo '
	[Artifactory-Sentient-Server]
name=Artifactory-Sentient-Server
baseurl=http://readonly-user:readonly@172.18.2.40:8081/artifactory/se-server-experimental/
enabled=1
gpgcheck=0' >> sudo /etc/yum.repos.d/artifactory1.sfo.repo
	echo "Initialiazing the repo"
	sudo yum makecache fast
	
	echo "Installing Senti-Configure"
	sudo yum -y install sentient-configure
	
	echo "1, Update the IP of other components under path /etc/sentient-configure/sentient-configure.conf
	2, Update email,Domain and credentials under path /etc/sentient-configure/.secrets/sentient-configure.properties"
fi
