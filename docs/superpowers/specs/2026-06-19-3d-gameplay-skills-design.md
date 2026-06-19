# 套件 3D 玩法 skill 补全设计 — 填 F1/F5 盲区

- **日期**:2026-06-19
- **状态**:设计已过用户评审(5 补强点全部采纳 + 1 增量建议纳入),待写实施计划
- **背景**:dogfood ③④⑤(`demo/docs/03-production-log.md` F0–F16)暴露 F1(3D CharacterBody 移动无专门 NEVER)/F5(Area3D 收集无 3D 专门 skill)系统性盲区,核心规则锁 2D(`characterbody-2d`)需迁移
- **入口依据**:`demo/docs/03-production-log.md:11,28,92`(F1/F5/三大模式)、`enhanced/src/tools/load-skill-search.ts`(召回机制)、`demo/scenes/player.gd`+`collectible.gd`(实测验证的活教材)
- **路径约定**:本文档为仓库相对路径,仓库根 = `D:\GitHub\godot-ai-kit`

---

## 1. 目标与验收

**目标**:在套件粘合层(仓库根)新建 2 个 3D 玩法 skill,填 dogfood 实测暴露的 F1/F5 盲区;同步把套件 skills 目录接入 `load_skill` 召回链路,使未来 dogfood / 用户 3D 开发时能召回到这些知识。

