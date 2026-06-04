#!/bin/bash
# iniciar-monitor.sh
# Menu para iniciar o monitoramento do GloboService
# Uso: chmod +x iniciar-monitor.sh && ./iniciar-monitor.sh

CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}  Monitor GloboService — Modo de inicialização${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════${RESET}"
echo ""
echo -e "  ${GREEN}${BOLD}[1] Monitor Inteligente${RESET} — lê INCs e Tarefas do dashboard,"
echo -e "      envia notificação macOS e abre fila automaticamente ${BOLD}[RECOMENDADO]${RESET}"
echo ""
echo -e "  ${YELLOW}[2] Monitor HTTP${RESET}        — verifica status HTTP da URL a cada 5s"
echo -e "  ${YELLOW}[3] Browser Refresh${RESET}     — apenas recarrega o browser a cada 5s"
echo -e "  ${YELLOW}[4] HTTP + Refresh${RESET}      — monitores 2 e 3 em janelas separadas"
echo ""
echo -e "  ${RED:-\033[0;31m}[0] Parar tudo${RESET}          — encerra todos os monitores em execução"
echo ""
read -rp "  Escolha (0, 1, 2, 3 ou 4): " opcao
echo ""

case "$opcao" in
  0)
    chmod +x "$DIR/parar-monitor.sh"
    "$DIR/parar-monitor.sh"
    ;;
  1)
    echo -e "  ${GREEN}Iniciando Monitor Inteligente...${RESET}"
    chmod +x "$DIR/monitor-dashboard.sh"
    "$DIR/monitor-dashboard.sh"
    ;;
  2)
    echo -e "  ${YELLOW}Iniciando Monitor HTTP...${RESET}"
    node "$DIR/monitor-globoservice.js"
    ;;
  3)
    echo -e "  ${YELLOW}Iniciando Browser Refresh...${RESET}"
    chmod +x "$DIR/browser-refresh.sh"
    "$DIR/browser-refresh.sh"
    ;;
  4)
    echo -e "  ${YELLOW}Abrindo duas janelas do Terminal...${RESET}"
    osascript <<APPLESCRIPT
tell application "Terminal"
  do script "node \"$DIR/monitor-globoservice.js\""
end tell
APPLESCRIPT
    sleep 1
    osascript <<APPLESCRIPT
tell application "Terminal"
  do script "chmod +x \"$DIR/browser-refresh.sh\" && \"$DIR/browser-refresh.sh\""
end tell
APPLESCRIPT
    echo -e "  Dois terminais abertos. Pressione Enter para fechar este menu."
    read -r
    ;;
  *)
    echo "  Opção inválida. Execute novamente e escolha entre 0 e 4."
    exit 1
    ;;
esac
