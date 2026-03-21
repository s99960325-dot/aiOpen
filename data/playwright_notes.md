# Playwright 浏览器自动化框架 — 深度学习笔记

> 更新时间：2026-03-20 | 当前最新版本：1.58.0
> 本机环境：macOS ARM64, Python 3.9.6（系统自带）, Node.js v24.14.0

---

## 一、核心概念：Browser / Context / Page 三层结构

```
Browser（浏览器实例）
  └── BrowserContext（浏览器上下文 = 独立的会话/指纹隔离区）
        ├── Page 1（标签页）
        ├── Page 2（标签页）
        └── Page 3（标签页）
```

| 层级 | 说明 | 资源消耗 |
|------|------|----------|
| **Browser** | 启动一个浏览器进程（Chromium/Firefox/WebKit） | 高（~200-400MB） |
| **BrowserContext** | 隔离的会话环境，独立的 cookies/storage/proxy/指纹 | 低（~30-50MB） |
| **Page** | 一个标签页，绑定到某个 Context | 极低 |

**关键设计思想：** 一个 Browser 实例可创建多个 Context，一个 Context 可创建多个 Page。Context 之间完全隔离（cookies、缓存、指纹互不影响），适合**多账号并行操作**。

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=False)
    
    # Context 1: 账号A的独立会话
    ctx1 = browser.new_context(user_agent="UA-A", proxy={"server": "http://proxy1:8080"})
    page1 = ctx1.new_page()
    page1.goto("https://example.com/login")
    # 登录账号A...
    
    # Context 2: 账号B的独立会话（完全隔离）
    ctx2 = browser.new_context(user_agent="UA-B", proxy={"server": "http://proxy2:8080"})
    page2 = ctx2.new_page()
    page2.goto("https://example.com/login")
    # 登录账号B...
    
    browser.close()
```

---

## 二、安装与配置

### 2.1 基础安装

```bash
# 安装 Python 包
pip install playwright==1.58.0

# 安装浏览器二进制文件（Chromium + Firefox + WebKit）
playwright install

# 只装 Chromium（最常用，节省空间）
playwright install chromium

# 安装系统依赖（Linux 服务器需要）
playwright install-deps
```

### 2.2 虚拟环境安装（推荐）

```bash
python3 -m venv pw-env
source pw-env/bin/activate
pip install playwright==1.58.0
playwright install chromium
```

### 2.3 Docker 部署

```dockerfile
FROM mcr.microsoft.com/playwright/python:v1.58.0-noble

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "bot.py"]
```

### 2.4 踩坑：Python 版本兼容性

- **Playwright 1.58.0 要求 Python >= 3.8**，推荐 3.9+
- 本机系统 Python 3.9.6 ✅ 可直接使用
- 如果需要 Python 3.13，用 pyenv 或 homebrew 安装后创建虚拟环境
- ⚠️ **坑点：** 不要在系统 Python 直接装，容易污染环境，且 brew/python.org 的 Python 可能缺少依赖

### 2.5 验证安装

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto("https://httpbin.org/headers")
    print(page.title())
    browser.close()
    print("✅ Playwright 安装成功！")
```

---

## 三、常用操作详解

### 3.1 页面导航

```python
# 基础跳转
page.goto("https://example.com")

# 等待不同加载状态
page.goto("https://example.com", wait_until="domcontentloaded")  # DOM 加载完
page.goto("https://example.com", wait_until="load")               # 完全加载（默认）
page.goto("https://example.com", wait_until="networkidle")        # 网络空闲

# 前进后退
page.go_back()
page.go_forward()

# 重新加载
page.reload()
```

### 3.2 元素定位（推荐优先级）

```python
# 1. 最推荐：按角色定位（语义化，不易碎）
page.get_by_role("button", name="登录").click()
page.get_by_role("link", name="关于我们").click()
page.get_by_role("textbox", name="用户名").fill("admin")

# 2. 按文本定位
page.get_by_text("欢迎回来").click()
page.get_by_text("确认", exact=True).click()  # 精确匹配

# 3. CSS 选择器
page.locator(".submit-btn").click()
page.locator("#username").fill("admin")

# 4. XPath
page.locator("//button[contains(text(),'登录')]").click()

# 5. 组合定位
page.locator("form").get_by_role("button", name="提交").click()
```

