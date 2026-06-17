# dogfood:套件 5 阶段工作流端到端验证设计 — 3D 收集小 Demo

- **日期**:2026-06-17
- **状态**:待最终审查(已过独立 reviewer 一轮:3 IMPORTANT + 4 ADVISORY,处置见 §7)
- **执行策略**:双轨对照(workflow 文档轨 ↔ load_skill / enhanced 工具轨,偏差记为裂缝)
- **入口依据**:`demo/scenes/player.gd` 占位注释明指"③ 生产阶段(godot-ai-kit v1)替换为完整角色控制(移动/跳跃/相机旋转/收集物)"

---

## 1. 目标与验收

**目标**:用套件自身 5 阶段工作流,把 demo 的占位 `player.gd` 填成最小可玩 3D 收集小 Demo;同时以 `workflow/*.md` 为基准逐阶段跑,把"文档写的 vs 实际能用的"偏差记为裂缝,产出套件改进输入。

**验收(三条全过)**:
1. **5 阶段每阶段真跑**:`load_skill` 命中知识 + 对应 enhanced 工具动手 + 验证门禁贴结果(`validate_gdd` / `read_scene` / `run_and_verify` / `profiler` / `verify_delivery`)
2. **demo 可跑可玩**:`godot --path demo scenes/Main.tscn` 启动后,角色 WASD 移动 / Space 跳跃 / 相机跟随 / 碰收集物计分 / 集齐过关
3. **产出裂缝清单**:每阶段执行文档结尾有 §裂缝记录小节,带严重度

---

## 1.5 与①②产出的衔接(dogfood 从③继续)

**①②已完成**(commit `a4c0c59`),产出:
- `demo/docs/01-concept-gdd.md`:Crystal Collector,MVP=移动+拾取信号(明示"不要求可玩"),跳跃/计分/过关标 v1
- `demo/docs/02-architecture-adr.md`:ADR-001 场景拆分(MVP 单 Main 内嵌 / v1 拆分)、ADR-002 autoload(MVP 无 / v1 ScoreManager)、ADR-003 信号(collected→Game→HUD)
- `demo/scenes/player.tscn`(手写骨架)+ `player.gd`(占位)

**dogfood 从③继续**;①②的 enhanced 工具轨当时为模拟/手写(validate_gdd 模拟、read_scene 未跑)。本会话已补 `read_scene` 真跑(验证点②过);`validate_gdd` 在③前补真调。

**范围决策(用户 2026-06-17 拍板:升级到可玩闭环)**:dogfood ③范围 = 原 GDD MVP(移动+拾取)+ 拉入 v1 项(跳跃/计分/集齐过关),达到"最小可玩"。此扩展超出原 GDD MVP 边界 → ③须**同步更新 01-gdd/02-adr 记录范围变更**(把跳跃/计分/过关从 v1 提到 dogfood 范围),保持文档诚实。场景拆分采用 ADR-001 的 **v1 策略**(独立 collectible.tscn)。

---

## 2. demo 技术设计(块 A,已确认)

### 2.1 场景结构

| 文件 | 状态 | 结构 |
|------|------|------|
| `scenes/player.tscn` | 已有骨架 | CharacterBody3D + Mesh(CapsuleMesh)+ Collision(CapsuleShape3D)+ SpringArm3D → Camera3D;补 `player.gd` |
| `scenes/collectible.tscn` | 新建 | Area3D + Mesh(小球)+ CollisionShape3D + `collectible.gd`;`body_entered` → 发 `collected` 信号 → `queue_free()` |
| `scenes/Main.tscn` | 新建(CLAUDE.md 已指向为入口) | Node3D + Player 实例 + Ground(StaticBody3D+大平面)+ 3×Collectible 实例 + CanvasLayer/ScoreLabel + `main.gd` |

> **A-3**:`Main.tscn` 当前不存在,**③ 生产阶段后才可达**。验收点 2 的"可跑"在③结束才成立。

### 2.2 组件职责

- **Player**(CharacterBody3D):WASD 移动(相对相机方向)、Space 跳跃、重力;SpringArm 第三人称跟随
- **Collectible**(Area3D):`body_entered` 触发 → `emit_signal("collected")` → 自销毁
- **Main**(Node3D):组合场景、连信号、维护 `score`、更新 Label、集齐判过关
- **ScoreLabel**(Label):显示 `收集: x/3`,集齐显示"过关!"

