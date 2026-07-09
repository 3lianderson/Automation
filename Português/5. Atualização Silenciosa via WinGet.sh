# 1. Código core do WinGet
$WingetCore = @'
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = "Stop"

# 1. Busca direta (Sem -Recurse na raiz). Vai direto na pasta do AppInstaller x64.
$AppInstallerPath = "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe"
$W = Resolve-Path $AppInstallerPath -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path -First 1

"=== WINGET: ATUALIZANDO APPS ==="

if ($W) {
    # 2. --disable-interactivity impede o winget de travar esperando inputs invisíveis
    & $W upgrade --all --silent --accept-source-agreements --accept-package-agreements --disable-interactivity 2>&1
    "=== PROCESSO WINGET CONCLUIDO ==="
} else {
    "ERRO: Winget nao localizado no host."
}
'@

$WingetBytes = [System.Text.Encoding]::Unicode.GetBytes($WingetCore)
$WingetEncoded = [Convert]::ToBase64String($WingetBytes)

# Execução limpa via PsExec
.\PsExec.exe -s \\computer powershell -NoProfile -EncodedCommand $WingetEncoded