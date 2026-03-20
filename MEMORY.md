# MEMORY.md - 狗狗军师长期记忆
> 此文件由 data/sync_memory.sh 自动同步
> 固定内容写在 ===DYNAMIC=== 上方，不会被覆盖
> 动态数据从SQLite同步

### 核心身份
- 我是狗狗军师，seven老师的私人军师
- 定位：全领域智囊 + 执行顾问
- 核心能力：决策判断、方案设计、任务分配、结果分析

### 交互规则
- 收到消息先👀确认
- 先结论再原因，不超300字
- 不确定打问号，不瞎编
- 群聊被@才开口
- 不泄露seven老师隐私
- 所有重要上下文必须实时存入SQLite数据库（data/memory.db）
- 不记得就去查数据库（query.sh），不主动恢复上下文避免卡顿
- 保证核心不丢，需要时查询即可

### 技术栈
- OpenClaw + Telegram + 飞书 + GLM-5-Turbo
- SQLite记忆数据库（data/memory.db）
- 浏览器自动化、GitHub、定时任务
- Claude Code（备用编程工具）
- 阿里云服务器：47.237.85.150（朋友/团队机器人用）

### 待办
- 买中转API key后配入OpenClaw（models.providers方案已研究完毕）
- 多设备互通方案待seven老师确认具体需求

