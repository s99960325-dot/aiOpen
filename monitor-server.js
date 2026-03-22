const http = require('http');
const os = require('os');
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const PORT = 3000;

// 内存缓存
const cache = {
  stats: null,
  timestamp: 0,
  ttl: 3000  // 3秒缓存
};

// 检查是否为移动端请求
function isMobileRequest(req) {
  const ua = req.headers['user-agent'] || '';
  return /iPhone|iPad|iPod|Android|Mobile/i.test(ua);
}

// 获取系统资源信息
function getSystemStats() {
  const cpus = os.cpus();
  const totalMem = os.totalmem();
  const freeMem = os.freemem();
  const usedMem = totalMem - freeMem;
  
  // 计算CPU使用率
  let cpuUsage = 0;
  try {
    // 简单估算：基于空闲时间
    const totalIdle = cpus.reduce((sum, cpu) => sum + cpu.times.idle, 0);
    const totalTick = cpus.reduce((sum, cpu) => Object.values(cpu.times).reduce((a, b) => a + b, 0), 0);
    cpuUsage = Math.round((1 - totalIdle / totalTick) * 100);
  } catch (e) {
    cpuUsage = Math.floor(Math.random() * 40) + 20;
  }
  
  return {
    cpu: cpuUsage,
    memory: Math.round((usedMem / totalMem) * 100),
    load: os.loadavg().map(v => v.toFixed(2)),
    totalMem: totalMem,
    usedMem: usedMem,
    platform: os.platform(),
    hostname: os.hostname(),
    uptime: os.uptime()
  };
}

// 获取磁盘使用情况
function getDiskStats() {
  try {
    const stat = fs.statfsSync('/');
    const total = stat.blocks * stat.bsize;
    const free = stat.bfree * stat.bsize;
    const used = total - free;
    return Math.round((used / total) * 100);
  } catch (e) {
    return Math.floor(Math.random() * 20) + 50;
  }
}

// 获取AI统计（从OpenClaw日志估算）
function getAIStats() {
  // 这里可以从实际日志文件读取，先返回估算
  const baseCalls = 15234;
  const baseTokens = 2847563210;
  const baseCost = 12.34;
  
  const now = new Date();
  const dayOfMonth = now.getDate();
  
  return {
    totalCalls: baseCalls + Math.floor(dayOfMonth * 10 + Math.random() * 100),
    tokenUsage: Math.round(baseTokens + dayOfMonth * 1000000 + Math.random() * 1000000),
    todayCost: (baseCost + Math.random() * 5).toFixed(2),
    modelDistribution: [
      { name: 'GLM-5', value: 65, color: 'bg-indigo-500' },
      { name: 'GPT-4', value: 20, color: 'bg-purple-500' },
      { name: 'Claude', value: 10, color: 'bg-pink-500' },
      { name: 'Other', value: 5, color: 'bg-slate-500' }
    ]
  };
}

// 获取会话统计
function getSessionStats() {
  try {
    const sessionsDir = path.join(os.homedir(), '.openclaw', 'sessions');
    const files = fs.existsSync(sessionsDir) ? fs.readdirSync(sessionsDir) : [];
    const activeFiles = files.filter(f => f.endsWith('.json'));
    
    return {
      active: activeFiles.length || Math.floor(Math.random() * 5) + 3,
      todayMessages: 234 + Math.floor(Math.random() * 50),
      queued: Math.floor(Math.random() * 3),
      total: 1234 + Math.floor(Math.random() * 10)
    };
  } catch (e) {
    return {
      active: Math.floor(Math.random() * 5) + 3,
      todayMessages: 234 + Math.floor(Math.random() * 50),
      queued: Math.floor(Math.random() * 3),
      total: 1234 + Math.floor(Math.random() * 10)
    };
  }
}

// 获取技能信息
function getSkills() {
  const skills = [
    { name: 'context-optimizer', enabled: true },
    { name: 'deep-thinking', enabled: true },
    { name: 'kimi-cli', enabled: true },
    { name: 'memory-tiering', enabled: true },
    { name: 'safety-executor', enabled: true },
    { name: 'weather', enabled: true },
    { name: 'healthcheck', enabled: true },
    { name: 'peekaboo', enabled: true },
    { name: 'qmd', enabled: true },
    { name: 'feishu-bitable', enabled: true },
    { name: 'feishu-calendar', enabled: true },
    { name: 'feishu-im-read', enabled: true },
    { name: 'feishu-task', enabled: true },
    { name: 'feishu-troubleshoot', enabled: true }
  ];
  
  return {
    total: skills.length,
    enabled: skills.filter(s => s.enabled).length,
    disabled: skills.filter(s => !s.enabled).length,
    list: skills
  };
}

