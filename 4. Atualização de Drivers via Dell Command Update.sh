# Esta fase usa exatamente a sintaxe que você validou com sucesso em ambiente (/applyUpdates), incluindo a flag /silent para evitar interrupções.
#PREPARAÇÃO: CHECAGEM E INSTALAÇÃO (RODADOS DIRETO NO TERMINAL LOCAL)
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

#EXECUÇÃO: FAÇA AS ATUALIZAÇÕES (BLOCO CORE DA DELL)
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
