# godot-touch-input 原创技能设计（Phase 2 首个）

> **来源**：gd-agentic disposal 规范 §5（Phase 2 原创替代路线）。本规范为 Phase 2 首个原创技能的独立设计。
> **clean room**：继承 disposal §5.2（不逐字复制 gd-agentic；单人看过原文 ≠ clean room）+ 3d-gameplay attribution 二分。
> **修订**：2026-06-19 spec 评审（M1-M3 MUST + S1-S3 SHOULD + A1-A6 ADVISORY 全采纳）。
> **For agentic workers**：本规范经 brainstorming + spec 评审定稿，下一步进 writing-plans（**必须新 session + 干净 agent**，见 clean room 机制段）。

## Goal（S1 收窄）

套件根原创 `godot-touch-input`，clean-room（干净 agent + Godot 官方 InputEvent 文档）覆盖 adapt-desktop-to-mobile **C2/C3 的 camera 输入场景**（touch_camera_pan_zoom），并提供 `dual_input_handler` 通用双兼容 `_input` 模式供 joystick/gesture（C2 另两脚本）修复参照。前置套件 `skills/` 后 camera 场景经 `load_skill` tie-break 优先召回（disposal §5.3，退役**不保证**生效——见退役段 fallback）。

> **范围诚实声明**（S1）：C2 含三脚本（joystick_spawner / gesture_combo / touch_camera_pan_zoom），本 skill 只提供 camera 场景的具体 `.gd` 替代 + 通用双兼容模式。joystick/gesture 无套件 `.gd` 替代 → gd-agentic 版仍被召回，C2 风险未全消；另开 spec。

## 背景

- **C2**（审查报告 CRITICAL-2，`:103`）：`dynamic_joystick_spawner` / `gesture_combo_system` / `touch_camera_pan_zoom` 只处理 `InputEventScreenTouch`，缺 `InputEventMouseButton` 分支 → 桌面/编辑器调试无法触发。另 `event.pressed` 不检查（审查 §2.5 IMPORTANT，仅 `on_screen_keyboard_handler` 正确）。
- **C3**（CRITICAL-3）：`touch_camera_pan_zoom` 用 `1.0/zoom.x` 单分量缩放，忽略 zoom.y → 非等比缩放偏移。**注意**（A1）：`touch_camera_pan_zoom` 同时命中 C2（camera 分支缺 MouseButton）+ C3（zoom.x），非仅 C3。
- **clean room 约束**（disposal §5.2 + §7）：单人看过原文 ≠ clean room（SSO 派生风险）。本会话 agent 已读 `adapt-desktop-to-mobile.md`（spec 自认）→ **本会话 agent 已污染，不能写实现层 `.gd`**（见 clean room 机制段）。
- **dogfood 缺位**：ai-kit demo 无移动端/touch 代码 → 来源改用官方文档，但需干净 agent 执行（见下）。

## clean room 来源与机制（M1 刚性）

**来源**：Godot 4 官方文档 `docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html`（`InputEvent` / `InputEventScreenTouch` / `InputEventScreenDrag` / `InputEventMouseButton` / `InputEventMouseMotion` / `Camera2D.zoom`）。**不参考** gd-agentic adapt-desktop-to-mobile（规避 SSO）。

**机制条款**（M1，**刚性**）：
- 实现层 `.gd` 代码由**未接触 gd-agentic adapt-desktop-to-mobile 原文的干净 agent** 执行（dispatching subagent + worktree 隔离 + **新 session**，记忆不继承）。
- 官方 InputEvent 文档为**唯一来源**；设计层概念（双兼容 / Vector2 zoom = 通用 Godot 知识）由本规范提供，实现 agent 据此 + 官方文档写代码。
- **本会话 agent 已污染**（读过原文），故 **writing-plans 必须新 session**（非仅 cost 纪律，是 clean room 必要条件）。
- attribution：每脚本头注 "基于 Godot 4 官方 InputEvent 文档原创（docs.godotengine.org/.../inputevent.html），非 gd-agentic 派生（clean room，disposal §5.2），实现 agent 未接触 gd-agentic 原文"。

事实性 API 用法迁移加出处；文案（NEVER 措辞）原创（disposal §5.2）。

## 技能结构（对齐 godot-characterbody-3d）