### 3.3 点击与输入

```python
# 点击
page.locator("button.submit").click()
page.locator("button.submit").click(force=True)  # 强制点击（跳过可见性检查）

# 双击 / 右键
page.locator(".item").dblclick()
page.locator(".item").click(button="right")

# 键盘输入
page.locator("#search").fill("关键词")            # 清空后输入
page.locator("#search").type("关键词", delay=100)  # 模拟逐字输入（带延迟）
page.locator("#search").press("Enter")             # 按回车

# 快捷键
page.keyboard.press("Control+A")  # Ctrl+A 全选
page.keyboard.press("Escape")      # ESC

# 下拉选择
page.locator("select#country").select_option("CN")
```

### 3.4 等待策略

```python
# 等待元素出现
page.wait_for_selector(".loaded-content")

# 等待元素消失
page.wait_for_selector(".loading-spinner", state="hidden")

# 等待网络空闲
page.wait_for_load_state("networkidle")

# 固定等待（尽量少用）
page.wait_for_timeout(2000)

# 等待导航完成
with page.expect_navigation():
    page.locator("a.next-page").click()

# ⚡ Playwright 自动等待机制：
# locator.click() 会自动等待元素可见、稳定、可交互，无需手动 sleep
```

### 3.5 截图与PDF

```python
# 全页截图
page.screenshot(path="full_page.png", full_page=True)

# 元素截图
page.locator(".chart").screenshot(path="chart.png")

# 带特定尺寸截图
page.set_viewport_size({"width": 1920, "height": 1080})
page.screenshot(path="desktop.png")

# PDF 导出（仅 Chromium）
page.pdf(path="report.pdf", format="A4")
```

### 3.6 文件上传下载

```python
# 文件上传
page.locator("input[type='file']").set_input_files("/path/to/file.pdf")

# 多文件上传
page.locator("input[type='file']").set_input_files(["file1.pdf", "file2.png"])

# 清除上传
page.locator("input[type='file']").set_input_files([])

# 文件下载
with page.expect_download() as download_info:
    page.locator("a.download-link").click()
download = download_info.value
download.save_as("/path/to/save/file.pdf")
print(f"下载文件名: {download.suggested_filename}")

# 监听所有下载
def handle_download(download):
    download.save_as(f"./downloads/{download.suggested_filename}")
page.on("download", handle_download)
```

### 3.7 执行 JavaScript

```python
# 执行任意 JS
result = page.evaluate("() => document.title")
print(result)

# 滚动到页面底部
page.evaluate("window.scrollTo(0, document.body.scrollHeight)")

# 获取页面所有链接
links = page.evaluate("() => Array.from(document.querySelectorAll('a')).map(a => a.href)")

# 修改 localStorage
page.evaluate("""
    () => {
        localStorage.setItem('token', 'xxx');
        sessionStorage.setItem('session', 'yyy');
    }
""")
```

---

## 四、🚨 反检测方案（重点）

### 4.1 常见检测手段

网站通过以下信号识别自动化浏览器：

| 检测项 | 说明 |
|--------|------|
| `navigator.webdriver` | 自动化浏览器默认为 `true` |
| User-Agent | 包含 "HeadlessChrome" 字样 |
| WebGL/Canvas 指纹 | 无头浏览器的渲染结果不同 |
| Chrome DevTools Protocol | CDP 连接痕迹 |
| 缺少浏览器插件 | navigator.plugins 为空 |
| 语言/时区不一致 | 多个 API 返回不一致 |
| 行为模式 | 鼠标轨迹过于精确、无随机性 |
| TLS 指纹 | 不完整或异常的 TLS 握手 |

### 4.2 方案一：playwright-stealth（基础防护）

```bash
pip install playwright-stealth
```

```python
from playwright.sync_api import sync_playwright
from playwright_stealth import stealth_sync

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    
    # 一行代码注入反检测脚本
    stealth_sync(page)
    
    page.goto("https://bot.sannysoft.com/")
    page.screenshot(path="stealth_test.png")
    browser.close()
```

