param (
  [String]$PSEmailServer = "email-smtp.us-east-1.amazonaws.com",
  [Int]$SMTPPort = 587,
  [String]$SMTPUsername = "AKIAUDMBYHIRGWKQUS4A",
  [String]$MailTo = "ng-support@pimcore.com",
  [String]$MailFrom = "ng-support@pimcore.com",
  [String]$MailSubject = "Alert Network Connectivity!!"
)  

## External Object and File data ##
$MailBody = @" 
<font face="verdana">Hi Team,<br><br>
<b>Alert </b> in machine : <b><font color="red">$(hostname)</font></b> is unable to contact Safe Machine (10.17.39.231) on port 80. Please inform Servicedesk@ngatemarkets.com , Ashwani.Kumar@ngatemarkets.com, Amit.Tugnait@ngatemarkets.com<br><br>

--<br>
NG Support</font>
"@ 
$EncryptedPasswordFile = "C:\Users\Public\Documents\pimcore_mandate.txt"
$SecureStringPassword = Get-Content -Path $EncryptedPasswordFile | ConvertTo-SecureString -AsPlainText -Force
$EmailCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $SMTPUsername,$SecureStringPassword

try {
    $tcpConn = New-Object System.Net.Sockets.TcpClient '10.17.39.231', 80; 
    if($tcpConn.Connected) {
		"OK"
        Remove-Item -Path C:\Users\Public\Documents\Email_port.txt -ErrorAction SilentlyContinue | Out-Null
	}
	else {
        Write-Host "Not Okay"
		Send-MailMessage -From $MailFrom -To $MailTo -Subject $MailSubject -Body $MailBody -BodyAsHtml -Port $SMTPPort -Credential $EmailCredential -UseSsl
	}
}
Catch {
    Write-Host $_.Exception.Message | Out-Null
    if (!(Test-Path C:\Users\Public\Documents\Email_port.txt )) {
        New-Item -path "C:\Users\Public\Documents\" -type file -name "Email_port.txt" -ErrorAction SilentlyContinue | Out-Null
        Write-Host "Email sent"
	    Send-MailMessage -From $MailFrom -To $MailTo -Subject $MailSubject -Body "$MailBody" -BodyAsHtml -Port $SMTPPort -Credential $EmailCredential -UseSsl
    }
}