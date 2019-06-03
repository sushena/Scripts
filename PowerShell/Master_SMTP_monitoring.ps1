param(  [String]$remoteHost="mail.eaton.com", 
        [String]$domain="smtp.gmail.com", 
        [String]$sendingdomain="smtp.gmail.com", 
        [String]$serSMTP = "SMTPSVC"
     )

function readResponse 
{
    while($stream.DataAvailable)  
    {  
        $read = $stream.Read($buffer, 0, 1024)    
        #Write-Host -n -ForegroundColor DarkYellow ($encoding.GetString($buffer, 0,$read))
        ""
        $Data = ($encoding.GetString($buffer, 0,$read))
        #$dt=[int]$Data.split(" ")[0]
        #$dt.GetType()
        if (( [int]$Data.split(" ")[0] -gt 200 ) -and ( [int]$Data.split(" ")[0] -lt 299 ))
        {
            Write-Host -n -ForegroundColor Cyan "[OK] -->"$Data.split(" ")[0]
            Write-EventLog -LogName Application -EntryType Information -EventId 8887 -Source "Application Error" -Message "No problem detected with SMTP, Read/Write on port 25 is success"

        }
        if (( [int]$Data.split(" ")[0] -ge 400 ) -and ( [int]$Data.split(" ")[0] -lt 499 ))
        {
            Write-Host -n -ForegroundColor Cyan "[ERROR] -->"$Data.split(" ")[0]
            Write-EventLog -LogName Application -EntryType Error -EventId 8886 -Source "Application Error" -Message "Connectivity ERROR with SMTP"
        }
    } 
}

[String]$serSMTP = Get-Service "SMTPSVC" | Select -ExpandProperty Status

if ( $serSMTP -ne "Running" )
{
    Write-Host "SMTP service not running !!"
    Write-EventLog -LogName Application -EntryType Error -EventId 8886 -Source "Application Error" -Message "Service $serSMTP isnt running"
    exit 1
}

$dirSize ="{0:N2} GB" -f ((Get-ChildItem C:\inetpub\mailroot\ -Recurse | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum / 1GB)
#[int]$dirSize = $dirSize.Split(" ")[0]
#$dirSize.GetType()
$dirSize = 3

if ( $dirSize -gt 20 )
{
	$fileCnt = Get-ChildItem C:\inetpub\mailroot\ -File | Measure-Object | %{$_.Count}
	if ( [int]$fileCnt -gt 3 )
	{
		Write-Host "Warning Folder Size - $fileCnt and File Size - $dirSize"
        Write-EventLog -LogName Application -EntryType Warning -EventId 8885 -Source "Application Error" -Message "Warning Folder Size greater then 20GB and File count is greater then 10k"
	}
    Write-Host "Warning Folder size - $dirSize"
    Write-EventLog -LogName Application -EntryType Warning -EventId 8885 -Source "Application Error" -Message "Warning Folder Size : $dirSize greater then 20GB"
}
else
{
    $fileCnt = Get-ChildItem C:\inetpub\mailroot\ -File | Measure-Object | %{$_.Count}
    if ( $fileCnt -gt 10000 )
    {
        Write-Host "Warning File size - $fileCnt and File Size - $dirSize"
        Write-EventLog -LogName Application -EntryType Warning -EventId 8885 -Source "Application Error" -Message "File count is greater then 10k"
    }
	Write-Host "Warning Folder size - $dirSize"
	Write-EventLog -LogName Application -EntryType Information -EventId 8887 -Source "Application Error" -Message "Info Folder Size : $dirSize"
}

$PingResult = Test-NetConnection -ComputerName localhost -Port 25
if ( $PingResult.TcpTestSucceeded -eq $false )
{
	Write-Host "Verfiying SMTP service status, Since SMTP port isnt accessible !!!"
	Get-Service -Name SMTPSVC | Stop-Service -ErrorAction SilentlyContinue
	[String]$serSMTP = Get-Service "SMTPSVC" | Select -ExpandProperty Status
	if ( $serSMTP -eq "Stopped" )
	{
		Write-Host "SMTP port wasnt accesible, Henceforth SMTP service was STOPPED"
		Write-EventLog -LogName Application -EntryType Error -EventId 8886 -Source "Application Error" -Message "SMTP port wasnt accesible, Henceforth SMTP service was STOPPED"
		exit 1
	}
}
if ( $PingResult.TcpTestSucceeded -eq $true )
{
	Write-EventLog -LogName Application -EntryType Information -EventId 8887 -Source "Application Error" -Message "SMTP port is open for connection, Verifying with Read/Write Response"
	$smtpPort = 25
	$socket = New-Object System.Net.Sockets.TcpClient($remoteHost, $smtpPort) 
    if($socket -eq $null) 
    { 
        return; 
    } 
	$stream = $socket.GetStream() 
    $writer = New-Object System.IO.StreamWriter($stream) 
    $buffer = New-Object System.Byte[] 1024 
    $encoding = New-Object System.Text.AsciiEncoding 
	
	readResponse($stream)
    $command = "HELO "+ $domain 
    write-host -ForegroundColor Green $command
    ""
	$writer.WriteLine($command) 
    $writer.Flush()
    start-sleep -m 500 
    readResponse($stream)
    Write-Host -ForegroundColor DarkRed ""
    $command = "MAIL FROM: <smtpcheck@" + $sendingdomain + ">" 
    write-host -foregroundcolor DarkGreen $command
    $writer.WriteLine($command) 
    $writer.Flush()
    start-sleep -m 500 
    readResponse($stream)
    $writer.Close() 
    $stream.Close() 
}