**验收(主,§6 展开)**:真实 `load_skill` 显式传 `libraries=[三目录]` 召回,**同一 query 下新 skill score > 现有最优 skill score**(禁硬绑绝对值,会误判)。
**验收(辅)**:两个示例脚本 `run_and_verify` 实跑 `hasErrors:false`(boundaries #4 以实跑为准);`config/claude/settings.json` 模板改动后 `${REPO_ROOT}` 替换校验通过。

---

## 2. 定位与边界(双层 skill 架构)

### 2.1 架构变更:首次引入"套件原生 skills/"

仓库根目前**没有** `skills/` 目录,现有 skill 全在两个 submodule 内(`GodotPrompter/skills`、`gd-agentic-skills/skills`;enhanced 是工具不持有 skill)。本设计**首次在套件粘合层引入仓库根 `skills/`**,与这两个 submodule 的 skills 目录**三目录并列**,由 `load_skill` 统一召回。

为何放仓库根而非某 submodule:
- **gd-agentic-skills 是 LGPLv3 submodule(上游 thedivergentai/gd-agentic-skills),不可写**(CLAUDE.md 真聚合策略:绝不修改其源文件)。
- **GodotPrompter 是 submodule,非本套件自有**。
- **仓库根是套件 MIT 自有领土**,新增 skill 随套件 MIT,合规边界清晰(见 §7)。

### 2.2 与现有 3D 资产的边界:引用不重复

现有资产已覆盖"3D 物理通用"和"2D→3D 迁移",**不覆盖"3D 玩法实现细节"**——正是 F1/F5 盲区。新 skill 引用它们,不复述。

| 现有资产 | 已覆盖 | 新 skill 填的缺口 |
|---|---|---|
| `gd-agentic-skills/skills/godot-physics-3d` | RigidBody3D / 物理层 / 楼梯检测 / RayCast / ragdoll | — |
| `gd-agentic-skills/skills/godot-master/references/adapt-2d-to-3d.md` | 节点转换矩阵 / 迁移步骤 / 灯光相机迁移 | — |
| **新 `godot-characterbody-3d`** | — | CharacterBody3D 玩家控制器实现(相机相对移动 / 断反馈循环 / 水平面投影 / delta 归一 decel / WASD InputMap) |
| **新 `godot-area3d-collection`** | — | Area3D 收集交互(body_entered + 组优先判别 / signal 带 sender / 连接而非硬连) |

---

## 3. 目录结构

```
skills/
├── godot-characterbody-3d/
│   ├── SKILL.md
│   └── scripts/
│       └── camera_relative_movement.gd      ← 精简自 demo/scenes/player.gd
└── godot-area3d-collection/
    ├── SKILL.md
    └── scripts/
        └── pickup_trigger.gd                ← 精简自 demo/scenes/collectible.gd
```

---

## 4. 召回链路接入

### 4.1 改 config 模板

`config/claude/settings.json` 的 `GODOT_SKILL_LIBRARIES` 末尾追加 `,${REPO_ROOT}/skills`:

```json
"GODOT_SKILL_LIBRARIES": "${REPO_ROOT}/GodotPrompter/skills,${REPO_ROOT}/gd-agentic-skills/skills,${REPO_ROOT}/skills"
```

### 4.2 install 自检自动覆盖(无需改 install 逻辑)

`install.ps1` Step 5(`install.ps1:158-168`)的校验是 `$envResolved -split ','` 后 `foreach ($lib in $libs) { Test-Path }`,对 `GODOT_SKILL_LIBRARIES` 里**所有目录**生效。改 config 模板后,新 `${REPO_ROOT}/skills` **自动纳入校验**,无需动 install.ps1/install.sh 逻辑。

**软警告事实**(非阻塞):`install.ps1:165-167` 的 `Test-Path` 失败走 `Write-Host ... -ForegroundColor Yellow`(软警告),非 `Write-Fail`(硬退出)。若**先改 config 后建目录**,install 会打印一条无害黄色警告 `技能库路径不存在(可能子模块未就绪)`,不中断,照样走到 `Write-Ok`。非约束,正常实施顺序(先建目录后改 config)不会触发。

### 4.3 部署裂缝:本次不修,验收绕过

记忆 `dogfood-load-skill-link-status` 指出:当前机器实际生效的是全局 `~/.claude.json` 的 `godot` server(已配 `GODOT_SKILL_LIBRARIES` env),套件项目级 `.claude/settings.json`(server 名 `godot-mcp-enhanced`)未被 Claude Code 加载。故**改 config 模板只对新部署生效**;当前机器要让新 skill 立即召回,需手改全局 env。

**本次不修此裂缝**(独立已知问题,记忆已记,留后续任务)。§6 验收用 `load_skill` 显式传 `libraries` 参数**绕过**裂缝——不依赖任何 env 配置即可召回。

---

## 5. skill 内容结构(仿 `characterbody-2d` 格式)

每个 SKILL.md 结构:

1. **frontmatter**:`name` + `description`。description 里**塞 Trigger keywords**——这是高召回关键(`load-skill-search.ts` 对 description 命中给 0.6 分,详见 §6)。
2. **`## NEVER Do`**:从 demo 实测修复提炼的硬规则(下方逐条)。
3. **`## 2D→3D 迁移对照`**:精简差异表,**引用** `adapt-2d-to-3d.md` 不复述全表。
4. **`## 示例脚本`**:1 个(§8 来源)。
5. **`## Common Gotchas`**:F14(缺光)/F15(反馈循环)这类 **headless 测不出、只有真机才发现**的坑(呼应 boundaries #7)。
6. **`## Reference`**:指向 `adapt-2d-to-3d`、`physics-3d`、demo 实测日志。

### 5.1 `godot-characterbody-3d` 的 NEVER(提炼自 F14/F15/F16 + I1/I2)

- **NEVER 用移动方向乘自身 basis** — `look_at`/旋转改朝向会与 `transform.basis * input` 形成**反馈循环**(W 自洽、A/S/D 振荡闪烁,F15)。方向取**相机臂 basis**(`spring_arm.global_transform.basis`)。
- **NEVER 跳过水平面投影直接归一** — 方向向量须先 `direction.y = 0` 投影到水平面再 `normalized()`,否则相机俯仰时斜向加速。
- **NEVER 写帧率敏感的减速** — decel 必须 delta 归一(`var decel := SPEED * DECEL * delta`;I2),`move_toward(velocity.x, 0, decel)`。
- **NEVER 假设 WASD 默认绑定** — Godot 4 默认 InputMap **不绑 WASD**(只绑方向键 + 手柄),须在 `project.godot` `[input]` 段用 `physical_keycode` 显式定义 `move_forward/back/left/right`(F14 真因)。
- **NEVER 旋转 Player 根节点做相机跟随** — 鼠标 yaw/pitch 只旋转 `SpringArm3D`,Player 根与 mesh 不动,否则视角乱、二次切方向无效(F16)。

### 5.2 `godot-area3d-collection` 的 NEVER(提炼自 F5 + I3/C2)

- **NEVER 用硬类型判断识别收集者** — `if body is CharacterBody3D` 过窄(NPC/载具拿不到)。用**组优先** `body.is_in_group("player")`(I3)。
- **NEVER 发无参收集信号** — `signal collected` 无法区分多个收集物。带 `sender` 参数 `signal collected(sender: Node)`,主控用 Set/Dict 去重(C2)。
- **NEVER 硬连 `body_entered` 到外部方法** — 用 `body_entered.connect(_on_body_entered)`(节点生命周期安全,运行时动态实例可重连)。
- **NEVER 用 Area3D 做阻挡** — Area3D 只做检测。墙/屏障用 `StaticBody3D`(引用 `physics-3d`)。

---

## 6. 召回机制与验收

### 6.1 评分机制(精简,让验收不碰运气)

`load-skill-search.ts:45-60` 的 `scoreMatch`:query 拆 term 后,每个 term 在三处子串匹配取最高,再对 term **取平均**。

| 命中位置 | 分数 |
|---|---|
| `name`(`includes`) | 1.0 |
| `description` | 0.6 |
| `body` | 0.3 |

**连字符坑(关键)**:`includes` 是子串匹配。query term `characterbody3d`(无连字符)在 name `godot-characterbody-3d`(有连字符)中 **`includes` 失败** → name 1.0 吃不到。真正杠杆是 **description 里写无连字符类名 `CharacterBody3D`**(小写后含 `characterbody3d`,desc 命中 0.6)。

**0.633 拆解印证**(query2 `CharacterBody movement NEVER` 对 `characterbody-2d`):
- `characterbody` → name 含 → 1.0
- `movement` → desc 含 → 0.6
- `never` → body 含 NEVER → 0.3
- `(1.0+0.6+0.3)/3 = 0.633` ✓(与 dogfood 记录一致)

**命名/description 策略**:name 沿用 `godot-<topic>` 惯例(类名可读,跨 query 召回);description **必须**含 `CharacterBody3D` / `Area3D` / `movement` / `collectible` / `body_entered` / `pickup` 等无连字符词,让每个 query term 都吃到分。

### 6.2 验收(相对比较,禁硬绑绝对值)

**阈值**:同一 query 下,`load_skill` 召回的**新 skill score > 同 query 下现有最优 skill score**。**禁硬绑绝对值**(如 0.63)——会误判:新 skill 对 query1 实测约 0.6 < 0.63,却优于现状 characterbody-2d 的约 0.3。

**用真实 `load_skill`,显式传 libraries 绕过 §4.3 部署裂缝**:

| Case | query(与 dogfood 原始 query 同构) | 断言 |
|---|---|---|
| A | `CharacterBody3D movement NEVER` | 新 `godot-characterbody-3d` score > 现有 `godot-characterbody-2d` |
| B | `Area3D body_entered signal collectible pickup` | 新 `godot-area3d-collection` 是该 query 召回的**第一名**(> 现有最高分;production-log:28 现状为 `csharp-signals`/`godot-2d-physics` 等) |

实测参考(脚本预跑,权威以真实 load_skill 为准):query1 → 新 ≈0.6 vs 现有 characterbody-2d ≈0.3。

### 6.3 附录:verify_recall.mjs(机制活证据)

复现 `load-skill-search.ts` 评分逻辑的小脚本,读真实 `characterbody-2d/SKILL.md` 作现状基准。**逻辑复现,权威性次于真实 `load_skill`**(可能漂移),仅作连字符坑活证据 + 快速预验证。验收 Case A/B 以真实 `load_skill` 为准。

```javascript
// verify_recall.mjs — 复现 load-skill-search.ts:45-60 评分,验证召回分数(快速预验证,非权威)
import { readFileSync } from 'fs'

function parseSkill(content, fallbackName) {
  let name = fallbackName, description = '', body = content
  const fm = content.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n([\s\S]*)$/)
  if (fm) {
    const f = fm[1]; body = fm[2]
    const nm = f.match(/^name:\s*(.+)$/m); if (nm?.[1]) name = nm[1].trim()
    const dm = f.match(/^description:\s*(.+)$/m); if (dm?.[1]) description = dm[1].trim()
  }
  return { name, description, body }
}

function score(query, name, description, body) {
  const terms = query.toLowerCase().split(/\s+/).filter(Boolean)
  const n = name.toLowerCase(), d = description.toLowerCase(), b = body.toLowerCase()
  let total = 0
  for (const t of terms) {
    let s = 0
    if (n.includes(t)) s = Math.max(s, 1.0)
    if (d.includes(t)) s = Math.max(s, 0.6)
    if (b.includes(t)) s = Math.max(s, 0.3)
    total += s
  }
  return terms.length ? total / terms.length : 0
}

// 用法:node verify_recall.mjs <path-to-SKILL.md>(默认 characterbody-2d 作现状基准)
const path = process.argv[2] ?? 'gd-agentic-skills/skills/godot-characterbody-2d/SKILL.md'
const { name, description, body } = parseSkill(readFileSync(path, 'utf-8'), path)
console.log('#', name)
for (const q of [
  'CharacterBody3D movement NEVER',     // Case A:现状 characterbody-2d 此处低分(无 3d)
  'CharacterBody movement NEVER',       // 印证 0.633
  'Area3D body_entered signal collectible pickup',
]) console.log(q, '→', score(q, name, description, body).toFixed(3))
```

---

## 7. 合规与 attribution(MIT 套件 + LGPLv3 submodule)

**License 实情**(起草时读核):
- 套件根 `LICENSE` = **MIT**(Copyright 2026 wgt,套件粘合层自有)
- `gd-agentic-skills/LICENSE` = **LGPLv3**(submodule,上游 thedivergentai)

**新 skill 随套件 MIT**。与 LGPLv3 submodule 聚合时,延续 CLAUDE.md 真聚合策略(不改源 + 指针/索引引用)。

**attribution 二分策略**(对任何上游 license 稳健,此处 MIT+LGPLv3 更宽松):
- **引擎事实**(`move_and_slide` 内部处理 delta、`is_on_floor` 用法、`body_entered` 信号机制等 Godot API 事实)= **思想/事实,非版权表达**。自由迁移,加出处注释是好习惯(非强制)。
- **NEVER 文案措辞**(characterbody-2d 的 NEVER 文案)= **版权表达**。**重写不逐字复制**,规避 LGPLv3 衍生义务。本设计的 NEVER 条目均从 demo 实测修复(`player.gd`/`collectible.gd` 的 F14–F16/I1–I3/C2)提炼,**原创表述**,不复制上游文案。

**不动 gd-agentic-skills 源文件**:纯套件粘合层新建 `skills/`,不引入 LGPLv3 修改义务。

---

## 8. 示例脚本来源(复用 demo 活教材)

两个脚本精简自 demo 已验证代码(经 F14–F16 修复 + WASD 人工实测,是"活教材")。

### 8.1 `camera_relative_movement.gd` ← `demo/scenes/player.gd`

> **演进说明(消歧)**:`production-log:184` 记录的 F15 修复是**世界坐标**(`Vector3(input_dir.x, 0, input_dir.y)`,去 `transform.basis`)断反馈循环;`player.gd` 最终版在鼠标相机(2026-06-18)后**演进为相机臂 basis**(第三人称相对移动,更优)。本脚本取最终版——与 production-log 中间态的此落差是演进,非矛盾。

**保留三件套**(camera_relative 之名所系,不可砍):
- `spring_arm.global_transform.basis` 取向(相机相对移动的物理载体,F15 核心)
- `direction.y = 0` 水平面投影 + `normalized()`
- `SPEED * DECEL * delta` delta 归一 decel

**只省略**:`MOUSE_MODE_CAPTURED` / ESC 释放 / 点击重捕等输入 UX(与移动核心无关,放 Gotchas 提及)。

### 8.2 `pickup_trigger.gd` ← `demo/scenes/collectible.gd`

基本原样(`extends Area3D` + `signal collected(sender)` + `body_entered.connect` + `is_in_group("player")` + `queue_free`),加注释说明组优先(I3)/signal 带 sender(C2)的设计理由。

---

## 9. 范围外(YAGNI,均留后续)

- **部署裂缝修复**(§4.3,项目级 settings.json 未被加载):独立任务,记忆已记。
- **3D 第三人称相机完整系统**(鼠标自由旋转/碰撞回弹/距离自适应):F16 已修最小跟随,用户 2026-06-18 决策"完整打磨留 v1"。
- **更多 3D 玩法 skill**(3D 输入映射/3D 碰撞交互/3D 动画等):超出 dogfood 已暴露盲区,按需再补。
- **dogfood 复测**(用新 skill 重跑 ③ 生产):可选验证,非本设计交付物。

---

## 10. 衔接

- **上游**:`demo/docs/03-production-log.md` F1/F5(盲区来源)、`docs/enhanced-boundaries.md`(降级语境)
- **下游**:本 spec 批准后 → `superpowers:writing-plans` 生成实施计划(建目录/写 SKILL.md/写脚本/改 config/验收)
- **关联记忆**:`dogfood-enhanced-tool-cracks`(三大模式)、`dogfood-load-skill-link-status`(召回链路/部署裂缝)