**playwright-stealth 做了什么：**
- 删除 `navigator.webdriver` 属性
- 修改 User-Agent 去掉 HeadlessChrome
- 伪装 WebGL 渲染器
- 添加假的浏览器插件
- 修改 Chrome 运行时属性
- 隐藏 automation 相关标志

**⚠️ 局限性：** 对 Cloudflare AI Labyrinth（2025年3月推出）、DataDome、Akamai 等企业级反bot系统效果有限。

### 4.3 方案二：Patchright（推荐 ⭐）

**Patchright** 是 Playwright 的反检测 Fork，原生修补了常见检测向量：

```bash
pip install patchright
patchright install chromium  # 使用真实 Chrome 而非 Chromium
```

```python
from patchright.sync_api import sync_patchright

with sync_patchright() as p:
    # Patchright 内置反检测，无需额外配置
    # 默认使用真实 Chrome 浏览器
    # navigator.webdriver = false
    # 移除 Chrome automation flags
    browser = p.chromium.launch(headless=False)
    page = browser.new_page()
    
    page.goto("https://nowsecure.nl/")
    page.wait_for_timeout(5000)
    page.screenshot(path="patchright_test.png")
    browser.close()
```

**Patchright 优势：**
- 使用**真实 Chrome** 而非 Chromium，TLS 指纹更真实
- 原生设置 `navigator.webdriver = false`
- 移除 `--enable-automation` 等 Chrome 自动化标志
- API 与 Playwright 100% 兼容，可零成本迁移

### 4.4 方案三：手动深度伪装（最强防护）

```python
import random
from playwright.sync_api import sync_playwright

STEALTH_JS = """
() => {
    // 1. 删除 webdriver 标志
    Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
    
    // 2. 伪装 plugins
    Object.defineProperty(navigator, 'plugins', {
        get: () => [1, 2, 3, 4, 5],
    });
    
    // 3. 伪装 languages
    Object.defineProperty(navigator, 'languages', {
        get: () => ['zh-CN', 'zh', 'en-US', 'en'],
    });
    
    // 4. 伪装 permissions
    const originalQuery = window.navigator.permissions.query;
    window.navigator.permissions.query = (parameters) =>
        parameters.name === 'notifications'
            ? Promise.resolve({ state: Notification.permission })
            : originalQuery(parameters);
    
    // 5. 伪装 Chrome runtime
    window.chrome = { runtime: {} };
    
    // 6. 修改 WebGL vendor/renderer
    const getParameter = WebGLRenderingContext.prototype.getParameter;
    WebGLRenderingContext.prototype.getParameter = function(parameter) {
        if (parameter === 37445) return 'Intel Inc.';
        if (parameter === 37446) return 'Intel Iris OpenGL Engine';
        return getParameter.call(this, parameter);
    };
}
"""

USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36",
]

def create_stealth_context(browser, proxy=None):
    """创建深度伪装的浏览器上下文"""
    context = browser.new_context(
        user_agent=random.choice(USER_AGENTS),
        viewport={"width": random.choice([1366, 1440, 1536, 1920]), 
                  "height": random.choice([768, 900, 864, 1080])},
        locale="zh-CN",
        timezone_id="Asia/Shanghai",
        color_scheme="light",
        screen={"width": 1920, "height": 1080},
        device_scale_factor=1,
        has_touch=False,
        proxy=proxy,
        ignore_https_errors=True,
    )
    return context

def simulate_human(page):
    """模拟人类行为模式"""
    # 随机鼠标移动
    for _ in range(random.randint(2, 5)):
        page.mouse.move(
            random.randint(100, 800),
            random.randint(100, 600),
            steps=random.randint(5, 15)
        )
        page.wait_for_timeout(random.randint(50, 200))
    
    # 随机滚动
    page.evaluate(f"window.scrollBy(0, {random.randint(100, 500)})")
    page.wait_for_timeout(random.randint(500, 1500))

with sync_playwright() as p:
    browser = p.chromium.launch(
        headless=False,
        args=[
            "--disable-blink-features=AutomationControlled",
            "--disable-dev-shm-usage",
            "--no-sandbox",
        ]
    )
    
    context = create_stealth_context(browser)
    page = context.new_page()
    
    # 注入反检测 JS（每个新页面都要注入）
    page.add_init_script(STEALTH_JS)
    
    # 模拟人类行为
    simulate_human(page)
    
    page.goto("https://target-site.com")
    page.wait_for_timeout(3000)
    
    # 验证是否通过检测
    webdriver = page.evaluate("() => navigator.webdriver")
    print(f"navigator.webdriver = {webdriver}")  # 应为 undefined
    
    browser.close()
```

