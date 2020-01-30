													## Existing guest
$secpasswd = ConvertTo-SecureString 'guest' -AsPlainText -Force
$credGuest = New-Object System.Management.Automation.PSCredential ('guest', $secpasswd)

													## New admin123 
$secpasswd2 = ConvertTo-SecureString 'admin123' -AsPlainText -Force
$credAdmin2 = New-Object System.Management.Automation.PSCredential ('admin', $secpasswd2)

$body = @{
               'password' = 'admin123'
               'tags' = 'administrator'
           } | ConvertTo-Json

Write-host "About to create new user " -NoNewline
$vhosts1 = Invoke-RestMethod 'http://localhost:15672/api/users/admin' -credential $credGuest  -Method Put -ContentType "application/json" -Body $body
start-sleep 5 
Start-Sleep -Milliseconds 400
Write-Host  '1: Results:'   $vhosts1
$body2 = @{
               'username' = 'admin'
               'vhost' = '/'
               'configure' = '.*'
               'write' = '.*'
               'read' = '.*'
           } | ConvertTo-Json
Write-host "Setting perms for new user..." -NoNewline
$vhosts3 = Invoke-RestMethod 'http://localhost:15672/api/permissions/%2f/admin' -credential $credGuest  -Method Put -ContentType "application/json" -Body $body2
Start-sleep 5
Start-Sleep -Milliseconds 400
write '4:' $vhosts3
Invoke-RestMethod 'http://localhost:15672/api/permissions/%2f/admin'  -Method get  -credential $credAdmin2