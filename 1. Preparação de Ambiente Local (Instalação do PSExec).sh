# PREPARAÇÃO: DOWNLOAD E EXTRAÇÃO DAS FERRAMENTAS BASE (RODADO LOCALMENTE)

# 1. Criar a estrutura de diretórios base
# (O parâmetro -Force garante que não haverá erro se a pasta já existir)
New-Item -ItemType Directory -Force -Path "C:\Maintenance\Tools"

# 2. Fazer o download do pacote oficial PSTools direto da fonte (Microsoft)
Invoke-WebRequest -Uri "https://download.sysinternals.com/files/PSTools.zip" -OutFile "C:\Maintenance\Tools\PSTools.zip"

# 3. Descompactar o pacote silenciosamente no diretório alvo
# (O -Force garante a substituição caso existam binários antigos na pasta)
Expand-Archive -Path "C:\Maintenance\Tools\PSTools.zip" -DestinationPath "C:\Maintenance\Tools" -Force

# 4. Fazer a limpeza do arquivo ZIP temporário para manter o ambiente organizado
Remove-Item -Path "C:\Maintenance\Tools\PSTools.zip" -Force

# 5. Mudar o contexto do terminal para a pasta de trabalho oficial
# (Obrigatório para que as chamadas subsequentes ao .\PsExec.exe funcionem)
cd "C:\Maintenance\Tools"

# 6. Obter informações do Computador
# Gera o inventário inicial do Windows, espaço em disco, valida reinicializações pendentes e salva um JSON na máquina alvo para comparação posterior.
# 1. Código core do Pre-Flight
$Core = @'
$ProgressPreference = 'SilentlyContinue'

$os = Get-CimInstance Win32_OperatingSystem
$comp = Get-CimInstance Win32_ComputerSystem
$uptime = (Get-Date) - $os.LastBootUpTime
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$pendingReboot = Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
$release = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue).DisplayVersion

$preFlightData = @{
    Caption       = $os.Caption
    Version       = $os.Version
    Release       = $release
    Uptime        = "$($uptime.Days) dias, $($uptime.Hours) horas"
    FreeSpaceGB   = [math]::Round($disk.FreeSpace/1GB, 2)
    TotalSpaceGB  = [math]::Round($disk.Size/1GB, 2)
    PendingReboot = $pendingReboot
    LoggedUser    = $comp.UserName # Nome do usuário na sessão ativa
}

@"
==================================================
          AUDITORIA PRE-FLIGHT
==================================================
Usuario Logado  : $($preFlightData.LoggedUser)
Windows Version : $($preFlightData.Caption) (Build $($preFlightData.Version)) - Rel: $($preFlightData.Release)
System Uptime   : $($preFlightData.Uptime)
Espaco Livre C: : $($preFlightData.FreeSpaceGB) GB de $($preFlightData.TotalSpaceGB) GB
Reboot Pendente : $(if($preFlightData.PendingReboot){"SIM"}else{"NAO"})
==================================================
"@ | Out-String -Width 120
'@

# Conversão e Execução
$Enc = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Core))
.\PsExec.exe -s \\computer powershell -NoProfile -EncodedCommand $Enc