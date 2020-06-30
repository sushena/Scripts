#!/usr/bin/env bash

#### Variable declaration ####
date=$(date +%Y-%m-%d)
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
     if [[ -z "${osType}" ]]
     then
       echo "${projectName},${pl},Linux,${tags},${labels}" >> ${csv_path}/${projectName}_${date}.csv
     else
       echo "${projectName},${pl},Windows,${tags},${labels}" >> ${csv_path}/${projectName}_${date}.csv
     fi
  done
  sed -i '1s/^/Project, Instance Name, Zone, Machine type, Internal IP, External IP, Status, Connection Type, Tags, Labels\n/' ${csv_path}/${projectName}_${date}.csv
done

echo "----- Executing python ------"
/usr/bin/env python3.6 - << EOF
#!/usr/bin/python3.6

import os
import pandas as pd
import glob
import smtplib
import os.path
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders

path = '/opt/script/GCP-instances-list/tmp/'
xlsxFile = '/opt/script/GCP-instances-list/report/gcp_instances_${date}_report.xlsx'
all_files = glob.glob(os.path.join(path, "*.csv"))

writer = pd.ExcelWriter('/opt/script/GCP-instances-list/report/gcp_instances_${date}_report.xlsx', engine='xlsxwriter')

for f in all_files:
    df = pd.read_csv(f)
    df.to_excel(writer, sheet_name=os.path.splitext(os.path.basename(f))[0], index=False)

writer.save()

def pime_SendMail():
        email = 'ngsupport@northmarkets.com'
        send_to_email = 'ng-infrastructure-support@pime.services'
        subject = 'GCP instances report ~ NorGate'
        message = """
Dear Ananth/Nabil,
   Attached report report for GCP instances

---
GCP Infra support
ng-infrastructure-support@pime.services

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

        server = smtplib.SMTP('smtp.northegonzalez.internal', 25)
        text = msg.as_string()
        server.sendmail(email, send_to_email, text)
        server.quit()

if __name__== "__main__":
        print("Executing ..")
        pime_SendMail()
EOF
echo " *** Completed *** "
