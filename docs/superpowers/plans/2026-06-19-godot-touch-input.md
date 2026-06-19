# godot-touch-input 原创技能 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: 用 superpowers:subagent-driven-development(推荐)或 superpowers:executing-plans 逐 task 执行。步骤用 checkbox(`- [ ]`)跟踪。

**Goal:** 在套件根新建原创 skill `godot-touch-input`(SKILL.md + 2 脚本),clean-room 覆盖 adapt-desktop-to-mobile 的 **C2/C3 camera 输入场景**(双兼容 ScreenTouch+MouseButton、`event.pressed` 守卫、Vector2 等比 zoom),并提供通用 `dual_input_handler` 双兼容 `_input` 模式供 joystick/gesture 修复参照。

**Architecture:** 套件根 `skills/godot-touch-input/`(MIT 自有领土)承载 skill。实现层 `.gd` 由**未接触 gd-agentic adapt-desktop-to-mobile 原文的干净 subagent** 在 worktree 隔离产出,**Godot 4 官方 InputEvent 文档为唯一事实来源**(spec M1 clean room 刚性)。退役靠 `GODOT_SKILL_LIBRARIES` 目录顺序 + load-skill-search.ts 的 stable sort tie-break(本 plan 实测验证并按需调整顺序)。

**Tech Stack:** GDScript(Godot 4.5+,tab 缩进)、Markdown(frontmatter SKILL.md,仿 `godot-characterbody-3d` 格式)、JSON(`config/claude/settings.json`)、enhanced MCP 工具(`execute_gdscript` 跑 headless 行为测试、`load_skill` 实测召回)。

**Spec:** `docs/superpowers/specs/2026-06-19-godot-touch-input-design.md`

---

## Global Constraints

(每个 task 的需求隐含包含本节)

