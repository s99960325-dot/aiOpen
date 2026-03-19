# 逆向工程 & 协议分析学习资源

## 一、核心工具（高星项目）

### 1. Ghidra - 65.9k ⭐
**地址**: https://github.com/NationalSecurityAgency/ghidra
**用途**: NSA 开源的逆向工程框架
**功能**:
- 反汇编器
- 反编译器
- 二进制分析
- 脚本扩展
**适用**: 桌面应用、固件、协议逆向

---

### 2. JADX - 47.7k ⭐
**地址**: https://github.com/skylot/jadx
**用途**: Android APK/DEX 反编译器
**功能**:
- APK 反编译为 Java 源码
- 支持 ProGuard 混淆
- 图形化界面
- 命令行工具
**适用**: Android 应用逆向

---

### 3. mitmproxy - 42.7k ⭐
**地址**: https://github.com/mitmproxy/mitmproxy
**用途**: 中间人代理，网络流量分析
**功能**:
- HTTPS 拦截
- 流量录制/回放
- 脚本扩展
- Web 界面
**适用**: 协议分析、API 逆向

---

### 4. Frida - 20k ⭐
**地址**: https://github.com/frida/frida
**用途**: 动态插桩工具
**功能**:
- 运行时 Hook
- 跨平台（iOS/Android/Windows/macOS/Linux）
- JavaScript 脚本
- 内存操作
**适用**: 协议破解、反调试、加密分析

---

### 5. MobSF - 20.6k ⭐
**地址**: https://github.com/MobSF/Mobile-Security-Framework-MobSF
**用途**: 移动应用安全测试框架
**功能**:
- 自动化静态分析
- 动态分析
- API 测试
- 漏洞扫描
**适用**: 移动应用安全评估

---

### 6. OWASP MASTG - 12.8k ⭐
**地址**: https://github.com/OWASP/mastg
**用途**: 移动应用安全测试指南
**内容**:
- Android/iOS 安全测试方法论
- 逆向工程技术
- 漏洞案例分析
- 最佳实践
**适用**: 学习移动安全

---

## 二、协议逆向工具

### 7. netzob - 825 ⭐
**地址**: https://github.com/netzob/netzob
**用途**: 协议逆向工程
**功能**:
- 协议推断
- 消息格式分析
- 自动化逆向
**适用**: 私有协议逆向

---

### 8. CAN_Reverse_Engineering - 439 ⭐
**地址**: https://github.com/brent-stone/CAN_Reverse_Engineering
**用途**: 汽车 CAN 总线协议逆向
**适用**: 汽车协议分析

---

## 三、Android 逆向工具集

### 9. CreditTone/hooker - 5k ⭐
**地址**: https://github.com/CreditTone/hooker
**用途**: Frida Hook 工具集合
**功能**:
- 自动化 Hook 脚本
- 常见防护绕过
**适用**: Android 抓包、脱壳

---

### 10. ax/apk.sh - 3.8k ⭐
**地址**: https://github.com/ax/apk.sh
**用途**: APK 分析工具集
**功能**:
- APK 信息提取
- 反编译
- 漏洞扫描
**适用**: APK 快速分析

---

### 11. Wallbreaker - 870 ⭐
**地址**: https://github.com/hluwa/Wallbreaker
**用途**: Frida 脱壳工具
**功能**:
- 加壳应用脱壳
- DEX dump
**适用**: 加壳应用逆向

---

### 12. dexcalibur - 1.1k ⭐
**地址**: https://github.com/FrenchYeti/dexcalibur
**用途**: 动态 Android 逆向
**功能**:
- 动态分析
- Hook 自动生成
- 可视化
**适用**: 复杂应用逆向

---

## 四、学习资源

### 13. awesome-reverse-engineering - 4.9k ⭐
**地址**: https://github.com/alphaSeclab/awesome-reverse-engineering
**内容**:
- 逆向工具集合
- 学习资料
- CTF 题目
**适用**: 入门学习

---

### 14. PRE-list - 181 ⭐
**地址**: https://github.com/techge/PRE-list
**内容**: 协议逆向工程论文列表
**适用**: 学术研究

---

## 五、实战工具组合

### 协议逆向流程
1. **抓包**: mitmproxy / Wireshark
2. **分析**: Ghidra / IDA Pro
3. **Hook**: Frida
4. **验证**: 自定义客户端

### Android 应用逆向流程
1. **反编译**: JADX
2. **静态分析**: MobSF
3. **动态分析**: Frida + hooker
4. **脱壳**: Wallbreaker / dexcalibur
5. **协议分析**: mitmproxy + Frida

---

## 六、关键技能点

### 必学技术
- **汇编语言**: ARM/x86
- **加密算法**: AES/RSA/自定义加密
- **网络协议**: TCP/UDP/HTTP/WebSocket
- **逆向工具**: Ghidra/Frida/JADX
- **Hook 技术**: Frida/Xposed
- **协议分析**: Wireshark/mitmproxy

### 进阶方向
- **固件逆向**: IoT 设备、路由器
- **游戏逆向**: 反作弊、协议
- **支付逆向**: 支付宝/微信支付协议
- **社交逆向**: 微信/QQ/Telegram 协议

---

## 七、法律边界

⚠️ **重要提醒**:
- 仅用于学习研究
- 不用于非法用途
- 不破解商业软件
- 不窃取用户数据
- 遵守当地法律

---

## 八、相关技能（OpenClaw 已装）

- **bird**: Twitter/X 操作
- **peekaboo**: macOS UI 自动化
- **coding-agent**: 自动写代码
- **browser**: 浏览器自动化

---

整理时间：2026-03-19 08:35
