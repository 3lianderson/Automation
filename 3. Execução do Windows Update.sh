# 1. Carregar e converter o seu script de atualização local para Base64
$ScriptContent = Get-Content ".\winupdate.ps1" -Raw
$Bytes = [System.Text.Encoding]::Unicode.GetBytes($ScriptContent)
$WinUpdateEncoded = [Convert]::ToBase64String($Bytes)

# 2. Injetar a execução oculta na memória da máquina BRD3HP554
.\PsExec.exe -s \\computer powershell -NoProfile -EncodedCommand $WinUpdateEncoded






# ==============================================================================
# CONFIGURAÇÃO DO ALVO (Insira o Nome, FQDN ou IP da máquina aqui)
# ==============================================================================
$Target = "br6lz8294" 

# 1. Carregar e converter o seu script de atualização local para Base64
if (-not (Test-Path ".\winupdate.ps1")) {
    Write-Error "ERRO: O arquivo .\winupdate.ps1 nao foi encontrado na pasta atual."
    exit 1
}

$ScriptContent = Get-Content ".\winupdate.ps1" -Raw
$Bytes = [System.Text.Encoding]::Unicode.GetBytes($ScriptContent)
$WinUpdateEncoded = [Convert]::ToBase64String($Bytes)

# 2. Execução Remota Automatizada via PsExec
"=== DISPARANDO PIPELINE DE ATUALIZACAO NO ALVO: \\$Target ===" | Out-String

.\PsExec.exe -s -accepteula \\$Target powershell -NoProfile -EncodedCommand $WinUpdateEncoded

"=== EXECUCAO DO WRAPPER CONCLUIDA ===" | Out-String