// OpenClaw Monitor 移动端优化脚本
(function() {
  'use strict';
  
  // 移动端检测
  const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
  if (!isMobile) return;
  
  // 轻量模式配置
  const MOBILE_CONFIG = {
    refreshInterval: 10000,      // 移动端降低刷新频率：10秒
    maxLogs: 10,                 // 减少日志条数
    maxDiscussionMessages: 5,    // 讨论频道只显示最近5条
    lazyLoadDelay: 500,          // 懒加载延迟
    skeletonLoading: true        // 骨架屏 loading
  };
  
  // 覆盖原有配置
  if (typeof CONFIG !== 'undefined') {
    CONFIG.refreshInterval = MOBILE_CONFIG.refreshInterval;
    CONFIG.maxLogs = MOBILE_CONFIG.maxLogs;
  }
  
  // 骨架屏生成
  function createSkeleton() {
    const skeletons = document.querySelectorAll('.card');
    skeletons.forEach(card => {
      if (!card.querySelector('.skeleton')) {
        const skeleton = document.createElement('div');
        skeleton.className = 'skeleton absolute inset-0 bg-slate-800 animate-pulse rounded-xl';
        skeleton.style.zIndex = '10';
        card.style.position = 'relative';
        card.appendChild(skeleton);
      }
    });
  }
  
  // 移除骨架屏
  function removeSkeleton() {
    document.querySelectorAll('.skeleton').forEach(el => el.remove());
  }
  
  // 讨论频道分页 - 只显示最近N条
  function optimizeDiscussion() {
    const chat = document.getElementById('discussion-chat');
    if (!chat) return;
    
    const messages = chat.children;
    const total = messages.length;
    
    if (total > MOBILE_CONFIG.maxDiscussionMessages) {
      // 隐藏旧消息
      for (let i = 0; i < total - MOBILE_CONFIG.maxDiscussionMessages; i++) {
        messages[i].style.display = 'none';
      }
      
      // 添加"显示更多"按钮
      if (!document.getElementById('show-more-btn')) {
        const btn = document.createElement('button');
        btn.id = 'show-more-btn';
        btn.className = 'w-full py-2 text-xs text-slate-500 hover:text-slate-300 transition-colors';
        btn.innerHTML = `<i class="fas fa-chevron-up mr-1"></i> 显示更多 (${total - MOBILE_CONFIG.maxDiscussionMessages}条)`;
        btn.onclick = function() {
          Array.from(chat.children).forEach(msg => msg.style.display = '');
          this.remove();
        };
        chat.parentElement.appendChild(btn);
      }
    }
  }
  
  // 延迟加载非关键内容
  function lazyLoadContent() {
    setTimeout(() => {
      // 延迟加载技能列表详情
      const skillsList = document.getElementById('skills-list');
      if (skillsList && skillsList.children.length > 5) {
        Array.from(skillsList.children).slice(5).forEach(el => {
          el.style.display = 'none';
        });
      }
      
      // 延迟加载模型分布图
      const modelChart = document.getElementById('model-chart');
      if (modelChart) {
        modelChart.style.opacity = '0';
        setTimeout(() => {
          modelChart.style.transition = 'opacity 0.3s';
          modelChart.style.opacity = '1';
        }, 300);
      }
    }, MOBILE_CONFIG.lazyLoadDelay);
  }
  
  // 本地缓存优化
  const MobileCache = {
    get(key) {
      try {
        const item = localStorage.getItem(`oc_${key}`);
        if (!item) return null;
        const { value, timestamp } = JSON.parse(item);
        // 5分钟内有效
        if (Date.now() - timestamp > 5 * 60 * 1000) {
          localStorage.removeItem(`oc_${key}`);
          return null;
        }
        return value;
      } catch (e) {
        return null;
      }
    },
    
    set(key, value) {
      try {
        localStorage.setItem(`oc_${key}`, JSON.stringify({
          value,
          timestamp: Date.now()
        }));
      } catch (e) {
        // 存储空间不足时清理旧数据
        this.clear();
      }
    },
    
    clear() {
      Object.keys(localStorage)
        .filter(k => k.startsWith('oc_'))
        .forEach(k => localStorage.removeItem(k));
    }
  };
  
  // 使用缓存数据初始化页面
  function initFromCache() {
    const cached = MobileCache.get('stats');
    if (cached) {
      try {
        updateSystemStats(cached.system);
        updateAIStats(cached.ai);
        updateSessionStats(cached.sessions);
        updateSkills(cached.skills);
      } catch (e) {
        console.log('Cache restore failed');
      }
    }
  }
  
  // 拦截刷新函数，添加缓存
  const originalRefresh = window.refresh;
  if (originalRefresh) {
    window.refresh = async function() {
      const result = await originalRefresh.apply(this, arguments);
      // 保存到缓存
      try {
        const stats = {
          system: {
            cpu: document.getElementById('cpu-value')?.textContent,
            memory: document.getElementById('mem-value')?.textContent,
            disk: document.getElementById('disk-value')?.textContent,
            load: [
              document.getElementById('load-1')?.textContent,
              document.getElementById('load-5')?.textContent,
              document.getId('load-15')?.textContent
            ]
          },
          ai: {
            totalCalls: document.getElementById('total-calls')?.textContent,
            tokenUsage: document.getElementById('token-usage')?.textContent,
            todayCost: document.getElementById('today-cost')?.textContent?.replace('¥', '')
          },
          sessions: {
            active: document.getElementById('active-sessions')?.textContent,
            todayMessages: document.getElementById('today-messages')?.textContent,
            queued: document.getElementById('queued-tasks')?.textContent,
            total: document.getElementById('total-sessions')?.textContent
          },
          skills: {
            total: document.getElementById('skills-total')?.textContent,
            enabled: document.getElementById('skills-enabled')?.textContent,
            disabled: document.getElementById('skills-disabled')?.textContent
          }
        };
        MobileCache.set('stats', stats);
      } catch (e) {}
      return result;
    };
  }
  
  // 触摸优化
  function optimizeTouch() {
    // 减少动画以提升流畅度
    document.documentElement.style.setProperty('--animation-duration', '0.1s');
    
    // 卡片点击反馈
    document.querySelectorAll('.card').forEach(card => {
      card.addEventListener('touchstart', () => {
        card.style.transform = 'scale(0.98)';
      }, { passive: true });
      card.addEventListener('touchend', () => {
        card.style.transform = '';
      }, { passive: true });
    });
  }
  
  // 初始化
  function init() {
    console.log('[OpenClaw Mobile] 轻量模式已启用');
    
    // 显示轻量模式提示
    const banner = document.createElement('div');
    banner.id = 'mobile-banner';
    banner.className = 'fixed top-0 left-0 right-0 bg-indigo-600 text-white text-xs text-center py-1 z-50';
    banner.innerHTML = '<i class="fas fa-mobile-alt mr-1"></i> 移动端轻量模式';
    document.body.appendChild(banner);
    setTimeout(() => banner.remove(), 3000);
    
    // 应用优化
    createSkeleton();
    initFromCache();
    
    // 等待页面加载完成
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', () => {
        setTimeout(() => {
          removeSkeleton();
          optimizeDiscussion();
          lazyLoadContent();
          optimizeTouch();
        }, 100);
      });
    } else {
      setTimeout(() => {
        removeSkeleton();
        optimizeDiscussion();
        lazyLoadContent();
        optimizeTouch();
      }, 100);
    }
  }
  
  // 启动
  init();
})();
