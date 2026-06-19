# 套件 3D 玩法 skill 补全 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: 用 superpowers:subagent-driven-development(推荐)或 superpowers:executing-plans 逐 task 执行。步骤用 checkbox(`- [ ]`)跟踪。

**Goal:** 在仓库根新建 2 个 3D 玩法 skill(`godot-characterbody-3d` + `godot-area3d-collection`),接入 `load_skill` 召回链路,填 dogfood 实测暴露的 F1/F5 盲区。

**Architecture:** 仓库根 `skills/`(套件 MIT 自有领土,首次引入"套件原生 skills/")承载新 skill;改 `config/claude/settings.json` 把 `${REPO_ROOT}/skills` 加进 `GODOT_SKILL_LIBRARIES`(install 自检自动覆盖);验收用真实 `load_skill` 显式 `libraries` 参数(绕过部署裂缝)。

**Tech Stack:** GDScript(Godot 4.5+,tab 缩进)、Markdown(frontmatter SKILL.md,仿 `characterbody-2d` 格式)、JSON(`config/claude/settings.json`)、enhanced MCP 工具(execute_gdscript/load_skill/run_and_verify,验证)。

**Spec:** `docs/superpowers/specs/2026-06-19-3d-gameplay-skills-design.md`(commit `6e9fb4b`+`e11c83c`)

## Global Constraints

(每个 task 的需求隐含包含本节)