### 4.5 方案四：绕过 Cloudflare（高难度）

```python
"""
⚠️ Cloudflare AI Labyrinth（2025年推出）是当前最强反bot系统
它会引导bot穿过虚假页面迷宫，超过4层自动标记为bot并注册指纹

应对策略（按难度递增）：
"""
import time
import random

# 策略1: headless=False + 住宅代理 + 完整人类模拟
# 大多数普通 Cloudflare 验证可以通过
def bypass_cf_basic(page):
    page.goto("https://cf-protected-site.com")
    time.sleep(5)  # 等待 Cloudflare 验证完成
    
    # 检查是否还在验证页面
    challenge = page.locator("#challenge-running")
    if challenge.count() > 0:
        # 等待 Turnstile 自动完成
        page.wait_for_selector("#challenge-success", timeout=30000)
    
    print("✅ Cloudflare 验证通过")

# 策略2: 使用 CapSolver 等验证码解决服务（付费）
# 适合 Cloudflare Turnstile / hCaptcha / reCAPTCHA
def bypass_cf_capsolver(page, api_key):
    """
    需要安装: pip install capsolver
    CapSolver 提供 Cloudflare Turnstile 的解决服务
    费用: 约 $0.001/次
    """
    # 1. 打开页面，获取 sitekey
    page.goto("https://cf-protected-site.com")
    
    # 2. 调用 CapSolver API 解决验证码
    # 3. 注入解决方案 token
    # 4. 提交表单
    pass  # 具体实现参考 capsolver 官方文档

# 策略3: Bright Data Scraping Browser（最强方案，企业级）
# 直接使用 Bright Data 的托管浏览器，内置指纹管理
# 费用: 约 $5/GB 流量起步
def bypass_cf_enterprise():
    from playwright.sync_api import sync_playwright
    
    with sync_playwright() as p:
        browser = p.chromium.connect_over_cdp(
            "wss://bright-data-chrome.proxy?token=YOUR_TOKEN"
        )
        page = browser.contexts[0].pages[0]
        page.goto("https://cf-protected-site.com")
        # Bright Data 自动处理指纹和验证
```

### 4.6 检测评分验证

```python
def check_stealth_score(page):
    """验证反检测效果"""
    results = {}
    
    results['webdriver'] = page.evaluate("() => navigator.webdriver")
    results['plugins'] = page.evaluate("() => navigator.plugins.length")
    results['languages'] = page.evaluate("() => navigator.languages")
    results['platform'] = page.evaluate("() => navigator.platform")
    results['vendor'] = page.evaluate("() => navigator.vendor")
    results['chrome'] = page.evaluate("() => !!window.chrome")
    results['permissions_query'] = page.evaluate("""
        () => {
            try {
                return navigator.permissions.query({name:'notifications'}).then(r => r.state);
            } catch(e) { return 'error'; }
        }
    """)
    
    score = 0
    if results['webdriver'] != True: score += 15
    if results['plugins'] > 0: score += 15
    if results['languages'] and len(results['languages']) > 1: score += 15
    if results['chrome'] == True: score += 15
    if results['vendor'] in ['Google Inc.', 'Apple Computer, Inc.']: score += 15
    
    print(f"检测结果: {results}")
    print(f"反检测得分: {score}/75")
    return score
```

---

## 五、多浏览器/多上下文并行操作（重点）

### 5.1 同步 API + 多线程（简单方案）

```python
import threading
from playwright.sync_api import sync_playwright

def scrape_one(url, results, index):
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context()
        page = context.new_page()
        
        try:
            page.goto(url, timeout=30000)
            results[index] = {
                "url": url,
                "title": page.title(),
                "status": "success"
            }
        except Exception as e:
            results[index] = {"url": url, "error": str(e), "status": "failed"}
        finally:
            browser.close()

urls = [f"https://httpbin.org/get?page={i}" for i in range(10)]
results = [None] * len(urls)

threads = []
for i, url in enumerate(urls):
    t = threading.Thread(target=scrape_one, args=(url, results, i))
    threads.append(t)
    t.start()

for t in threads:
    t.join()

print(f"完成: {sum(1 for r in results if r['status']=='success')}/{len(urls)}")
```

