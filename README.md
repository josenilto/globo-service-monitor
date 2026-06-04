# Monitor GloboService

Monitoramento automático em background do dashboard **Platform Analytics** do GloboService (ServiceNow).  
A cada 5 segundos recarrega a página, lê os contadores diretamente do browser e dispara **notificação macOS** quando há INCs ou Tarefas na fila — abrindo automaticamente a lista filtrada para assumir.

---

## Arquivos

| Arquivo | Plataforma | Descrição |
| --- | --- | --- |
| `monitor-dashboard.sh` | macOS | Monitor inteligente — lê DOM, notifica e abre fila |
| `browser-refresh.sh` | macOS | Recarrega o browser a cada 5s via AppleScript |
| `iniciar-monitor.sh` | macOS | Menu interativo de inicialização |
| `parar-monitor.sh` | macOS | Encerra todos os monitores em execução |
| `monitor-globoservice.js` | macOS / Windows | Verifica status HTTP da URL a cada 5s |
| `browser-refresh.ps1` | Windows | Versão PowerShell do refresh (não usar no Mac) |
| `iniciar-monitor.bat` | Windows | Menu para Windows (não usar no Mac) |

---

## Pré-requisitos

- **macOS** com **Google Chrome** instalado e logado no GloboService
- **Node.js** v14 ou superior → [nodejs.org](https://nodejs.org)

```bash
node --version   # verificar instalação
```

---

## Instalação

```bash
# Entrar na pasta do projeto
cd ~/Desktop/project-globo-service-inc

# Dar permissão de execução (apenas uma vez)
chmod +x monitor-dashboard.sh browser-refresh.sh iniciar-monitor.sh parar-monitor.sh
```

---

## Como usar

### Menu interativo

```bash
./iniciar-monitor.sh
```

```text
  [1] Monitor Inteligente  — abre em nova janela, roda em segundo plano  [RECOMENDADO]
  [2] Monitor HTTP         — verifica status HTTP da URL a cada 5s
  [3] Browser Refresh      — apenas recarrega o browser a cada 5s
  [4] HTTP + Refresh       — monitores 2 e 3 em janelas separadas

  [0] Parar tudo           — encerra todos os monitores em execução
```

Todas as opções que iniciam um monitor abrem uma **nova janela do Terminal**, mantendo o menu disponível para outras ações.

---

## Encerrando os monitores

### Pelo menu

```bash
./iniciar-monitor.sh   # escolha opção 0
```

### Direto pelo terminal

```bash
./parar-monitor.sh
```

O script identifica e encerra os três monitores se estiverem rodando, exibindo os PIDs de cada processo finalizado:

```text
════════════════════════════════════════════════════════
  Encerrando Monitor GloboService
════════════════════════════════════════════════════════

  ✔ Monitor HTTP encerrado        (PIDs: 12345)
  ✔ Browser Refresh encerrado     (PIDs: 12346)
  ✔ Monitor Inteligente encerrado (PIDs: 12347)

  3 processo(s) encerrado(s) com sucesso.
```

---

## Monitor Inteligente — `monitor-dashboard.sh`

### O que faz

A cada ciclo de **5 segundos**:

1. Recarrega a aba ativa do Chrome (via AppleScript)
2. Aguarda **3 segundos** para o ServiceNow renderizar o DOM
3. Executa JavaScript no Chrome e lê os contadores das cards:
   - **INCs nas minhas filas**
   - **# Tarefas na minha Fila**
4. Compara com o valor anterior e age se mudou:

| Situação | Ação |
| --- | --- |
| INCs > 0 e mudou | Notificação macOS + abre lista de Incidents filtrada |
| Tarefas > 0 e mudou | Notificação macOS + abre lista de Tasks filtrada |
| Fila zerou | Notificação de conclusão |

### Filtros ativos

As listas abertas no Chrome já chegam pré-filtradas com dois critérios combinados:

| Filtro | Campo ServiceNow | Valor |
| --- | --- | --- |
| Designado | `assignment_group` | `operação publicação` |
| Status | `state_label` | `aguardando atendimento` |

Query enviada ao ServiceNow (`^` = AND):

```text
assignment_group.nameLIKEoperação publicação^state_labelLIKEaguardando atendimento
```

### Exemplo de terminal

```text
════════════════════════════════════════════════════════
  Monitor Inteligente — GloboService Dashboard
════════════════════════════════════════════════════════
  Monitorando: INCs nas minhas filas
               # Tarefas na minha Fila
  Filtro     : Designado → operação publicação
               Status    → aguardando atendimento
  Intervalo  : 5s   Aguarda DOM: 3s
════════════════════════════════════════════════════════

  Horário                   INCs Fila    Tasks Fila   Status
  ──────────────────────────────────────────────────────
  04/06/2026 09:00:08       0            0            ok
  04/06/2026 09:00:13       0            0            ok
  04/06/2026 09:00:18       2            1            ok
  ▶ ALERTA: 2 INC(s) sem atribuição na sua fila!
  ▶ ALERTA: 1 Tarefa(s) na sua fila! Abrindo para assumir...
  04/06/2026 09:00:23       0            0            ok
  ✔ Fila de INCs zerada.
  ✔ Fila de Tarefas zerada.
```

### Notificações macOS

| Evento | Título | Som |
| --- | --- | --- |
| INC na fila | ⚠️ GloboService — INC na fila | Basso |
| Tarefa na fila | 📋 GloboService — Tarefa na fila | Glass |
| Fila zerada | ✅ GloboService | Ping |

### Configurações

Edite as variáveis no topo do arquivo `monitor-dashboard.sh`:

```bash
# Filtros aplicados ao abrir as listas no Chrome
FILTER_GROUP="operação publicação"       # Designado (assignment_group)
FILTER_STATUS="aguardando atendimento"   # Estado (state_label)

INTERVAL=5    # segundos entre cada refresh
WAIT_DOM=3    # segundos aguardando DOM renderizar após reload
```

---

## Monitor HTTP — `monitor-globoservice.js`

Verifica se a URL está respondendo, sem abrir browser. Exibe status HTTP, uptime e tempo decorrido.

```bash
node monitor-globoservice.js
```

```text
[04/06/2026 09:00:05]  ✔ HTTP 200  #1  Uptime: 100.0%  Tempo: 00:00:05
[04/06/2026 09:00:10]  ✔ HTTP 200  #2  Uptime: 100.0%  Tempo: 00:00:10
[04/06/2026 09:00:15]  ✘ TIMEOUT   #3  Uptime: 66.7%   Tempo: 00:00:15
```

Pressione `Ctrl+C` para ver o resumo final com total de verificações e uptime.

---

## Browser Refresh — `browser-refresh.sh`

Abre o dashboard no Chrome e envia reload a cada 5s via AppleScript. Sem leitura de valores nem notificações.

```bash
./browser-refresh.sh
```

Detecta automaticamente o browser disponível:

| Browser | Método |
| --- | --- |
| Google Chrome | AppleScript nativo `reload` |
| Microsoft Edge | AppleScript nativo `reload` |
| Firefox | AppleScript + `Cmd+R` |
| Safari | AppleScript + `location.reload()` |

---

## Como funciona a leitura do DOM

O `monitor-dashboard.sh` usa a cadeia:

```text
Shell → AppleScript → Chrome → JavaScript → innerText das cards → JSON → Shell
```

O JavaScript percorre as linhas de texto da página procurando pelos títulos das cards e captura o número imediatamente abaixo — sem depender de seletores CSS específicos da versão do ServiceNow.
