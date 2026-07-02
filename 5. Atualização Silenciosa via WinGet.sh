# 1. Código core do WinGet
$WingetCore = @'
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = "Stop"

# Busca inteligente pelo caminho do Winget
$W = Get-ChildItem "C:\Program Files\WindowsApps" -Filter "winget.exe" -Recurse -ErrorAction SilentlyContinue | 
     Where-Object {$_.FullName -like "*Microsoft.DesktopAppInstaller*"} | 
     Select-Object -ExpandProperty FullName -First 1

"=== WINGET: ATUALIZANDO APPS ===" | Out-String

if ($W) {
    # 2>&1 redireciona erros para o fluxo de saída padrão (evita o XML)
    & $W upgrade --all --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-String
    "=== PROCESSO WINGET CONCLUIDO ===" | Out-String
} else {
    "ERRO: Winget nao localizado no host." | Out-String
}
'@

$WingetBytes = [System.Text.Encoding]::Unicode.GetBytes($WingetCore)
$WingetEncoded = [Convert]::ToBase64String($WingetBytes)

# Execução limpa
.\PsExec.exe -s \\computer powershell -NoProfile -EncodedCommand $WingetEncoded