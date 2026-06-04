/**
 * Monitor GloboService - Verifica e registra o status do dashboard a cada 5 segundos
 * Uso: node monitor-globoservice.js
 */

const https = require('https');
const { execSync } = require('child_process');

const CONFIG = {
  url: 'https://globoservice.service-now.com/now/platform-analytics-workspace/dashboards/params/edit/false/sys-id/43e575caecf2932007fca0232ca324da',
  interval: 5000, // 5 segundos
  hostname: 'globoservice.service-now.com',
  path: '/now/platform-analytics-workspace/dashboards/params/edit/false/sys-id/43e575caecf2932007fca0232ca324da',
};

const COLORS = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m',
  gray: '\x1b[90m',
  bold: '\x1b[1m',
};

let checkCount = 0;
let successCount = 0;
let failCount = 0;
let lastStatus = null;
let startTime = Date.now();

function timestamp() {
  return new Date().toLocaleString('pt-BR', { timeZone: 'America/Sao_Paulo' });
}

function elapsed() {
  const ms = Date.now() - startTime;
  const h = Math.floor(ms / 3600000);
  const m = Math.floor((ms % 3600000) / 60000);
  const s = Math.floor((ms % 60000) / 1000);
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
}

function uptime() {
  if (checkCount === 0) return '0%';
  return ((successCount / checkCount) * 100).toFixed(1) + '%';
}

function checkStatus() {
  checkCount++;

  const options = {
    hostname: CONFIG.hostname,
    path: CONFIG.path,
    method: 'GET',
    timeout: 8000,
    headers: {
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    },
  };

  const req = https.request(options, (res) => {
    const status = res.statusCode;
    const changed = lastStatus !== status;
    lastStatus = status;

    const isOk = status >= 200 && status < 400;
    isOk ? successCount++ : failCount++;

    const icon = isOk ? `${COLORS.green}✔` : `${COLORS.red}✘`;
    const statusColor = isOk ? COLORS.green : (status >= 400 ? COLORS.red : COLORS.yellow);
    const changeTag = changed ? ` ${COLORS.yellow}[MUDOU]${COLORS.reset}` : '';

    const line = [
      `${COLORS.gray}[${timestamp()}]${COLORS.reset}`,
      `${icon}${COLORS.reset}`,
      `${statusColor}HTTP ${status}${COLORS.reset}`,
      `${COLORS.cyan}#${checkCount}${COLORS.reset}`,
      `Uptime: ${COLORS.bold}${uptime()}${COLORS.reset}`,
      `Tempo: ${COLORS.gray}${elapsed()}${COLORS.reset}`,
      changeTag,
    ].join('  ');

    console.log(line);

    // Drena a resposta para liberar a conexão
    res.resume();
  });

  req.on('timeout', () => {
    failCount++;
    lastStatus = 'TIMEOUT';
    console.log(`${COLORS.gray}[${timestamp()}]${COLORS.reset}  ${COLORS.red}✘ TIMEOUT${COLORS.reset}  #${checkCount}  Uptime: ${uptime()}  Tempo: ${elapsed()}`);
    req.destroy();
  });

  req.on('error', (err) => {
    failCount++;
    lastStatus = 'ERROR';
    console.log(`${COLORS.gray}[${timestamp()}]${COLORS.reset}  ${COLORS.red}✘ ERRO: ${err.message}${COLORS.reset}  #${checkCount}  Uptime: ${uptime()}  Tempo: ${elapsed()}`);
  });

  req.end();
}

function printHeader() {
  console.clear();
  console.log(`${COLORS.bold}${COLORS.cyan}═══════════════════════════════════════════════════════════════${COLORS.reset}`);
  console.log(`${COLORS.bold}  🔍 Monitor GloboService - Platform Analytics Dashboard${COLORS.reset}`);
  console.log(`${COLORS.cyan}═══════════════════════════════════════════════════════════════${COLORS.reset}`);
  console.log(`  URL: ${COLORS.gray}${CONFIG.url.substring(0, 70)}...${COLORS.reset}`);
  console.log(`  Intervalo: ${COLORS.bold}${CONFIG.interval / 1000}s${COLORS.reset}   Iniciado: ${COLORS.gray}${timestamp()}${COLORS.reset}`);
  console.log(`  Pressione ${COLORS.bold}Ctrl+C${COLORS.reset} para encerrar`);
  console.log(`${COLORS.cyan}═══════════════════════════════════════════════════════════════${COLORS.reset}`);
  console.log();
}

function printSummary() {
  console.log();
  console.log(`${COLORS.cyan}═══════════════════════════════════════════════════════════════${COLORS.reset}`);
  console.log(`${COLORS.bold}  Resumo Final${COLORS.reset}`);
  console.log(`  Total de verificações: ${COLORS.bold}${checkCount}${COLORS.reset}`);
  console.log(`  Sucesso: ${COLORS.green}${successCount}${COLORS.reset}   Falhas: ${COLORS.red}${failCount}${COLORS.reset}   Uptime: ${COLORS.bold}${uptime()}${COLORS.reset}`);
  console.log(`  Tempo total: ${elapsed()}`);
  console.log(`${COLORS.cyan}═══════════════════════════════════════════════════════════════${COLORS.reset}`);
}

// Captura Ctrl+C para exibir resumo antes de sair
process.on('SIGINT', () => {
  printSummary();
  process.exit(0);
});

// Início
printHeader();
checkStatus();
setInterval(checkStatus, CONFIG.interval);
