# dogfood:3D 收集小 Demo(Crystal Collector)实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: 用 superpowers:subagent-driven-development(推荐)或 superpowers:executing-plans 逐 task 实施。步骤用 `- [ ]` 跟踪。

**Goal:** 用套件 5 阶段工作流把 demo 占位 `player.gd` 填成最小可玩 3D 收集小 Demo(移动/跳跃/收集计分/集齐过关),并全程双轨对照产出裂缝清单。

**Architecture:** ①②已完成(`a4c0c59`:GDD + ADR + player.tscn 骨架)。dogfood 从③继续:填 `player.gd` + 新建 `collectible.tscn`/`collectible.gd` + `Main.tscn`/`main.gd`,场景拆分采用 ADR-001 v1 策略(独立 collectible)。每步 load_skill(英文 query)采知识 → enhanced 工具落地 → 验证门禁 → §裂缝记录。

**Tech Stack:** Godot 4.5+ GDScript(不用 C#)/ enhanced MCP(`write_script`、`run_and_verify`、`profiler`、`verify_delivery`、`validate_gdd`、`read_scene`、`add_node`、`save_scene`)/ load_skill(gd-agentic + GodotPrompter,144 SKILL.md)

## Global Constraints

- Godot 4.5+;GDScript only(不用 C#)
- **双轨**:每 task 先 `load_skill`(英文 query;P0 是大小写不敏感 substring 匹配,中文假阴性)→ enhanced 工具「真调」→ 验证 → 结尾 **§裂缝记录**(无裂缝写明原因)
- **禁内置 Edit 改 .gd** → 全程 enhanced `write_script`/`edit_script`(`search_and_replace`,CRLF 安全;boundaries #2)
- `validate_scripts` 不一致(最致命,#4)→ 脚本结论必须与 `run_and_verify` 交叉确认,**以实跑为准**
- `add_node`/`batch_add_nodes` 前置 `query_scene_tree` 查同名(#5)
- `run_and_verify` 显式传 `timeout`≥60s(#6);每次后 `stop_project`(run→verify→stop 原子,#9)
- 范围:可玩闭环(移动+跳跃+计分+集齐过关),③同步更新①②文档记 F2

---

## File Structure

| 文件 | 责任 | 状态 |
|------|------|------|
| `demo/docs/01-concept-gdd.md` | 轻量 GDD | 改(记范围扩展 F2) |
| `demo/docs/02-architecture-adr.md` | ADR | 改(场景拆分用 v1;collected 信号简化) |
| `demo/scenes/player.gd` | CharacterBody3D 控制(移动/跳跃/朝向) | 改(填实现,替换占位) |
| `demo/scenes/collectible.gd` | Area3D 收集物:body_entered→emit collected→free | 新建 |
| `demo/scenes/collectible.tscn` | 收集物场景(Area3D+Mesh+Collision) | 新建 |
| `demo/scenes/main.gd` | Main 协调:接信号/计分/过关 | 新建 |
| `demo/scenes/Main.tscn` | 组合场景(Player+Ground+3 Collectible+HUD) | 新建 |
| `.gitattributes` | LF 规范化(治 CRLF warning,#3) | 新建 |
| `demo/docs/03-production-log.md` | ③生产执行日志 + §裂缝记录 | 新建 |

**信号契约**(跨 task 共享,后续 task 依赖):
- `Collectible.collected()` —— 无参信号(简化 ADR-003 的 `collected(N)`,记 F3)
- `Main._on_collected()` —— 计数 + 更新 Label + 集齐判过关
- Collectible 节点入 group `"crystals"`;ScoreLabel 用 unique name `%ScoreLabel`

---

## Task 1:前置 — ①② enhanced 补真调 + 范围文档更新(F2)

**Files:**
- Modify: `demo/docs/01-concept-gdd.md`(记范围扩展)
- Modify: `demo/docs/02-architecture-adr.md`(场景拆分 v1 + collected 简化)
- Create: `demo/docs/03-production-log.md`(执行日志骨架)

**Interfaces:** 产出到③的入口:范围=可玩闭环;collectible 独立场景;`collected()` 无参信号。

- [ ] **Step 1:真调 validate_gdd(验证可用性)**

Run enhanced:`validation` action=`validate_gdd`,入参 `document=demo/docs/01-concept-gdd.md`。
Expected:返回 status(pass/warn)或工具报错。**若工具不可用或报错 → 记 🔴 裂缝**(F-cand),降级手动核对 GDD 结构,不得回退"模拟"。

- [ ] **Step 2:更新 01-gdd 记范围扩展(F2)**

在 `01-concept-gdd.md` 核心机制表后追加:
```markdown
## 范围变更(dogfood ③,2026-06-17)

原 MVP=移动+拾取信号(不要求可玩)。dogfood 升级到**可玩闭环**:
移动 + 跳跃 + 计分 + 集齐过关(原标 v1 的跳跃/计分/过关提到 dogfood 范围)。
原因:dogfood 需可玩 demo 才有端到端验证价值。详见 spec §1.5。
```

- [ ] **Step 3:更新 02-adr 记决策变更(F2 + F3)**

在 `02-architecture-adr.md` 末尾追加:
```markdown
## 决策变更(dogfood ③,2026-06-17)

- **ADR-001 场景拆分**:dogfood 采用 **v1 策略**(独立 collectible.tscn),
  非 MVP 单 Main 内嵌——因要实现完整收集逻辑,独立场景更干净。
- **ADR-003 信号简化**:collected(N) → collected() 无参(MVP 计数不需 index)。
  记为 F3 小偏离。Game.gd 更名为 main.gd。
```

- [ ] **Step 4:创建执行日志骨架**

Create `demo/docs/03-production-log.md`:
```markdown
# ③ 生产阶段执行日志(Crystal Collector)

> 双轨对照:每步 load_skill → enhanced 工具 → 验证 → §裂缝记录

## §裂缝记录(执行时现填;无裂缝写明原因)

| F# | 现象 | 严重度 | 补救 |
|----|------|--------|------|
| F0 | boundaries 阶段命名(原型/灰盒)≠ workflow(概念/架构) | 🟢 | 统一 workflow 命名 |
| F1 | 3D CharacterBody 移动无专门 NEVER(见 Task 2 实测) | 🟡 | TBD |
| F2 | 范围扩展超原 GDD MVP | 🟢 | 已更新①②文档(本 Task) |
| F3 | collected(N)→collected() 简化 | 🟢 | 已记 ADR 变更 |
```

- [ ] **Step 5:Commit**

```bash
git add demo/docs/01-concept-gdd.md demo/docs/02-architecture-adr.md demo/docs/03-production-log.md
git commit -m "docs(dogfood③): ①②范围扩展+决策变更日志(F2/F3)"
```

---

## Task 2:③-A 知识采集 + 3D 移动 NEVER 盲区探测(F1)

**Files:** 无产出文件,仅 load_skill 取证 → 填日志 F1。

**Interfaces:** 为 Task 3/4 提供 player/collectible 实现的 NEVER 依据。

- [ ] **Step 1:探测 3D 移动 NEVER 盲区(双 query 对比)**

Run:
- `load_skill(query="CharacterBody3D movement NEVER", limit=4)` —— 文档基准
- `load_skill(query="CharacterBody movement NEVER", limit=4)` —— 去 3D 召回 2D 源

Expected(spec §3.1 已实测):前者散落命中(通用百科/adapt-2d-to-3d,无 3D 专门 NEVER);后者召回 `godot-characterbody-2d` 0.63(核心 NEVER 锁 2D)。

- [ ] **Step 2:采迁移源(去 3D query 召回的 characterbody-2d)**

从 Step 1 第二个 query 的 `godot-characterbody-2d` 命中,记下可迁移到 3D 的 NEVER 要点(如"NEVER 用 RigidBody 做玩家控制器"、"move_and_slide 在 _physics_process")。写进日志 F1 补救列。

- [ ] **Step 3:采集 collectible/信号知识**

Run:`load_skill(query="Area3D body_entered signal collectible", limit=3)`。
Expected:命中收集物信号模板。记要点(Area3D + body_entered + emit_signal + queue_free)。

- [ ] **Step 4:填日志 F1**

更新 `03-production-log.md` §裂缝记录 F1 补救列:
```
| F1 | 3D CharacterBody 移动无专门 NEVER;核心锁 characterbody-2d | 🟡 | 用去3D query 召回 2D NEVER 迁移;player.gd 按 move_and_slide/_physics_process 落地 |
```

- [ ] **Step 5:Commit**

```bash
git add demo/docs/03-production-log.md
git commit -m "docs(dogfood③): 3D移动NEVER盲区探测+知识采集(F1)"
```

---

## Task 3:③-B collectible.gd + collectible.tscn

**Files:**
- Create: `demo/scenes/collectible.gd`
- Create: `demo/scenes/collectible.tscn`

**Interfaces:**
- Produces: `signal collected()`(无参);节点入 group `crystals`;Area3D + Mesh(黄)+ CollisionShape3D(BoxShape3D)

- [ ] **Step 1:write collectible.gd(enhanced write_script,禁内置 Edit)**

Run enhanced `script` action=`write_script`,`script_path=demo/scenes/collectible.gd`,content:
```gdscript
extends Area3D

signal collected

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		collected.emit()
		queue_free()
```

- [ ] **Step 2:搭 collectible.tscn(query 前置 #5)**

Run enhanced `scene`:
1. `create_scene` root_node_type=Area3D, root_node_name=Collectible → 存 `demo/scenes/collectible.tscn`
2. `query_scene_tree` 查 root 下无同名 → `add_node` MeshInstance3D(BoxMesh,黄材质)+ CollisionShape3D(BoxShape3D)
3. `add_node` 时给根 Area3D 加 `groups=["crystals"]`(或 edit_node 设 groups)
4. `edit_node` 根节点 `script = res://scenes/collectible.gd`
5. `save_scene`

- [ ] **Step 3:validate_scripts + run_and_verify 交叉(#4)**

Run:
- `validation` action=`validate_scripts`(collectible.gd)
- `validation` action=`run_and_verify`(scene=collectible.tscn, `timeout=60`)
Expected:两路都无错。**不一致以 run_and_verify 为准**。

- [ ] **Step 4:stop_project(#9)**

Run enhanced `runtime` action=`stop_project`。

- [ ] **Step 5:§裂缝记录 + Commit**

日志记 collectible 阶段裂缝(若有),无则写"无,write_script + run_and_verify 一致"。
```bash
git add demo/scenes/collectible.gd demo/scenes/collectible.tscn demo/docs/03-production-log.md
git commit -m "feat(dogfood③): collectible 场景+脚本(Area3D collected 信号)"
```

---

## Task 4:③-C player.gd 角色控制

**Files:**
- Modify: `demo/scenes/player.gd`(替换占位)

**Interfaces:**
- Consumes: SpringArm3D 子节点(player.tscn 已有)
- Produces: CharacterBody3D 可控(WASD 移动 + Space 跳跃 + 面朝移动方向);移动用 Godot 内置 `ui_*` 输入(无需配 input map)

- [ ] **Step 1:load_skill 核对 NEVER(Task 2 采集)**

确认落地要点:`_physics_process` 内 `move_and_slide`、`is_on_floor` 判跳、`Input.get_vector`、不手算碰撞。

- [ ] **Step 2:write player.gd(enhanced write_script,覆盖占位)**

Run enhanced `script` action=`write_script`,`script_path=demo/scenes/player.gd`,`overwrite=true`,content:
```gdscript
extends CharacterBody3D

const SPEED := 5.0
const JUMP_VELOCITY := 4.5

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		var face := global_position + Vector3(velocity.x, 0.0, velocity.z)
		if face != global_position:
			look_at(face, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)
	move_and_slide()
```

- [ ] **Step 3:交叉验证(#4)**

Run:
- `validate_scripts`(player.gd)
- `run_and_verify`(scene=player.tscn, `timeout=60`)—— 验证脚本 attach 无运行时报错
Expected:一致无错。

- [ ] **Step 4:stop_project + §裂缝记录 + Commit**

```bash
git add demo/scenes/player.gd demo/docs/03-production-log.md
git commit -m "feat(dogfood③): player.gd 第三人称控制(移动/跳跃/朝向)"
```
日志记:若 load_skill NEVER 与代码冲突 → 记裂缝并调整;否则"player.gd 按 2D 迁移 NEVER 落地,无冲突"。

---

## Task 5:③-D Main.tscn + main.gd + 终态验证(验收点②)

**Files:**
- Create: `demo/scenes/main.gd`
- Create: `demo/scenes/Main.tscn`

**Interfaces:**
- Consumes: Task 3 collectible(信号 collected + group crystals);Task 4 player.tscn
- Produces: 可跑 Main.tscn;`_on_collected()` 计分;`%ScoreLabel` 更新

- [ ] **Step 1:write main.gd**

```gdscript
extends Node3D

@export var total := 3
var score := 0

@onready var score_label: Label = %ScoreLabel

func _ready() -> void:
	_update_label()
	for crystal in get_tree().get_nodes_in_group("crystals"):
		crystal.collected.connect(_on_collected)

func _on_collected() -> void:
	score += 1
	_update_label()
	if score >= total:
		score_label.text = "过关!"

func _update_label() -> void:
	score_label.text = "收集: %d/%d" % [score, total]
```

- [ ] **Step 2:搭 Main.tscn(query 前置 #5)**

Run enhanced `scene`:
1. `create_scene` Node3D root=Main → `demo/scenes/Main.tscn`
2. `query_scene_tree` → `add_node`:Ground(StaticBody3D + BoxMesh 灰 + BoxShape3D 大平面)
3. `instance_scene` player.tscn 为 Player 子节点
4. `instance_scene` collectible.tscn ×3 → Collectibles 容器(Node),各 crystal 位置散布
5. `add_node` CanvasLayer → Label(`unique_name_in_owner=true`,名 ScoreLabel)
6. `edit_node` 根 Main `script=res://scenes/main.gd`
7. `save_scene`

- [ ] **Step 3:run_and_verify 终态(验收点②)+ assert**

Run:
- `run_and_verify`(scene=Main.tscn, `timeout=90`,`capture_tree=true`)—— 启动无运行时报错
- `validation` action=`assert` —— 断言场景树含 Player/3×crystals/ScoreLabel
Expected:启动无错;树含预期节点。

- [ ] **Step 4:行为人工确认 + stop_project**

Run `screenshot capture`(3D 可用,非 #7 的 2D 限制)或 editor 人工:角色能动/能收集/计分更新/集齐过关。
Run `stop_project`。

- [ ] **Step 5:§裂缝记录 + Commit**

```bash
git add demo/scenes/main.gd demo/scenes/Main.tscn demo/docs/03-production-log.md
git commit -m "feat(dogfood③): Main 组合+计分+终态可玩(验收②)"
```

---

## Task 6:④精修 — profiler + 交叉验证

**Files:** 无新增;改日志。

- [ ] **Step 1:load_skill 性能知识**

Run:`load_skill(query="performance draw call profiler", limit=3)`。记命中度(预期 GodotPrompter 性能指南)。

- [ ] **Step 2:profiler 性能快照**

Run enhanced `profiler` action=`snapshot`(跑 Main.tscn)。记 FPS/绘制调用/内存。Expected:60fps 稳定(MVP 场景简单)。

- [ ] **Step 3:validate_scripts 全脚本交叉(#4)**

Run `validate_scripts`(player/collectible/main 三脚本)+ `run_and_verify`(Main.tscn)。Expected:一致。

- [ ] **Step 4:(可选)鼠标旋转相机补全**

若用户要,`edit_script` player.gd 加 `@onready var spring_arm=$SpringArm3D` + `_unhandled_input` 鼠标转 spring_arm.rotation。否则跳过(记"最小闭环不含,留 v1")。

- [ ] **Step 5:§裂缝记录 + Commit**

```bash
git add demo/docs/03-production-log.md
git commit -m "docs(dogfood④): 精修 profiler+交叉验证(若改 player.gd 一并 add)"
```

---

## Task 7:⑤交付 — verify_delivery + CRLF + 裂缝汇总

**Files:**
- Create: `.gitattributes`
- Modify: `demo/docs/03-production-log.md`(裂缝汇总 + 收尾)

- [ ] **Step 1:load_skill 发布清单**

Run:`load_skill(query="release review checklist godot", limit=3)`。记命中度。

- [ ] **Step 2:verify_delivery(验收点①的门禁)**

Run enhanced `validation` action=`verify_delivery`(project=demo)。Expected:pass(场景完整+脚本健康+性能)。**若报 autoload 盲区(#1)→ 记裂缝,传 `load_autoloads=true` 重试**(本 demo 无 autoload,预期不触发)。

- [ ] **Step 3:治 CRLF(#3,本次提交已见 warning)**

Create `.gitattributes`:
```
* text=auto eol=lf
*.gd text eol=lf
*.tscn text eol=lf
*.godot text eol=lf
```
Run:`git add --renormalize .`(规范化存量)。

- [ ] **Step 4:裂缝汇总(验收点③)**

更新 `03-production-log.md` 末尾,汇总 F0–F3 + 执行中新发现的裂缝,每条带严重度/补救/改进建议。抄送 Obsidian `[[GodotAIKit/wiki/load_skill]]`(由主会话写,非 plan 执行者)。

- [ ] **Step 5:run→verify→stop 终检(#9)+ Commit**

Run `run_and_verify`(Main.tscn)→ 确认绿 → `stop_project`。
```bash
git add .gitattributes demo/docs/03-production-log.md
git commit -m "feat(dogfood⑤): 交付验证+CRLF规范+裂缝汇总(验收③)"
```

---

## Self-Review

**1. Spec 覆盖**:
- 验收①(5阶段真跑):Task1 validate_gdd / Task3-5 run_and_verify / Task6 profiler / Task7 verify_delivery ✅
- 验收②(可跑可玩):Task5 终态 ✅
- 验收③(裂缝清单):每 Task §裂缝记录 + Task7 汇总 ✅
- §1.5 衔接①②:Task1 文档更新 ✅
- §3.1 盲区:Task2 ✅
- boundaries #2/#3/#4/#5/#6/#9:分别在 Task3-7 标注 ✅

**2. Placeholder 扫描**:代码块完整(player/collectible/main.gd 全给);load_skill query 全英文;无 TBD(F1 补救列在 Task2 填实际)。✅

**3. 类型一致性**:`collected()` 无参在 Task3 定义、Task5 消费 ✅;`%ScoreLabel` 在 Task5 Step1/2 一致 ✅;group `crystals` Task3 加、Task5 消费 ✅。
