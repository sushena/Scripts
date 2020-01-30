$Disk = Get-Disk -Number 1
Set-Disk -InputObject $Disk -IsOffline $false
Initialize-Disk -InputObject $Disk
New-Partition $Disk.Number -UseMaximumSize -DriveLetter D
Format-Volume -DriveLetter D -FileSystem NTFS -AllocationUnitSize 65536 -NewFileSystemLabel DATAFILES_1 -Confirm:$false

$Disk = Get-Disk -Number 2
Set-Disk -InputObject $Disk -IsOffline $false
Initialize-Disk -InputObject $Disk
New-Partition $Disk.Number -UseMaximumSize -DriveLetter E
Format-Volume -DriveLetter E -FileSystem NTFS -AllocationUnitSize 65536 -NewFileSystemLabel DATAFILES_2 -Confirm:$false