### 5.2 异步 API + asyncio（推荐方案 ⭐）

```python
import asyncio
from playwright.async_api import async_playwright

async def scrape_one(url):
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context()
        page = await context.new_page()
        
        try:
            await page.goto(url, timeout=30000)
            title = await page.title()
            return {"url": url, "title": title, "status": "success"}
        except Exception as e:
            return {"url": url, "error": str(e), "status": "failed"}
        finally:
            await browser.close()

async def main():
    urls = [f"https://httpbin.org/get?page={i}" for i in range(20)]
    
    # 并发控制：同时最多 5 个浏览器实例
    semaphore = asyncio.Semaphore(5)
    
    async def limited_scrape(url):
        async with semaphore:
            return await scrape_one(url)
    
    tasks = [limited_scrape(url) for url in urls]
    results = await asyncio.gather(*tasks)
    
    success = sum(1 for r in results if r["status"] == "success")
    print(f"完成: {success}/{len(urls)}")

asyncio.run(main())
```

### 5.3 单浏览器多上下文（资源最优方案 ⭐⭐）

```python
import asyncio
from playwright.async_api import async_playwright

async def batch_scrape():
    async with async_playwright() as p:
        # 只启动一个浏览器进程
        browser = await p.chromium.launch(headless=True)
        
        # 创建多个独立上下文（轻量级，共享浏览器进程）
        urls = [f"https://httpbin.org/get?page={i}" for i in range(10)]
        contexts = [await browser.new_context() for _ in urls]
        pages = [await ctx.new_page() for ctx in contexts]
        
        # 并发导航
        tasks = [page.goto(url) for page, url in zip(pages, urls)]
        await asyncio.gather(*tasks)
        
        # 收集结果
        for page, url in zip(pages, urls):
            title = await page.title()
            print(f"{url} -> {title}")
        
        await browser.close()

asyncio.run(batch_scrape())
```

---

## 六、代理 IP 配置

### 6.1 基础代理设置

```python
# 方式1: 浏览器级别代理（所有请求走同一代理）
browser = p.chromium.launch(
    proxy={
        "server": "http://proxy-server:8080",
        "username": "user",
        "password": "pass"
    }
)

# 方式2: 上下文级别代理（每个 context 可以不同代理）
context = browser.new_context(
    proxy={
        "server": "http://proxy-server:8080",
        "username": "user",
        "password": "pass"
    }
)
```

### 6.2 代理轮换（生产级方案 ⭐）

```python
import random
import asyncio
from playwright.async_api import async_playwright

PROXY_LIST = [
    {"server": "http://proxy1:8080", "username": "u1", "password": "p1"},
    {"server": "http://proxy2:8080", "username": "u2", "password": "p2"},
    {"server": "http://proxy3:8080", "username": "u3", "password": "p3"},
    {"server": "http://proxy4:8080", "username": "u4", "password": "p4"},
    {"server": "http://proxy5:8080", "username": "u5", "password": "p5"},
]

async def scrape_with_rotation(urls):
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        
        tasks = []
        for i, url in enumerate(urls):
            proxy = PROXY_LIST[i % len(PROXY_LIST)]
            tasks.append(scrape_task(browser, url, proxy))
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        await browser.close()
        return results

async def scrape_task(browser, url, proxy):
    context = await browser.new_context(
        proxy=proxy,
        user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    )
    page = await context.new_page()
    try:
        await page.goto(url, timeout=30000)
        return await page.title()
    finally:
        await context.close()

asyncio.run(scrape_with_rotation(
    [f"https://httpbin.org/ip?page={i}" for i in range(5)]
))
```

### 6.3 代理类型说明

