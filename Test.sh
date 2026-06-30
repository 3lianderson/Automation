📁 Fase 1: Preparação do Ambiente Local (Instalação do PsExec)
#Execute este bloco na sua máquina de gerenciamento local para garantir que a pasta e as ferramentas estejam prontas:

#PowerShell
#1. Criar a estrutura de pastas local, se não existir
New-Item -ItemType Directory -Force -Path "C:\Maintenance\Tools"

#2. Transferir o pacote oficial PSTools
Invoke-WebRequest -Uri "https://download.sysinternals.com/files/PSTools.zip" -OutFile "C:\Maintenance\Tools\PSTools.zip"

# 3. Extrair os ficheiros de forma silenciosa
Expand-Archive -Path "C:\Maintenance\Tools\PSTools.zip" -DestinationPath "C:\Maintenance\Tools" -Force

# 4. Remover o ficheiro ZIP temporário
Remove-Item -Path "C:\Maintenance\Tools\PSTools.zip" -Force

# 5. Navegar para a pasta das ferramentas
cd "C:\Maintenance\Tools"












🔍 Fase 2: Conectividade e Validação da Máquina Remota
cd "C:\Maintenance\Tools"

# 1. Validar se a porta de rede do SMB está acessível na máquina alvo
Test-NetConnection BRHLZ8294 -Port 445

# 2. Primeiro contacto remoto (Aceitação silenciosa dos termos e recolha do hostname)
.\PsExec.exe -accepteula \\computer hostname












#📊 Fase 3: Pré-Checagem (Pre-Flight)
Gera o inventário inicial do Windows, espaço em disco, valida reinicializações pendentes e salva um JSON na máquina alvo para comparação posterior.

#PowerShell
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
















🛒 Fase 4: Execução do Windows Update (Via Memória)
PowerShell
# 1. Carregar e converter o seu script de atualização local para Base64
$ScriptContent = Get-Content ".\winupdate.ps1" -Raw
$Bytes = [System.Text.Encoding]::Unicode.GetBytes($ScriptContent)
$WinUpdateEncoded = [Convert]::ToBase64String($Bytes)

# 2. Injetar a execução oculta na memória da máquina BRD3HP554
.\PsExec.exe -s \\computer powershell -NoProfile -EncodedCommand $WinUpdateEncoded









💻 Fase 5: Atualização de Drivers via Dell Command Update
Esta fase usa exatamente a sintaxe que você validou com sucesso em ambiente (/applyUpdates), incluindo a flag /silent para evitar interrupções.


PREPARAÇÃO: CHECAGEM E INSTALAÇÃO (RODADOS DIRETO NO TERMINAL LOCAL)

# PASSO A: Checar se o Dell Command Update já está instalado no computador remoto
# (Valida os caminhos das versões Padrão e Universal)
.\PsExec.exe \\computer powershell -Command "if (Test-Path 'C:\Program Files\Dell\CommandUpdate\dcu-cli.exe') { '-> ACHEI: Versao Padrao' } elseif (Test-Path 'C:\Program Files\Dell\CommandUpdateUniversal\dcu-cli.exe') { '-> ACHEI: Versao Universal' } else { '-> Erro: Dell Command Update nao instalado nesta maquina' }"

# PASSO B: Se o utilitário estiver ausente, copia o instalador para o diretório temporário do alvo
robocopy "C:\Maintenance\Tools" "\\computer\c$\Windows\Temp" "Dell-Command-Update.exe" /R:2 /W:2

# PASSO C: Executa a instalação remota silenciosa em contexto de SYSTEM (-s)
.\PsExec.exe -s \\computer C:\Windows\Temp\Dell-Command-Update.exe /s

# PASSO D: Força a ativação e inicialização do serviço da Dell (Garante que não está 'Desativado')
Se tiver ative o Dell Client Management Service:
.\PsExec.exe -s \\computer powershell -Command "Set-Service -Name DellClientManagementService -StartupType Automatic; Start-Service -Name DellClientManagementService; Get-Service -Name DellClientManagementService"


EXECUÇÃO: FAÇA AS ATUALIZAÇÕES (BLOCO CORE DA DELL)
# 1. Código core da Dell
$DellCore = @'
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = "Continue"
 
# 1. Garantir que o serviço do DCU está rodando (Evita o "Fatal Error 2" na conta SYSTEM)
$ServiceName = "DellClientManagementService"
$Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($Service -and $Service.Status -ne 'Running') {
    "Iniciando $ServiceName..." | Out-String
    Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3 # Tempo para o serviço estabilizar
}
 
