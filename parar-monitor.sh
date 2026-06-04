#!/bin/bash
# parar-monitor.sh
# Encerra todos os processos do Monitor GloboService (opção 4: HTTP + Refresh)
# Uso: chmod +x parar-monitor.sh && ./parar-monitor.sh

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

echo ""
echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}  Encerrando Monitor GloboService${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════════${RESET}"
echo ""

killed=0

# Encerra: node monitor-globoservice.js
PIDS=$(pgrep -f "monitor-globoservice.js" 2>/dev/null)
if [ -n "$PIDS" ]; then
  echo "$PIDS" | xargs kill 2>/dev/null
  echo -e "  ${GREEN}✔ Monitor HTTP encerrado${RESET}  ${YELLOW}(PIDs: $PIDS)${RESET}"
  killed=$((killed + 1))
else
  echo -e "  ${YELLOW}—  Monitor HTTP não estava em execução${RESET}"
fi

# Encerra: browser-refresh.sh
PIDS=$(pgrep -f "browser-refresh.sh" 2>/dev/null)
if [ -n "$PIDS" ]; then
  echo "$PIDS" | xargs kill 2>/dev/null
  echo -e "  ${GREEN}✔ Browser Refresh encerrado${RESET}  ${YELLOW}(PIDs: $PIDS)${RESET}"
  killed=$((killed + 1))
else
  echo -e "  ${YELLOW}—  Browser Refresh não estava em execução${RESET}"
fi

# Encerra: monitor-dashboard.sh
PIDS=$(pgrep -f "monitor-dashboard.sh" 2>/dev/null)
if [ -n "$PIDS" ]; then
  echo "$PIDS" | xargs kill 2>/dev/null
  echo -e "  ${GREEN}✔ Monitor Inteligente encerrado${RESET}  ${YELLOW}(PIDs: $PIDS)${RESET}"
  killed=$((killed + 1))
else
  echo -e "  ${YELLOW}—  Monitor Inteligente não estava em execução${RESET}"
fi

echo ""
if [ "$killed" -gt 0 ]; then
  echo -e "  ${GREEN}${BOLD}$killed processo(s) encerrado(s) com sucesso.${RESET}"
else
  echo -e "  ${YELLOW}Nenhum monitor estava em execução.${RESET}"
fi
echo ""
