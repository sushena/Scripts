$SerSMTP = "SMTPSVC"
$SerFilChk = "FileCheckher"

$SerSMTP = Get-Service | Where-Object { $_.Name -eq "SMTPSVC" }
$SerFilChk = Get-Service | Where-Object { $_.Name -eq "FileCheckher" }

if (( $SerSMTP.Status -ne "Running" ) -or ( $SerFilChk.Status -ne "Running" ))
{
    Write-Host "Critical"
    #Write-EventLog -LogName Application -EntryType Error -EventId 8886 -Source {} -Message "Service $SerSMTP or $SerFilChk isnt running"
    exit 1
}

$DirSize = "{0:N2} GB" -f ((Get-ChildItem C:\inetpub\mailroot\   -Recurse | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum / 1GB)
[int]$DirSize = $DirSize.Split(" ")[0]

if ( $DirSize -gt 20 )
{
    $FileCnt = Get-ChildItem C:\inetpub\mailroot\   -File | Measure-Object | %{$_.Count}
    if ( $FileCnt -gt 10000 )
    {
        Write-Host "Warning Folder Size and File Size"
        #Write-EventLog -LogName Application  -EntryType Warning -EventId 8885 -Source {} -Message "Warning Folder Size greater then 20GB and File count is greater then 10k"
    }
    Write-Host "Warning Folder size"
    #Write-EventLog -LogName Application  -EntryType Warning -EventId 8885 -Source {} -Message "Warning Folder Size greater then 20GB
}
Else
{
    $FileCnt = Get-ChildItem C:\inetpub\mailroot\   -File | Measure-Object | %{$_.Count}
    if ( $FileCnt -gt 10000 )
    {
        Write-Host "Warning File size"
        #Write-EventLog -LogName Application  -EntryType Warning -EventId 8885 -Source {} -Message "File count is greater then 10k"
    }
}

$PingResult = Test-NetConnection -ComputerName localhost -Port 25
if ( $PingResult.TcpTestSucceeded -eq "False" )
{
    Stop-Service -Name $SerSMTP -Force
    #Write-EventLog -LogName Application -EntryType Error -EventId 8886 -Source {} -Message "Service $SerSMTP wasnt running, This has been stopped for now"
    exit 1
}