$servers = Get-Content -Path C:\tlog\sql_fqdn.txt

forEach($server in $servers) {
    $username = 'NG\Ansibleservice'
    $password = '27Bp+*S<5q$Vn#]M'
    $pw = ConvertTo-SecureString $password -AsPlainText -Force
    $cred = New-Object Management.Automation.PSCredential ($username, $pw)
    $myfile = [System.IO.File]::ReadAllBytes("C:\tlog\Monitoring_SQL.sql")
    $s = New-PSSession -ComputerName $server -credential $cred
        Enter-PSSession $s
        Invoke-Command -Session $s -ArgumentList $myfile -Scriptblock {
            [System.IO.File]::WriteAllBytes("C:\dest_monitoring.sql", $using:myfile)
            try
            {
                $Conn=New-Object System.Data.SQLClient.SQLConnection "Server=localhost;Database=tciinstore;UID=NG\Ansibleservice;PWD='27Bp+*S<5q$Vn#]M';Integrated Security=true ;"
                $Conn.Open();
                $DataCmd = New-Object System.Data.SqlClient.SqlCommand;
                [String]$MyQuery = Get-Content -Path "C:\dest_monitoring.sql";
                $DataCmd.CommandText = $MyQuery;
                $DataCmd.Connection = $Conn;
                $DAadapter = New-Object System.Data.SqlClient.SqlDataAdapter;
                $DAadapter.SelectCommand = $DataCmd;
                $DTable = New-Object System.Data.DataTable;
                $DAadapter.Fill($DTable)|Out-Null;
                $Conn.Close();
                $Conn.Dispose();
                $DTable;
            }
            Catch {
                Write-Host "DB Error $_.Exception.Message"
            }
        }
        Remove-PSSession $s
}
