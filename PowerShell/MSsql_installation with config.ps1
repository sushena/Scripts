    param (
        [ValidateNotNullOrEmpty()]
        [String]$sqlPath,

        [ValidateNotNullOrEmpty()]
        [String]$configPath = "http://test.com/config.ini",

        [ValidateNotNullOrEmpty()]
        [String]$userName = $env:UserName
    )

if ( $PSVersionTable.PSVersion.Major -eq 6 )
{
    $Cred = Get-Credential

    #local copy pull
    $sqlPath = "C:\Users\ampleadmin\Downloads\mssql\SQLServer2017-DEV-x64-ENU"   #Installation file
    $configPath = "C:\Users\ampleadmin\Downloads\mssql\SQLServer2017-DEV-x64-ENU\ConfigurationFile.ini"    #Configuration file

    #remote pull
    Invoke-WebRequest $sqlPath -OutFile C:\Users\$userName\Downloads\Sql.exe -Credential $Cred -AllowUnencryptedAuthentication
    Invoke-WebRequest $configPath -OutFile C:\Users\$userName\Downloads\Config.ini -Credential $Cred -AllowUnencryptedAuthentication

    [String]$msSer = Get-Service "mssql*" | Select -ExpandProperty Status
    #Write-Host "Service available: $msSer"
    if ( $msSer -ne "Running")
    {
        try{
            #$cmd = "C:\Users\$userName\Downloads\Sql.exe /ConfigurationFile=C:\Users\$userName\Downloads\Config.ini /SAPWD=Testing@123"
            $cmd = "$sqlPath\Setup.exe /ConfigurationFile=$configPath /SAPWD=Testing@123"
            Invoke-Expression $cmd | Write-Verbose
            Write-Host "`n MsSQl installed succesfully" -BackgroundColor Green
           }

        catch{
            Write-Host $_.Exception.Message
            #Write-Host -LogName Application -EntryType Error -EventId 2020 -Source "Application Error" -Message "$_.Exception.Message"
        }
    }
    else
    {
        Write-Host "`n MSsql Already installed" -BackgroundColor DarkCyan
    }
}
else
{
    Write-Host "`n Upgrade PowerShell-Core:6 and try installing the MSsql" -BackgroundColor DarkRed
    #iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI"
}