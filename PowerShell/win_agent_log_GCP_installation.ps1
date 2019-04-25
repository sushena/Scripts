$ErrorActionPreference = "SilentlyContinue"

md C:\Users\logileprod\GCP_Stackdriver\
cd C:\Users\logileprod\GCP_Stackdriver\

Invoke-webrequest https://repo.stackdriver.com/windows/StackdriverMonitoring-GCM-46.exe -OutFile StackdriverMonitoring-GCM-46.exe;

ECHO 'Y' | ./StackdriverMonitoring-GCM-46.exe /FORCE /S

Invoke-WebRequest https://dl.google.com/cloudagents/windows/StackdriverLogging-v1-8.exe -OutFile StackdriverLogging-v1-8.exe;

ECHO 'Y' | ./StackdriverLogging-v1-8.exe /FORCE /S