### 2.3 数据流

`Player` 进 `Collectible.Area3D` → `collected` 信号 → `Main._on_collected()` → `score += 1` → Label 更新 → 集齐过关。

### 2.4 输入取舍

键盘 WASD+Space 为主;**鼠标旋转相机留到精修阶段**(最小闭环先用固定 SpringArm 跟随,降低生产阶段复杂度)。

---

## 3. 5 阶段执行映射(块 B,reviewer 修正后)

> **P0 约束(A-2)**:`load_skill` 是 substring 匹配,query **必须用英文**(中文 query 在英文 skill 上假阴性)。下表 query 全英文。
>
> **enhanced 标注(I-2)**:每阶段标注工具是「真调」还是「降级」,杜绝"模拟"含糊。本次所有 enhanced 工具均「真调」——`validate_gdd` 在 `validation` action 枚举可用、`read_scene` 本会话已实测跑通。

| 阶段 | 文档基准 query | enhanced 工具(真调/降级) | 门禁 / 产出 | 双轨验证点 |
|------|----------------|---------------------------|-------------|------------|
| **①概念** | `load_skill("3D platformer collectible")` | `validate_gdd`【真调,测其对轻量 GDD 的有效性】 | 轻量 GDD | query 能否命中 3D platformer/收集类蓝图 |
| **②架构** | `load_skill("scene split autoload signal architecture")` | `read_scene`(player.tscn)【真跑,已验证可跑,顺带验证 player.gd"避免加载报错"声称】+ `add_node`/`batch_add_nodes`/`save_scene`【真跑,搭骨架】 | ADR + Main/collectible 场景骨架 | 场景拆分/信号架构知识命中度;**#5 节点幂等**(query→条件 add) |
| **③生产** | `load_skill("CharacterBody3D movement NEVER")`【**主动探测盲区,见 §3.1**】 | `write_script`×3 + `run_and_verify`【真调】 | 可跑 `Main.tscn`(能动/跳/收集) | **3D CharacterBody 移动 NEVER 盲区** |
| **④精修** | `load_skill("performance draw call")` | `profiler` + `validate_scripts`【真调,**#4 交叉 run_and_verify**】 | 性能快照 +(可选)鼠标旋转相机补全 | 性能指南命中度 |
| **⑤交付** | `load_skill("release review checklist")` | `verify_delivery`【真调】 | 交付验证报告 + 可发布 demo | 发布清单命中度;**#9 run→verify→stop 原子** |

### 3.1 生产阶段盲区探测(I-1,已实测)

| query | 最高分 | 命中 | 结论 |
|-------|--------|------|------|
| `CharacterBody3D movement NEVER`(文档原文) | 0.43 | 通用 `never_list_encyclopedia` + `godot-adapt-2d-to-3d` + `player-controller` | **无 3D CharacterBody 移动专门 NEVER**,散落命中 |
| `CharacterBody movement NEVER`(去 3D) | **0.63** | `godot-characterbody-2d`(snippet 直开"## NEVER Do — NEVER use RigidBody2D…") | **核心 NEVER 锁在 2D skill** |

**预记 🟡 裂缝 F1**:套件知识库对 3D CharacterBody 移动**缺专门 NEVER skill**,核心规则锁在 `characterbody-2d` 里需迁移。生产阶段用去 3D 的 query 召回 2D 源做迁移参考。

---

## 4. 裂缝记录机制(I-3)

每阶段执行文档结尾**强制** §裂缝记录小节;**无裂缝也写明原因**(避免"零条目=没找"的歧义)。

**条目模板**:
```
[F#] [阶段] 文档基准 → 实际现象 → 严重度(🔴致命/🟡中等/🟢轻微)→ 补救 → 改进建议
```

**预建裂缝表(设计阶段已可预见的,执行时现填实际)**:

