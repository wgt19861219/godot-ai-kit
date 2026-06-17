# ② 架构阶段:ADR + 场景树设计

> **load_skill 演示(P0 无 stage)**
>
> ```gdscript
> # 检索 gd-agentic 架构决策矩阵示例(P0 签名仅 query,无 stage)
> load_skill(query="scene split autoload signal architecture")
> ```
>
> **P0 返回约定(plan1):** 返回 `matches[]`,每项含 **200 字符 `snippet`** + **`path`**。
> 需要决策矩阵全文时按 `path` 二次读取(如 `godot-autoload-architecture/SKILL.md`)。
> 预期命中:`godot-autoload-architecture` / `godot-composition` / `godot-camera-systems`。
>
> **query 语言提示:** gd-agentic skill 多为英文,**query 用英文关键词更准**
> (P0 是大小写不敏感 substring 匹配,中文词在英文 skill 上可能 miss)。

---

## ADR-001: 场景拆分策略

**状态:** Accepted(MVP)
**日期:** 2026-06-17
**决策者:** godot-ai-kit demo

### 背景

3D 收集物游戏需要组织:玩家、相机、关卡、收集物、计分。两种极端:
- 单场景全塞(简单但难扩展)
- 每实体独立场景实例化(干净但 MVP 过度工程)

### 决策

**MVP:** 单 `Main.tscn` 内嵌玩家 + 关卡 + 收集物节点组。
**v1:** 拆分为 `player.tscn` / `level.tscn` / `collectible.tscn`,用 `instance_scene` 组合。

**理由:** MVP 范围只有"移动+拾取信号",拆分收益 < 复杂度成本。v1 增加跳跃/HUD/
过关时按 ③ production 阶段拆分,届时用 enhanced `instance_scene` 落地。

### 场景树设计(MVP Main.tscn)

```
Main (Node3D)                      ← 根,挂 Game.gd(协调)
├── Player (CharacterBody3D)       ← 见 scenes/player.tscn 骨架
│   ├── MeshInstance3D             ← 蓝色胶囊(可视)
│   ├── CollisionShape3D           ← CapsuleShape3D
│   └── SpringArm3D → Camera3D     ← 第三人称相机(SpringArm 跟随)
├── Level (Node3D)
│   ├── Platform (StaticBody3D)
│   │   ├── MeshInstance3D         ← 灰色 Box
│   │   └── CollisionShape3D       ← BoxShape3D
│   └── Collectibles (Node)        ← 收集物容器
│       ├── Crystal_0 (Area3D)
│       │   ├── MeshInstance3D     ← 黄色八面体
│       │   └── CollisionShape3D
│       ├── Crystal_1 (Area3D)
│       └── Crystal_2 (Area3D)
└── HUD (CanvasLayer)              ← v1: Label 计分
```

## ADR-002: Autoload 架构(计分)

**状态:** Accepted(v1,MVP 预留)

### 决策

`project.godot` 注册 autoload `ScoreManager`(RefCounted 或 Node 单例),
暴露 `score` / `total` 属性 + `crystal_collected(index)` 方法。

**MVP:** 不注册 autoload(计分逻辑内联在 Game.gd)。
**v1:** 注册 autoload,跨场景(过关切关)保留计分状态。

**load_skill 参考:** `godot-autoload-architecture` 的决策矩阵
(autoload vs 节点单例 vs 静态类),按 `path` 二次读全文获取权衡细节。

## ADR-003: 信号架构

**状态:** Accepted

### 决策

```
Crystal_N (Area3D)
   └── signal body_entered(body)
        └── if body is Player:
            emit_signal("collected", N)
                 │
                 ▼
Game.gd._on_crystal_collected(N):
   collected += 1
   if collected == total:
       emit_signal("level_complete")
```

**原则:**
- 收集物**只发信号**(`collected`),不直接改计分(单向依赖,易测试)
- Game.gd 订阅并聚合,**不向下调用**收集物(避免循环依赖)
- HUD(v1)订阅 Game 的 `score_changed` 信号更新 UI

**load_skill 参考:** `godot-composition` 的信号编排模式,
`godot-game-loop-collection` 的收集物信号模板。

---

## 场景骨架产出

- **`scenes/player.tscn`**(本 Task): 手写 .tscn 骨架,CharacterBody3D +
  MeshInstance3D(蓝色胶囊)+ CollisionShape3D(CapsuleShape3D)+ Camera3D 基础结构。
  > **生产时可用 enhanced `add_node` + `save_scene` 重建**——Task 6 不必跑 enhanced MCP,
  > 手写骨架即可满足"架构阶段产出物"的要求。v1 production 阶段重建更复杂场景时用 enhanced。
- **`Main.tscn`** (③ production): 组合 Player + Level + HUD。

## ✅ 架构审查清单

- [x] 场景拆分策略明确(MVP 单场景 / v1 拆分)
- [x] autoload 边界清晰(MVP 无 / v1 ScoreManager)
- [x] 信号单向流动(收集物 → Game → HUD)
- [x] player.tscn 骨架存在
- [ ] Main.tscn(③ production)
- [ ] ScoreManager autoload(v1)

---
*spec §6.3 架构阶段 | plan2 Task 6 Step 3 | 上一步 → 01-concept-gdd.md*
