# gd-agentic Phase 1 减险收口 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: 用 superpowers:subagent-driven-development 或 executing-plans 逐 task 执行。步骤用 checkbox(`- [ ]`)跟踪。

**Goal:** gd-agentic 6 CRITICAL 传导风险收口(README 入口警示 + 召回频率盘点 + enhanced 工具层 warning 需求),为 Phase 2 原创替代铺路。**不改 gd-agentic 源**(LGPLv3 真聚合)。

**Architecture:** 套件层 README/enhanced-boundaries 警示补强 + 产出召回频率初表(Phase 2 排期依据) + enhanced `load-skill-search.ts` 工具层 warning(enhanced-workflow,提需求你改)。全不碰 gd-agentic 源码。

**Tech Stack:** Markdown(README/docs)、enhanced TypeScript(load-skill-search.ts,仅提需求)。

**Spec:** `docs/superpowers/specs/2026-06-19-gd-agentic-disposal-design.md`(§4 Phase 1)

## Global Constraints

- **绝不改 gd-agentic 源码**(LGPLv3 真聚合,NOTICE:10-15 豁免不动)
- **enhanced 改动走 enhanced-workflow**:提需求,你在 `D:/GitHub/godot-mcp-enhanced` 改;push 决策权在你
- **git**:`"C:/Program Files/Git/cmd/git.exe" -C "D:/GitHub/godot-ai-kit" ...`(Bash 沙箱 PATH 缺 git);commit message 末尾 `Co-Authored-By: Claude <noreply@anthropic.com>`
- **6 CRITICAL 清单**:C1 `offline_save_sync.gd` 硬编码密钥 / C2 移动端缺 InputEventMouseButton / C3 `touch_camera_pan_zoom` 非等比缩放 / C4 `fake_gi_bounce` 光泄漏 / C5 `light_lod_optimizer` visible vs fade / C6 `transparency_sorting_fix` 未判 null(详见 `docs/enhanced-boundaries.md` #12)

---

### Task 1: README 入口警示补强(spec §4.1)

**Files:**
- Modify: `README.md:5-6`(现有 `[!warning]` callout)

**Interfaces:** 无(独立文档改)

- [ ] **Step 1: Edit README callout 补第二层**

现有 `README.md:5-6`:
```
> [!warning] gd-agentic-skills 为实验性子模块(v0.0.6 预发布,API 可能变)
> 本套件对其仅做指针/索引引用(LGPLv3 真聚合,不修改其源文件)。深度调用其蓝图/技能可能在后续版本失效,详见 `docs/compatibility-matrix.md`。
```

改为(在第二行后补第三行警示):
```
> [!warning] gd-agentic-skills 为实验性子模块(v0.0.6 预发布,API 可能变)
> 本套件对其仅做指针/索引引用(LGPLv3 真聚合,不修改其源文件)。深度调用其蓝图/技能可能在后续版本失效,详见 `docs/compatibility-matrix.md`。
> **另**:2026-06-19 深审发现技能库 **6 CRITICAL**(含 `offline_save_sync.gd` 硬编码密钥)。`load_skill` 召回的 scripts 是**参考代码,复制到生产前必须人工审**,详见 `docs/enhanced-boundaries.md` #12。
```

- [ ] **Step 2: 验证两层覆盖 + #12 锚点**

读 `README.md:5-7` 确认:callout 同时覆盖"实验性/API 变"(原)+ "6 CRITICAL 必审"(新)+ 含 `docs/enhanced-boundaries.md` #12 指向。

- [ ] **Step 3: Commit**

```bash
"C:/Program Files/Git/cmd/git.exe" -C "D:/GitHub/godot-ai-kit" add README.md
"C:/Program Files/Git/cmd/git.exe" -C "D:/GitHub/godot-ai-kit" commit -m "docs(readme): 补 gd-agentic 6 CRITICAL 警示 + #12 指向" -m "Phase 1 §4.1:README warning 补第二层(参考代码复制前必审)。spec 2026-06-19-gd-agentic-disposal §4.1。" -m "Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 2: 召回频率初表(spec §4.2,Phase 2 排期依据)

**Files:**
- Create: `docs/gd-agentic-recall-frequency.md`

**Interfaces:**
- Produces: gd-agentic 各 skill 召回频率排序 → Phase 2 首批原创候选(强候选 `godot-adapt-desktop-to-mobile`,C1/C2/C3 集中)

- [ ] **Step 1: 盘点 dogfood 召回记录**

读以下 dogfood 日志,提取所有 `load_skill` 召回 gd-agentic skill 的记录(query + 召回 skill + score):
- `demo/docs/03-production-log.md`(F1/F5 召回:T2 知识采集 query1/query2 + collectible query)
- `docs/enhanced-boundaries.md`(#12 引用审查报告)
- `D:\workspace\Obsidian\godot-ai-kit\开发日志\` 各 2026-06-17/18/19 日志(若有额外 load_skill 召回记录)

**统计方法**:每个 gd-agentic skill 计被召回次数(同 skill 多 query 多次计)。标注含 CRITICAL 的(`godot-adapt-desktop-to-mobile` 含 C1/C2/C3、`godot-3d-lighting` 含 C4、`godot-3d-materials` 含 C5/C6 —— 核 `D:\workspace\review\.claude\reviews\2026-06-19-godot-ai-kit-skills-scripts-review.md` 确认 CRITICAL 脚本所属 skill)。

- [ ] **Step 2: 写频率初表**

Create `docs/gd-agentic-recall-frequency.md`:

```markdown
# gd-agentic skill 召回频率初表(Phase 2 排期依据)

> 数据源:dogfood 日志(demo/docs/03-production-log + enhanced-boundaries #12 + Obsidian 开发日志)的 load_skill 召回记录。
> 性质:**初表**(基于历史 dogfood,非全量统计),Phase 2 排期参考,待迭代。

## 频率排序(召回次数降序)

| gd-agentic skill | 召回次数 | 含 CRITICAL | 备注 |
|---|---|---|---|
| <skill-name> | <N> | C1/C2/C3 等 / 无 | <dogfood 场景> |
| ... | | | |

## Phase 2 首批原创候选(按频率 × CRITICAL 集中度)

1. **<首选>**(高频 + CRITICAL 集中)
2. ...

## 数据不足说明

若 dogfood 日志召回记录不足以覆盖 gd-agentic 全 skill,标注"数据不足",Phase 1 末评估是否上 enhanced load_skill 计数(spec §4.2 fallback)。
```

填实际统计数据(Step 1 盘点结果)。**若数据不足**(dogfood 只覆盖少数 skill),如实标注 + 列已知召回 + 标"Phase 1 末评估 enhanced 计数"。

- [ ] **Step 3: 验证初表完整**

读 `docs/gd-agentic-recall-frequency.md` 确认:覆盖已知召回 skill + 标注含 CRITICAL 的 + Phase 2 首批候选排序 + 数据不足说明(如适用)。

- [ ] **Step 4: Commit**

```bash
"C:/Program Files/Git/cmd/git.exe" -C "D:/GitHub/godot-ai-kit" add docs/gd-agentic-recall-frequency.md
"C:/Program Files/Git/cmd/git.exe" -C "D:/GitHub/godot-ai-kit" commit -m "docs: gd-agentic 召回频率初表(Phase 2 排期依据)" -m "Phase 1 §4.2:盘点 dogfood load_skill 召回记录,产出频率初表 + Phase 2 首批候选。spec §4.2。" -m "Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 3: enhanced 工具层 warning 需求清单(spec §4.3,enhanced-workflow)

**Files:**
- Create: `docs/enhanced-load-skill-warning-requirement.md`(套件侧需求文档,提给 enhanced)

**Interfaces:**
- Produces: enhanced `load-skill-search.ts` warning 需求(你在 `D:/GitHub/godot-mcp-enhanced` 改)

- [ ] **Step 1: 确认 load-skill-search.ts warning 落点**

读 `enhanced/src/tools/load-skill-search.ts:110-134`(`searchSkills` 返回 matches 处)。warning 落点:每个 match 若 path 命中"CRITICAL 脚本清单",在该 match 的 snippet/description 后附 warning block(不改 gd-agentic 源,纯 enhanced MIT 行为)。

- [ ] **Step 2: 整理 CRITICAL 脚本路径清单**

从 `D:\workspace\review\.claude\reviews\2026-06-19-godot-ai-kit-skills-scripts-review.md` 提取 6 CRITICAL 脚本的仓库相对路径:
- C1 `gd-agentic-skills/skills/godot-adapt-desktop-to-mobile/scripts/offline_save_sync.gd`
- C2 <3 个移动端脚本,核审查报告>(`_mobile_` 或 InputEventMouseButton 相关)
- C3 `touch_camera_pan_zoom.gd`
- C4 `fake_gi_bounce.gd`
- C5 `light_lod_optimizer.gd`
- C6 `transparency_sorting_fix.gd`

**注**:C2/C3/C5 的所属 skill 目录要核审查报告确认(审查报告:194-199)。

- [ ] **Step 3: 写 enhanced 需求清单**

Create `docs/enhanced-load-skill-warning-requirement.md`:

```markdown
# enhanced load_skill 工具层 warning 需求(提给 enhanced)

> 来源:gd-agentic disposal spec §4.3。enhanced-workflow:此为套件侧**需求**,enhanced 实现在 `D:/GitHub/godot-mcp-enhanced`。

## 需求

`load_skill`(enhanced/src/tools/load-skill-search.ts)召回结果,若 match 的 path 命中下方"CRITICAL 脚本清单",在该 match 返回内容末尾附 warning block:

\`\`\`
⚠️ 参考代码含已知 CRITICAL(<C 编号 + 一句话>),复制到生产前必须人工审。详见 godot-ai-kit docs/enhanced-boundaries.md #12。
\`\`\`

不改 gd-agentic 源(纯 enhanced MIT 行为)。命中的 match 才附,不命中不附。

## CRITICAL 脚本清单(6)

| C# | 脚本路径(gd-agentic-skills/ 内) | 一句话 |
|---|---|---|
| C1 | skills/godot-adapt-desktop-to-mobile/scripts/offline_save_sync.gd | 硬编码密钥 secure_mobile_key_123! + 无校验 |
| C2 | <移动端脚本,核审查报告> | 缺 InputEventMouseButton 分支 |
| C3 | <touch_camera_pan_zoom.gd 路径> | 非等比缩放 |
| C4 | <fake_gi_bounce.gd 路径> | 动态光泄漏 |
| C5 | <light_lod_optimizer.gd 路径> | visible 硬切换 vs distance_fade |
| C6 | <transparency_sorting_fix.gd 路径> | 未判 null 必崩 |

## 验收

load_skill 召回 `offline_save_sync.gd` 等含 CRITICAL 脚本 → 结果含 warning;召回升阶 skill 不附。

## 落点参考

load-skill-search.ts:110-134 searchSkills 返回处;CRITICAL 清单维护在套件 docs/(本文件),enhanced 读套件配置或硬编清单(plan 执行时定)。
```

填实际 CRITICAL 脚本路径(Step 2 核实结果)。

- [ ] **Step 4: Commit(套件侧需求文档)**

```bash
"C:/Program Files/Git/cmd/git.exe" -C "D:/GitHub/godot-ai-kit" add docs/enhanced-load-skill-warning-requirement.md
"C:/Program Files/Git/cmd/git.exe" -C "D:/GitHub/godot-ai-kit" commit -m "docs: enhanced load_skill warning 需求(Phase 1 §4.3)" -m "Phase 1 §4.3:套件侧需求文档(enhanced-workflow),含 6 CRITICAL 脚本清单 + warning 落点。enhanced 实现留你本地改。spec §4.3。" -m "Co-Authored-By: Claude <noreply@anthropic.com>"
```

**enhanced 实现**(Task 3 之外,enhanced-workflow):你在 `D:/GitHub/godot-mcp-enhanced` 按 `docs/enhanced-load-skill-warning-requirement.md` 改 `load-skill-search.ts`。push 决策权在你(不擅自)。

---

## 验收总门(Phase 1)

- `README.md:5-7` callout 两层覆盖(实验性 + 6 CRITICAL 必审)+ #12 指向
- `docs/gd-agentic-recall-frequency.md` 存在(频率初表 + Phase 2 候选,或数据不足标注)
- `docs/enhanced-load-skill-warning-requirement.md` 存在(6 CRITICAL 清单 + warning 落点,提给 enhanced)
- 全程未改 `gd-agentic-skills/` 源(`git diff` 确认 submodule 无改动)
- 3 个 commit(均带 Co-Authored-By)

## 后续(Phase 1 外)

- enhanced 实现 warning(你在 enhanced 改)+ 套件 pin bump(enhanced 发布批次时)
- Phase 2:首个原创 skill spec(强候选 `godot-adapt-desktop-to-mobile`,C1/C2/C3 集中)
