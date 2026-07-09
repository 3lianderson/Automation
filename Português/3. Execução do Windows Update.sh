# 1. Carregar e converter o seu script de atualização local para Base64
$ScriptContent = Get-Content ".\winupdate.ps1" -Raw
$Bytes = [System.Text.Encoding]::Unicode.GetBytes($ScriptContent)
$WinUpdateEncoded = [Convert]::ToBase64String($Bytes)

# 2. Injetar a execução oculta na memória da máquina BRD3HP554
.\PsExec.exe -s \\computer powershell -NoProfile -EncodedCommand $WinUpdateEncoded


./windows-update hoxxxxx
