#!/usr/bin/env bash

#### Variable declaration ####
instances_log="/home/praveen/log/instances.log"
project_name="emeraldpos" #"captiveportal-235706"
ToDate=$(date +%Y-%m-%d)
reportName="/home/praveen/snapDisk_${ToDate}_report.csv"
yesDT=`echo -e "$(TZ=GMT+30 date +%Y-%m-%d)\n$(TZ=GMT+20 date +%Y-%m-%d)" | grep -v $(date +%Y-%m-%d) | tail -1`

#cat /dev/null > ${reportName}
projectID=`gcloud projects list --format="value(projectId)"`

for prtID in ${projectID}
do
        gcloud compute instances list --project=${prtID} | awk '{print $1, $2}' > ${instances_log}
        sed -i '1d' ${instances_log};sed -i 's/ /:/g' ${instances_log}
        echo "Instance Name, Disk, Date, Status" > ${reportName}

#### instances idempotent ####
        for line in `cat ${instances_log}`
        do
                HostName="$(cut -d':' -f1 <<<"${line}")"
                ZoneName="$(cut -d':' -f2 <<<"${line}")"
                Diskname=`gcloud compute instances describe ${HostName} --zone ${ZoneName} --project=${prtID} | grep "source" | awk -F'/' '{ print $NF }'`

#### Disk idempotent ####
                for sDisk in ${Diskname}
                do
                        echo "Working on project : ${prtID} = ${HostName} and ${sDisk}"
                        SnapCnt=`gcloud compute snapshots list --filter="creationTimestamp ~ .*${yesDT}.* AND sourceDisk ~ .*${sDisk}.*" --project ${prtID} | grep -w "READY" | wc -l`
                        echo "Snap value : ${SnapCnt}"
                        if [ ${SnapCnt} -eq 1 ]
                        then
                                echo "${HostName}, ${sDisk}, ${yesDT}, SUCCESS" >> ${reportName}
                        elif [ ${SnapCnt} -eq 0 ]
                        then
                                echo "${HostName}, ${sDisk}, ${yesDT}, Not_available" >> ${reportName}
                        else
                                echo "${HostName}, ${sDisk}, ${yesDT}, INVALID" >> ${reportName}
                        fi
                done
         done
done
