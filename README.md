## 💻 Sobre o Projeto

Este projeto consiste em um **Pipeline Automatizado de Orquestração e Manutenção Remota** desenvolvido para simplificar o gerenciamento de infraestrutura e endpoints Windows em larga escala. 

A solução nasceu da necessidade de eliminar tarefas manuais e repetitivas de suporte técnico, permitindo a execução headless (em segundo plano) de auditorias, instalações e atualizações críticas diretamente nos hosts remotos. O grande diferencial do projeto está na sua resiliência: ele foi blindado para rodar sob o contexto **`NT AUTHORITY\SYSTEM`** (via `PsExec`), contornando de forma inteligente as restrições comuns desse ambiente (como falta de console interativo, falhas de autenticação Kerberos/DNS e perfis de usuário ausentes para gerenciadores de pacotes).

## ⚙️ Funcionalidades

O pipeline foi construído de forma modular e inteligente, sendo capaz de entregar:

- [x] **Verificação de Integridade e Conectividade:** Validação de status e disponibilidade dos hosts remotos antes de iniciar qualquer procedimento.
- [x] **Fallback Dinâmico para IP:** Ignora falhas de resolução de DNS ou erros de autenticação Kerberos chaveando automaticamente a comunicação para o endereço IP do alvo.
- [x] **Gerenciamento Automático de Serviços Críticos:** Detecta se serviços essenciais (como o *Dell Client Management Service*) estão desativados, corrigindo seu tipo de inicialização e forçando o início imediato em background.
- [x] **Varredura Avançada de Binários UWP:** Localiza os caminhos reais de executáveis modernos do Windows (como o `winget.exe` dentro de `WindowsApps`) para permitir o uso seguro por contas de sistema.
- [x] **Tratamento Inteligente de Códigos de Erro (`Exit Codes`):** Mapeia e traduz retornos complexos de ferramentas de terceiros. Trata de forma nativa avisos como reboots pendentes (Erro `5`), reinicializações necessárias (Erro `2`) ou sistemas já atualizados (Erro `3003`), normalizando-os para não quebrar o fluxo de execução das próximas máquinas do parque.
- [x] **Execução Segura via Base64:** Envelopa os blocos de código core em strings codificadas, evitando quebras de aspas, caracteres especiais ou problemas de parse durante a transmissão via rede.

## 🛠️ Tecnologias Utilizadas

As principais ferramentas e linguagens que sustentam o ecossistema são:

* **PowerShell 7+** – Engine principal para orquestração, manipulação de serviços, tratamento de erros e conversão de payloads.
* **Sysinternals PsExec** – Utilizado para a elevação de privilégios e execução remota headless no contexto `SYSTEM`.
* **WinGet (Windows Package Manager)** – Responsável pelo deploy silencioso e automatizado de softwares e dependências no host alvo.
* **Dell Command Update CLI (`dcu-cli.exe`)** – Automação integrada para inventário, download e aplicação de drivers/firmwares diretamente no hardware.

## 🚀 Pré-requisitos

Para garantir que o script consiga se comunicar e atuar nas máquinas sem impedimentos, certifique-se de cumprir os seguintes requisitos:

### No Computador Local (Orquestrador)
* Windows 10/11 ou Windows Server.
* Permissões de **Administrador** no terminal.
* Binário do `PsExec.exe` devidamente baixado e acessível (ou adicionado ao `PATH` do sistema).

### No
