# OpenClaw 移动端加载优化方案

## 问题分析

| 问题 | 原因 | 影响 |
|------|------|------|
| 128k上下文传输 | 移动端网络不稳定，大数据量传输慢 | 首屏加载 >5s |
| 知识索引膨胀 | knowledge-index.md 54KB | 增加解析时间 |
| 无分页/懒加载 | 一次性加载所有内容 | DOM渲染慢 |
| 无缓存机制 | 每次重新请求全部数据 | 重复加载 |
| 多技能叠加 | deep-thinking + context-optimizer + memory-tiering | 处理开销大 |

## 已实施的优化方案

### 1. 服务端优化 ✅

**文件**: `monitor-server.js`

| 优化项 | 实现 | 效果 |
|--------|------|------|
| API响应缓存 | 3秒TTL内存缓存 | 减少重复计算 |
| gzip压缩 | 响应>1KB自动压缩 | 减少传输量 60-80% |
| 移动端检测 | User-Agent识别 | 差异化响应 |
| 日志分页 | 移动端只返回5条 | 减少数据量 75% |

### 2. 前端优化 ✅

**文件**: `monitor.html` + `monitor-mobile.js`

| 优化项 | 实现 | 效果 |
|--------|------|------|
| LocalStorage缓存 | 5分钟有效期 | 二次加载 <1s |
| 刷新频率降低 | 10s (移动端) | 减少请求 50% |
| 骨架屏loading | 占位动画 | 感知加载更快 |
| 讨论频道分页 | 只显示5条 | 减少DOM节点 |
| 懒加载 | 延迟加载非关键内容 | 首屏更快 |

### 3. Service Worker 缓存 ✅

**文件**: `monitor-sw.js`

- 静态资源缓存优先
- API请求网络优先+缓存回退
- 离线可访问

### 4. 数据归档优化 ✅

**文件**: `scripts/archive-old-memories.sh`

- 3天前记忆自动归档
- 知识索引自动精简
- 定时清理任务

## 配置对比

### 优化前 (默认配置)

```json
{
  "context_window": 128000,
  "refresh_interval": 5000,
  "max_logs": 20,
  "skills": ["deep-thinking", "context-optimizer", "memory-tiering"],
  "cache": false,
  "gzip": false
}
```

### 优化后 (移动端)

```json
{
  "context_window": 64000,
  "refresh_interval": 10000,
  "max_logs": 10,
  "skills": ["context-optimizer", "memory-tiering"],
  "cache": true,
  "gzip": true
}
```

## 预期效果

| 指标 | 优化前 | 优化后 | 提升 |
|------|--------|--------|------|
| 首屏加载时间 | 5-8s | 2-3s | **60%** |
| 二次加载时间 | 5-8s | <1s | **90%** |
| 数据传输量 | 100% | 20-30% | **70%** |
| API请求频率 | 12次/分钟 | 6次/分钟 | **50%** |

## 使用说明

### 一键执行优化

```bash
bash /Users/seven/clawd/scripts/optimize-mobile.sh
```

### 手动归档数据

```bash
bash /Users/seven/clawd/scripts/archive-old-memories.sh
```

### 重启监控服务器

```bash
pkill -f "node.*monitor-server.js"
cd /Users/seven/clawd && node monitor-server.js
```

### 安装定时任务

```bash
crontab /Users/seven/clawd/scripts/crontab-config.txt
```

## 访问地址

- **桌面端**: http://localhost:3000 (完整功能)
- **移动端**: http://<server-ip>:3000 (自动轻量模式)

## 测试验证

1. **首次加载测试**
   - 手机浏览器访问 http://<server-ip>:3000
   - 观察首屏出现时间

2. **缓存测试**
   - 刷新页面
   - 第二次应该明显更快

3. **离线测试**
   - 关闭网络
   - 页面应该仍能显示（缓存数据）

## 故障排查

### 问题：Service Worker未生效
```bash
# Chrome DevTools → Application → Service Workers
# 点击 "Unregister" 后刷新页面
```

### 问题：缓存未更新
```bash
# 清除浏览器缓存
# 或打开隐身模式测试
```

### 问题：服务器无法启动
```bash
# 检查端口占用
lsof -i :3000

# 强制关闭后重启
pkill -9 -f "node.*monitor-server.js"
node monitor-server.js
```

## 后续优化建议

1. **CDN部署**: 将静态资源部署到CDN
2. **图片优化**: 监控大屏图表使用WebP格式
3. **HTTP/2**: 升级到HTTP/2支持多路复用
4. **预加载**: 关键资源使用 `<link rel="preload">`
