# PREPARAÇÃO: TESTE DE REDE E CREDENCIAL (RODADO DIRETO NO TERMINAL LOCAL)

# PASSO ÚNICO: Tentar mapear o compartilhamento administrativo IPC$
# Se retornar "Comando concluído com êxito", a rede está perfeita.
net use \\computer\IPC$ /user:DOMINIO\Usuario Senha

# PREPARAÇÃO: VALIDAÇÃO DE PORTA E DIRETÓRIO DE TRABALHO

# PASSO A: Navegar para o diretório de trabalho (Garante a execução do binário correto)
cd "C:\Maintenance\Tools"

# PASSO B: Validar se a porta de rede do SMB (445) está acessível na máquina alvo
# (É esperado que o parâmetro TcpTestSucceeded retorne True)
Test-NetConnection computer -Port 445


# EXECUÇÃO: PRIMEIRO CONTATO REMOTO (TESTE DE FOGO)

# 1. Primeiro contato remoto (Aceitação silenciosa dos termos e recolha do hostname)
# O sucesso é confirmado se o terminal imprimir o nome do servidor remoto.
.\PsExec.exe -accepteula \\computer hostname


#Reiniciar Computador
#**** verificar se usuário está em reunião antes ****
.\PsExec.exe -s \\<<COMPUTER>> shutdown /r /t 60 /f /c "Seu computador será reiniciado em 1 minuto para conclusão de atualizações. Salve seu trabalho imediatamente."
