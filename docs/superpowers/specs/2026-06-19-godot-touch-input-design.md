# godot-touch-input 原创技能设计（Phase 2 首个）

> **来源**：gd-agentic disposal 规范 §5（Phase 2 原创替代路线）。本规范为 Phase 2 首个原创技能的独立设计。
> **clean room**：继承 disposal §5.2（不逐字复制 gd-agentic；单人看过原文 ≠ clean room）+ 3d-gameplay attribution 二分。
> **For agentic workers**：本规范经 brainstorming 评审通过（approach A），下一步进 writing-plans。

## Goal

套件根原创 `godot-touch-input` 技能，基于 clean-room（Godot 官方 InputEvent 文档）覆盖 adapt-desktop-to-mobile 的 **C2/C3** CRITICAL 场景（触摸+鼠标双兼容输入、相机等比缩放）。前置套件 `skills/` 后经 `load_skill` tie-break 优先召回，实现减险 + 启动退役机制（disposal §5.3）。

## 背景

- **C2**：gd-agentic adapt-desktop-to-mobile 的 `dynamic_joystick_spawner`/`gesture_combo_system`/`touch_camera_pan_zoom` 只处理 `InputEventScreenTouch`，缺 `InputEventMouseButton` 分支 → 桌面/编辑器调试无法触发（审查报告 CRITICAL-2，`:103`）。
- **C3**：`touch_camera_pan_zoom` 用 `1.0/zoom.x` 单分量缩放，忽略 zoom.y → 非等比缩放方向偏移（审查报告 CRITICAL-3）。
- **clean room 约束**（disposal §5.2 + §7）：不逐字复制 gd-agentic 源；**单人看过 gd-agentic 原文 ≠ clean room**（SSO 派生风险）。本会话 agent 已读 `adapt-desktop-to-mobile.md`，**不能基于它改写**；来源改用 Godot 官方 InputEvent 文档。
- **dogfood 缺位**：ai-kit demo 无移动端/touch 代码（disposal §5.2 首选"从 dogfood 提炼"在移动端无来源），故采用官方文档原创（评审 approach C）。

## 范围

**做**：2 脚本，覆盖 C2/C3 输入处理场景：
1. `dual_input_handler.gd` — `_input()` 同时分支 `InputEventScreenTouch`/`InputEventScreenDrag`（移动）+ `InputEventMouseButton`/`InputEventMouseMotion`（桌面/编辑器调试）。**修 C2**。
2. `touch_camera_pan_zoom.gd` — 1指相对 pan + 2指 pinch zoom，**zoom 用 Vector2 除法（`1.0 / zoom` 向量，非 `1.0/zoom.x` 单分量）**，修 C3；mouse drag/wheel 兼容。

**不做**：
- **C1**（offline_save_sync 加密保存）— disposal §7 禁 HMAC（security theater），save 安全是独立议题，单独制定规范。
- 整个 adapt-desktop-to-mobile（keyboard/haptic/shader/battery/safe-area 等 10+ 脚本）— disposal §7 逐技能独立制定规范，本技能只覆盖输入场景。
- 改 gd-agentic 源（disposal §6/§7）。

## clean room 来源与 attribution

- **来源**：Godot 4 官方文档（`InputEvent` / `InputEventScreenTouch` / `InputEventScreenDrag` / `InputEventMouseButton` / `InputEventMouseMotion` / `Camera2D.zoom`）。**不参考** gd-agentic adapt-desktop-to-mobile（规避 SSO）。
- **attribution**：每脚本头注释：
  ```
  # 基于 Godot 4 官方 InputEvent 文档原创（docs.godotengine.org InputEvent 章节）。
  # 非 gd-agentic 派生（clean room，disposal 规范 §5.2）。
  ```
- 事实性 API 用法迁移加出处；文案（NEVER 措辞）原创（disposal §5.2）。

## 技能结构（对齐 godot-characterbody-3d）