- **⚠️ clean room 刚性(M1,最高优先级):**
  - **实现层 `.gd` 代码**必须由**未接触 gd-agentic `adapt-desktop-to-mobile` 任何原文**(SKILL.md / references/*.md / scripts/*.gd)的干净 subagent 在 **git worktree 隔离 + 新 session**(记忆不继承)下产出。
  - **唯一事实来源**:Godot 4 官方 InputEvent 文档 `https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html`(`InputEvent` / `InputEventScreenTouch` / `InputEventScreenDrag` / `InputEventMouseButton` / `InputEventMouseMotion` / `Camera2D.zoom`)。
  - **设计层概念**(双兼容分支、Vector2 zoom 等比、pressed 守卫、两指 pinch)由本 plan + spec 提供(通用 Godot 知识,非原文特定表达);干净 subagent 据此 + 官方文档独立写 `.gd`。
  - **plan 内的 `.gd` 代码块是「设计层目标实现」**(供 plan reviewer 审查 + 实现后对照基准),**clean room 合规**:基于 spec 设计 + 官方文档事实,非 adapt-desktop-to-mobile 的 SSO 派生。执行 subagent **不得逐字复制 plan 代码块**,须据官方文档独立实现后对照契约。
  - **attribution 头注**:每脚本头注须含「基于 Godot 4 官方 InputEvent 文档原创(clean room,disposal §5.2),非 gd-agentic 派生;实现 agent 未接触 gd-agentic 原文」+ 官方文档 URL(见 Task 2/3 头注模板)。
  - **本 plan 撰写 agent** 未读 adapt-desktop-to-mobile 原文(用户明令禁止),仅读 spec + 官方文档;撰写 session 视为干净。

- **Godot 4.5+**(项目 floor);GDScript **tab 缩进**(内置 Edit 改 .gd 失效,只用 enhanced `edit_script`/`write_script` 或干净 subagent 直接落盘)。

- **绝不修改 `gd-agentic-skills` 源文件**(LGPLv3 submodule,真聚合);新 skill 只在仓库根 `skills/` 新建。

- **License**:套件根 = MIT(自有)。新 skill 随套件 MIT。**NEVER 文案原创**,不逐字复制上游文案(规避 LGPLv3 衍生义务,见 spec §7/合规)。

- **Camera2D-only(A6)**:本 skill 脚本针对 `Camera2D`(有 `zoom: Vector2` 属性);`Camera3D` 无 zoom,3D 场景须改 `fov`/`size`,另开 spec。SKILL.md 顶部 + 每脚本头注须声明。

- **验证以实跑为准**:脚本解析用 `execute_gdscript` 的 `GDScript.reload()`;touch 契约(pressed 守卫 / 双兼容分支 / Vector2 factor / pinch 等比)用 `execute_gdscript` 构造 `InputEvent` 实例做**真实运行时行为断言**(非 `validate_scripts`,非仅解析)。

- **仓库根** = `D:/GitHub/godot-ai-kit`;本 plan 在 ai-kit 的 git worktree 执行(superpowers:using-git-worktrees),下文 `$WT` = 当前 worktree 根;git 命令用 `-C "$WT"`。

- **load_skill `libraries` 参数**:必须**绝对路径**、不含 `..`(`load-skill-search.ts:80-85` 校验);三目录 = `["D:/GitHub/godot-ai-kit/skills","D:/GitHub/godot-ai-kit/GodotPrompter/skills","D:/GitHub/godot-ai-kit/gd-agentic-skills/skills"]`(顺序见 Task 4 实测后定)。

- **召回机制**(`load-skill-search.ts:45-60`):`name` 命中 1.0 / `description` 0.6 / `body` 0.3,多 term 平均(`scoreMatch`)。
- **tie-break 机制**(`load-skill-search.ts:178`):`matches.sort((a,b) => b.score - a.score)` —— 降序 score,**同 score 时靠 JS sort 稳定性 + libraries 遍历顺序(`:140` for lib)** 决定先后,**无其他 tie-break 键**。⇒ **lib 顺序靠前的 skill 在同 score 时排前**。Task 4 实测据此调整。

- **git**:本机 Bash 沙箱 PATH 缺 `git`,用完整路径 `"C:/Program Files/Git/cmd/git.exe" -C "$WT" ...`;commit message 末尾加 `Co-Authored-By: Claude <noreply@anthropic.com>`。

---

## File Structure

| 文件 | 责任 | task |
|---|---|---|
| `skills/godot-touch-input/SKILL.md` | 触摸/鼠标输入 NEVER + 桌面/移动对照 + Camera2D-only 声明 + Gotchas + 官方文档 Reference | T1 |
| `skills/godot-touch-input/scripts/dual_input_handler.gd` | 通用双兼容 `_input` 模式(ScreenTouch+MouseButton 双分支 + pressed 守卫 + 信号接口)修 C2/M2 | T2 |
| `skills/godot-touch-input/scripts/touch_camera_pan_zoom.gd` | Camera2D pan(Vector2 factor)+ pinch(两指等比 ratio)+ 桌面 wheel,修 C3/M3 | T3 |
| `config/claude/settings.json` | `GODOT_SKILL_LIBRARIES` 顺序调整(套件根前置,让 godot-touch-input tie-break 胜出) | T4 |

---

### Task 1: SKILL.md(设计层文档 + 触发关键词)

**Files:**
- Create: `skills/godot-touch-input/SKILL.md`

**Interfaces:**
- Consumes: spec §技能结构(NEVER / 对照表 / Gotchas / Reference 要求);`godot-characterbody-3d/SKILL.md`(格式对齐参考,允许读);官方 InputEvent 文档 URL
- Produces: `load_skill(query="InputEventScreenTouch camera pan pinch zoom mouse", libraries=[三目录])` 可召回 `godot-touch-input`;Camera2D-only 声明落地(A6)

> 本 task 是文档,非 clean room 核心(无 `.gd` 实现逻辑),但仍由干净 subagent 在 worktree 落盘(统一执行口径)。description 须含无连字符类名 `InputEventScreenTouch` 等(召回机制:name 1.0 / desc 0.6)。

- [ ] **Step 1: 建目录**

```
skills/godot-touch-input/scripts/
```

- [ ] **Step 2: 写 SKILL.md**

Create `skills/godot-touch-input/SKILL.md`:

```markdown
---
name: godot-touch-input
description: "Expert patterns for dual touch + mouse input handling in Godot 4: InputEventScreenTouch + InputEventMouseButton dual-compatibility branches, event.pressed guards against double-trigger, InputEventScreenDrag + InputEventMouseMotion drag equivalence, Camera2D pan with Vector2 zoom factor, two-finger pinch zoom with index tracking, mouse wheel zoom. Use for mobile touch, virtual joystick, camera pan, pinch zoom, desktop debug with mouse, mobile_input. Camera2D only. Trigger keywords: InputEventScreenTouch, InputEventScreenDrag, InputEventMouseButton, InputEventMouseMotion, virtual_joystick, pinch_zoom, camera_pan, touch, mobile_input, Vector2 zoom, event.pressed, NEVER."
---

# 触摸/鼠标双兼容输入实现(Camera2D)

移动触摸与桌面鼠标的等价输入处理:双兼容 `ScreenTouch+MouseButton` 分支、`event.pressed` 守卫、Camera2D Vector2 等比 pan/pinch。

> **Camera2D-only(A6)**:本 skill 脚本针对 `Camera2D`(有 `zoom: Vector2` 属性)。`Camera3D` 无 zoom,3D 场景须改 `fov`/`size`,另开 spec。

**clean room**:基于 Godot 4 官方 InputEvent 文档原创(disposal §5.2),非 gd-agentic 派生;实现 agent 未接触 gd-agentic adapt-desktop-to-mobile 原文。

## NEVER Do

- **NEVER touch 只处理 `InputEventScreenTouch` 不补 `InputEventMouseButton`** — 缺鼠标分支则桌面/编辑器调试无法触发(C2)。**必须双兼容**:`ScreenTouch`(移动)+ `MouseButton button_index==MOUSE_BUTTON_LEFT`(桌面)两条分支。
- **NEVER 不检查 `event.pressed`** — touch/mouse 事件 pressed=true(按下)与 pressed=false(抬起)都触发 `_input`,不守卫则**双触发**(M2)。按下分支须 `if event.pressed:`。
- **NEVER 用 `1.0/zoom.x` 单分量缩放** — zoom 是 `Vector2`,取 `.x` 单分量做 factor 会**非等比缩放偏移**(C3)。pan 与 pinch **都禁**:pan 用 `Vector2.ONE / camera.zoom`(Vector2 factor),pinch 用 `camera.zoom * ratio`(Vector2 乘)。
- **NEVER 生产 camera pan 用 `_input`** — `_input` 在 GUI 之前调用,**点 UI(暂停按钮)也触发 pan**(穿透)。生产 camera pan 建议 `_unhandled_input`(GUI 拦截后才到);示例脚本用 `_input` 简化,SKILL 此处明示权衡(S2)。

## 桌面鼠标 vs 移动触摸对照

| 操作 | 移动触摸 | 桌面鼠标(等价) |
|---|---|---|
| 按下 | `InputEventScreenTouch`(`pressed=true`) | `InputEventMouseButton`(`button_index=MOUSE_BUTTON_LEFT`,`pressed=true`) |
| 拖动 | `InputEventScreenDrag`(`relative: Vector2`) | `InputEventMouseMotion`(`relative`)+ `Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)` |
| 缩放 | 两指 pinch(`InputEventScreenTouch` `index` 0/1) | 鼠标滚轮(`MOUSE_BUTTON_WHEEL_UP`/`_DOWN`) |

> `InputEventScreenDrag` 只有 `position`/`relative`,**无 from**(A2)——拖动起点的回溯须消费者自己累积。

## 示例脚本

### [dual_input_handler.gd](scripts/dual_input_handler.gd)
通用双兼容 `_input` 模式:ScreenTouch+MouseButton 双分支 + `pressed` 守卫 + `touch_occurred`/`drag_delta` 信号接口(解耦具体控件)。修 C2(缺鼠标分支)+ M2(pressed 守卫)。

### [touch_camera_pan_zoom.gd](scripts/touch_camera_pan_zoom.gd)
Camera2D 平移 + 双指缩放 + 桌面滚轮。pan 用 `Vector2.ONE/zoom`(Vector2 factor),pinch 两指 `index` 0/1 据距离比 `zoom=start_zoom*ratio`(等比)。修 C3(zoom.x 单分量)+ M3(Vector2 factor 钉死)。

## Common Gotchas(headless 测不出,只有真机才发现)

- **headless 测不出真实触摸**:触屏硬件事件只有真机/模拟器产生;headless 只能构造 `InputEvent` 实例验**逻辑分支**(pressed 守卫 / 双兼容 / Vector2 factor),**手感/惯性须真机人工**。
- **`_input` 穿透**:点 UI 按钮(暂停/菜单)会先经 `_input` 再到 GUI → camera pan 误触发。生产用 `_unhandled_input`(S2)。
- **mouse drag 无 pressed 字段**:`InputEventMouseMotion` 不带 pressed,须查 `Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)` 判断是否拖动中。
- **Camera2D-only**:Camera3D 无 `zoom`,3D 须改 `fov`/`size`(A6,另开 spec)。

## Reference

- Godot 4 官方 InputEvent 文档(唯一事实来源,clean room):`https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html`
- 输入事件处理顺序(官方):`_input`(GUI 前)→ GUI `_gui_input` → `_unhandled_input`(GUI 后);gameplay 输入官方推荐 `_unhandled_input`(允许 GUI 拦截)
```

- [ ] **Step 3: 验证 frontmatter + 关键词召回潜力**

调用 `mcp__godot__execute_gdscript`,project_path=`D:/GitHub/godot-ai-kit/demo`(或任意 Godot 项目,仅做字符串校验),code:

```gdscript
extends SceneTree
func _init():
	var f := FileAccess.open("$WT/skills/godot-touch-input/SKILL.md", FileAccess.READ)
	assert(f != null, "SKILL.md 不存在")
	var txt := f.get_as_text()
	assert(txt.find("name: godot-touch-input") >= 0)
	assert(txt.find("InputEventScreenTouch") >= 0 and txt.find("InputEventMouseButton") >= 0)
	assert(txt.find("Camera2D-only") >= 0 or txt.find("Camera2D only") >= 0)
	assert(txt.find("1.0/zoom.x") >= 0)  # NEVER 明示单分量禁用
	assert(txt.find("docs.godotengine.org") >= 0)  # 官方文档 Reference
	_mcp_output("sk_ok", true)
	_mcp_done()
```

**预期**:`sk_ok=true`。**降级**(若沙箱拦 FileAccess 绝对路径):用 enhanced `script read_script` 读 SKILL.md 全文,人工核对 6 个断言对应内容齐全。

- [ ] **Step 4: Commit**

```bash
"C:/Program Files/Git/cmd/git.exe" -C "$WT" add skills/godot-touch-input/SKILL.md
"C:/Program Files/Git/cmd/git.exe" -C "$WT" commit -m "feat(skills): godot-touch-input SKILL.md(触摸/鼠标双兼容)" -m "触摸+鼠标双兼容输入 skill 文档:双兼容 ScreenTouch+MouseButton / pressed 守卫 / Vector2 zoom 等比 / Camera2D-only。clean room 基于官方 InputEvent 文档,非 gd-agentic 派生。" -m "Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 2: dual_input_handler.gd(修 C2 双兼容 + M2 pressed 守卫 + A2 信号)

**Files:**
- Create: `skills/godot-touch-input/scripts/dual_input_handler.gd`
- Test: `execute_gdscript` 内联行为测试(headless)

**Interfaces:**
- Consumes: 官方 InputEvent 文档(`InputEventScreenTouch.pressed`/`.position`、`InputEventScreenDrag.position`/`.relative`、`InputEventMouseButton.button_index`/`.pressed`、`InputEventMouseMotion.relative`、`Input.is_mouse_button_pressed`);spec §dual_input_handler 设计
- Produces: `signal touch_occurred(position: Vector2)`、`signal drag_delta(position: Vector2, relative: Vector2)`(A2,供消费者订阅解耦)

> **⚠️ clean room**:本 task `.gd` 由干净 worktree subagent 据**官方 InputEvent 文档**独立实现,下方代码块是**设计层目标实现**(对照基准,不得逐字复制)。

- [ ] **Step 1: 写失败测试(execute_gdscript 行为断言)**

调用 `mcp__godot__execute_gdscript`,project_path=`D:/GitHub/godot-ai-kit/demo`,code(被测脚本由 Step 2 产出后内联为 `HANDLER_SRC`;此步先跑确认「脚本不存在 → FAIL」):

```gdscript
extends SceneTree

# Step 2 产出后,把 dual_input_handler.gd 完整内容逐字粘贴为下面多行字符串。
# 转义注意:GDScript 三引号字符串内保持 tab 缩进原样。
const HANDLER_SRC := """
<执行 agent:粘贴 dual_input_handler.gd 完整内容于此>
"""

func _init():
	var s := GDScript.new()
	s.source_code = HANDLER_SRC
	var err := s.reload()
	assert(err == OK, "dual_input_handler 解析失败 err=%d" % err)
	var h := s.new()
	var touches := []
	var drags := []
	h.touch_occurred.connect(func(p): touches.append(p))
	h.drag_delta.connect(func(p, r): drags.append([p, r]))

	# ── M2: ScreenTouch pressed=true 触发一次 ──
	var t1 := InputEventScreenTouch.new()
	t1.pressed = true
	t1.position = Vector2(100, 200)
	h._input(t1)
	assert(touches.size() == 1 and touches[0] == Vector2(100, 200), "M2 pressed=true 应触发")

	# ── M2: ScreenTouch pressed=false 不应再触发(防双触发)──
	var t2 := InputEventScreenTouch.new()
	t2.pressed = false
	t2.position = Vector2(100, 200)
	h._input(t2)
	assert(touches.size() == 1, "M2 pressed=false 不应触发(防双触发),实际 %d" % touches.size())

	# ── C2: MouseButton LEFT pressed=true 双兼容触发 ──
	var m1 := InputEventMouseButton.new()
	m1.button_index = MOUSE_BUTTON_LEFT
	m1.pressed = true
	m1.position = Vector2(50, 50)
	h._input(m1)
	assert(touches.size() == 2, "C2 MouseButton LEFT 应双兼容触发,实际 %d" % touches.size())

	# ── C2: MouseButton 非 LEFT 不触发(只等价 touch 主键)──
	var m2 := InputEventMouseButton.new()
	m2.button_index = MOUSE_BUTTON_RIGHT
	m2.pressed = true
	h._input(m2)
	assert(touches.size() == 2, "非 LEFT 不应触发")

	# ── A2: ScreenDrag → drag_delta(position, relative) ──
	var d1 := InputEventScreenDrag.new()
	d1.position = Vector2(10, 10)
	d1.relative = Vector2(5, 7)
	h._input(d1)
	assert(drags.size() == 1 and drags[0][1] == Vector2(5, 7), "A2 ScreenDrag relative")

	_mcp_output("handler_pass", true)
	_mcp_done()
```

**预期(此步)**:`reload()` 失败或断言失败(脚本未实现)。确认测试框架本身可跑(execute_gdscript 不报语法错)。

- [ ] **Step 2: 干净 subagent 据官方文档实现(RED → GREEN)**

干净 worktree subagent 据**官方 InputEvent 文档** + 下方设计契约,独立实现 `skills/godot-touch-input/scripts/dual_input_handler.gd`(tab 缩进)。

**设计契约(必须满足):**
- `extends Node`
- 头注:clean room 声明 + 官方文档 URL + 修 C2/M2 说明(见下方头注模板)
- `signal touch_occurred(position: Vector2)`、`signal drag_delta(position: Vector2, relative: Vector2)`
- `func _input(event: InputEvent) -> void:`
  - `InputEventScreenTouch`:`if event.pressed:` → `touch_occurred.emit(event.position)`(M2 守卫)
  - `elif InputEventMouseButton`:`if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:` → `touch_occurred.emit(event.position)`(C2 双兼容)
  - `InputEventScreenDrag` → `drag_delta.emit(event.position, event.relative)`
  - `elif InputEventMouseMotion`:`if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):` → `drag_delta.emit(event.position, event.relative)`

**头注模板(逐字要求 clean room 声明):**
```gdscript
## dual_input_handler.gd — 通用双兼容输入处理(移动触摸 + 桌面鼠标)
## 基于 Godot 4 官方 InputEvent 文档原创(clean room,disposal §5.2),
## 非 gd-agentic 派生;实现 agent 未接触 gd-agentic adapt-desktop-to-mobile 原文。
## 官方文档:https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html
##
## 修 C2(缺 InputEventMouseButton 分支 → 桌面/编辑器调试无法触发)
##   + M2(必检查 event.pressed,防双触发)。
## 信号接口(A2)解耦具体控件:消费者订阅信号,不关心 touch 还是 mouse 来源。
```

**设计层目标实现(对照基准,执行 subagent 不得逐字复制,据官方文档独立写后对照):**
```gdscript
extends Node
## dual_input_handler.gd — 通用双兼容输入处理(移动触摸 + 桌面鼠标)
## 基于 Godot 4 官方 InputEvent 文档原创(clean room,disposal §5.2),
## 非 gd-agentic 派生;实现 agent 未接触 gd-agentic adapt-desktop-to-mobile 原文。
## 官方文档:https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html
##
## 修 C2(缺 InputEventMouseButton 分支 → 桌面/编辑器调试无法触发)
##   + M2(必检查 event.pressed,防双触发)。
## 信号接口(A2)解耦具体控件:消费者订阅信号,不关心 touch 还是 mouse 来源。

# 按下瞬间(只 pressed=true 触发一次,M2 防双触发)。
signal touch_occurred(position: Vector2)
# 拖动增量(InputEventScreenDrag 只有 position/relative,无 from —— A2)。
signal drag_delta(position: Vector2, relative: Vector2)


func _input(event: InputEvent) -> void:
	# ── 按下(touch / mouse 等价,C2 双兼容 + M2 pressed 守卫)──
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_occurred.emit(event.position)
	elif event is InputEventMouseButton:
		# C2 核心:补 MouseButton 分支,桌面/编辑器调试可触发。
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			touch_occurred.emit(event.position)
	# ── 拖动(touch drag / mouse drag 等价)──
	if event is InputEventScreenDrag:
		drag_delta.emit(event.position, event.relative)
	elif event is InputEventMouseMotion:
		# mouse drag:InputEventMouseMotion 无 pressed 字段,查 Input 单例判断左键按住。
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			drag_delta.emit(event.position, event.relative)
```

- [ ] **Step 3: 跑测试验通过(GREEN)**

把 Step 2 产出的 `.gd` 完整内容内联为 Step 1 测试的 `HANDLER_SRC`,重跑 `execute_gdscript`。

**预期**:`handler_pass=true`(M2 pressed 守卫 + C2 双兼容 + A2 信号 全断言通过)。

- [ ] **Step 4: clean room 自检 + 对照契约**

- [ ] 实现脚本头注含 clean room 声明 + 官方文档 URL(read_script 核对)
- [ ] 实现含 `InputEventScreenTouch` + `InputEventMouseButton`(C2 双兼容)
- [ ] 实现 `event.pressed` 守卫(M2,grep `event.pressed` 命中按下分支)
- [ ] 实现未逐字复制 plan 对照基准(执行 subagent 自述独立据官方文档写)
- [ ] **执行 subagent 确认未读** gd-agentic adapt-desktop-to-mobile 任何原文(clean room 宣誓)

- [ ] **Step 5: Commit**

```bash
"C:/Program Files/Git/cmd/git.exe" -C "$WT" add skills/godot-touch-input/scripts/dual_input_handler.gd
"C:/Program Files/Git/cmd/git.exe" -C "$WT" commit -m "feat(skills): dual_input_handler.gd(修 C2 双兼容 + M2 pressed 守卫)" -m "通用双兼容 _input 模式:ScreenTouch+MouseButton 双分支 + event.pressed 守卫 + touch_occurred/drag_delta 信号接口。headless 行为测试通过(M2 防双触发 + C2 双兼容 + A2 信号)。clean room 据官方 InputEvent 文档独立实现。" -m "Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 3: touch_camera_pan_zoom.gd(修 C3 Vector2 + M3 pan factor + pinch 等比 + 桌面 wheel)

**Files:**
- Create: `skills/godot-touch-input/scripts/touch_camera_pan_zoom.gd`
- Test: `execute_gdscript` 内联行为测试(headless)

**Interfaces:**
- Consumes: 官方 InputEvent 文档(`InputEventScreenTouch.index`/`.pressed`/`.position`、`InputEventScreenDrag.index`/`.relative`/`.position`、`InputEventMouseButton.button_index` `MOUSE_BUTTON_WHEEL_*`、`Camera2D.zoom: Vector2`、`Camera2D.offset: Vector2`);spec §touch_camera_pan_zoom 设计
- Produces: Camera2D pan/pinch/wheel 控制器(挂载后设 `camera` 引用即用);Camera2D-only 声明

> **⚠️ clean room**:同 Task 2,`.gd` 由干净 worktree subagent 据官方文档独立实现。

- [ ] **Step 1: 写失败测试(execute_gdscript 行为断言)**

调用 `mcp__godot__execute_gdscript`,project_path=`D:/GitHub/godot-ai-kit/demo`,code:

```gdscript
extends SceneTree

const CAM_SRC := """
<执行 agent:粘贴 touch_camera_pan_zoom.gd 完整内容于此>
"""

func _init():
	var s := GDScript.new()
	s.source_code = CAM_SRC
	assert(s.reload() == OK, "touch_camera_pan_zoom 解析失败")
	var cs := s.new()
	var cam := Camera2D.new()
	cs.camera = cam  # 注入 Camera2D 引用

	# ── M3: pan 用 Vector2 factor(NEVER 1.0/zoom.x)──
	# zoom=(2,2) → factor=ONE/zoom=(0.5,0.5);offset -= relative*factor = -(10,0)*(0.5,0.5)=(-5,0)
	cam.zoom = Vector2(2, 2)
	cam.offset = Vector2.ZERO
	cs._apply_pan(Vector2(10, 0))
	assert(cam.offset == Vector2(-5, 0), "M3 pan Vector2 factor: %s" % str(cam.offset))

	# ── C3 反向:zoom 非等比时 pan 仍逐分量等比(factor 与 zoom 分量对应)──
	cam.zoom = Vector2(2, 4)
	cam.offset = Vector2.ZERO
	cs._apply_pan(Vector2(10, 10))
	# factor=ONE/(2,4)=(0.5,0.25);offset=-(10,10)*(0.5,0.25)=(-5,-2.5)
	assert(cam.offset == Vector2(-5, -2.5), "C3 非等比 zoom pan 逐分量: %s" % str(cam.offset))

	# ── A4/A5: pinch 两指 index 0/1 → zoom 各分量同比(比值恒定,非 == )──
	cam.zoom = Vector2(2, 2)
	cam.offset = Vector2.ZERO
	var p0 := InputEventScreenTouch.new()
	p0.index = 0
	p0.pressed = true
	p0.position = Vector2(0, 0)
	cs._input(p0)
	var p1 := InputEventScreenTouch.new()
	p1.index = 1
	p1.pressed = true
	p1.position = Vector2(100, 0)  # 起始两指距离 100
	cs._input(p1)
	# drag index 1 移到 (200,0) → 当前距离 200 → ratio=2 → zoom=start_zoom*2=(4,4)
	var d1 := InputEventScreenDrag.new()
	d1.index = 1
	d1.position = Vector2(200, 0)
	cs._input(d1)
	# A5: zoom.x/zoom.y 比值恒定(此处初始等比 2/2=1 → 4/4=1);用比值断言避免初始非等比假阴
	var ratio_xy: float = cam.zoom.x / cam.zoom.y
	assert(abs(ratio_xy - 1.0) < 0.001, "A5 pinch 等比(比值恒定): %s ratio=%f" % [str(cam.zoom), ratio_xy])
	assert(abs(cam.zoom.x - 4.0) < 0.001 and abs(cam.zoom.y - 4.0) < 0.001, "pinch zoom=start*ratio: %s" % str(cam.zoom))

	# ── A5 补强:初始非等比 zoom 时 pinch 仍保比值恒定(防 zoom.x==zoom.y 假阴)──
	cam.zoom = Vector2(2, 3)  # 初始非等比
	cam.offset = Vector2.ZERO
	var cs2 := s.new()
	cs2.camera = cam
	# 重置 pinch 状态(两指重落)
	var q0 := InputEventScreenTouch.new(); q0.index = 0; q0.pressed = true; q0.position = Vector2(0, 0); cs2._input(q0)
	var q1 := InputEventScreenTouch.new(); q1.index = 1; q1.pressed = true; q1.position = Vector2(100, 0); cs2._input(q1)
	var qd := InputEventScreenDrag.new(); qd.index = 1; qd.position = Vector2(150, 0); cs2._input(qd)
	# ratio=1.5 → zoom=(2*1.5, 3*1.5)=(3, 4.5);比值 3/4.5=0.667 == 2/3=0.667 恒定
	var r2: float = cam.zoom.x / cam.zoom.y
	assert(abs(r2 - (2.0/3.0)) < 0.001, "A5 初始非等比 pinch 保比值: %s ratio=%f" % [str(cam.zoom), r2])

	_mcp_output("cam_pass", true)
	_mcp_done()
```

**预期(此步)**:`reload()` 失败或断言失败(`_apply_pan`/`_input`/pinch 未实现)。

- [ ] **Step 2: 干净 subagent 据官方文档实现(RED → GREEN)**

干净 worktree subagent 据**官方 InputEvent 文档** + 下方设计契约,独立实现 `skills/godot-touch-input/scripts/touch_camera_pan_zoom.gd`(tab 缩进)。

**设计契约(必须满足):**
- `extends Node`,头注 clean room 声明 + 官方文档 URL + Camera2D-only(A6)+ 修 C3/M3 说明
- `@export var camera: Camera2D`
- pinch 状态:`var _pinch: Dictionary`(index→position)、`_pinch_start_dist: float`、`_pinch_start_zoom: Vector2`
- `func _apply_pan(relative: Vector2) -> void:`:`var factor: Vector2 = Vector2.ONE / camera.zoom`;`camera.offset -= relative * factor`(**M3:Vector2 factor,NEVER `1.0/zoom.x`**)
- `func _input(event: InputEvent) -> void:` 分发:
  - `InputEventScreenTouch`:pressed 记/erase `_pinch[event.index]`;两指就位(size==2)时记 `_pinch_start_dist` + `_pinch_start_zoom`
  - `InputEventScreenDrag`:更新 `_pinch[event.index]`;两指时据 `cur_dist/_pinch_start_dist` ratio 算 `camera.zoom = _pinch_start_zoom * ratio`(Vector2 乘,等比);单指时 `_apply_pan(event.relative)`
  - `InputEventMouseButton`:`MOUSE_BUTTON_WHEEL_UP`→放大,`_DOWN`→缩小(桌面 wheel)
- zoom clamp(Vector2 各分量 clamp 到 [_MIN_ZOOM, _MAX_ZOOM])

**头注模板(逐字要求):**
```gdscript
## touch_camera_pan_zoom.gd — Camera2D 平移 + 双指缩放 + 桌面滚轮
## 基于 Godot 4 官方 InputEvent 文档原创(clean room,disposal §5.2),
## 非 gd-agentic 派生;实现 agent 未接触 gd-agentic adapt-desktop-to-mobile 原文。
## 官方文档:https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html
##
## Camera2D-only(A6):Camera2D 有 zoom(Vector2);Camera3D 无 zoom,3D 须改 fov/size,另开 spec。
## 修 C3(zoom.x 单分量 → 非等比缩放偏移)+ M3(pan factor 钉死 Vector2,pan/pinch 都禁 1.0/zoom.x)。
```

**设计层目标实现(对照基准,执行 subagent 不得逐字复制):**
```gdscript
extends Node
## touch_camera_pan_zoom.gd — Camera2D 平移 + 双指缩放 + 桌面滚轮
## 基于 Godot 4 官方 InputEvent 文档原创(clean room,disposal §5.2),
## 非 gd-agentic 派生;实现 agent 未接触 gd-agentic adapt-desktop-to-mobile 原文。
## 官方文档:https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html
##
## Camera2D-only(A6):Camera2D 有 zoom(Vector2);Camera3D 无 zoom,3D 须改 fov/size,另开 spec。
## 修 C3(zoom.x 单分量 → 非等比缩放偏移)+ M3(pan factor 钉死 Vector2,pan/pinch 都禁 1.0/zoom.x)。

@export var camera: Camera2D

# 双指 pinch 状态:index(int) -> position(Vector2)
var _pinch: Dictionary = {}
var _pinch_start_dist: float = 0.0
var _pinch_start_zoom: Vector2 = Vector2.ONE

const _MIN_ZOOM := 0.1
const _MAX_ZOOM := 10.0
const _WHEEL_STEP := 1.1


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_pinch_touch(event)
	elif event is InputEventScreenDrag:
		if _pinch.has(event.index):
			_pinch[event.index] = event.position
			if _pinch.size() == 2 and _pinch_start_dist > 0.0:
				# pinch:ratio 等比(Vector2 乘,NEVER zoom.x 单分量)
				var ratio := _current_pinch_dist() / _pinch_start_dist
				camera.zoom = _clamp_zoom(_pinch_start_zoom * ratio)
			else:
				_apply_pan(event.relative)
		else:
			_apply_pan(event.relative)
	elif event is InputEventMouseButton:
		_handle_wheel(event)


# pan:Vector2 factor(M3 钉死 Vector2,NEVER 1.0/zoom.x —— pan/pinch 都禁)。
func _apply_pan(relative: Vector2) -> void:
	var factor: Vector2 = Vector2.ONE / camera.zoom
	camera.offset -= relative * factor


func _handle_pinch_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_pinch[event.index] = event.position
		if _pinch.size() == 2:
			_pinch_start_dist = _current_pinch_dist()
			_pinch_start_zoom = camera.zoom
	else:
		_pinch.erase(event.index)


func _current_pinch_dist() -> float:
	var pts: Array = _pinch.values()
	if pts.size() < 2:
		return 0.0
	return float((pts[0] as Vector2).distance_to(pts[1] as Vector2))


func _handle_wheel(event: InputEventMouseButton) -> void:
	# 桌面滚轮缩放(Vector2 乘 scalar,等比)
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		camera.zoom = _clamp_zoom(camera.zoom * _WHEEL_STEP)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		camera.zoom = _clamp_zoom(camera.zoom / _WHEEL_STEP)


func _clamp_zoom(z: Vector2) -> Vector2:
	return Vector2(clamp(z.x, _MIN_ZOOM, _MAX_ZOOM), clamp(z.y, _MIN_ZOOM, _MAX_ZOOM))
```

- [ ] **Step 3: 跑测试验通过(GREEN)**

把 Step 2 产出的 `.gd` 内联为 Step 1 测试的 `CAM_SRC`,重跑 `execute_gdscript`。

**预期**:`cam_pass=true`(M3 Vector2 pan + C3 非等比逐分量 + A4/A5 两指 pinch 等比/比值恒定 全通过)。

- [ ] **Step 4: M3 单分量禁用静态自检**

调用 `execute_gdscript`(或 read_script + grep),确认 `touch_camera_pan_zoom.gd` 全文**不含** `1.0/zoom.x` / `zoom.x` 单分量做 factor(grep `zoom\.x` 应只出现在注释/头注的「禁用」说明里,不出现于 factor 计算):

```gdscript
extends SceneTree
func _init():
	var f := FileAccess.open("$WT/skills/godot-touch-input/scripts/touch_camera_pan_zoom.gd", FileAccess.READ)
	var src := f.get_as_text()
	var lines := src.split("\n")
	var violations := []
	for i in lines.size():
		var ln := lines[i]
		# 跳过注释行(# 开头)
		if ln.strip_edges().begins_with("#"):
			continue
		# 非注释行出现 zoom.x / zoom.y 单分量做除法/factor → 违规
		if ln.find("zoom.x") >= 0 or ln.find("zoom.y") >= 0:
			violations.append("L%d: %s" % [i+1, ln])
	_mcp_output("zoom_single_component_violations", violations)
	_mcp_done()
```

**预期**:`zoom_single_component_violations=[]`(空)。**降级**:read_script 全文人工核对 pan/pinch 路径只用 `Vector2.ONE / camera.zoom` 与 `zoom * ratio/scalar`,无 `.x`/`.y` 单分量。

- [ ] **Step 5: clean room 自检 + Commit**

- [ ] 头注含 clean room 声明 + 官方文档 URL + Camera2D-only(A6)
- [ ] pan 用 `Vector2.ONE / camera.zoom`(M3)、pinch 用 `zoom * ratio`(等比)
- [ ] 执行 subagent 宣誓未读 gd-agentic adapt-desktop-to-mobile 原文

```bash
"C:/Program Files/Git/cmd/git.exe" -C "$WT" add skills/godot-touch-input/scripts/touch_camera_pan_zoom.gd
"C:/Program Files/Git/cmd/git.exe" -C "$WT" commit -m "feat(skills): touch_camera_pan_zoom.gd(修 C3 Vector2 + M3 pan factor + pinch 等比)" -m "Camera2D pan(Vector2.ONE/zoom)+pinch(两指 index 0/1 距离比 zoom=start*ratio)+桌面 wheel。headless 测试通过(M3 Vector2 pan + C3 非等比逐分量 + A4/A5 pinch 比值恒定)。Camera2D-only(A6)。clean room 据官方 InputEvent 文档独立实现。" -m "Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 4: 退役机制实测 + config 顺序调整(S3 fallback 落实)

**Files:**
- Modify: `config/claude/settings.json`(`GODOT_SKILL_LIBRARIES` 顺序)
- Read(机制依据): `D:/GitHub/godot-mcp-enhanced/src/tools/load-skill-search.ts:140,178`(已读:tie-break = stable sort + lib 遍历顺序,无其他键)

**Interfaces:**
- Consumes: Task 1/2/3 已建 `skills/godot-touch-input/`;load-skill-search.ts tie-break 机制
- Produces: `load_skill` camera query 召回 `godot-touch-input` **优先于** `godot-adapt-desktop-to-mobile`(退役生效);characterbody-3d Case A 不回归

> spec §退役 S3 明示「stable-sort + lib 顺序是**未验证假设**,plan 实现时验证,若有其他 tie-break 键则调整」。本 task 实测驱动(归因铁律:不以静态推断下结论,必实测前后对比)。

- [ ] **Step 1: 读当前 config 顺序**

读 `config/claude/settings.json` 的 `GODOT_SKILL_LIBRARIES`,确认当前目录顺序。**预期**(3d-gameplay-skills plan Task 3 所定):`GodotPrompter/skills, gd-agentic-skills/skills, skills`(套件根在末尾)。

- [ ] **Step 2: 实测 load_skill camera query(当前顺序)→ godot-touch-input 是否优先**

调用 `mcp__godot__load_skill`:
- query=`"InputEventScreenTouch camera pan pinch zoom mouse"`
- libraries=当前三目录(Step 1 读到的顺序)

**观察**:召回列表中 `godot-touch-input`(source=`skills`)与 `godot-adapt-desktop-to-mobile`(source=`gd-agentic-skills`)的**相对排名 + 各自 score**。

**判定**:
- 若两者 score 不同 → 不依赖 tie-break,score 高者优先(记录实测 score,退役是否生效取决于 description 关键词命中,见 Step 5 机制核对)。
- 若两者 score **相同** → 按 `load-skill-search.ts:178` stable sort + lib 顺序:当前套件根 `skills` 在**末尾** → **`godot-adapt-desktop-to-mobile`(在前)优先,`godot-touch-input` 落后** → **退役失败**。⇒ 进 Step 3 调整顺序。

- [ ] **Step 3: 调整 config(套件根 skills 前置到 gd-agentic 之前)**

仅当 Step 2 判定「同 score 且 adapt-desktop-to-mobile 优先」时执行(若 score 不同且 godot-touch-input 已优先,跳过本 step,Step 5 记录)。把套件根 `skills` 提到 `gd-agentic-skills/skills` **之前**:

```json
{
  "mcpServers": {
    "godot-mcp-enhanced": {
      "command": "node",
      "args": ["${REPO_ROOT}/enhanced/build/index.js"],
      "env": {
        "GODOT_SKILL_LIBRARIES": "${REPO_ROOT}/skills,${REPO_ROOT}/GodotPrompter/skills,${REPO_ROOT}/gd-agentic-skills/skills"
      }
    }
  }
}
```

(套件根 `${REPO_ROOT}/skills` 提到最前;GodotPrompter 居中;gd-agentic 最后。⇒ 同 score 时套件根优先,符合「MIT 原创领土优先于 LGPLv3 submodule」的退役意图。)

**对 3d-gameplay-skills plan Task 3 的影响**:characterbody-3d 靠 **score 胜出**(description 含无连字符 `CharacterBody3D`,characterbody-2d 不含 → score 不同),**不依赖 tie-break** ⇒ 前置套件根对 Case A 无影响(Task 5 Step 2 复验确认)。

- [ ] **Step 4: 复验退役生效 + Case A 不回归**

调用 `mcp__godot__load_skill` 两次,libraries 均为**调整后三目录**(套件根前置):

1. **退役复验**:query=`"InputEventScreenTouch camera pan pinch zoom mouse"`
   - **预期**:`godot-touch-input`(source=`skills`)排名 **不低于** `godot-adapt-desktop-to-mobile`(source=`gd-agentic-skills`);若同 score 则 `godot-touch-input` **在前**(套件根前置 + stable sort)。

2. **Case A 不回归**:query=`"CharacterBody3D movement NEVER"`
   - **预期**:`godot-characterbody-3d`(source=`skills`)score **仍 >** `godot-characterbody-2d`(source=`gd-agentic-skills`)(score 不同,顺序调整无影响)。

- [ ] **Step 5: 机制核对 + description 关键词确保**

若 Step 4 退役复验中 `godot-touch-input` score **低于** `godot-adapt-desktop-to-mobile`(非 tie,真低分):核对 SKILL.md `description` 含 query 的每个 term 的无连字符形式(`InputEventScreenTouch`/`camera`/`pan`/`pinch`/`zoom`/`mouse`),让每个 term 在 description 命中 0.6(name 1.0 需 query term 含 `godot-touch-input` 的子串)。必要时补关键词到 description(召回机制:`load-skill-search.ts:45-60`)。

**fallback 透明化**(spec §退役 S3):在 commit message / 开发日志记录实测 tie-break 结论(stable sort + lib 顺序,无其他键)+ 调整依据(套件根前置让 tie-break 胜出)。

- [ ] **Step 6: Commit(若有 config 改动)**

```bash
"C:/Program Files/Git/cmd/git.exe" -C "$WT" add config/claude/settings.json
"C:/Program Files/Git/cmd/git.exe" -C "$WT" commit -m "fix(config): GODOT_SKILL_LIBRARIES 套件根 skills 前置(touch-input 退役 tie-break)" -m "load-skill-search.ts:178 tie-break=stable sort+lib 顺序(无其他键);套件根原在末尾致同 score 时 adapt-desktop-to-mobile 优先、touch-input 退役失败。前置套件根让 godot-touch-input tie-break 胜出。characterbody-3d 靠 score 胜出不回归(Task 5 复验)。spec §退役 S3 fallback 实测落实。" -m "Co-Authored-By: Claude <noreply@anthropic.com>"
```

(若 Step 2 实测显示 godot-touch-input 已靠 score 优先、无需调整顺序,则跳过本 commit,在日志记录「无需调整,score 已胜出」。)

---

### Task 5: 端到端验收 + attribution 文档同步

**Files:**
- Modify(酌情): `NOTICE`、`docs/compatibility-matrix.md`(补 godot-touch-input + clean room 声明)
- Read(验收依据): spec §验收

**Interfaces:**
- Consumes: Task 1-4 产出
- Produces: 验收清单全绿;attribution/clean room 透明化

- [ ] **Step 1: 端到端 load_skill 退役复验**

调用 `mcp__godot__load_skill`,query=`"InputEventScreenTouch camera pan pinch zoom mouse"`,libraries=调整后三目录。

**预期**:`godot-touch-input`(source=`skills`)在召回列表中,且排名不低于 `godot-adapt-desktop-to-mobile`(退役生效)。记录实测 score + 排名到开发日志。

- [ ] **Step 2: Case A 不回归复验**

`load_skill` query=`"CharacterBody3D movement NEVER"` → `godot-characterbody-3d` score 仍 > `godot-characterbody-2d`。

- [ ] **Step 3: 验收清单(spec §验收逐条)**

- [ ] `skills/godot-touch-input/` 含 SKILL.md + `dual_input_handler.gd` + `touch_camera_pan_zoom.gd`
- [ ] 两脚本头注含 attribution(官方文档 URL + clean room 声明 + 实现未接触 gd-agentic 原文)
- [ ] `dual_input_handler`:ScreenTouch+MouseButton 双分支 + `event.pressed` 守卫(M2),headless 测试通过
- [ ] `touch_camera_pan_zoom`:pan `Vector2.ONE/zoom` + pinch `zoom*ratio`,pan/pinch 都禁 `1.0/zoom.x`(M3),headless 测试通过
- [ ] Camera2D-only 声明(A6):SKILL.md + touch_camera_pan_zoom 头注
- [ ] headless:pressed 守卫 + 双兼容 + 两指 pinch 各分量同比(A4/A5)全通过
- [ ] `load_skill` camera query 套件版优先(退役生效,Task 4 实测)
- [ ] 实现层 `.gd` 由干净 agent(新 session + worktree + 官方文档唯一来源)产出(M1)

- [ ] **Step 4: attribution 文档同步(酌情)**

在 `NOTICE` 或 `docs/compatibility-matrix.md` 补一条:`godot-touch-input`(套件根 MIT 原创,clean room 基于 Godot 官方 InputEvent 文档,非 gd-agentic 派生;覆盖 adapt-desktop-to-mobile C2/C3 camera 场景)。若现有文档有「三目录」措辞,说明套件根 skills 已前置(tie-break 让套件版优先)。

- [ ] **Step 5: Commit(若有文档改动)**

```bash
"C:/Program Files/Git/cmd/git.exe" -C "$WT" add NOTICE docs/compatibility-matrix.md
"C:/Program Files/Git/cmd/git.exe" -C "$WT" commit -m "docs: godot-touch-input attribution + clean room 声明同步" -m "端到端验收通过(load_skill 退役复验 + Case A 不回归 + 两脚本 headless 行为测试 + clean room 自检)。补 godot-touch-input MIT 原创 + clean room 声明,套件根 skills 前置说明。" -m "Co-Authored-By: Claude <noreply@anthropic.com>"
```

(若 Step 4 无改动可跳过。)

---

## 验收总门(全 task 完成后)

- `skills/godot-touch-input/`(SKILL.md + 2 脚本)存在且内容完整,attribution + Camera2D-only 声明齐全
- 两脚本 `execute_gdscript` headless 行为测试全绿(dual_input_handler: M2/C2/A2;touch_camera_pan_zoom: M3/C3/A4/A5)
- `config/claude/settings.json` 套件根 skills 前置(或实测确认无需调整),`load_skill` camera query `godot-touch-input` 优先于 `godot-adapt-desktop-to-mobile`
- characterbody-3d Case A 不回归
- git log 含 4-5 个 feat/fix/docs commit(均带 Co-Authored-By)
- 未触碰 `gd-agentic-skills/` 任何源文件(`git diff` 确认 submodule 无改动)
- clean room:实现 `.gd` 由干净 worktree subagent 据官方文档独立产出,未读 adapt-desktop-to-mobile 原文

## 后续(本 plan 范围外,spec §不做 / §范围诚实声明)

- **joystick/gesture(C2 另两脚本)**:本 skill 只提供 camera 场景 `.gd` + 通用双兼容模式;joystick_spawner / gesture_combo 无套件 `.gd` 替代 → gd-agentic 版仍召回,C2 风险未全消,**另开 spec**(spec §范围诚实声明)
- **Camera3D 缩放**:Camera3D 无 zoom,3D 须改 `fov`/`size`,**另开 spec**(A6)
- **C1 HMAC 完整性校验**:security theater,不做(spec §7)
- **改 gd-agentic 源码 / clean room 内化 / 整 adapt-desktop-to-mobile 重写**:均不做(spec §7,合规同源关闭)
