#$ErrorActionPreference = "SilentlyContinue"

param(  [String]$remoteHost="mail.eaton.com", 
        [String]$domain="smtp.gmail.com", 
        [String]$sendingdomain="smtp.gmail.com", 
        [String]$SerSMTP = "SMTPSVC"
          #[String] $SerFilChk = "FileCheckher"
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
            Write-EventLog -LogName Application -EntryType Information -EventId 8887 -Source "Application Error" -Message "No problem detected with SMTP connection"

        }
        elseif (( [int]$Data.split(" ")[0] -ge 400 ) -and ( [int]$Data.split(" ")[0] -lt 499 ))
        {
            Write-Host -n -ForegroundColor Cyan "[ERROR] -->"$Data.split(" ")[0]
            Write-EventLog -LogName Application -EntryType Error -EventId 8886 -Source "Application Error" -Message "Connectivity ERROR with SMTP"
        }
    } 
}


$SerSMTP = Get-Service | Where-Object { $_.Name -eq "SMTPSVC" }
#$SerFilChk = Get-Service | Where-Object { $_.Name -eq "FileCheckher" }

if ( $SerSMTP.Status -ne "Running" ) #-or ( $SerFilChk.Status -ne "Running" ))
{
    Write-Host "SMTP not running"
    Write-EventLog -LogName Application -EntryType Error -EventId 8886 -Source "Application Error" -Message "Service $SerSMTP isnt running"
    exit 1
}

#$DirSize = "{0:N2} GB" -f ((Get-ChildItem C:\inetpub\mailroot\ -Recurse | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum / 1GB)
$DirSize=19
#[int]$DirSize = $DirSize.Split(" ")[0]

if ( $DirSize -gt 20 )
{
    $FileCnt = Get-ChildItem C:\inetpub\mailroot\ -File | Measure-Object | %{$_.Count}
    if ( $FileCnt -gt 10000 )
    {
        Write-Host "Warning Folder Size and File Size"
        Write-EventLog -LogName Application -EntryType Warning -EventId 8885 -Source "Application Error" -Message "Warning Folder Size greater then 20GB and File count is greater then 10k"
    }
    Write-Host "Warning Folder size"
    Write-EventLog -LogName Application -EntryType Warning -EventId 8885 -Source "Application Error" -Message "Warning Folder Size greater then 20GB"
}
Else
{
    $FileCnt = Get-ChildItem C:\inetpub\mailroot\ -File | Measure-Object | %{$_.Count}
    if ( $FileCnt -gt 10000 )
    {
        Write-Host "Warning File size"
        Write-EventLog -LogName Application -EntryType Warning -EventId 8885 -Source "Application Error" -Message "File count is greater then 10k"
    }
}

$PingResult = Test-NetConnection -ComputerName localhost -Port 25
if ( [String]$PingResult.TcpTestSucceeded -eq "False" )
{
    echo "Checking SMTP service"
    Get-Service -Name SMTPSVC | Stop-Service -ErrorAction SilentlyContinue
    Write-EventLog -LogName Application -EntryType Error -EventId 8886 -Source "Application Error" -Message "Service $SerSMTP wasnt running, This has been stopped for now"
    exit 1
}

if ( [String]$PingResult.TcpTestSucceeded -eq "True" ) 
{
    $port = 25 
    $socket = new-object System.Net.Sockets.TcpClient($remoteHost, $port) 
    if($socket -eq $null) 
    { 
        return; 
    } 

    $stream = $socket.GetStream() 
    $writer = new-object System.IO.StreamWriter($stream) 
    $buffer = new-object System.Byte[] 1024 
    $encoding = new-object System.Text.AsciiEncoding 

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