@echo off
title Monitor GloboService
echo.
echo  Escolha o modo de monitoramento:
echo.
echo  [1] Monitor HTTP (verifica status da URL a cada 5s - terminal)
echo  [2] Browser Refresh (abre e atualiza o browser a cada 5s)
echo  [3] Ambos simultaneamente
echo.
set /p opcao="  Digite a opcao (1, 2 ou 3): "

if "%opcao%"=="1" goto monitor_http
if "%opcao%"=="2" goto browser_refresh
if "%opcao%"=="3" goto ambos

:monitor_http
echo.
echo  Iniciando Monitor HTTP...
node monitor-globoservice.js
goto fim

:browser_refresh
echo.
echo  Iniciando Browser Refresh...
powershell -ExecutionPolicy Bypass -File browser-refresh.ps1
goto fim

:ambos
echo.
echo  Iniciando ambos em janelas separadas...
start "Monitor HTTP" cmd /k "node monitor-globoservice.js"
start "Browser Refresh" powershell -ExecutionPolicy Bypass -File browser-refresh.ps1
goto fim

:fim
pause
