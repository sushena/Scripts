#!/usr/bin/env bash

#### Variable declaration ####
ToDate=$(date +%Y-%m-%d)
instances_log="/opt/scripts/snapShot_report/log/instances_${ToDate}.log"
reportName="/opt/scripts/snapShot_report/reports/snapDisk_${ToDate}_report.csv"
yesDT=`echo -e "$(TZ=GMT+30 date +%Y-%m-%d)\n$(TZ=GMT+20 date +%Y-%m-%d)" | grep -v $(date +%Y-%m-%d) | tail -1`
#cat /dev/null > ${reportName}

projectID=`gcloud projects list --format="value(projectId)"`
echo "Project, Instance Name, Disk, Date, Status" > ${reportName}
#cat /dev/null > ${instances_log}

#### project idempotent ####
for prtID in ${projectID}
do
        gcloud compute instances list --project=${prtID} | awk '{print $1, $2}' > ${instances_log}
        sed -i '1d' ${instances_log};sed -i 's/ /:/g' ${instances_log}

#### instances idempotent ####
        for line in `cat ${instances_log}`
        do
                HostName="$(cut -d':' -f1 <<<"${line}")"
                ZoneName="$(cut -d':' -f2 <<<"${line}")"
                Diskname=`gcloud compute instances describe ${HostName} --zone ${ZoneName} --project=${prtID} | grep "source" | awk -F'/' '{ print $NF }'`

#### Disk idempotent ####
                for sDisk in ${Diskname}
                do
                        echo "Working on project: ${prtID}, Hostname:${HostName}, Disk:${sDisk}, Zone:${ZoneName}"
                        SnapCnt=`gcloud compute snapshots list --filter="creationTimestamp ~ .*${yesDT}.* AND sourceDisk ~ .*${sDisk}.*" --project ${prtID} | grep -w "READY" | wc -l`
                        echo -e "Snap value: ${SnapCnt} \n"
                        if [ ${SnapCnt} -ge 1 ]
                        then
                                echo "${prtID}, ${HostName}, ${sDisk}, ${yesDT}, SUCCESS" >> ${reportName}
                        elif [ ${SnapCnt} -eq 0 ]
                        then
                                echo "${prtID}, ${HostName}, ${sDisk}, ${yesDT}, NotAvailable" >> ${reportName}
                        else
                                echo "${prtID}, ${HostName}, ${sDisk}, ${yesDT}, INVALID" >> ${reportName}
                        fi
                        fi
                done
        done
done

python - << EOF
import smtplib
import pandas as pd
from email import encoders
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase

csvFile = '/opt/scripts/snapShot_report/reports/snapDisk_${ToDate}_report.csv'
xlsxFile = '/opt/scripts/snapShot_report/reports/snapDisk_${ToDate}_report.xlsx'
read_file = pd.read_csv(csvFile)
read_file.to_excel(xlsxFile, index=None, header=True)

def pimcore_SendMail():
        username = 'AKdsjfsdfil'
        password = 'BEMsdkfjdsjkdsfj3Bi9Jqc4j8B'
        send_from = 'ng-support <ng-support@p.com>'
        send_to = 'ng-support@p.com'
        Cc = 'kumar.saurabh@p.com'

        msg = MIMEMultipart()
        msg['From'] = send_from
        msg['To'] = send_to
        msg['Cc'] = Cc
        body = """Hi all,
        Please find attached report

 --
 NG support
        """
        msg.attach(MIMEText(body, 'plain'))
        msg['Subject'] = 'SnapShot Report ~ North gate'

        fp = open(xlsxFile, 'rb')
        part = MIMEBase('application','vnd.ms-excel')
        part.set_payload(fp.read())
        fp.close()

        encoders.encode_base64(part)
        part.add_header('Content-Disposition', 'attachment', filename='SNAP_report.xlsx')
        msg.attach(part)
        smtp = smtplib.SMTP('email-smtp.us-east-1.amazonaws.com:587')
        smtp.ehlo()
        smtp.starttls()
        smtp.login(username,password)
        smtp.sendmail(send_from, send_to.split(',') + msg['Cc'].split(','), msg.as_string())
        smtp.quit()

if __name__== "__main__":
        print("Executing ..")
        pimcore_SendMail()
EOF
echo "Done !!"