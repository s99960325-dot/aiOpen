// OpenClaw Monitor Service Worker - 移动端缓存优化
const CACHE_NAME = 'openclaw-monitor-v1';
const STATIC_ASSETS = [
  '/',
  '/monitor.html',
  '/api/stats'
];

// 安装时缓存静态资源
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(STATIC_ASSETS);
    })
  );
  self.skipWaiting();
});

// 激活时清理旧缓存
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_NAME)
          .map((name) => caches.delete(name))
      );
    })
  );
  self.clients.claim();
});

// 请求拦截策略：缓存优先，网络回退
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);
  
  // API请求使用网络优先策略
  if (url.pathname === '/api/stats') {
    event.respondWith(
      fetch(request)
        .then((response) => {
          // 更新缓存
          const clone = response.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(request, clone);
          });
          return response;
        })
        .catch(() => {
          // 网络失败时返回缓存
          return caches.match(request);
        })
    );
    return;
  }
  
  // 静态资源使用缓存优先
  event.respondWith(
    caches.match(request).then((response) => {
      return response || fetch(request);
    })
  );
});