- **Godot 4.5+**(项目 floor);GDScript **tab 缩进**(内置 Edit 改 .gd 失效,只用 enhanced `edit_script`/`write_script`,见 boundaries #2)
- **绝不修改 `gd-agentic-skills` 源文件**(LGPLv3 submodule,真聚合);新 skill 只在仓库根 `skills/` 新建
- **License**:套件根 = MIT(自有);gd-agentic-skills = LGPLv3。新 skill 随套件 MIT。**NEVER 文案原创**,不逐字复制上游 `characterbody-2d` 文案(规避 LGPLv3 衍生义务,见 spec §7)
- **验证以实跑为准**(boundaries #4):`validate_scripts` 不可信,脚本用 `execute_gdscript` 的 `GDScript.reload()` 真实解析;skill 召回用 `load_skill` 实跑
- **仓库根** = `D:/GitHub/godot-ai-kit`;plan 内路径为仓库相对路径
- **load_skill `libraries` 参数**:必须**绝对路径**、不含 `..`(`load-skill-search.ts:80-85` 校验);三目录 = `["D:/GitHub/godot-ai-kit/GodotPrompter/skills","D:/GitHub/godot-ai-kit/gd-agentic-skills/skills","D:/GitHub/godot-ai-kit/skills"]`
- **git**:本机 Bash 沙箱 PATH 缺 `git`,用完整路径 `"C:/Program Files/Git/cmd/git.exe" -C "D:/GitHub/godot-ai-kit" ...`;提交到 main(项目 spec/文档惯例,见 git log `docs(...)` 系列);commit message 末尾加 `Co-Authored-By: Claude <noreply@anthropic.com>`
- **召回机制**(spec §6.1):`name` 命中 1.0 / `description` 0.6 / `body` 0.3,多 term 平均。**连字符坑**:`godot-characterbody-3d`(name,有连字符)对 query term `characterbody3d`(无连字符)`includes` 失败 → name 1.0 吃不到,真正杠杆是 **description 写无连字符类名 `CharacterBody3D`**(desc 0.6)

---

## File Structure

| 文件 | 责任 | task |
|---|---|---|
| `skills/godot-characterbody-3d/SKILL.md` | CharacterBody3D 3D 玩法 NEVER + 迁移对照 + Reference | T1 |
| `skills/godot-characterbody-3d/scripts/camera_relative_movement.gd` | 相机相对移动示例(三件套) | T1 |
| `skills/godot-area3d-collection/SKILL.md` | Area3D 收集交互 NEVER + 迁移对照 + Reference | T2 |
| `skills/godot-area3d-collection/scripts/pickup_trigger.gd` | 收集触发示例(组优先+signal 带 sender) | T2 |
| `config/claude/settings.json` | `GODOT_SKILL_LIBRARIES` 加第三目录 | T3 |

---

### Task 1: godot-characterbody-3d skill

**Files:**
- Create: `skills/godot-characterbody-3d/SKILL.md`
- Create: `skills/godot-characterbody-3d/scripts/camera_relative_movement.gd`

**Interfaces:**
- Consumes: `demo/scenes/player.gd`(精简源,已验证);`gd-agentic-skills` 的 `adapt-2d-to-3d.md` / `physics-3d`(Reference 指向,不复制)
- Produces: `load_skill(query="CharacterBody3D movement NEVER", libraries=[三目录])` 召回 `godot-characterbody-3d`,score > `godot-characterbody-2d`(spec §6.2 Case A)

- [ ] **Step 1: 建目录**

```
skills/godot-characterbody-3d/scripts/
```

- [ ] **Step 2: 写 SKILL.md**

Create `skills/godot-characterbody-3d/SKILL.md`:

```markdown
---
name: godot-characterbody-3d
description: "Expert patterns for CharacterBody3D player controllers in 3D: camera-relative movement via spring arm basis, breaking transform.basis feedback loops, horizontal-plane projection, delta-normalized deceleration, WASD InputMap binding, gravity and jump. Use for 3D player characters, third-person controllers, 3D platformer or shooter movement. Trigger keywords: CharacterBody3D, move_and_slide, is_on_floor, velocity, spring_arm, camera_relative, movement, WASD, InputMap, third_person, 3d player controller, gravity, jump, NEVER."
---

# CharacterBody3D 3D 玩法实现

3D 玩家控制器的实现细节:相机相对移动、断反馈循环、水平面投影、delta 归一 decel、WASD InputMap。
**不重复** `godot-physics-3d`(RigidBody/物理层/楼梯检测)与 `adapt-2d-to-3d`(节点转换矩阵/迁移步骤)——本 skill 只管"3D 玩法实现细节"。

## NEVER Do

- **NEVER 用移动方向乘自身 basis** — `transform.basis * input_dir` 配合旋转改朝向会形成**反馈循环**(W 自洽不抖、A/S/D 振荡闪烁,F15)。方向取**相机臂 basis**(`spring_arm.global_transform.basis`),Player 根与 mesh 全程不转。
- **NEVER 跳过水平面投影直接归一** — 方向向量须先 `direction.y = 0` 投影水平面再 `normalized()`,否则相机俯仰时斜向加速。
- **NEVER 写帧率敏感的减速** — decel 必须 delta 归一:`var decel := SPEED * DECEL * delta`,`move_toward(velocity.x, 0.0, decel)`(I2)。裸 `move_toward(velocity.x, 0, SPEED)` 帧率敏感。
- **NEVER 假设 WASD 默认绑定** — Godot 4 默认 InputMap **不绑 WASD**(只方向键 + 手柄 D-Pad,F14)。须在 `project.godot` `[input]` 段用 `physical_keycode` 显式定义 `move_forward(W=87)`/`move_back(S=83)`/`move_left(A=65)`/`move_right(D=68)`。
- **NEVER 旋转 Player 根做相机跟随** — 鼠标 yaw/pitch 只旋转 `SpringArm3D`,Player 根不动;否则相机跟着角色转 → 视角乱、二次切方向无效(F16)。朝向变化用 `lerp_angle` 平滑作用于 mesh,不瞬转。

## 2D→3D 迁移对照(精简)

| 维度 | CharacterBody2D | CharacterBody3D |
|---|---|---|
| 输入向量 | `Input.get_vector`(Vector2,x/y) | 同 API,映射到 x/z 平面 |
| 方向空间 | 世界或自身 basis | **相机臂 basis**(第三人称);世界坐标是 F15 中间态 |
| 重力轴 | `velocity.y += gravity*delta`(2D y 向下) | `velocity.y -= gravity*delta`(3D,JUMP 正值向上) |
| 楼梯/坡 | `floor_snap_length` | 引用 `physics-3d` 的 ShapeCast3D 楼梯逻辑 |

> 完整节点转换矩阵(`CharacterBody2D`→`CharacterBody3D` 等)见 `adapt-2d-to-3d.md`。

## 示例脚本

### [camera_relative_movement.gd](scripts/camera_relative_movement.gd)
3D 第三人称玩家控制器:相机臂 basis 取向 + 水平面投影 + delta 归一 decel。精简自 `demo/scenes/player.gd`(经 F14–F16 实测修复 + WASD 人工实测)。

## Common Gotchas(headless 测不出,只有真机才发现)

- **缺光源**:3D 场景无 `DirectionalLight3D`/`WorldEnvironment` 时画面全黑(F14)。headless 截图"渲染正常"常是误判 —— 色调暗未细看。
- **反馈循环**:`transform.basis*input` + `look_at` 改朝向 = A/S/D 闪烁(F15),只有真机按键才暴露,headless 完全无法复现。
- **WASD 默认不绑**:Godot 4 InputMap 不含 WASD(F14),headless 测"输入响应"是盲区;InputMap 绑定可 `execute_gdscript` 读 InputMap 验证,但**按键实际响应须人工**。

## Reference

- [`adapt-2d-to-3d`](../../../gd-agentic-skills/skills/godot-master/references/adapt-2d-to-3d.md) — 节点转换矩阵、迁移步骤(迁移源头)
- [`godot-physics-3d`](../../../gd-agentic-skills/skills/godot-physics-3d/SKILL.md) — RigidBody vs CharacterBody 选择、ShapeCast3D 楼梯检测
- demo 实测:`demo/docs/03-production-log.md` F14/F15/F16(`:176-192`)
```

- [ ] **Step 3: 写 camera_relative_movement.gd**

Create `skills/godot-characterbody-3d/scripts/camera_relative_movement.gd`(tab 缩进):

```gdscript
extends CharacterBody3D
## camera_relative_movement.gd — 3D 第三人称玩家控制器(相机相对移动)
## 精简自 demo/scenes/player.gd(经 F14-F16 实测修复 + WASD 人工实测)。
## 保留:相机臂 basis 取向 + 水平面投影 + delta 归一 decel 三件套。
## 省略:鼠标捕获(MOUSE_MODE_CAPTURED)/ESC 的输入 UX(与移动核心无关)。

const SPEED := 5.0
const JUMP_VELOCITY := 4.5
const DECEL := 10.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# 相机臂:方向取自它的 basis(只受鼠标影响),绝不取 Player 自身 basis —— 断反馈循环(F15)。
@onready var spring_arm: SpringArm3D = $SpringArm3D


func _physics_process(delta: float) -> void:
	# 重力(3D:JUMP_VELOCITY 正值向上,故重力用减)
	if not is_on_floor():
		velocity.y -= gravity * delta
	# 跳跃(ui_accept = Space,不重定义避免污染 UI 导航)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	# WASD 输入(须在 project.godot [input] 段用 physical_keycode 显式定义 —— Godot 4 默认不绑,F14)
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	# 方向取自相机臂 basis,不是 Player basis(断反馈循环)
	var cam_basis := spring_arm.global_transform.basis
	var forward := -cam_basis.z
	var right := cam_basis.x
	var direction := right * input_dir.x - forward * input_dir.y
	# 水平面投影 + 归一(否则相机俯仰时斜向加速)
	direction.y = 0.0
	direction = direction.normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		# delta 归一 decel(帧率无关,I2)
		var decel := SPEED * DECEL * delta
		velocity.x = move_toward(velocity.x, 0.0, decel)
		velocity.z = move_toward(velocity.z, 0.0, decel)
	move_and_slide()
```

- [ ] **Step 4: 验证脚本解析(真实 Godot 编译器)**

用 `execute_gdscript`(project_path=demo,headless)内联脚本内容做 `GDScript.reload()` 解析检查(boundaries #4 以实跑为准,非 validate_scripts):

调用 `mcp__godot__execute_gdscript`,project_path=`D:/GitHub/godot-ai-kit/demo`,code(把 Step 3 的脚本完整内容作为 `source_code` 字符串内联):

```gdscript
var s := GDScript.new()
s.source_code = "<Step 3 的 camera_relative_movement.gd 完整内容,逐字内联>"
var err := s.reload()
_mcp_output("parse_err", err)
_mcp_output("ok", err == OK)
_mcp_done()
```

**预期**:`ok=true`、`parse_err=0`(OK)。
**降级**:若内联转义困难,改用 enhanced `script read_script` 读 `skills/godot-characterbody-3d/scripts/camera_relative_movement.gd` 全文,人工对照 `demo/scenes/player.gd:41-61` 确认是精简子集(三件套在、MOUSE_MODE/ESC 已省)—— 因脚本源自已验证的 demo 代码,语法正确性由 demo `run_and_verify`(F14-F16 实测 hasErrors:false)保证。

- [ ] **Step 5: 验证 load_skill Case A 召回(显式 libraries 绕过部署裂缝)**

调用 `mcp__godot__load_skill`:
- query=`"CharacterBody3D movement NEVER"`
- libraries=`["D:/GitHub/godot-ai-kit/GodotPrompter/skills","D:/GitHub/godot-ai-kit/gd-agentic-skills/skills","D:/GitHub/godot-ai-kit/skills"]`

**预期**:召回列表含 `godot-characterbody-3d`(source=`skills`),其 score **大于** `godot-characterbody-2d`(source=`gd-agentic-skills`)的 score。spec §6.2 Case A。
**机制核对**(若 score 不达):确认 SKILL.md `description` 含无连字符词 `CharacterBody3D`、`movement`、`NEVER`、`spring_arm`(让 query 的每个 term 在 description 命中 0.6,见 Global Constraints 连字符坑)。

- [ ] **Step 6: Commit**

```bash
"C:/Program Files/Git/cmd/git.exe" -C "D:/GitHub/godot-ai-kit" add skills/godot-characterbody-3d
"C:/Program Files/Git/cmd/git.exe" -C "D:/GitHub/godot-ai-kit" commit -m "feat(skills): godot-characterbody-3d(填 F1 盲区)" -m "CharacterBody3D 3D 玩法 skill:相机相对移动/断反馈循环/水平面投影/delta decel/WASD InputMap。示例脚本精简自 demo player.gd(F14-F16 实测)。load_skill Case A 召回验证通过。" -m "Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 2: godot-area3d-collection skill

**Files:**
- Create: `skills/godot-area3d-collection/SKILL.md`
- Create: `skills/godot-area3d-collection/scripts/pickup_trigger.gd`

**Interfaces:**
- Consumes: `demo/scenes/collectible.gd`(精简源,已验证);`gd-agentic-skills` 的 `adapt-2d-to-3d` / `physics-3d`(Reference)
- Produces: `load_skill(query="Area3D body_entered signal collectible pickup", libraries=[三目录])` 召回 `godot-area3d-collection` 为该 query **第一名**(spec §6.2 Case B)

- [ ] **Step 1: 建目录**

```
skills/godot-area3d-collection/scripts/
```

- [ ] **Step 2: 写 SKILL.md**

Create `skills/godot-area3d-collection/SKILL.md`:

```markdown
---
name: godot-area3d-collection
description: "Expert patterns for Area3D collection and pickup interactions in 3D: body_entered trigger, group-based identification via is_in_group, signal with sender parameter for dedup, connect vs hard-wire, Area3D as detection not blocking. Use for 3D collectibles, pickups, triggers, crystals, coins, items, 3D collection loops. Trigger keywords: Area3D, body_entered, collectible, pickup, collection, signal, is_in_group, queue_free, crystals, coins, items, trigger, NEVER."
---

# Area3D 收集交互实现

3D 收集物(Area3D)的实现模式:body_entered 触发 + 组优先判别 + signal 带 sender + 自销毁。
**不重复** `godot-physics-3d`(Area3D 只检测不阻挡、3D 物理层)与 `adapt-2d-to-3d`(Area2D→Area3D 转换矩阵)。

## NEVER Do

- **NEVER 用硬类型判断识别收集者** — `if body is CharacterBody3D` 过窄(NPC/载具/其他玩家拿不到,I3)。用**组优先** `body.is_in_group("player")`。
- **NEVER 发无参收集信号** — `signal collected` 无法区分多个收集物,主控无法去重(C2)。带 sender 参数 `signal collected(sender: Node)`,主控用 Set/Dict 按 sender 去重。
- **NEVER 硬连 body_entered 到外部方法** — 用 `body_entered.connect(_on_body_entered)`(节点生命周期安全;运行时动态 `instance` 的收集物可重连,硬连会漏)。
- **NEVER 用 Area3D 做阻挡** — Area3D 只做检测/触发。墙/屏障/边界用 `StaticBody3D` 保证立即、稳健的阻挡(引用 `godot-physics-3d`)。

## 2D→3D 迁移对照(精简)

| 维度 | Area2D | Area3D |
|---|---|---|
| 触发信号 | `body_entered(body: PhysicsBody2D)` | `body_entered(body: PhysicsBody3D)` |
| 监听空间 | `physics/2d` 层 | `physics/3d` 层(与 2D **独立**的系统,须重配 layer/mask) |
| 碰撞形状 | `Shape2D`(`BoxShape2D` 等) | `Shape3D`(`BoxShape3D` 等) |
| 机制 | body_entered / area_entered | **相同**(模式直接迁移) |

> 完整节点转换矩阵见 `adapt-2d-to-3d.md`。

## 示例脚本

### [pickup_trigger.gd](scripts/pickup_trigger.gd)
Area3D 收集触发:body_entered + 组优先 + signal 带 sender + queue_free。精简自 `demo/scenes/collectible.gd`(经 I3/C2 修复)。

## Common Gotchas

- **layer/mask 互补**:Area3D 与玩家 PhysicsBody3D 须在互补的 collision layer/mask 上,`body_entered` 才触发(3D 物理层独立于 2D,迁移时须重配)。
- **去重**:多收集物并发触发时,无参 signal 会让主控重复计分;signal 带 sender 主控方可按 sender 去重(C2)。
- **动态实例**:运行时 `instance` 的收集物(非场景树静态节点)须手动 `body_entered.connect` + 信号连主控,不依赖编辑器连线。

## Reference

- [`adapt-2d-to-3d`](../../../gd-agentic-skills/skills/godot-master/references/adapt-2d-to-3d.md) — Area2D→Area3D 转换、3D 物理层重配
- [`godot-physics-3d`](../../../gd-agentic-skills/skills/godot-physics-3d/SKILL.md) — Area3D 只检测不阻挡、3D collision layer/mask
- demo 实测:`demo/docs/03-production-log.md` F5/I3/C2(`:11,28,109-113`)
```

- [ ] **Step 3: 写 pickup_trigger.gd**

Create `skills/godot-area3d-collection/scripts/pickup_trigger.gd`(tab 缩进):

```gdscript
extends Area3D
## pickup_trigger.gd — Area3D 收集交互(组优先 + signal 带 sender)
## 精简自 demo/scenes/collectible.gd(经 I3/C2 修复 + 人工实测)。

# 带 sender 参数:主控可据此去重(C2),避免同一收集物重复计分。
signal collected(sender: Node)


func _ready() -> void:
	add_to_group("crystals")
	# connect 而非硬连外部方法:节点生命周期安全,运行时动态实例可重连。
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: PhysicsBody3D) -> void:
	# 组优先(I3):不硬判 is CharacterBody3D(过窄,NPC/载具拿不到)。
	if body.is_in_group("player"):
		collected.emit(self)
		queue_free()
```

- [ ] **Step 4: 验证脚本解析**

同 Task 1 Step 4:`execute_gdscript`(project_path=demo)内联 pickup_trigger.gd 内容做 `GDScript.reload()`。
**预期**:`ok=true`、`parse_err=0`。降级:read_script 对照 `demo/scenes/collectible.gd`(逐行一致 + 注释补充)。

- [ ] **Step 5: 验证 load_skill Case B 召回**

调用 `mcp__godot__load_skill`:
- query=`"Area3D body_entered signal collectible pickup"`(与 dogfood 原始 query 同构,含 `signal`,production-log:28)
- libraries=三目录(同 Task 1 Step 5)

**预期**:`godot-area3d-collection`(source=`skills`)是召回列表**第一名**(score 高于现状 `csharp-signals`/`godot-2d-physics` 等)。spec §6.2 Case B。
**机制核对**:确认 description 含 `Area3D`、`body_entered`、`signal`、`collectible`、`pickup`(每个 query term 在 description 命中)。

- [ ] **Step 6: Commit**

```bash
"C:/Program Files/Git/cmd/git.exe" -C "D:/GitHub/godot-ai-kit" add skills/godot-area3d-collection
"C:/Program Files/Git/cmd/git.exe" -C "D:/GitHub/godot-ai-kit" commit -m "feat(skills): godot-area3d-collection(填 F5 盲区)" -m "Area3D 收集交互 skill:body_entered+组优先+signal 带 sender+自销毁。示例脚本精简自 demo collectible.gd(I3/C2 修复)。load_skill Case B 第一名验证通过。" -m "Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 3: 接入 load_skill 召回链路(config 模板)

**Files:**
- Modify: `config/claude/settings.json:7`

**Interfaces:**
- Consumes: Task 1/2 已建 `skills/` 目录(否则 install 自检报软警告,非阻塞)
- Produces: 新部署的 `.claude/settings.json` `GODOT_SKILL_LIBRARIES` 含三目录;`install.ps1` Step5 自检自动覆盖 `${REPO_ROOT}/skills`

- [ ] **Step 1: 改 config 模板加第三目录**

Modify `config/claude/settings.json`,把 `GODOT_SKILL_LIBRARIES` 从两目录改三目录:

```json
{
  "mcpServers": {
    "godot-mcp-enhanced": {
      "command": "node",
      "args": ["${REPO_ROOT}/enhanced/build/index.js"],
      "env": {
        "GODOT_SKILL_LIBRARIES": "${REPO_ROOT}/GodotPrompter/skills,${REPO_ROOT}/gd-agentic-skills/skills,${REPO_ROOT}/skills"
      }
    }
  }
}
```

(只改 line 7 的 env 值,末尾加 `,${REPO_ROOT}/skills`)

- [ ] **Step 2: 确认 install 自检自动覆盖(读核,不改 install 逻辑)**

读 `install.ps1:158-168`(Step 5):`$envResolved = $envVal -replace '\$\{REPO_ROOT\}', $repoRootFwd` 后 `foreach ($lib in $libs) { Test-Path }`。逻辑对 `GODOT_SKILL_LIBRARIES` **所有**目录生效 → 改 config 模板后 `${REPO_ROOT}/skills` **自动纳入校验**,无需改 install.ps1/install.sh。

**软警告确认**:`install.ps1:165-167` 的 `Test-Path` 失败走 `Write-Host ... -ForegroundColor Yellow`(非 `Write-Fail` 硬退出)。若先改 config 后建 skills 目录(本 plan 顺序是先建后改,不触发),只打印无害黄色警告 `技能库路径不存在(可能子模块未就绪)`,不阻塞 install。

- [ ] **Step 3: dry 校验模板替换**

手动模拟 install 替换,确认三目录解析正确(PowerShell):

```powershell
$envVal = (Get-Content "D:/GitHub/godot-ai-kit/config/claude/settings.json" -Raw | ConvertFrom-Json).mcpServers.'godot-mcp-enhanced'.env.GODOT_SKILL_LIBRARIES
$envResolved = $envVal -replace '\$\{REPO_ROOT\}', 'D:/GitHub/godot-ai-kit'
($envResolved -split ',').Trim()
```

**预期**:输出三行 `D:/GitHub/godot-ai-kit/GodotPrompter/skills` / `D:/GitHub/godot-ai-kit/gd-agentic-skills/skills` / `D:/GitHub/godot-ai-kit/skills`,且 `Test-Path` 对三者皆 True(Task 1/2 已建 `skills/`)。

- [ ] **Step 4: Commit**

```bash
"C:/Program Files/Git/cmd/git.exe" -C "D:/GitHub/godot-ai-kit" add config/claude/settings.json
"C:/Program Files/Git/cmd/git.exe" -C "D:/GitHub/godot-ai-kit" commit -m "feat(config): GODOT_SKILL_LIBRARIES 加套件 skills 目录(召回链路接入)" -m "config/claude/settings.json 末尾加 \${REPO_ROOT}/skills,与两 submodule skills 三目录并列。install.ps1 Step5 自检自动覆盖(软警告非阻塞)。" -m "Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 4: 端到端验收 + 文档同步

**Files:**
- Modify(酌情): `NOTICE`、`docs/compatibility-matrix.md`(补"套件自带 skills 目录")
- Read(验收依据): spec §1 + §6.2

**Interfaces:**
- Consumes: Task 1/2/3 产出
- Produces: 验收清单全绿;文档同步套件 skills 目录

- [ ] **Step 1: 端到端 load_skill 复验 Case A + B(显式 libraries 三目录)**

调用 `mcp__godot__load_skill` 两次,libraries 均为三目录:
- Case A:query=`"CharacterBody3D movement NEVER"` → 断言 `godot-characterbody-3d` score > `godot-characterbody-2d`
- Case B:query=`"Area3D body_entered signal collectible pickup"` → 断言 `godot-area3d-collection` 第一名

**预期**:两条断言成立(spec §6.2)。记录实测 score 到本 plan 的执行日志 / Obsidian 开发日志。

- [ ] **Step 2: verify_recall.mjs 机制活证据(可选)**

从 spec §6.3 拷贝 `verify_recall.mjs` 代码到临时文件,`node` 跑:

```bash
node <spec §6.3 的 verify_recall.mjs,默认读 gd-agentic-skills/skills/godot-characterbody-2d/SKILL.md>
```

**预期**:对 query2 `CharacterBody movement NEVER` 输出 `0.633`(印证 spec §6.1 拆解);对 query1 `CharacterBody3D movement NEVER` 输出低分(连字符坑活证据,characterbody-2d 不含 3d)。
**注**:此脚本是逻辑复现,权威性次于真实 `load_skill`(Step 1),仅作机制证据。

- [ ] **Step 3: 文档同步(酌情,§7 attribution 透明化)**

在 `NOTICE` 或 `docs/compatibility-matrix.md` 补一条:套件根自带 `skills/` 目录(MIT,与 LGPLv3 submodule 真聚合;3D 玩法 skill 为原创,NEVER 文案不复制上游)。若现有文档已有"三 submodule"措辞,改为"两 submodule skills + 套件原生 skills 三目录"。

- [ ] **Step 4: 验收清单(spec §1 + §6.2 逐条确认)**

- [ ] 主验收 Case A:新 characterbody-3d > 现有 characterbody-2d(同 query)
- [ ] 主验收 Case B:新 area3d-collection = query2 第一名
- [ ] 辅验收:两示例脚本 `execute_gdscript GDScript.reload()` 解析 ok(T1/T2 Step 4)
- [ ] 辅验收:`config/claude/settings.json` 模板含三目录,`${REPO_ROOT}` 替换校验通过(T3 Step 3)
- [ ] 合规:未改 gd-agentic-skills 源;NEVER 文案原创;套件 MIT 标注(spec §7)

- [ ] **Step 5: Commit**

```bash
"C:/Program Files/Git/cmd/git.exe" -C "D:/GitHub/godot-ai-kit" add NOTICE docs/compatibility-matrix.md
"C:/Program Files/Git/cmd/git.exe" -C "D:/GitHub/godot-ai-kit" commit -m "docs: 套件 skills 目录同步(NOTICE/compatibility-matrix)" -m "端到端验收通过(load_skill Case A/B + 脚本解析 + config 替换)。补套件原生 skills/ 三目录说明,attribution 透明化。" -m "Co-Authored-By: Claude <noreply@anthropic.com>"
```

(若 Step 3 无改动可跳过本 commit)

---

## 验收总门(全 task 完成后)

- `skills/godot-characterbody-3d/`(SKILL.md + 脚本)+ `skills/godot-area3d-collection/`(SKILL.md + 脚本)存在且内容完整
- `config/claude/settings.json` `GODOT_SKILL_LIBRARIES` 三目录
- `load_skill` Case A/B 断言成立(真实工具,显式 libraries)
- git log 含 3-4 个 feat/docs commit(均带 Co-Authored-By)
- 未触碰 `gd-agentic-skills/` 任何源文件(`git diff` 确认 submodule 无改动)

## 后续(本 plan 范围外)

- 部署裂缝修复(项目级 settings.json 未被加载):独立任务,记忆 `dogfood-load-skill-link-status` 已记
- dogfood 复测(用新 skill 重跑 ③ 生产):可选验证
- 更多 3D skill(相机完整系统/3D 输入等):按需,YAGNI
