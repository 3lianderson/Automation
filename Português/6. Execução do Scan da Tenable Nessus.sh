# 1. Código core do Nessus
$NessusCore = @'
param([string]$U="61148d32-f9e7-4af2-837f-db2c494bd5a3",[int]$C=4,[int]$I=30)
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference="Continue"
$p=@("$env:ProgramFiles\Tenable\Nessus Agent\nessuscli.exe","$env:SystemDrive\Program Files (x86)\Tenable\Nessus Agent\nessuscli.exe") | Where-Object {Test-Path $_} | Select-Object -First 1

if(-not $p){"ERROR: nessuscli.exe nao encontrado." | Out-String; exit 127}

"=== TENABLE AGENT: STATUS INICIAL ===" | Out-String
& $p agent status --local
& $p scan-triggers --list

"=== ACIONANDO SCAN TRIGGER ===" | Out-String
$res = & $p scan-triggers --start --uuid=$U
$res | Out-String

"=== MONITORANDO STATUS ASYNCHRONOUS ===" | Out-String
for($i=1; $i -le $C; $i++){
    "Checagem $i de $C..." | Out-String
    & $p agent status --local
    if($i -lt $C){Start-Sleep -Seconds $I}
}
"=== PROCESSO CONCLUIDO VIA CLI ===" | Out-String
'@

$NessusBytes = [System.Text.Encoding]::Unicode.GetBytes($NessusCore)
$NessusEncoded = [Convert]::ToBase64String($NessusBytes)

.\PsExec.exe -s \\BRD3HP554 powershell -NoProfile -EncodedCommand $NessusEncoded