| 类型 | 配置示例 | 适用场景 |
|------|---------|----------|
| HTTP | `http://ip:port` | 通用，兼容性最好 |
| HTTPS | `https://ip:port` | 加密代理 |
| SOCKS5 | `socks5://ip:port` | 更底层，支持 TCP/UDP |
| 住宅代理 | `http://user:pass@gate.proxy:port` | 最难被检测，防封首选 |
| 数据中心代理 | `http://ip:port` | 速度快但易被识别 |

---

## 七、实战场景

### 7.1 批量账号注册（教育用途）

```python
import asyncio
import random
from playwright.async_api import async_playwright

async def register_account(email, password, proxy=None):
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=False)
        context_opts = {
            "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36",
            "viewport": {"width": 1366, "height": 768},
            "locale": "en-US",
            "timezone_id": "America/New_York",
        }
        if proxy:
            context_opts["proxy"] = proxy
        
        context = await browser.new_context(**context_opts)
        page = await context.new_page()
        
        try:
            await page.goto("https://example.com/register")
            
            # 填写注册表单（模拟人类打字速度）
            await page.locator("#email").type(email, delay=random.randint(50, 150))
            await page.wait_for_timeout(random.randint(300, 800))
            
            await page.locator("#password").type(password, delay=random.randint(80, 200))
            await page.wait_for_timeout(random.randint(300, 800))
            
            await page.locator("#confirm-password").type(password, delay=random.randint(80, 200))
            await page.wait_for_timeout(random.randint(500, 1000))
            
            # 勾选协议
            await page.locator("#agree-terms").click()
            await page.wait_for_timeout(random.randint(200, 500))
            
            # 提交
            await page.locator("button[type='submit']").click()
            
            # 等待结果
            await page.wait_for_url("**/dashboard**", timeout=10000)
            print(f"✅ 注册成功: {email}")
            
        except Exception as e:
            print(f"❌ 注册失败: {email} - {e}")
        finally:
            await browser.close()

# 批量执行
async def batch_register():
    accounts = [
        (f"user{i}@example.com", f"Pass_{random.randint(10000,99999)}!")
        for i in range(1, 6)
    ]
    
    # 顺序执行（避免并发触发风控）
    for email, pwd in accounts:
        await register_account(email, pwd)
        await asyncio.sleep(random.randint(5, 15))  # 间隔 5-15 秒

asyncio.run(batch_register())
```

### 7.2 数据采集（电商平台商品信息）

```python
import json
import asyncio
from playwright.async_api import async_playwright

async def scrape_products():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            viewport={"width": 1920, "height": 1080},
        )
        page = await context.new_page()
        
        products = []
        base_url = "https://example.com/products"
        
        for page_num in range(1, 6):
            await page.goto(f"{base_url}?page={page_num}")
            await page.wait_for_selector(".product-card")
            await asyncio.sleep(random.uniform(1, 3))
            
            cards = await page.locator(".product-card").all()
            for card in cards:
                try:
                    product = {
                        "name": await card.locator(".product-name").inner_text(),
                        "price": await card.locator(".price").inner_text(),
                        "rating": await card.locator(".rating").get_attribute("data-score"),
                        "url": await card.locator("a").get_attribute("href"),
                    }
                    products.append(product)
                except Exception as e:
                    print(f"解析商品失败: {e}")
            
            print(f"第{page_num}页: 获取 {len(cards)} 个商品")
        
        # 保存结果
        with open("products.json", "w", encoding="utf-8") as f:
            json.dump(products, f, ensure_ascii=False, indent=2)
        
        print(f"共采集 {len(products)} 个商品")
        await browser.close()

asyncio.run(scrape_products())
```

### 7.3 网络拦截直取 API 数据（最高效方案 ⭐⭐）

```python
import json
from playwright.sync_api import sync_playwright

def scrape_via_api(target_url, api_pattern):
    """拦截页面内部的 API 请求，直接获取 JSON 数据，比解析 HTML 快 10 倍"""
    captured = []
    
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        
        # 注册响应监听器
        def handle_response(response):
            if api_pattern in response.url and response.status == 200:
                try:
                    data = response.json()
                    captured.append(data)
                except:
                    pass
        
        page.on("response", handle_response)
        
        # 加载页面（只加载文本，跳过图片/CSS/字体，大幅提速）
        await page.route("**/*.{png,jpg,jpeg,gif,svg,css,woff,woff2}", 
                        lambda route: route.abort())
        
        page.goto(target_url)
        page.wait_for_load_state("networkidle")
        browser.close()
    
    return captured

# 实战：拦截商品列表 API
data = scrape_via_api(
    "https://example.com/shop",
    "api/v1/products"
)
print(json.dumps(data, indent=2, ensure_ascii=False))
```

