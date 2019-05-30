param(  [String] $remoteHost="mail.eaton.com", 
        [String] $domain="smtp.gmail.com", 
        [String] $sendingdomain="smtp.gmail.com" 
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
            #Write-EventLog -LogName Application -EntryType Information -EventId 8887 -Source {} -Message "No problem detected with SMTP connection"

        }
        elseif (( [int]$Data.split(" ")[0] -ge 400 ) -and ( [int]$Data.split(" ")[0] -lt 499 ))
        {
            Write-Host -n -ForegroundColor Cyan "[ERROR] -->"$Data.split(" ")[0]
            #Write-EventLog -LogName Application -EntryType Error -EventId 8886 -Source {} -Message "Connectivity ERROR with SMTP"
        }
    } 
}

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