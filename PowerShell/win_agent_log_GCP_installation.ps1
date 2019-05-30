$ErrorActionPreference = "SilentlyContinue"

md C:\Users\logileprod\GCP_Stackdriver\
cd C:\Users\logileprod\GCP_Stackdriver\

$StackMonitoring = "StackdriverMonitoring"
$StackLogging = "StackdriverLogging"

if (( Get-Service 

Invoke-webrequest https://repo.stackdriver.com/windows/StackdriverMonitoring-GCM-46.exe -OutFile StackdriverMonitoring-GCM-46.exe;

ECHO 'Y' | ./StackdriverMonitoring-GCM-46.exe /FORCE /S

Invoke-WebRequest https://dl.google.com/cloudagents/windows/StackdriverLogging-v1-8.exe -OutFile StackdriverLogging-v1-8.exe;

ECHO 'Y' | ./StackdriverLogging-v1-8.exe /FORCE /S

Install-PackageProvider -Name NuGet -RequiredVersion 2.8.5.201 -Force

Install-Module -Name Googlecloud -AllowClobber -Confirm:$False -Force

set $env:GCLOUD_SDK_INSTALLATION_NO_PROMPT