### 7.4 自动化登录与会话保持

```python
from playwright.sync_api import sync_playwright
import json

def login_and_save_session(url, username, password):
    """登录后保存会话状态，后续可直接复用，无需重复登录"""
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False)
        context = browser.new_context()
        page = context.new_page()
        
        # 登录
        page.goto(f"{url}/login")
        page.locator("#username").fill(username)
        page.locator("#password").fill(password)
        page.locator("button[type='submit']").click()
        page.wait_for_url("**/dashboard**")
        
        # 保存 cookies 和 localStorage
        cookies = context.cookies()
        local_storage = page.evaluate("() => JSON.stringify(localStorage)")
        
        session = {"cookies": cookies, "localStorage": json.loads(local_storage)}
        with open("session.json", "w") as f:
            json.dump(session, f)
        
        print("✅ 会话已保存到 session.json")
        browser.close()

def load_saved_session(url):
    """使用已保存的会话，跳过登录"""
    with open("session.json") as f:
        session = json.load(f)
    
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context()
        
        # 恢复 cookies
        context.add_cookies(session["cookies"])
        page = context.new_page()
        
        # 恢复 localStorage
        page.goto(url)
        page.evaluate(f"""
            () => {{
                const data = {json.dumps(session['localStorage'])};
                for (const [key, value] of Object.entries(data)) {{
                    localStorage.setItem(key, value);
                }}
            }}
        """)
        
        # 刷新页面使会话生效
        page.reload()
        page.wait_for_load_state("networkidle")
        
        # 现在已登录，直接操作
        print(f"当前页面: {page.title()}")
        browser.close()
```

---

## 八、2026 年最新特性与趋势

### 8.1 Playwright 1.58.0 新特性（2026年3月）

- **MCP (Model Context Protocol) 支持**：AI Agent 可直接控制浏览器
  ```bash
  npx @playwright/mcp@latest
  ```
- **playwright init-agents**：自动初始化 AI Agent 集成
- **Accessibility Tree 优先执行**：基于可访问性树的操作，更稳定
- **Self-Healing Tests**：选择器失败时自动尝试替代方案

### 8.2 2026 年生态变化

| 趋势 | 说明 |
|------|------|
| **MCP 集成** | Claude/GPT/Cursor 可用自然语言控制浏览器，无需写代码 |
| **Patchright 兴起** | Playwright 反检测 Fork，API 兼容，内置 stealth |
| **Cloudflare AI Labyrinth** | 2025年3月推出的新一代反bot，通过迷宫页面识别bot |
| **Stagehand / Browser Use** | AI + Playwright 的框架，用自然语言描述操作 |
| **Crawlee** | Apify 维护的爬虫框架，Playwright 优先支持 |

### 8.3 2026 年常见踩坑点

**坑1：headless 模式更容易被检测**
```python
# ❌ 反检测效果差
browser = p.chromium.launch(headless=True)

# ✅ 用 new_headless 模式（Chrome 新版无头模式）
browser = p.chromium.launch(
    headless=True,
    args=["--headless=new"]  # Chrome 112+ 新版无头，指纹更真实
)
```

**坑2：playwright 不是线程安全的**
```python
# ❌ 不能在多个线程间共享同一个 Playwright 实例
# ✅ 每个线程创建自己的 sync_playwright() 上下文
# ✅ 或使用 asyncio 的异步 API（推荐）
```

**坑3：Context 关闭后 Page 不可用**
```python
# ❌ 先关闭 context 再操作 page 会导致错误
# ✅ 操作完 page 后再关闭 context
await page.close()
await context.close()  # 顺序很重要
```

**坑4：Linux 服务器缺少系统依赖**
```bash
# 常见错误: error while loading shared libraries
# 解决方案：
playwright install-deps
# 或 Docker 部署（推荐）
```

