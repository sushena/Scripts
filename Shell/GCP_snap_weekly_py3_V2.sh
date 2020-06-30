#!/usr/bin/env bash

#### Variable declaration ####

ToDate=$(date +%Y-%m-%d)
instances_log="/opt/script/GCP-snapShot/log/instances_${ToDate}.log"
reportName="/opt/script/GCP-snapShot/report/snapDisk_${ToDate}_report.csv"
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
                        SnapCnt=`gcloud compute snapshots list --filter="creationTimestamp ~ .*${yesDT}.* AND sourceDisk ~ .*${sDisk}.*" --project ${prtID} | grep -w "R
EADY" | wc -l`
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
                done
        done
done
/usr/bin/env python3.6 - << EOF
#!/usr/bin/env python3.6
import openpyxl
import re
from openpyxl.chart import PieChart, Reference
import pandas as pd
import smtplib
import os.path
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders


csvFile = '/opt/script/GCP-snapShot/report/snapDisk_${ToDate}_report.csv'
xlsxFile = '/opt/script/GCP-snapShot/report/snapDisk_${ToDate}_report.xlsx'
read_file = pd.read_csv(csvFile)
read_file.to_excel(xlsxFile, index=None, header=True)

wb_obj = openpyxl.load_workbook(xlsxFile)
sheet_obj = wb_obj.active
m_row = sheet_obj.max_row
sCnt = 0
nCnt = 0

for i in range(1, m_row + 1):
  cell_obj = sheet_obj.cell(row = i, column = 5)
  cellStr = re.sub(r"\r?\n?$", "", cell_obj.value)
  if cellStr == " SUCCESS" :
    sCnt = sCnt + 1
  elif cellStr == " NotAvailable" :
    nCnt = nCnt + 1

wb_obj_2=wb_obj.create_sheet(index = 1 , title = "pie Chart")
c1=wb_obj_2.cell(row = 1, column = 1)
c1.value = "Status"
c2 =wb_obj_2.cell(row= 1, column = 2)
c2.value = "Count"

c3=wb_obj_2.cell(row = 2, column = 1)
c3.value = "Success"

c4=wb_obj_2.cell(row = 3, column = 1)
c4.value = "Not available"

c5=wb_obj_2.cell(row = 2, column = 2)
c5.value = sCnt

c6=wb_obj_2.cell(row = 3,column = 2)
c6.value = nCnt

pie = PieChart()
labels = Reference(wb_obj_2, min_col=1, min_row=2, max_row=3)
data = Reference(wb_obj_2, min_col=2, min_row=1, max_row=3)
pie.add_data(data, titles_from_data = True)
pie.set_categories(labels)
pie.title = " GCP instances snap report "
wb_obj_2.add_chart(pie, "C5")
wb_obj.save(xlsxFile)

def pimcore_SendMail():
        email = 'ngsupport@northgatemarkets.com'
        send_to_email = 'ng-support@pimcore.com'
        subject = 'SnapShot Report ~ North gate'
        message = """
Hi all,
  PFA report GCP weekly snap report.

---
GCP Infra support

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

        server = smtplib.SMTP('smtp.northgategonzalez.internal', 25)
        text = msg.as_string()
        server.sendmail(email, send_to_email, text)
        server.quit()

if __name__== "__main__":
        print("Executing ..")
        pimcore_SendMail()
EOF
echo "Done !!"