===DYNAMIC===
### 最近更新
- [技术] 支付宝SDK PayTask.orderInfo完整字段: orderInfo是key=value&拼接字符串，核心字段：app_id(商户APPID)、method=alipay.trade.app.pay(接口名)、... (阿里云开发者社区+CSDN) [https://developer.aliyun.com/article/316048]
- [技术] 支付宝scheme协议关键格式: 转账到支付宝PID：alipays://platformapi/startapp?appId=20000067&url=encode(alipays://pla... (GitHub Gist+tankphper) [https://gist.github.com/tankphper/2cf5d8e36db38d5d5e81c86f10d7ed1d]
- [技术] 微信支付Intent参数解析: 闲鱼→微信支付Intent包含：_wxapi_payreq_appid(商户ID)、_wxapi_payreq_partnerid(商户号)、_wxapi_pa... (自主分析+logcat抓取)
- [技术] Android不hook不root抓支付链接方案: 方案1：adb logcat过滤(已验证可行)，抓Intent中的scheme链接。方案2：无障碍服务(AccessibilityService)，独立app全... (自主分析)
- [技术] 免root Xposed框架现状2026: LSPatch已停更(2023.12)。替代品：ONPatch(OPatch魔改版，去原神启动动画，不用锁后台不用Shizuku)、NPatch(LSPatch... (GitHub+酷安+cnblogs)
- [技术] Android支付SDK核心Hook点: 支付宝SDK：PayTask.payV2(String orderInfo, boolean showLoading)是最底层入口，orderInfo含app_... (自主调研+阿里云开发者社区)
- [技术] Android支付协议抓取方案完整调研: 目标：抓取alipays://支付协议链接用于代付。已验证：logcat可抓到Intent跳转（含微信支付参数）。关键发现：1)闲鱼调起支付走Intent，包含... (自主调研)
- [技术] 定时任务配置: 两个cron：1.SQLite记忆同步(每6小时)→运行sync_memory.sh同步DB到MEMORY.md 2.git-auto-push(每小时)→检查... (狗狗军师)
- [技术] 记忆系统架构: 三层结构：1.SQLite数据库(data/memory.db)存储知识/案例/法律/人脉/项目 2.sync_memory.sh每6小时同步DB→MEMORY... (狗狗军师)
- [法律] GEO投毒法律定性分析: 君合律所沈程：1.GEO投喂不实内容致AI输出误导→消费者保护责任或侵权责任。2.AI平台默许语料污染→消费者保护/合同/侵权三重责任。3.GEO公司可能构成不... (21世纪经济报道+君合律所) [https://finance.sina.com.cn/roll/2026-03-18/doc-inhrizny1753580.shtml]
- [技术] OpenClaw最佳实践2026: 核心配置：AGENTS.md工作规范+MEMORY.md记忆优化+子Agent团队协作+Cron定时任务+Skill技能扩展。最佳组合：OpenClaw管数字生... (博客园+知乎+美团技术) [https://www.cnblogs.com/nf01/p/19645571]
- [赚钱路径] 2026年AI赚钱5大核心场景: 1.AI+消费电子硬件(智能眼镜等依托中国供应链)。2.AI出海(海外付费习惯好)。3.细分领域AI Agent(落地性强)。4.百度秒哒无代码平台(累计50万... (铅笔新闻+新浪科技) [https://m.pencilnews.cn/p/46617.html]
- [赚钱路径] 2026年普通人AI赚钱12条路径: 零门槛：AI数据标注(15-50元/时，百度众包/京东众智)、AI语音转写(10-30元/小时音频)、AI图文排版(单篇20-100元)、AI应用测试(单次5-... (搜狐+国务院数字经济促进法) [https://www.sohu.com/a/984359430_100050143]
- [风控] 支付新规2026年2月实施: 央行修订《非银行支付机构分类评级管理办法》2026年2月1日起实施。核心：差异化监管、穿透式评级、压实机构与个人双重责任。重点关注：反洗钱、交易真实性、商户准入... (央行+移动支付网) [https://m.mpaypass.com.cn/news/202512/31175803.html]
- [风控] 2026年支付行业监管最新动态: 2026年开年14家支付机构罚没8674万元。开联通支付单家罚没3843万元创年内新高，银盛支付罚没1584万元。双罚制全面覆盖：8家机构11名负责人被追责，个... (21世纪经济报道+界面新闻+新浪财经) [https://www.21jingji.com/article/20260319/herald/6d03e025db2cd9814784cccfc7e383e8.html]
- [灰产生态] 代理退保黑灰产最新案例: 2026年1月金融监管总局公安部联合发布第二批典型案例。以全额退保维权为幌子，通过恶意信访投诉、虚假陈述牟取高额佣金。第一步非法获取公民个人信息作为精准客源。法... (建设银行+金融监管总局) [https://www.ccb.com/chn/2026-01/27/article_2026012709053634877.shtml]
- [灰产生态] AI网文自动化产业链: 唐库平台宣称48小时生成500万字长篇小说，全自动AI写作。产业链：技术平台开发(如唐库)→分发到番茄小说等平台→靠量取胜。真实收益：平台签约作者客单价几百到几... (中国新闻周刊) [http://www.inewsweek.cn/finance/2026-03-10/29228.shtml]
- [灰产生态] GEO投毒灰产链完整揭秘: 315晚会曝光：GEO服务商通过自媒体批量发布软文投喂AI大模型，操纵搜索结果。操作手法：1.关键词挖掘 2.生成结构化内容(结论前置、分点逻辑、引用权威) 3... (央视315+21世纪经济报道+新浪财经) [https://finance.sina.com.cn/roll/2026-03-18/doc-inhrizny1753580.shtml]
- [技术] 第三方API聚合服务商: poloapi：超低折扣，1元=1美元汇率，比市场价省85%。OpenRouter：30+模型一个入口，支持免费层。各家中转站普遍提供GPT/Claude/Ge... (百度千帆社区+新浪财经 2026.1)
- [技术] 免费大模型API汇总2026: Google Gemini AI Studio：旗舰级模型免费调用，2026性价比最高免费API。OpenRouter：30+免费模型无需绑卡。GLM-4-Fl... (知乎+腾讯云+网易 2026.3)

### 数据统计
- 知识: 65
- 案例: 11
- 法律: 5
- 人脉: 0
- 项目: 0
- 详细查询: `data/query.sh <关键词>`

> 同步: 2026-03-20 06:23:25 PDT | 源: data/memory.db