| F# | 阶段 | 现象 | 严重度 | 补救 |
|----|------|------|--------|------|
| F0 | 文档对齐 | `enhanced-boundaries.md` 阶段编号(①原型②灰盒③生产④打磨⑤发布)与 `workflow/*.md`(概念/架构/生产/精修/交付)**不对齐** | 🟢 | 执行时统一用 workflow 命名;建议 boundaries 补映射注 |
| F1 | ③生产 | 3D CharacterBody 移动无专门 NEVER skill,核心锁在 characterbody-2d | 🟡 | query 去 3D 召回 2D 源迁移(见 §3.1 实测) |
| F2 | ③生产 | dogfood 范围(可玩闭环)超原 GDD MVP(移动+拾取);跳跃/计分/过关原属 v1 | 🟢 | ③同步更新 01-gdd/02-adr 记录范围变更(见 §1.5) |

汇总去向:本设计文档附录 + Obsidian `[[GodotAIKit/wiki/load_skill]]`。

---

## 5. 已知边界与降级(A-1,引 `docs/enhanced-boundaries.md`)

> boundaries 阶段编号 ①–⑤(原型/灰盒/生产/打磨/发布)对应 workflow(概念/架构/生产/精修/交付):③生产一致,①≈概念、②≈架构、④≈精修、⑤≈交付。

| workflow 阶段 | 相关裂缝 # | 降级要点 |
|---------------|-----------|----------|
| ①概念 | #4 | 若涉脚本,validate_scripts 交叉确认 |
| ②架构 | #4、#5 | add 前 `query_scene_tree` 查同名 → 条件 add |
| ③生产 | #1、#2、#3、#4、#5、#6、#9 | autoload 传 `load_autoloads=true`;**禁内置 Edit 走 `edit_script`**;CRLF 走 `search_and_replace`;validate_scripts 交叉 `run_and_verify`;add 前置 query;`run_and_verify` 显式 timeout;run→verify→stop |
| ④精修 | #6、#7 | 显式 timeout;本次 3D,#7(2D 截图)影响小但标注 |
| ⑤交付 | #8、#9 | GateGuard 走 `confirm_and_execute`;run→verify→stop 原子三步 |

**关键 3 条(继承 CLAUDE.md)**:① 禁内置 Edit 改 .gd → enhanced `edit_script`;② `validate_scripts` 不一致(最致命)→ 交叉 `run_and_verify`,**以实跑为准**;③ 2D 截图 headless 不可用 → 本次 3D 影响小,视觉证据走 editor/人工。

---

## 6. 验证手段

- **阶段门禁**:`validate_gdd` → `read_scene` 核对 → `run_and_verify` → `profiler` → `verify_delivery`
- **终态**:`godot --path demo scenes/Main.tscn` 实跑,角色可控 / 收集计分 / 集齐过关
- **视觉证据**:3D 场景 headless 截图(若可用),否则 editor 人工肉眼

---

## 7. 审查处理记录(reviewer 2026-06-17)

| 反馈 | 处置 | 依据 |
|------|------|------|
| **I-1** 生产 query 盲区 | ✅ 采纳 | §3.1 实测:query1 散落无 3D 专门、query2 召回 2D 核心 NEVER 0.63 |
| **I-2** 前 2 阶段 enhanced 轨空转 | ✅ 采纳(选 a) | `validate_gdd` 在 `validation` action 枚举**可用**、`read_scene` 本会话已跑通 → 门禁表标"真调"非"模拟" |
| **I-3** 裂缝记录无载体 | ✅ 采纳 | §4 预建裂缝表模板 + 每阶段强制 §裂缝记录(无裂缝写明原因) |
| **A-1** 补 #5/#9 | ✅ 采纳 | boundaries 核对:#5 影响 ②③、#9 影响 ③⑤,吻合 |
| **A-2** substring+英文加注 | ✅ 采纳 | §3 P0 约束;实测印证 |
| **A-3** Main.tscn 标注③后可达 | ✅ 采纳 | §2.1 注 |
| **A-4** validate_gdd 推到③ | ⚠️ **部分驳回** | `validate_gdd` 工具可用,无理由推迟;改为"概念阶段即真调 + 测有效性",无效才记裂缝 |

**澄清(已修正)**:初版 spec 误以为"01-gdd / 02-adr 尚未产出"——实际①②已完成于 `a4c0c59`,两份文档存在;reviewer 初审 I-2/I-3/A-4 是引用其**实际内容**(01-gdd 自述 validate_gdd 模拟、02-adr 自述不必跑 enhanced),非预判。已补 §1.5 衔接 + §4 F2 范围裂缝。
