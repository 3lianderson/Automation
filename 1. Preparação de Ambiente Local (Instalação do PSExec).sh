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