# gd-agentic 处置 spec — 方案 X 确认与 Phase 1/Phase 2 路线

- **日期**:2026-06-19
- **状态**:决策已拍板(方案 X / A 路线);**spec 已过用户评审(2026-06-19),3 取舍已定**,Phase 1 待新 session 进 plan,Phase 2 为路线
- **背景**:2026-06-19 重提"fork gd-agentic + 改源修 6 CRITICAL"设计,经评审判定与同日已否决的"去子模块化 C 类"合规同源(fork 改源 = LGPLv3 §5 修改义务 = 推翻 NOTICE 聚合豁免)。确认延续方案 X(spec `6e9fb4b`)= A 路线。本 spec 固化处置框架。
- **入口依据**:
  - 决策溯源:`D:\workspace\Obsidian\godot-ai-kit\开发日志\2026-06-19 去子模块化提案审查否决.md`、`D:\workspace\Obsidian\godot-ai-kit\开发日志\2026-06-19 gd-agentic fork案评审与方案X确认.md`
  - 6 CRITICAL 清单:`D:\workspace\review\.claude\reviews\2026-06-19-godot-ai-kit-comprehensive-review.md:194-199`、完整 `D:\workspace\review\.claude\reviews\2026-06-19-godot-ai-kit-skills-scripts-review.md`
  - 现有警示:`docs/enhanced-boundaries.md:188-194`(#12)、`README.md:5-6`
  - 方案 X 架构:`docs/superpowers/specs/2026-06-19-3d-gameplay-skills-design.md`(§2.1 套件根 skills/ 原创)
- **路径约定**:正文用仓库相对路径(仓库根 = `D:\GitHub\godot-ai-kit`);审查/日志用绝对路径

---

## 1. 目标与验收

**目标**:在不动 gd-agentic 源码(LGPLv3 真聚合)前提下,把 gd-agentic 6 CRITICAL 的传导风险降到可接受,并为长期源头解决(套件根 `skills/` 原创替代)铺路。

**验收**:
- **Phase 1**:① `README.md` 入口警示同时覆盖"实验性/API 变"+"6 CRITICAL 复制前必审"且指向 #12;② 产出 gd-agentic skill 召回频率初表(基于 dogfood 日志盘点);③ 复核 #12 已覆盖 C1 安全标注(现状已覆盖)。
- **Phase 2**:每个原创 skill 满足方案 X 双层架构 + clean room;原创覆盖某 gd-agentic skill 场景后,套件停止召回 gd-agentic 该 skill(退役触发)。

---

## 2. 决策溯源(为何 A 不是 B)

| 路线 | 合规 | 结论 |
|---|---|---|
| **A 方案 X**(聚合豁免,不碰源) | LGPLv3 真聚合,无修改义务 | ✅ 定案(spec `6e9fb4b`) |
| B fork 改源修 6 CRITICAL | fork 改源 = LGPLv3 §5 修改义务 = 推翻 `NOTICE:10-15` 聚合豁免论证 | ❌ 与 06-19 否决的 C 类(clean room 内化)合规同源,关闭 |

B 的 5 个技术问题(与 NOTICE 互斥 / 漏列 C3·C5 / C1 HMAC theater / 双轨 PR / submodule 脚注)详见 fork 评审日志。**核心根因**:错误套用 enhanced 模式——enhanced 是自有 MIT 仓库(fork 改源无义务),gd-agentic 是他人 LGPLv3。C1 的 HMAC 完整性校验是 security theater(客户端密钥必然可逆,单机存档无服务端校验场景)。

---

## 3. 现状盘点(Phase 1 起点)

| 项 | 现状 | 缺口 |
|---|---|---|
| #12 警示 | `enhanced-boundaries.md:188-194` 已写全:点出 6 CRITICAL、C1 密钥硬编码 `secure_mobile_key_123!`、"复制前必审"、指向完整审查报告、可报上游 issue | 无(C1 安全标注已覆盖) |
| README 入口 | `README.md:5-6` 仅"实验性子模块 / API 可能变" | 未提 6 CRITICAL、未指向 #12 |
| load_skill 工具层 | 召回不附 warning,纯靠文档警示 | 待增强(见 §4.3,评审定为倾向必做) |
| 召回频率 | 无计数机制 | Phase 2 排期缺数据(见 §4.2) |
| 套件根 `skills/` 原创 | `godot-characterbody-3d` / `godot-area3d-collection` 已落地(3d-gameplay spec) | Phase 2 扩展对象待排期 |

**结论**:Phase 1 实质工作——#12 警示已做透,Phase 1 = "README 入口收口 + 排期数据采集 + 工具层 warning 增强"。

---

## 4. Phase 1:减险收口 + 排期前置

### 4.1 README 入口警示补强(必做,小改)

**文件**:`D:\GitHub\godot-ai-kit\README.md:5-6`(现有 `> [!warning]` callout)

**改动**:现有 callout(只说"实验性/API 变")补第二层——明确 gd-agentic 技能库 2026-06-19 深审含 6 CRITICAL(含硬编码密钥),`load_skill` 召回的 scripts 复制到生产前必须人工审,详见 `docs/enhanced-boundaries.md` #12。

**验收**:README warning 同时覆盖两层(实验性 + 6 CRITICAL 必审);含 #12 锚点跳转。

### 4.2 召回频率初表(必做,Phase 2 排期依据)

**做法**:盘点 dogfood 历史召回——读 `demo/docs/` 各 production-log + enhanced-boundaries 引用记录,人工统计 gd-agentic 各 skill 被 load_skill 召回的次数,产出"频率初表"。

**产出文件**:`docs/gd-agentic-recall-frequency.md`(套件仓库内,git 跟踪、发版后他人/AI session 可见;标"基于 dogfood 日志初表,待迭代")。Obsidian 仅放个人分析笔记,初表主体进仓库。

**验收**:初表覆盖 gd-agentic 全部 skill,标注含 CRITICAL 的(godot-adapt-desktop-to-mobile 含 C1/C2/C3、godot-3d-lighting 含 C4/C5、godot-3d-materials 含 C6);给出 Phase 2 首批原创候选排序。

**若数据不足**:Phase 1 末评估是否上 enhanced load_skill 计数(改 `enhanced/src/tools/load-skill-search.ts`,轻量 log 召回 skill 名)。

### 4.3 load_skill 工具层 warning(评审定:倾向必做)

**触发条件**:Phase 1 末强评估——**默认倾向必做**(6 CRITICAL 含安全风险,文档警示靠纪律 AI 可能不看,工具层 warning 是召回时即时源头减险更强)——除非 §4.2 频率显示 CRITICAL skill 极低召回。

**落点**:`enhanced/src/tools/load-skill-search.ts` 召回结果输出处 + 套件 docs/ 维护"CRITICAL 脚本路径清单"(6 CRITICAL 脚本路径)。命中清单时,返回内容末尾附 warning block。

**合规**:改的是 enhanced(自有 MIT)、在召回结果末尾附 block、**措辞描述风险不复制 gd-agentic 源码片段**——不触发 LGPLv3 义务,与 §6 一致。

**验收**:load_skill 召回 `offline_save_sync.gd` 等含 CRITICAL 脚本时,结果含 warning;召回升阶 skill 不附。

---

## 5. Phase 2:原创替代路线(长期,逐 skill spec)

### 5.1 排序维度

Phase 2 按以下维度排原创优先级(每个 skill 独立 spec→plan):
1. **召回频率**(Phase 1 初表):高频先用上 → 减险收益最大
2. **CRITICAL 集中度**:`godot-adapt-desktop-to-mobile`(C1/C2/C3 三连)最高,强首批候选
3. **dogfood 盲区价值**:填实测暴露的系统性缺口(如 3d-gameplay spec 填 F1/F5)

### 5.2 clean room 原则(继承 3d-gameplay spec §2 + §7 attribution 二分)

- 套件根 `skills/` 原创内容随套件 MIT
- **不逐字复制** gd-agentic 源文(单人看过原文 ≠ clean room,SSO 派生风险,06-19 否决教训)
- 从 dogfood 实测代码提炼(如 3d-gameplay 从 `demo/scenes/player.gd` 精简)
- 事实性引擎 API 用法迁移加出处注释;文案(NEVER 措辞)原创重写

### 5.3 退役触发(评审定:前置套件 skills/)

套件根原创覆盖某 gd-agentic skill 场景后 → load_skill 命中优先返回套件原创版 → 套件停止依赖 gd-agentic 该 skill。

**机制(plan 定)**:**前置套件 `skills/`** 于 `config/claude/settings.json` 的 `GODOT_SKILL_LIBRARIES`(现列末尾)。基于 `load-skill-search.ts` 跨 lib 合并后 sort by score、同 score 时 JS stable sort 保留 lib 遍历顺序——前置让套件原创在 tie-break 时先于 gd-agentic/GodotPrompter。套件仅 2 skill 主题窄,前置不过度召回;比 name/desc 杠杆可靠(后者依赖每个 skill 写作质量)。

**plan 实现时读 `load-skill-search.ts` 验证 stable-sort 假设**——若有其他 tie-break 键则调整机制。

**终态**:有价值 gd-agentic skill 全被原创替代 → 评估 gd-agentic submodule 是否可移除(届时另开 spec,非本 spec 范围)。

---

## 6. 合规边界(不变)

- `NOTICE:10-15` 聚合豁免论证不动
- 不 fork、不改 gd-agentic 源码、不做 clean room 内化
- Phase 1/2 全程不触发 LGPLv3 §5 修改义务
- 套件根 `skills/` 原创 = MIT,与 gd-agentic LGPLv3 submodule 并列(三目录:GodotPrompter / gd-agentic / 套件根)

---

## 7. 不做的事(防 scope creep)

- ❌ fork gd-agentic(合规同源于已否决 C 类)
- ❌ 改 gd-agentic 源码修 6 CRITICAL(LGPLv3 修改义务)
- ❌ clean room 内化(单人 clean room 不成立)
- ❌ C1 HMAC 完整性校验(security theater)
- ❌ 批量原创重写(逐 skill 独立 spec,按 §5.1 排序)

**若后续有人提议动 gd-agentic 源码** → 引本 spec §2 + 06-19 否决记录,合规同源关闭,不再重议。

---

## 8. 下一步

- **Phase 1**(§4.1 + §4.2 + §4.3)→ spec 已评审通过(2026-06-19),3 取舍已定(§4.2 产出进 `docs/`、§4.3 工具层 warning 倾向必做、§5.3 前置套件 `skills/`),**新 session 进 plan**
- **Phase 2** → 按 §5.1 排序,首个原创 skill 独立 spec(强候选:`godot-adapt-desktop-to-mobile`,C1/C2/C3 集中)
- plan / 执行新 session(本会话已长,cost critical)
