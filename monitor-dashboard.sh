#!/bin/bash
# monitor-dashboard.sh
# Monitor inteligente: recarrega o dashboard a cada 5s, lê os valores do DOM via AppleScript,
# dispara notificação macOS e abre o browser automaticamente quando há INCs ou Tarefas.
# Uso: chmod +x monitor-dashboard.sh && ./monitor-dashboard.sh

# ─── Configuração ────────────────────────────────────────────────────────────
URL_DASHBOARD="https://globoservice.service-now.com/now/platform-analytics-workspace/dashboards/params/edit/false/sys-id/43e575caecf2932007fca0232ca324da"

# Filtros ativos
FILTER_GROUP="operação publicação"   # Designado (assignment_group)
FILTER_STATUS="aguardando atendimento"  # Estado (state_label)

# Função de encode de URL
_encode() { python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$1" 2>/dev/null || echo "$1"; }

# Query combinada: Designado AND Status (^ = AND no ServiceNow)
FILTER_QUERY="assignment_group.nameLIKE$(_encode "$FILTER_GROUP")^state_labelLIKE$(_encode "$FILTER_STATUS")"

# URLs das filas com filtros aplicados
URL_INC_FILA="https://globoservice.service-now.com/now/nav/ui/classic/params/target/incident_list.do%3Fsysparm_query%3D${FILTER_QUERY}"
URL_TASK_FILA="https://globoservice.service-now.com/now/nav/ui/classic/params/target/sc_task_list.do%3Fsysparm_query%3D${FILTER_QUERY}"

INTERVAL=5          # segundos entre cada refresh
WAIT_DOM=3          # segundos aguardando DOM renderizar após reload
# ─────────────────────────────────────────────────────────────────────────────

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
RESET='\033[0m'

count=0
prev_inc=-1
prev_task=-1
start_time=$(date +%s)

# ─── Funções ──────────────────────────────────────────────────────────────────

timestamp() { date "+%d/%m/%Y %H:%M:%S"; }

elapsed() {
  local now=$(date +%s)
  local diff=$((now - start_time))
  printf "%02d:%02d:%02d" $((diff/3600)) $(((diff%3600)/60)) $((diff%60))
}

# Recarrega a aba ativa do Chrome
reload_chrome() {
  osascript <<'APPLESCRIPT' 2>/dev/null
    tell application "Google Chrome"
      activate
      tell active tab of front window
        reload
      end tell
    end tell
APPLESCRIPT
}

# Lê os valores das cards do dashboard via JavaScript executado no Chrome
read_dashboard_values() {
  osascript <<'APPLESCRIPT' 2>/dev/null
    tell application "Google Chrome"
      try
        set jsResult to execute active tab of front window javascript "
          (function() {
            try {
              var body = document.body;
              if (!body || body.innerText.length < 50) {
                return JSON.stringify({inc: -1, task: -1, status: 'loading'});
              }
              var lines = body.innerText.split(/[\\n\\r]+/)
                .map(function(l){ return l.trim(); })
                .filter(function(l){ return l.length > 0; });

              var inc  = -1;
              var task = -1;

              for (var i = 0; i < lines.length; i++) {
                // Card: INCs nas minhas filas
                if (inc === -1 && lines[i].indexOf('INCs nas minhas filas') !== -1) {
                  for (var j = i + 1; j < Math.min(i + 10, lines.length); j++) {
                    if (/^\\d+$/.test(lines[j])) { inc = parseInt(lines[j]); break; }
                  }
                }
                // Card: Tarefas na minha Fila (aceita variações)
                if (task === -1 && (
                  lines[i].indexOf('Tarefas na minha') !== -1 ||
                  lines[i].indexOf('Tarefa na minha')  !== -1 ||
                  lines[i].indexOf('# Tarefas')        !== -1
                )) {
                  for (var j = i + 1; j < Math.min(i + 10, lines.length); j++) {
                    if (/^\\d+$/.test(lines[j])) { task = parseInt(lines[j]); break; }
                  }
                }
              }
              return JSON.stringify({inc: inc, task: task, status: 'ok'});
            } catch(e) {
              return JSON.stringify({inc: -1, task: -1, status: 'error', msg: e.message});
            }
          })()
        "
        return jsResult
      on error
        return "{\"inc\": -1, \"task\": -1, \"status\": \"applescript_error\"}"
      end try
    end tell
APPLESCRIPT
}

# Notificação macOS
notify() {
  local title="$1"
  local msg="$2"
  local sound="${3:-Glass}"
  osascript -e "display notification \"$msg\" with title \"$title\" sound name \"$sound\"" 2>/dev/null
}

# Abre URL em nova aba do Chrome
open_tab() {
  local url="$1"
  osascript <<APPLESCRIPT 2>/dev/null
    tell application "Google Chrome"
      open location "$url"
      activate
    end tell
APPLESCRIPT
}

# Verifica se Chrome está aberto com o dashboard
chrome_has_dashboard() {
  osascript <<'APPLESCRIPT' 2>/dev/null
    tell application "Google Chrome"
      try
        set tabURL to URL of active tab of front window
        if tabURL contains "globoservice" then
          return "yes"
        else
          return "no"
        end if
      on error
        return "no"
      end try
    end tell
APPLESCRIPT
}

# ─── Inicialização ────────────────────────────────────────────────────────────

clear
echo ""
echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}  Monitor Inteligente — GloboService Dashboard${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════════${RESET}"
echo -e "  Monitorando: ${GRAY}INCs nas minhas filas${RESET}"
echo -e "               ${GRAY}# Tarefas na minha Fila${RESET}"
echo -e "  Filtro     : ${BOLD}Designado → ${FILTER_GROUP}${RESET}"
echo -e "               ${BOLD}Status    → ${FILTER_STATUS}${RESET}"
echo -e "  Intervalo  : ${BOLD}${INTERVAL}s${RESET}   Aguarda DOM: ${BOLD}${WAIT_DOM}s${RESET}"
echo -e "  Pressione  : ${BOLD}Ctrl+C${RESET} para encerrar"
echo -e "${CYAN}════════════════════════════════════════════════════════${RESET}"
echo ""

# Abre o dashboard se Chrome não estiver nele
has_dash=$(chrome_has_dashboard)
if [ "$has_dash" != "yes" ]; then
  echo -e "  ${YELLOW}Abrindo dashboard no Chrome...${RESET}"
  open "$URL_DASHBOARD"
  sleep 5
else
  echo -e "  ${GREEN}Chrome já está no dashboard.${RESET}"
  sleep 1
fi

echo ""
echo -e "  ${GREEN}Monitoramento iniciado!${RESET}"
echo ""
printf "  %-25s %-12s %-12s %s\n" "Horário" "INCs Fila" "Tasks Fila" "Status"
echo "  ──────────────────────────────────────────────────────"

# ─── Captura Ctrl+C ──────────────────────────────────────────────────────────
trap 'echo ""; echo -e "  ${CYAN}Encerrado — Total refreshes: ${BOLD}${count}${RESET}  Tempo: $(elapsed)"; exit 0' INT

# ─── Loop principal ──────────────────────────────────────────────────────────
while true; do

  # 1. Reload da aba
  reload_chrome 2>/dev/null
  count=$((count + 1))

  # 2. Aguarda DOM renderizar
  sleep "$WAIT_DOM"

  # 3. Lê os valores do dashboard
  raw=$(read_dashboard_values)
  inc_val=$(echo "$raw"  | grep -o '"inc":[^,}]*'  | grep -o '[0-9-]*' | head -1)
  task_val=$(echo "$raw" | grep -o '"task":[^,}]*' | grep -o '[0-9-]*' | head -1)
  dom_status=$(echo "$raw" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)

  inc_val=${inc_val:--1}
  task_val=${task_val:--1}

  # 4. Monta linha de log
  ts=$(timestamp)
  inc_display="${inc_val}"
  task_display="${task_val}"
  status_display="${GRAY}ok${RESET}"

  if [ "$dom_status" = "loading" ]; then
    status_display="${YELLOW}carregando...${RESET}"
  elif [ "$dom_status" = "applescript_error" ] || [ "$dom_status" = "error" ]; then
    status_display="${RED}erro DOM${RESET}"
  fi

  # Destaque se valor > 0
  [ "$inc_val"  -gt 0 ] 2>/dev/null && inc_display="${RED}${BOLD}${inc_val}${RESET}"
  [ "$task_val" -gt 0 ] 2>/dev/null && task_display="${YELLOW}${BOLD}${task_val}${RESET}"

  printf "  %-25s %-20b %-20b %b\n" "$ts" "$inc_display" "$task_display" "$status_display"

  # 5. Lógica de alerta — INCs na fila
  if [ "$inc_val" -gt 0 ] 2>/dev/null; then
    if [ "$inc_val" != "$prev_inc" ]; then
      echo -e "  ${RED}${BOLD}▶ ALERTA: ${inc_val} INC(s) sem atribuição na sua fila!${RESET}"
      notify "⚠️ GloboService — INC na fila" "${inc_val} INC(s) aguardando atribuição na sua fila!" "Basso"
      # Abre a lista de incidents para assumir
      open_tab "$URL_INC_FILA"
    fi
  fi

  # 6. Lógica de alerta — Tarefas na fila
  if [ "$task_val" -gt 0 ] 2>/dev/null; then
    if [ "$task_val" != "$prev_task" ]; then
      echo -e "  ${YELLOW}${BOLD}▶ ALERTA: ${task_val} Tarefa(s) na sua fila! Abrindo para assumir...${RESET}"
      notify "📋 GloboService — Tarefa na fila" "${task_val} tarefa(s) aguardando na sua fila. Assuma agora!" "Glass"
      # Abre a lista de tasks para assumir
      open_tab "$URL_TASK_FILA"
    fi
  fi

  # 7. Alerta de resolução (voltou a zero)
  if [ "$prev_inc" -gt 0 ] 2>/dev/null && [ "$inc_val" -eq 0 ] 2>/dev/null; then
    echo -e "  ${GREEN}✔ Fila de INCs zerada.${RESET}"
    notify "✅ GloboService" "Fila de INCs zerada." "Ping"
  fi
  if [ "$prev_task" -gt 0 ] 2>/dev/null && [ "$task_val" -eq 0 ] 2>/dev/null; then
    echo -e "  ${GREEN}✔ Fila de Tarefas zerada.${RESET}"
    notify "✅ GloboService" "Fila de Tarefas zerada." "Ping"
  fi

  prev_inc="$inc_val"
  prev_task="$task_val"

  # 8. Aguarda o restante do intervalo
  remaining=$((INTERVAL - WAIT_DOM))
  [ "$remaining" -gt 0 ] && sleep "$remaining"

done