位置：`D:\GitHub\godot-ai-kit\skills\godot-touch-input\`

- `SKILL.md`（中文）：
  - frontmatter：`name` / `description`（trigger keywords：InputEventScreenTouch, InputEventScreenDrag, InputEventMouseButton, InputEventMouseMotion, virtual_joystick, pinch_zoom, camera_pan, touch, mobile_input, NEVER）
  - NEVER Do：touch 无 hover（必双兼容 ScreenTouch+MouseButton / 必检查 `event.pressed`）/ **zoom 用 Vector2 除法非 .x 单分量（pan 与 pinch 路径都禁）** / 桌面调试须鼠标分支
  - 桌面鼠标 vs 移动触摸对照表
  - 示例脚本说明
  - Common Gotchas（headless 测不出触摸 / 真机须人工 / `_input` 穿透）
  - Reference：Godot 官方 InputEvent 文档
- `scripts/dual_input_handler.gd`
- `scripts/touch_camera_pan_zoom.gd`

> **Camera2D-only 声明**（A6）：本 skill 脚本针对 `Camera2D`（有 `zoom` 属性）；`Camera3D` 无 zoom，3D 场景须改 `fov`/`size`，另开 spec。

## 脚本设计

### dual_input_handler.gd（修 C2 模式 + M2 pressed）
- `_input(event)`：
  - `if event is InputEventScreenTouch and event.pressed:` → touch 处理（移动）【M2：补 pressed，防双触发】
  - `elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:` → 等价 touch（桌面）— **C2 修复核心**
  - `if event is InputEventScreenDrag:` → drag 处理（移动）
  - `elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):` → drag 处理（桌面）
- 信号接口（A2，`InputEventScreenDrag` 只有 position/relative，无 from）：`touch_occurred(position: Vector2)` / `drag_delta(position: Vector2, relative: Vector2)`（供消费者订阅，解耦具体控件）

### touch_camera_pan_zoom.gd（修 C3 + M3 pan factor）
- **pan**：`var factor: Vector2 = Vector2.ONE / camera.zoom`（M3 钉死 Vector2，非标量）；`camera.offset -= drag.relative * factor`（逐分量，等比）
- **pinch**（2指）：`var ratio := current_dist / start_dist; camera.zoom = start_zoom * ratio`（Vector2 乘，等比）
- **NEVER**（M3 补 pan 路径）：`1.0/zoom.x`（单分量）— **pan 与 pinch 都禁**；改 `Vector2.ONE/zoom`（Vector2）或 `zoom * scalar`
- mouse wheel：`camera.zoom *= clamp(event.factor, ...)`（桌面缩放）
- **`_input` vs `_unhandled_input`**（S2）：示例用 `_input` 简化；**生产 camera pan 建议 `_unhandled_input`**，否则点 UI（暂停按钮）也触发 pan（穿透）。

## 测试

- **headless**：
  - 构造 `InputEventScreenTouch`（pressed true/false）→ 验只在 `pressed=true` 触发（M2，防双触发）
  - 构造 `InputEventMouseButton` → 验双兼容分支（C2）
  - pinch 两指 `InputEventScreenTouch` **`index` 0/1**（A4）→ 验 zoom 各分量同比变化（A5：`zoom.x/zoom.y` 比值恒定；**非 `zoom.x==zoom.y`** — 初始非等比 zoom 会假阴）
- **真机须人工**：触摸响应/手感/惯性只有真机暴露（Gotcha，对齐 characterbody-3d 风格，headless 盲区明示）。

## 退役机制（disposal §5.3 + S3 fallback）

- 前置套件 `skills/` 于 `config/claude/settings.json` 的 `GODOT_SKILL_LIBRARIES`（现列末尾）。
- camera query 时套件版与 gd-agentic adapt-desktop-to-mobile 同 score → JS stable sort 保留 lib 遍历顺序 → 套件优先（**待验证**）。
- **fallback**（S3）：stable-sort + lib 顺序是**未验证假设**（disposal §5.3 line104）；**前置 ≠ 退役必然生效**。plan 实现时读 `load-skill-search.ts` 验证，若有其他 tie-break 键则调整机制（disposal §5.3 承诺）。
- **退役边界**（S1）：仅 camera 场景完全退役；joystick/gesture 无套件 `.gd`，gd-agentic 仍召回。

## 合规（disposal §6）

- 套件根 skills/ 原创 = MIT，与 gd-agentic LGPLv3 submodule 并列。
- 不 fork、不改 gd-agentic 源、不逐字复制、不 clean room 内化（disposal §7）。
- NOTICE:10-15 聚合豁免不动。

## 验收

- `skills/godot-touch-input/` 含 SKILL.md + 2 脚本，attribution 注官方文档 URL + 干净 agent 声明。
- `dual_input_handler`：ScreenTouch+MouseButton 双分支，**含 `event.pressed` 守卫**（M2）。
- `touch_camera_pan_zoom`：pan `Vector2.ONE/zoom` + pinch `zoom*ratio`，**pan/pinch 都禁 `1.0/zoom.x`**（M3）。
- Camera2D-only 声明（A6）。
- headless：pressed 守卫 + 双兼容 + 两指 pinch 各分量同比（A4/A5）。
- `load_skill` camera query 套件版优先（前置 + stable-sort 验证，fallback 明示）。
- 实现层 `.gd` 由干净 agent（新 session + worktree + 官方文档唯一来源）产出（M1）。

## 不做（disposal §7，防 scope creep）

- ❌ C1 HMAC 完整性校验（security theater）
- ❌ 改 gd-agentic 源码（LGPLv3 修改义务）
- ❌ clean room 内化（单人 clean room 不成立）
- ❌ 整 adapt-desktop-to-mobile 重写（逐技能独立制定规范）

若后续有人提议动 gd-agentic 源码 → 引 disposal §2 + 06-19 否决记录，合规同源关闭。
