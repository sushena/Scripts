#############################################################
#This script fetch the CPU and Memory from snaplogic server #
#      -- for queries : ng-support@pimcore.com --           #
#                                                           #
#############################################################

#!/usr/bin/env bash

ToDate=$(date +%Y-%m-%d)
memReport="/usr/scripts/SnapLogicReport/log/memory_${ToDate}_report.csv"
cpuReport="/usr/scripts/SnapLogicReport/log/cpu_${ToDate}_report.csv"
mem_cpu_report="/usr/scripts/SnapLogicReport/report/mem_cpu_${ToDate}_report.csv"
mem_1="/usr/scripts/SnapLogicReport/log/mem_1.txt"
mem_2="/usr/scripts/SnapLogicReport/log/mem_2.txt"
cpu_1="/usr/scripts/SnapLogicReport/log/cpu_1.txt"
cpu_2="/usr/scripts/SnapLogicReport/log/cpu_2.txt"

cat /dev/null > ${mem_1};cat /dev/null > ${mem_2}
cat /dev/null > ${cpu_1};cat /dev/null > ${cpu_2}

#### Get Memory details ####
ansible -m shell -a "free -m" snaplogic >> ${mem_1}
ansible -m shell -a "free -m" snap-onprem >> ${mem_1}

sed -i '/^Swap:/d' ${mem_1};sed -i '/^\-\/\+/d' ${mem_1};sed -i '/total/d' ${mem_1}
echo "hostname used free total" >> ${mem_2}

while IFS= read -r line
do
  if echo "${line}" | grep -q "CHANGED"; then
    hostname="$( awk '{print $1}' <<<"${line}")"
    echo -n "${hostname} " >> ${mem_2}
  fi

  if echo "${line}" | grep -q "Mem"; then
    dtNum="$( awk '{print $2, $3, $4}'  <<<"${line}")"
    echo -n "${dtNum}" >> ${mem_2}
    echo "" >> ${mem_2}
  fi
  unset hostname dtNum
done <"${mem_1}"
echo "Report done"
sed -i 's/\s/,/g' ${mem_2}

#### Get CPU details ####
ansible -m shell -a "sar -u 1 1" snaplogic >> ${cpu_1}
ansible -m shell -a "sar -u 1 1" snap-onprem >> ${cpu_1}

echo "hostname CPU-Usage" >> ${cpu_2}
sed -i '/^Linux/,+3d' ${cpu_1}
while IFS= read -r line
do
  if echo "${line}" | grep -q "CHANGED"; then
    hostname="$( awk '{print $1}' <<<"${line}")"
    echo -n "${hostname} " >> ${cpu_2}
  fi
  if echo "${line}" | grep -q "Average"; then
    dtNum="$( awk '{print $NF}'  <<<"${line}")"
    dtNum=`expr "100 - ${dtNum}" | bc`
    echo -n "${dtNum}" >> ${cpu_2}
    echo "" >> ${cpu_2}
  fi
  unset hostname dtNum
done <"${cpu_1}"
sed -i 's/\s/,/g' ${cpu_2}

echo "renaming in progress"
mv ${mem_2} ${memReport}
mv ${cpu_2} ${cpuReport}

cat ${memReport} > ${mem_cpu_report};echo "" >> ${mem_cpu_report};cat ${cpuReport} >> ${mem_cpu_report}
rm -rf ${memReport} ${cpuReport}

/usr/bin/env python2.7 - << EOF
#!/usr/bin/env python2.7
import smtplib
import os.path
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders

mem_cpu_report="/usr/scripts/SnapLogicReport/report/mem_cpu_${ToDate}_report.csv"

def pimcore_SendMail():
        email = 'ngsupport@northgatemarkets.com'
        send_to_email = 'ng-support@pimcore.com'
        subject = 'Snaplogic servers CPU & memory Report ~ Northgate Markets'
        message = """
Hi all,
  Please find attached CPU and Memory of snaplogic servers report.

---
GCP Infra support
ng-support@pimcore.com

        """
        msg = MIMEMultipart()
        msg['From'] = email
        msg['To'] = send_to_email
        msg['Subject'] = subject

        msg.attach(MIMEText(message, 'plain'))

        filename = os.path.basename(mem_cpu_report)
        attachment = open(mem_cpu_report, "rb")
        part = MIMEBase('application', 'octet-stream')
        part.set_payload(attachment.read())
        part.add_header('Content-Disposition', "attachment; filename= %s" % filename)
        encoders.encode_base64(part)
        msg.attach(part)

        server = smtplib.SMTP('smtp.northgategonzalez.internal', 25)
        text = msg.as_string()
        server.sendmail(email, send_to_email, text)
        server.quit()

if __name__== "__main__":
        print("Executing ..")
        pimcore_SendMail()
EOF

echo " --- done ---"