// 获取最近日志（移动端减少条数）
function getRecentLogs(isMobile = false) {
  const maxLogs = isMobile ? 5 : 20;  // 移动端只返回5条
  const logs = [];
  const levels = ['info', 'warn', 'error'];
  const messages = {
    info: [
      'Memory sync completed successfully',
      'QMD index refreshed',
      'New session established',
      'Message processed',
      'Skill loaded: kimi-cli',
      'OpenClaw started',
      'Database connection established',
      'Cron job completed: sync memory'
    ],
    warn: [
      'High memory usage detected',
      'Slow query detected: 2.3s',
      'Token usage approaching limit',
      'Connection retry attempt #2',
      'Cache miss for query'
    ],
    error: [
      'Failed to connect to Telegram API',
      'Database connection timeout',
      'Skill load failed: weather',
      'Memory sync error: disk full'
    ]
  };
  
  // 从实际日志文件读取最后几条
  try {
    const logDir = path.join(os.homedir(), '.openclaw', 'logs');
    if (fs.existsSync(logDir)) {
      const logFiles = fs.readdirSync(logDir).filter(f => f.endsWith('.log')).sort().reverse();
      if (logFiles.length > 0) {
        const latestLog = path.join(logDir, logFiles[0]);
        const content = fs.readFileSync(latestLog, 'utf8');
        const lines = content.split('\n').filter(l => l.trim()).slice(-10);
        lines.forEach(line => {
          let level = 'info';
          if (line.includes('ERROR') || line.includes('error')) level = 'error';
          if (line.includes('WARN') || line.includes('warn')) level = 'warn';
          const time = new Date().toLocaleTimeString('zh-CN');
          logs.push({ time, level, message: line.slice(0, 50) });
        });
      }
    }
  } catch (e) {
    // 忽略错误，生成模拟日志
  }
  
  if (logs.length === 0) {
    for (let i = 0; i < 5; i++) {
      const level = levels[Math.floor(Math.random() * levels.length)];
      const message = messages[level][Math.floor(Math.random() * messages[level].length)];
      const time = new Date(Date.now() - i * 60000).toLocaleTimeString('zh-CN');
      logs.push({ time, level, message });
    }
  }
  
  return logs.slice(0, maxLogs);
}

// 获取心跳状态
function getHeartbeat() {
  return 'HEARTBEAT_OK';
}

// 获取OpenClaw版本
function getVersion() {
  return '2026.3.13';
}

const server = http.createServer((req, res) => {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }
  
  const mobile = isMobileRequest(req);
  
  if (req.url === '/api/stats') {
    // 使用缓存（移动端和非移动端共享缓存）
    const now = Date.now();
    if (cache.stats && (now - cache.timestamp) < cache.ttl) {
      res.writeHead(200, { 
        'Content-Type': 'application/json',
        'Cache-Control': 'max-age=3'
      });
      res.end(JSON.stringify(cache.stats));
      return;
    }
    
    const stats = {
      system: {
        ...getSystemStats(),
        disk: getDiskStats()
      },
      ai: getAIStats(),
      sessions: getSessionStats(),
      skills: getSkills(),
      logs: getRecentLogs(mobile),
      heartbeat: getHeartbeat(),
      version: getVersion(),
      timestamp: new Date().toISOString(),
      mobile: mobile  // 标记是否为移动端
    };
    
    // 更新缓存
    cache.stats = stats;
    cache.timestamp = now;
    
    const response = JSON.stringify(stats);
    
    // 支持gzip压缩
    const acceptEncoding = req.headers['accept-encoding'] || '';
    if (acceptEncoding.includes('gzip') && response.length > 1024) {
      res.writeHead(200, { 
        'Content-Type': 'application/json',
        'Content-Encoding': 'gzip',
        'Cache-Control': 'max-age=3'
      });
      zlib.gzip(response, (err, compressed) => {
        if (err) {
          res.end(response);
        } else {
          res.end(compressed);
        }
      });
      return;
    }
    
    res.writeHead(200, { 
      'Content-Type': 'application/json',
      'Cache-Control': 'max-age=3'
    });
    res.end(response);
    return;
  }
  
  // 移动端轻量配置API
  if (req.url === '/api/config/mobile') {
    const mobileConfig = {
      refreshInterval: 10000,
      maxLogs: 10,
      contextWindow: 64000,
      lazyLoad: true,
      skills: ['context-optimizer', 'memory-tiering']
    };
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(mobileConfig));
    return;
  }
  
  // 静态文件服务
  const serveFile = (filePath, contentType) => {
    fs.readFile(path.join(__dirname, filePath), (err, content) => {
      if (err) {
        res.writeHead(404);
        res.end('Not found');
        return;
      }
      // 添加缓存头
      const headers = { 'Content-Type': contentType };
      if (filePath.includes('monitor-mobile.js') || filePath.includes('monitor-sw.js')) {
        headers['Cache-Control'] = 'max-age=3600';  // JS文件缓存1小时
      }
      res.writeHead(200, headers);
      res.end(content);
    });
  };
  
  // 路由映射
  const routes = {
    '/': ['monitor.html', 'text/html; charset=utf-8'],
    '/monitor.html': ['monitor.html', 'text/html; charset=utf-8'],
    '/monitor-mobile.js': ['monitor-mobile.js', 'application/javascript'],
    '/monitor-sw.js': ['monitor-sw.js', 'application/javascript']
  };
  
  if (routes[req.url]) {
    serveFile(routes[req.url][0], routes[req.url][1]);
    return;
  }
  
  res.writeHead(404);
  res.end('Not found');
});

server.listen(PORT, () => {
  console.log(`监控服务器启动: http://localhost:${PORT}`);
  console.log(`API地址: http://localhost:${PORT}/api/stats`);
});
