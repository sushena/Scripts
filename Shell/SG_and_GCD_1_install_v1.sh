#!/bin/bash

usage() { echo "Usage: $0 [-y <yum command, either install or update>] " 1>&2; exit 1; }
YUM_CMD=

set -e

while getopts ":y:" o; do
    case "${o}" in
        y)
            YUM_CMD=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [[ ! -z "${YUM_CMD}"  &&  "${YUM_CMD}" == "install" ]]
then
        #echo -e "I am into _main_ ${YUM_CMD} \n"
        echo -e "*** Please update the REPO to se-server-experimental ***\n"

        echo -e "Initialiazing the repo \n"
        sudo yum makecache fast

        echo -e "Installing Senti-Configure \n"
        sudo yum -y install sentient-configure

        echo -e "1, Update the IP of other components under path /etc/sentient-configure/sentient-configure.conf
        2, Update email,Domain and credentials under path /etc/sentient-configure/.secrets/sentient-configure.properties \n"
        echo -e "**********************************\n"
        echo -e "Then proceed with script 2 for further setup\n"
else
        echo -e "Invalid entry \n"
        exit 1
fi