位置：`D:\GitHub\godot-ai-kit\skills\godot-touch-input\`

- `SKILL.md`（中文）：
  - frontmatter：`name` / `description`（trigger keywords：InputEventScreenTouch, InputEventScreenDrag, InputEventMouseButton, InputEventMouseMotion, virtual_joystick, pinch_zoom, camera_pan, touch, mobile_input, NEVER）
  - NEVER Do：touch 无 hover（必双兼容 ScreenTouch+MouseButton）/ zoom 用 Vector2 除法非 .x 单分量 / 桌面调试须鼠标分支
  - 桌面鼠标 vs 移动触摸对照表
  - 示例脚本说明
  - Common Gotchas（headless 测不出触摸 / 真机须人工）
  - Reference：Godot 官方 InputEvent 文档
- `scripts/dual_input_handler.gd`
- `scripts/touch_camera_pan_zoom.gd`

## 脚本设计

### dual_input_handler.gd（修 C2）
- `_input(event)`：
  - `if event is InputEventScreenTouch`：touch 处理（移动）
  - `elif event is InputEventMouseButton and button_index == MOUSE_BUTTON_LEFT`：等价 touch 处理（桌面）— **C2 修复核心：补此分支**
  - `if event is InputEventScreenDrag`：drag 处理（移动）
  - `elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)`：drag 处理（桌面）
- 信号接口：`touch_occurred(position: Vector2)` / `drag_occurred(from: Vector2, to: Vector2)`（供消费者订阅，解耦具体控件）

### touch_camera_pan_zoom.gd（修 C3）
- 1指 ScreenDrag / mouse motion（左键按下）→ 相对 pan（`offset -= drag.relative * factor`）
- 2指 pinch：`var ratio := current_dist / start_dist; camera.zoom = start_zoom * ratio`（Vector2 乘，等比）— **C3 修复核心：Vector2 运算**
- **NEVER** `1.0 / zoom.x`（单分量）；改 `1.0 / zoom`（Vector2）或 `zoom * scalar`
- mouse wheel 兼容（桌面缩放，`event.factor`）

## 测试

- **headless**：构造 `InputEventScreenTouch`/`InputEventMouseButton` 实例 → 调用 `_input` → 验证信号/状态分支（双兼容）。camera zoom 构造 pinch（两个 ScreenTouch）→ 验证 Vector2 等比（zoom.x == zoom.y，非 .x 单分量偏移）。
- **真机须人工**：触摸响应/手感/惯性只有真机暴露（Gotcha，对齐 characterbody-3d 风格，headless 盲区明示）。

## 退役机制（disposal §5.3）

- 前置套件 `skills/` 于 `config/claude/settings.json` 的 `GODOT_SKILL_LIBRARIES`（现列末尾）。
- `load_skill` 召回 touch/camera query 时，套件 godot-touch-input 与 gd-agentic adapt-desktop-to-mobile 同 score → JS stable sort 保留 lib 遍历顺序 → 套件优先。
- **plan 实现时验证 `load-skill-search.ts` stable-sort 假设**（disposal §5.3 line104）。

## 合规（disposal §6）

- 套件根 skills/ 原创 = MIT，与 gd-agentic LGPLv3 submodule 并列。
- 不 fork、不改 gd-agentic 源、不逐字复制、不 clean room 内化（disposal §7）。
- NOTICE:10-15 聚合豁免不动。

## 验收

- `skills/godot-touch-input/` 含 SKILL.md + 2 脚本，attribution 注官方文档出处（非 gd-agentic）。
- `dual_input_handler` 双分支（ScreenTouch+MouseButton / ScreenDrag+MouseMotion）— C2 修复可证。
- `touch_camera_pan_zoom` zoom 用 Vector2 运算（zoom.x == zoom.y 等比）— C3 修复可证。
- headless 测试覆盖双兼容 + Vector2 等比。
- `load_skill` 召回 touch input → 套件版优先（前置 + stable-sort 验证）。

## 不做（disposal §7，防 scope creep）

- ❌ C1 HMAC 完整性校验（security theater）
- ❌ 改 gd-agentic 源码（LGPLv3 修改义务）
- ❌ clean room 内化（单人 clean room 不成立）
- ❌ 整 adapt-desktop-to-mobile 重写（逐技能独立制定规范）

若后续有人提议动 gd-agentic 源码 → 引 disposal §2 + 06-19 否决记录，合规同源关闭。