# 2. Localizar o dcu-cli.exe (Cobrindo Padrão e Universal)
$DcuPath = @(
    "$env:ProgramFiles\Dell\Command Update\dcu-cli.exe",
    "$env:ProgramFiles(x86)\Dell\Command Update\dcu-cli.exe",
    "$env:ProgramFiles\Dell\CommandUpdate\dcu-cli.exe",
    "$env:ProgramFiles(x86)\Dell\CommandUpdate\dcu-cli.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
 
if (-not $DcuPath) {
    "ERROR: dcu-cli.exe nao encontrado." | Out-String
    exit 127
}
 
"=== DELL: ATUALIZANDO DRIVERS ===" | Out-String
 
# 3. Execução avançada: Capturando o processo para tratar o Código 2
$DcuProcess = Start-Process -FilePath $DcuPath -ArgumentList "/applyUpdates -reboot=disable" -Wait -PassThru -NoNewWindow
$ExitCode = $DcuProcess.ExitCode
 
# 4. Tratamento de Erros da Dell
if ($ExitCode -eq 2) {
    "AVISO [Exit Code 2]: A Dell reportou um Reboot Necessario ou erro do contexto SYSTEM. A operacao principal nao quebrou, mas o PC de destino precisara ser reiniciado posteriormente." | Out-String
    exit 0 # Força um código 0 (Sucesso) para o PsExec não interromper o pipeline
} elseif ($ExitCode -ne 0) {
    "ERROR: Processo dcu-cli.exe falhou com codigo de saida: $ExitCode" | Out-String
    exit $ExitCode
}
 
"=== PROCESSO DELL CONCLUIDO COM SUCESSO ===" | Out-String
'@
 
# 2. Conversão segura para Base64
$DellBytes = [System.Text.Encoding]::Unicode.GetBytes($DellCore)
$DellEncoded = [Convert]::ToBase64String($DellBytes)
 
# 3. Execução Remota via IP
.\PsExec.exe -s \\computer powershell.exe -NoProfile -EncodedCommand $DellEncoded









🚀 Fase 6: Atualização Silenciosa via WinGet
PowerShell
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









🛡️ Fase 7: Execução do Scan da Tenable (Nessus)
PowerShell
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









📊 Fase 8: Pós-Checagem Comparativa (Post-Flight)
Faz o cruzamento com os dados da Fase 3, detalha o que mudou na build, calcula o delta exato de GB consumidos ou liberados e limpa a pasta temporária.

PowerShell
# 1. Código core do Post-Flight
$PostCore = @'
$ProgressPreference = 'SilentlyContinue'

if (-not (Test-Path "C:\Windows\Temp\preflight.json")) {
    "ERROR: Dados do Pre-Flight nao foram encontrados para comparacao." | Out-String; exit 1
}
$pre = Get-Content "C:\Windows\Temp\preflight.json" | ConvertFrom-Json

$os = Get-CimInstance Win32_OperatingSystem
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$pendingReboot = Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
$postFreeSpace = [math]::Round($disk.FreeSpace/1GB, 2)

# 1. Comparar Sistema Operacional
$osReport = if ($pre.WinBuild -ne $os.Version) {
    "Windows OS      : Versao Modificada!`n                  De: $($pre.WinVersion) (Build $($pre.WinBuild))`n                  Para: $($os.Caption) (Build $($os.Version))"
} else {
    "Windows OS      : $($os.Version) (Nenhum patch alterou a Build do Kernel)"
}

# 2. Comparar Espaço em Disco
$diffSpace = [math]::Round($postFreeSpace - $pre.FreeSpaceGB, 2)
$diskReport = if ($diffSpace -lt 0) {
    "Espaco em Disco : De $($pre.FreeSpaceGB) GB para $postFreeSpace GB ($([math]::Abs($diffSpace)) GB consumidos em updates)"
} elseif ($diffSpace -gt 0) {
    "Espaco em Disco : De $($pre.FreeSpaceGB) GB para $postFreeSpace GB (+$diffSpace GB liberados por limpeza)"
} else {
    "Espaco em Disco : Sem alteracao volumetrica ($postFreeSpace GB livres)"
}

# 3. Comparar Estado de Reboot
$preRebootText = if($pre.PendingReboot){'SIM'}else{'NAO'}
$postRebootText = if($pendingReboot){'SIM'}else{'NAO'}
$rebootReport = "Reboot Requerido: De [$preRebootText] para [$postRebootText]"

# Montar Bloco Único de Saída de Texto Limpo
@"
==================================================
       RELATORIO COMPARATIVO POST-FLIGHT          
==================================================
$osReport
$diskReport
$rebootReport
==================================================
"@ | Out-String

# Limpeza do arquivo temporário
Remove-Item "C:\Windows\Temp\preflight.json" -Force
'@

$PostBytes = [System.Text.Encoding]::Unicode.GetBytes($PostCore)
$PostEncoded = [Convert]::ToBase64String($PostBytes)

.\PsExec.exe -s \\BRD3HP554 powershell -NoProfile -EncodedCommand $PostEncoded







🔄 Fase 9: Reinicialização Forçada e Consolidação

**** verificar se usuário está em reunião antes ****
.\PsExec.exe -s \\<<COMPUTER>> shutdown /r /t 60 /f /c "Seu computador será reiniciado em 1 minutos para conclusão de atualizações. Salve seu trabalho imediatamente."









TESTE:

# 1. Código core da Dell
$DellCore = @'
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = "Continue"

# Localizar o dcu-cli.exe incluindo a sua pasta local
$DcuPath = @(
    "$env:ProgramFiles\Dell\CommandUpdate\dcu-cli.exe",
    "$env:SystemDrive\Program Files\Dell\CommandUpdate\dcu-cli.exe",
    "$env:ProgramFiles(x86)\Dell\CommandUpdate\dcu-cli.exe",
    "C:\Caminho\Para\Sua\Pasta\Local\dcu-cli.exe" # <-- INSIRA O CAMINHO DA SUA PASTA LOCAL AQUI
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $DcuPath) {
    "ERROR: dcu-cli.exe nao encontrado nas pastas especificadas." | Out-String
    exit 2 # Alterado para o código 2 para refletir "File Not Found" caso o erro venha do script
}

"=== DELL: ATUALIZANDO DRIVERS (SINTAXE MINIMALISTA) ===" | Out-String

# Execução sem o /silent (ou pode testar com /silent novamente se não for um problema do executável)
& $DcuPath /applyUpdates -reboot=disable

"=== PROCESSO DELL CONCLUIDO ===" | Out-String
'@

# 2. Conversão segura
$DellBytes = [System.Text.Encoding]::Unicode.GetBytes($DellCore)
$DellEncoded = [Convert]::ToBase64String($DellBytes)






ComputerList:
-  <<COMPUTER>>
- BRF5W1TZ3
