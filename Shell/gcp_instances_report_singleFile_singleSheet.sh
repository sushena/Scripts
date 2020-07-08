#!/usr/bin/env bash

#### Variable declaration ####
date=$(date +%b-%d)
Project_list="/opt/script/GCP-instances-list/tmp/Project_list.txt"
csv_path="/opt/script/GCP-instances-list/tmp"

echo "I am starting"
projectID=`gcloud projects list --format="value(projectId)"`
rm -rf ${csv_path}/*.csv
echo "*** Deleted the existing file csv***"

### Loop to get list of project ###
for prtID in ${projectID}
do
  gcloud compute instances list --project="${prtID}" --format="csv(NAME,ZONE,MACHINE_TYPE,INTERNAL_IP,EXTERNAL_IP,STATUS)" > ${Project_list}
  projectName=`gcloud projects list --filter="${prtID}" | awk -F" " '{ print $2 }' | tail -1`
  sed -i '1d' ${Project_list}
  echo "*** Working on ${prtID} ***"

### Individual instances detais ###
  for pl in `cat ${Project_list}`
  do
     HostName="$(cut -d',' -f1 <<<"${pl}")"
     ZoneName="$(cut -d',' -f2 <<<"${pl}")"
     osType=`gcloud compute instances describe ${HostName} --zone ${ZoneName} --project=${prtID} | grep -w "guestOsFeatures"`
     tags=`gcloud compute instances describe ${HostName} --zone ${ZoneName} --project=${prtID} --format="csv(tags)"`
     tags=$(echo ${tags} | sed -e 's/"/""/g');tags=$(echo $tags | sed 's/tags //g');tags="\"${tags}";tags="${tags}\""
     labels=`gcloud compute instances describe ${HostName} --zone ${ZoneName} --project=${prtID} --format="csv(labels)"`
     labels=$(echo ${labels}| sed 's/labels //g')
     creatDate=`gcloud compute instances describe ${HostName} --zone ${ZoneName} --project=${prtID} | grep -w creationTimestamp | cut -d" " -f 2 | tr -d "'"`
     if [[ -z "${osType}" ]]
     then
       echo "${projectName},${pl},${creatDate},Linux,${tags},${labels}" >> ${csv_path}/${projectName}_${date}.csv
     else
       echo "${projectName},${pl},${creatDate},Windows,${tags},${labels}" >> ${csv_path}/${projectName}_${date}.csv
     fi
  done
  sed -i '1s/^/Project, Instance Name, Zone, Machine type, Internal IP, External IP, Status, Creation Time,Connection Type, Tags, Labels\n/' ${csv_path}/${proje
ctName}_${date}.csv
done

echo "----- Executing python ------"
/usr/bin/env python3.6 - << EOF
#!/usr/bin/python3.6

import os
import pandas as pd
import glob
import smtplib
import os.path
from glob import glob
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders

xlsxFile = '/opt/script/GCP-instances-list/report/gcp_instances_${date}_report.xlsx'
csv_files = glob("/opt/script/GCP-instances-list/tmp/*.csv")
csvFile = '/opt/script/GCP-instances-list/report/gcp_instances_${date}_report.csv'

df_list = []
for filename in sorted(csv_files):
  df_list.append(pd.read_csv(filename))

full_df = pd.concat(df_list)
full_df.to_csv('/opt/script/GCP-instances-list/report/gcp_instances_${date}_report.csv', index=False)

read_file = pd.read_csv(csvFile)
read_file.to_excel(xlsxFile, index=None, header=True)

def pm_SendMail():
        email = 'ngsupport@northmarkets.com'
        send_to_email = 'ng-infrastructure-support@pm.services'
        subject = 'GCP instances report ~ north'
        message = """
Dear Team,
   Attached report for GCP instances(single sheet)

---
GCP Infra support
ng-infrastructure-support@pm.services

        """
        msg = MIMEMultipart()
        msg['From'] = email
        msg['To'] = send_to_email
        msg['Subject'] = subject

        msg.attach(MIMEText(message, 'plain'))
		
        filename = os.path.basename(xlsxFile)
        attachment = open(xlsxFile, "rb")
        part = MIMEBase('application', 'octet-stream')
        part.set_payload(attachment.read())
        encoders.encode_base64(part)
        part.add_header('Content-Disposition', "attachment; filename= %s" % filename)
        msg.attach(part)

        server = smtplib.SMTP('smtp.north.internal', 25)
        text = msg.as_string()
        server.sendmail(email, send_to_email, text)
        server.quit()

if __name__== "__main__":
        print("Executing ..")
        pm_SendMail()
EOF
rm -rf /opt/script/GCP-instances-list/report/gcp_instances_${date}_report.csv
echo " *** Completed *** "