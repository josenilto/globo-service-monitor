#!/bin/bash
# browser-refresh.sh
# Abre o GloboService no browser e recarrega a cada 5 segundos usando AppleScript
# Uso: chmod +x browser-refresh.sh && ./browser-refresh.sh

URL="https://globoservice.service-now.com/now/platform-analytics-workspace/dashboards/params/edit/false/sys-id/43e575caecf2932007fca0232ca324da"
INTERVAL=5
count=0

# Detecta qual browser está disponível
detect_browser() {
  if osascript -e 'tell application "Google Chrome" to get name' &>/dev/null 2>&1; then
    echo "Google Chrome"
  elif osascript -e 'tell application "Microsoft Edge" to get name' &>/dev/null 2>&1; then
    echo "Microsoft Edge"
  elif osascript -e 'tell application "Firefox" to get name' &>/dev/null 2>&1; then
    echo "Firefox"
  else
    echo "Safari"
  fi
}

# Recarrega a aba ativa no browser
reload_browser() {
  local browser="$1"

  case "$browser" in
    "Google Chrome"|"Microsoft Edge")
      osascript <<APPLESCRIPT
tell application "$browser"
  activate
  tell active tab of front window
    reload
  end tell
end tell
APPLESCRIPT
      ;;
    "Firefox")
      osascript <<APPLESCRIPT
tell application "Firefox"
  activate
end tell
tell application "System Events"
  keystroke "r" using command down
end tell
APPLESCRIPT
      ;;
    "Safari")
      osascript <<APPLESCRIPT
tell application "Safari"
  activate
  do JavaScript "location.reload(true)" in current tab of front window
end tell
APPLESCRIPT
      ;;
  esac
}

# Abre URL no browser
open_url() {
  open "$URL"
}

# Cores ANSI
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
RESET='\033[0m'

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}  Browser Refresh - GloboService Dashboard${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════${RESET}"
echo -e "  Intervalo: ${BOLD}${INTERVAL}s${RESET}"
echo -e "  Pressione ${BOLD}Ctrl+C${RESET} para encerrar"
echo -e "${CYAN}════════════════════════════════════════════════════${RESET}"
echo ""

BROWSER=$(detect_browser)
echo -e "  Browser detectado: ${BOLD}${BROWSER}${RESET}"
echo ""

echo -e "  ${YELLOW}Abrindo dashboard...${RESET}"
open_url
sleep 4

echo -e "  ${GREEN}Refresh automático iniciado!${RESET}"
echo ""

# Captura Ctrl+C
trap 'echo ""; echo -e "  ${CYAN}Encerrado. Total de refreshes: ${BOLD}${count}${RESET}"; exit 0' INT

while true; do
  sleep "$INTERVAL"
  count=$((count + 1))
  timestamp=$(date "+%d/%m/%Y %H:%M:%S")

  if reload_browser "$BROWSER" 2>/dev/null; then
    echo -e "${GRAY}[${timestamp}]${RESET}  ${GREEN}✔ Refresh #${count}${RESET}  ${BOLD}${BROWSER}${RESET}"
  else
    echo -e "${GRAY}[${timestamp}]${RESET}  ${YELLOW}⚠ Browser não encontrado. Reabrindo...${RESET}"
    open_url
    sleep 3
  fi
done
