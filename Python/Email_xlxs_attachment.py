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