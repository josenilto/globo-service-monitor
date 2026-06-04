# browser-refresh.ps1
# Abre o GloboService no browser e envia F5 a cada 5 segundos para manter o dashboard atualizado
# Uso: .\browser-refresh.ps1

$URL = "https://globoservice.service-now.com/now/platform-analytics-workspace/dashboards/params/edit/false/sys-id/43e575caecf2932007fca0232ca324da"
$INTERVAL = 5  # segundos

Add-Type -AssemblyName System.Windows.Forms

Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Browser Refresh - GloboService Dashboard" -ForegroundColor White
Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Intervalo: $INTERVAL segundos" -ForegroundColor Gray
Write-Host "  Pressione Ctrl+C para encerrar" -ForegroundColor Gray
Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Abre o link no browser padrão
Write-Host "[$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')]  Abrindo browser..." -ForegroundColor Yellow
Start-Process $URL

# Aguarda o browser carregar
Start-Sleep -Seconds 4

Write-Host "[$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')]  Iniciando refresh automático a cada $INTERVAL segundos..." -ForegroundColor Green
Write-Host ""

$count = 0

try {
    while ($true) {
        Start-Sleep -Seconds $INTERVAL
        $count++

        # Envia F5 para o processo do browser ativo
        $wshell = New-Object -ComObject wscript.shell

        # Tenta ativar o browser (Edge, Chrome ou Firefox)
        $browserProcesses = @('msedge', 'chrome', 'firefox')
        $activated = $false

        foreach ($browser in $browserProcesses) {
            $proc = Get-Process -Name $browser -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($proc) {
                $wshell.AppActivate($proc.Id) | Out-Null
                Start-Sleep -Milliseconds 300
                [System.Windows.Forms.SendKeys]::SendWait('{F5}')
                $activated = $true
                Write-Host "[$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')]  ✔ F5 enviado para $browser  (#$count)" -ForegroundColor Green
                break
            }
        }

        if (-not $activated) {
            Write-Host "[$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')]  ⚠ Browser não encontrado. Reabrindo..." -ForegroundColor Yellow
            Start-Process $URL
            Start-Sleep -Seconds 3
        }
    }
}
finally {
    Write-Host ""
    Write-Host "Monitor encerrado. Total de refreshes: $count" -ForegroundColor Cyan
}