**坑5：内存泄漏**
```python
# 长时间运行的任务必须手动关闭 context/page
# 否则内存会持续增长
async def safe_scrape(url):
    browser = await p.chromium.launch()
    context = await browser.new_context()
    try:
        page = await context.new_page()
        await page.goto(url)
        return await page.content()
    finally:
        await page.close()      # ← 不要忘记
        await context.close()   # ← 不要忘记
        await browser.close()   # ← 不要忘记
```

**坑6：wait_for_timeout 不精确**
```python
# page.wait_for_timeout(1000) 实际等待可能超过 1 秒
# 对于需要精确等待的场景，使用 wait_for_selector
```

**坑7：截图在不同系统上可能不一致**
```python
# Docker 环境中需要安装额外字体和依赖
# 使用固定 viewport 避免差异
context = browser.new_context(viewport={"width": 1280, "height": 720})
```

---

## 九、工具链推荐

### 9.1 反检测工具

| 工具 | 安装 | 难度 | 效果 |
|------|------|------|------|
| playwright-stealth | `pip install playwright-stealth` | ⭐ | ⭐⭐ |
| Patchright | `pip install patchright` | ⭐ | ⭐⭐⭐⭐ |
| 手动 JS 注入 | 无需安装 | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| Bright Data | 付费服务 | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| CapSolver | 付费服务 | ⭐⭐ | ⭐⭐⭐⭐（验证码） |

### 9.2 代理服务

| 服务 | 类型 | 价格参考 | 特点 |
|------|------|----------|------|
| Bright Data | 住宅/数据中心 | $5/GB 起 | 全球最大住宅网络 |
| Oxylabs | 住宅/数据中心 | $6/GB 起 | 企业级稳定性 |
| IPRoyal | 住宅 | $1.75/GB 起 | 性价比高 |
| 免费代理 | 数据中心 | 免费 | 不稳定，易被封 |

### 9.3 AI Agent 集成

```bash
# Playwright MCP Server — 让 AI 直接控制浏览器
npx @playwright/mcp@latest

# Stagehand — AI + Playwright 框架
npm install @browserbasehq/stagehand

# Browser Use — 另一个 AI 浏览器框架
pip install browser-use
```

---

## 十、快速参考速查表

```python
# === 启动 ===
browser = p.chromium.launch(headless=False, args=["--start-maximized"])
context = browser.new_context(user_agent="...", proxy={"server": "..."})
page = context.new_page()

# === 导航 ===
page.goto(url, wait_until="networkidle", timeout=30000)

# === 等待 ===
page.wait_for_selector(".el")
page.wait_for_load_state("networkidle")
page.wait_for_timeout(1000)
page.wait_for_url("**/dashboard**")

# === 定位 ===
page.get_by_role("button", name="登录")
page.get_by_text("欢迎")
page.locator(".class")
page.locator("#id")

# === 交互 ===
.click() / .dblclick() / .click(button="right")
.fill("text") / .type("text", delay=100)
.press("Enter") / .press("Tab")
.select_option("value")
.set_input_files("/path")

# === 获取信息 ===
.inner_text() / .inner_html()
.get_attribute("href")
.text_content()
.count() / .all() / .all_inner_texts()
page.title() / page.url() / page.content()

# === 截图 ===
page.screenshot(path="a.png", full_page=True)
page.pdf(path="a.pdf")

# === JS 执行 ===
page.evaluate("() => document.title")
page.add_init_script("() => { ... }")

# === 网络拦截 ===
page.on("response", handler)
page.route("**/*.png", lambda r: r.abort())
page.route("**/api/**", lambda r: r.fulfill(body="mock"))

# === 会话管理 ===
context.cookies() / context.add_cookies(cookies)
context.storage_state(path="state.json")
browser.new_context(storage_state="state.json")
```

---

## 附录：学习资源

- 官方文档：https://playwright.dev/python/
- GitHub：https://github.com/microsoft/playwright
- Patchright：https://github.com/Kaliiiiiiiiii-Vinyzu/patchright
- playwright-stealth：https://github.com/AtuboDad/playwright_stealth
- Playwright MCP：https://github.com/microsoft/playwright-mcp
- Crawlee（Apify）：https://crawlee.dev/
