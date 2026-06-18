# ③ 生产阶段执行日志(Crystal Collector)

> 双轨对照:每步 load_skill → enhanced 工具 → 验证 → §裂缝记录

## §裂缝记录(执行时现填;无裂缝写明原因)

| F# | 阶段 | 现象 | 严重度 | 补救 |
|----|------|------|--------|------|
| F0 | 文档对齐 | boundaries 阶段命名(原型/灰盒)≠ workflow(概念/架构) | 🟢 | 统一用 workflow 命名 |
| F1 | ③生产 | 3D CharacterBody 移动无专门 NEVER;query1 散落(百科0.43),query2 召回 2D characterbody-2d(0.63) | 🟡 | 去3D query 召回 2D NEVER 迁移:move_and_slide / _physics_process / is_on_floor |
| F5 | ③生产 | Area3D 收集物同样无 3D 专门 skill;collectible query 召回 godot-2d-physics(2D)+ csharp-signals(C#),无 3D Area3D | 🟡 | 从 godot-2d-physics 迁移 body_entered 模式(Area2D→Area3D 机制同);系统性:套件 3D 知识普遍缺,锁 2D 需迁移 |
| F6 | ③生产 | enhanced edit_script 验证 + run_and_verify 的 precheck 用错误 res:// 路径(`res://D:/GitHub/...` 拼了绝对 project_path)→ 脚本加载误报 "returned null";但场景实跑正常 | 🟡 | #4 以实跑为准(hasErrors:false→pass);write_script 正常(不经 precheck 路径 bug) |
| F7 | ③生产 | edit_node 设 script 报 `success:true`,但 .tscn 实际未写 script 属性(假成功,极危险) | 🔴 | 降级手写 .tscn(同①②阶段);enhanced edit_node 不可信,须读 .tscn 复核 |
| F8 | ③生产 | add_node properties 设资源(shape/mesh 字符串)被静默忽略,节点创建但无资源 | 🔴 | 降级手写 .tscn SubResource;enhanced add_node 不支持设资源 |
| F2 | ③生产 | 范围扩展超原 GDD MVP(移动+拾取 → 可玩闭环) | 🟢 | 已更新①②文档(T1) |
| F3 | ③生产 | collected(N) → collected() 简化 | 🟢 | 已记 ADR-003 变更 |
| F4 | ①概念 | `validate_gdd` 真调报错 `Cannot read properties of undefined (reading 'replace')`;validation MCP schema 未暴露其必需参数(document/gdd 路径)→ 工具存在但经 MCP 调不起来 | 🔴 | 降级手动核对 01-gdd 结构(完整→pass);向 enhanced 报 issue |

## validate_gdd 降级核对(T1,2026-06-17)

`validate_gdd` 经 MCP 调用失败(F4)。手动核对 `01-concept-gdd.md` 结构:
游戏概念 / 核心机制 / 关卡设计 / 技术约束 齐全 → **pass(降级)**。
真实 enhanced validate_gdd 待 enhanced 侧修复参数暴露后补跑。

## T2 知识采集 + 盲区探测(2026-06-17)

- **3D 移动 NEVER(F1)**:query1 `CharacterBody3D movement NEVER` 散落命中(通用百科 0.43 / adapt-2d-to-3d / player-controller),无 3D 专门 NEVER;query2 `CharacterBody movement NEVER` 召回 `godot-characterbody-2d` 0.63(核心 NEVER 锁 2D)。复测与 spec §3.1 一致,数据稳定。
- **collectible / Area3D(F5)**:query `Area3D body_entered signal collectible pickup` 召回 csharp-signals(C# 不相关)/ godot-brainstorming / **godot-2d-physics(2D)** —— 无 3D Area3D 专门 skill,从 2D 迁移 body_entered 模式。
- **系统性观察**:套件知识库 3D 专门 skill 普遍缺失(CharacterBody / Area3D 均是),核心规则锁在对应 2D skill,3D 开发靠 2D→3D 迁移。**建议套件补 3D 专门 skill**(改进输入)。

## T3 collectible 场景+脚本(2026-06-17)

- collectible.gd:write_script 落地(经 #8 确认令牌);edit_script 加 add_to_group 被 precheck 路径 bug(F6)回滚 → 改 write_script overwrite 成功(13 行)。
- collectible.tscn:enhanced create_scene+add_node+edit_node 链 **失效**(F7 edit_node 假成功不挂 script / F8 add_node 不设资源)→ 降级**手写 .tscn**(同①②阶段做法;内置 Write 改 .tscn 不违反 #2)。
- 交叉验证(#4):run_and_verify 实跑 `hasErrors:false`,scene_tree 确认 script/shape/mesh 全生效;但 precheck 误报脚本 "returned null"(F6 路径 bug)。**以实跑为准 → collectible 通过**。
- stop_project 清理(#9)。
- **关键认知**:enhanced scene 工具链(create+add+edit+save)在设资源/attach script 上不可靠 —— 这是①②阶段"手写骨架"的真正原因,dogfood ③ 重现。后续 player.tscn(已有手写)/Main.tscn 同样走手写。

## T4 player.gd 角色控制(2026-06-17)

- player.gd:write_script overwrite(25 行,移动 WASD + 跳跃 Space + 面朝移动方向)。lint L021 警告 `gravity`/`input_dir` "可能与父类同名" —— **实为误报**(CharacterBody3D 无 `gravity` 成员;`velocity` 是父类成员,直接用未声明)。
- 交叉验证(#4):run_and_verify player.tscn `hasErrors:false` → **通过**;precheck 仍误报 returned null(F6 路径 bug)。以实跑为准。
- **#9 观察**:run_and_verify 的 timeout(45s)自动 kill 进程,后续 stop_project 报 "no project running" —— 残留进程风险在 timeout 模式下不触发(timeout kill 已清理);冗余 stop 可省,但 CI 场景仍建议显式钩子。

## T5 Main + 计分 + 终态(验收②,2026-06-17)

- main.gd(21 行)+ Main.tscn(手写,22 节点)。run_and_verify `hasErrors:false`,scene_tree 完整:Main(script,total=3)/ Player(CharacterBody3D+CapsuleMesh+SpringArm→Camera)/ Platform(StaticBody3D+Box)/ Crystal_0-2(Area3D+BoxShape3D+BoxMesh)/ HUD+ScoreLabel(unique_name_in_owner=true,text="收集: 0/3")。**验收②结构达成**。
- 信号链就绪:player → collectible.Area3D `body_entered` → `collected` → main `_on_collected` → score → Label。
- **#7 精确化(重要)**:3D headless 截图**可用**(screenshot.png 7209B / 1280×720 渲染正常)—— boundaries #7"2D 截图 headless 不可用"**严格限定 2D,3D 不受影响**。建议 boundaries #7 补注"3D 例外"。
- F9:screenshot `analyze` 返回 image URL 而非文字描述,模型无法判读画面内容(工具层缺陷)。
- 交互行为(移动/收集计分)需输入,headless 无法模拟 → 待人工 / Game Bridge 确认。

## T6 精修(④,2026-06-17)

- 性能知识 load_skill 命中:`godot-performance-optimization` **0.80** + `godot-optimization` 0.68 —— **命中度高**(性能通用、不分类 2D/3D,无盲区;与 F1/F5 的 3D 专用盲区形成正反对比)。
- profiler snapshot 数据异常:fps=1 / **node_count=0** / draw_calls=0 —— Main.tscn 有 22 节点但 profiler 报 0 → 采样未覆盖目标场景(project 未设 `run/main_scene` → profiler 跑空)。
- F10:profiler snapshot 不指定场景时跑空,node_count/fps/draw_calls 无意义;需项目设 `run/main_scene` 或 profiler 支持指定目标场景。
- #4 交叉:已由 T3/T4/T5 run_and_verify 实跑 `hasErrors:false` 覆盖(validate_scripts 静态走 F6 路径 bug,以实跑为准)。
- 鼠标旋转相机:跳过(留 v1,spec §2.4 一致;MVP 固定 SpringArm 跟随即可玩)。
- MVP 场景极简(22 节点),性能非瓶颈。

## T7 交付(⑤,2026-06-17)

- 发布知识 load_skill 命中一般:godot-code-review 0.43 / optimization 0.37 / mobile-adapt 0.32 —— **无专门"交付 checklist" skill**(code-review 可部分覆盖)。
- verify_delivery 经 MCP 调用报错 `scope must be one of: scene, script, full` —— validation MCP schema **未暴露 scope 参数**(同 F4 的 validate_gdd)→ 工具不可用,降级**手动交付核对**(run_and_verify + scene_tree + 各脚本实跑已证交付物完整)。
- #3 CRLF 治理:套件根建 `.gitattributes`(`* text=auto eol=lf`),renormalize 显示存量已 LF(无额外 diff),`.gitattributes` 阻止 checkout 转 CRLF。配 `.gitignore` 忽略 screenshot.png。

## 裂缝汇总(验收③,2026-06-17)

dogfood ③④⑤ 双轨对照共记录 12 条裂缝(F0-F11):

| F# | 类别 | 严重度 | 一句话 | 改进建议 |
|----|------|--------|--------|----------|
| F0 | 文档 | 🟢 | boundaries 阶段命名(原型/灰盒)≠ workflow(概念/架构) | 补映射注 |
| F1 | 知识盲区 | 🟡 | 3D CharacterBody 移动无专门 NEVER(锁 characterbody-2d) | 补 3D skill |
| F2 | 范围 | 🟢 | dogfood 范围超原 GDD MVP | 已更新①②文档 |
| F3 | 范围 | 🟢 | collected(N)→collected() 简化 | 已记 ADR 变更 |
| F4 | 工具 | 🔴 | validate_gdd 必需参数未在 MCP schema 暴露 | enhanced 暴露 document 参数 |
| F5 | 知识盲区 | 🟡 | Area3D 收集无 3D 专门 skill(系统性) | 补 3D skill |
| F6 | 工具 | 🟡 | edit_script/precheck res:// 路径拼接 bug(res://D:/...) | enhanced 修路径拼接 |
| F7 | 工具 | 🔴 | edit_node 报 success 但 .tscn 未挂 script(假成功) | enhanced 修 + 读 .tscn 复核 |
| F8 | 工具 | 🔴 | add_node properties 设资源被静默忽略 | enhanced 支持资源 / 手写 |
| F9 | 工具 | 🟢 | screenshot analyze 返回 image URL 非文字描述 | enhanced 返回文字描述 |
| F10 | 工具 | 🟡 | ~~profiler 跑空~~ **订正(reviewer C3)**:真根因是 project.godot `main_scene` 配错(指向 player.tscn 空骨架)→ profiler 跑空场景 node_count=0,非 profiler 不支持指定场景 | **已修** `main_scene`→Main.tscn(见 F13) |
| F11 | 工具 | 🔴 | verify_delivery scope 参数未在 MCP 暴露 | enhanced 暴露 scope |
| F12 | ⑤交付 | 🟡 | UI 中文字体未配置(默认字体无中文字形→tofu)+ screenshot analyze 无法判读 → "过关"视觉验收从未完成(reviewer I4) | 配中文字体或改英文;人工肉眼复核 |
| F13 | ⑤交付 | 🔴 | project.godot `main_scene` 配错(=F10 真根因,reviewer C3);`godot --path demo` 默认跑空 player.tscn → demo 不可玩 | **已修** `main_scene`→Main.tscn |

**三大关键模式**:
1. **enhanced validation 工具门禁失效**(F4/F11):validate_gdd / verify_delivery 必需参数未在 MCP schema 暴露 → ①概念、⑤交付的 enhanced 门禁经 MCP 不可用,降级手动。这是套件工作流与 enhanced MCP 集成的核心裂缝。
2. **enhanced scene 工具设资源不可靠**(F7/F8):edit_node 假成功 + add_node 不设资源 → ①②③ 全程手写 .tscn(印证 02-adr"手写骨架"的真正原因)。
3. **套件 3D 专门 skill 系统性缺失**(F1/F5):CharacterBody 移动 / Area3D 收集均无 3D 专门 skill,核心规则锁 2D 需迁移;性能/优化通用知识命中好(无盲区)。

**正向**:load_skill 数据层稳定(query 可复现)、run_and_verify 实跑可靠(全程 hasErrors:false)、3D headless 截图可用(#7 精确化:只 2D 受限)、write_script 正常(不经 precheck 路径 bug)。

抄送 Obsidian `[[GodotAIKit/wiki/load_skill]]`(主会话写)。

## reviewer 终审处置(2026-06-18)

独立 code-reviewer 审 merged demo(`084e9ee..03899e5`):3 Critical + 5 Important + 4 Minor。F0-F11 裁决:10 认可 / F3 部分驳回(简化引入 C2 去重副作用未追踪)/ **F10 驳回**(根因错记,已订正)。

**已修(本次)**:
- **C3(必修,阻塞验收②)**:`project.godot` `main_scene` player.tscn → **Main.tscn**。`godot --path demo` 默认入口现在跑 Main(可玩),验收②真正达成。run_and_verify 默认入口 `hasErrors:false` 确认。
- **F10 订正**:node_count=0 真根因是 main_scene 配错(非 profiler 缺陷)—— 原记录粉饰了配置 bug,不诚实,已订正。
- 补 **F12**(UI 中文字体/视觉验收盲区)/ **F13**(main_scene 配错=F10 真根因)。

**已修(本次 refactor commit,用户选"教材质量";reviewer 原标 v0.1.1 不阻塞)**:
- **C1**:`main.gd` 信号订阅依赖隐含的子节点 `_ready` 先于父时序(当前可玩但脆弱)→ 改收集物主动连主控,或加注释固化前提。
- **C2**:`_on_collected` 无去重(F3 无参简化副作用)→ `collected` 加 sender 参数 + main 用 Set/Dict 去重。
- **I1**:`player.gd` 朝向计算冗余(direction 已归一,`face!=position` 永真)+ look_at 瞬转无平滑。
- **I2**:`move_toward` 减速帧率敏感(非 delta 归一)→ `decel=SPEED*delta*k`。
- **I3**:`collectible` body 类型注解过窄 + 硬判断 `is CharacterBody3D` → 组优先(`is_in_group("player")`)。
- **I4**:ScoreLabel 中文 UI 字体(=F12)+ screenshot 无法判读 → 视觉验收盲区。
- M1-M4:风格/性能/文档完整性小项(ADR-003 主图未更新等)。

## reviewer 复审(2026-06-18,fresh context)

**判定:Ready(可交付)**。7 条修复(C3/C1/C2/I1-I4)全部 ✅ 实质生效,实跑 `hasErrors:false`,默认 main_scene 正确,游戏可玩。修复 diff 精准、命名清晰,符合教材质量。

**新发现 2 Minor(非阻塞,v0.1.1 polish)**:
- **Minor-1 ✅ 已修(本次)**:`_on_collected` 加 `sender.tree_exited.connect(func() -> void: _collected.erase(sender))`,清 crystal free 后悬挂 key。
- **Minor-2 ✅ 已修(本次)**:`_connect_crystals` 加注释说明 C1 限定覆盖范围(初始静态 crystal;运行时动态 instance 的需手动重连)。

## 全面审查报告复审订正(2026-06-18,两份外部全面审查)

两份外部全面审查(架构审查 + BlockB 设计审查)对 merged 套件提出若干发现。逐条核实(不照单全收)后处置:

### WASD 输入映射修复(报告1 C1,真功能 Bug ✅ 已修)

- **核实成立**:`player.gd` 用 `Input.get_vector("ui_left/right/up/down")`,但 `project.godot` 无 `[input]` 段;Godot 4 默认 InputMap **不绑 WASD**(只绑方向键 + 手柄 D-Pad)→ WASD 完全无响应。本日志 T4(上 line 41)声称"移动 WASD"名不副实,印证了"可玩性验收从未真正执行"的系统性盲区(boundaries #7 输入盲区)。
- **修复(方案 B,UI 与游戏 action 分离,更干净的活教材)**:`project.godot` 新增 `[input]` 段,用 `physical_keycode` 定义 `move_forward(W=87)`/`move_back(S=83)`/`move_left(A=65)`/`move_right(D=68)`;`player.gd:17` 改 `get_vector("move_left","move_right","move_forward","move_back")`。Space 跳跃仍走默认 `ui_accept`(不重定义,避免污染 UI 导航)。
- **验证**:`execute_gdscript` 读 InputMap 确认 4 个 action 绑定正确物理键码 + Space 可用 → **PASS**;`run_and_verify Main.tscn` `hasErrors:false`(#4 以实跑为准)。
- **残留盲区**:WASD **按键实际响应**需人工/编辑器确认(headless 无法模拟输入),如实标注,不假装已验证。

### 终局文案订正(报告1 I4,归因纠正)

- **报告1 归因错误**:报告1 称"代码英文 Clear!/Score、初始英文 Score:0/3、运行时中文 收集:%d/%d"三套语言混用。**核实实际**:`main.gd:31="Clear!"`、`:34="Score: %d/%d"`、`Main.tscn:45="Score: 0/3"`——**代码全英文一致**;"运行时中文"是基于本日志 T5 旧快照(line 47 `text="收集: 0/3"`)的误判。
- **真相**:T5 记录时 UI 是中文,reviewer 复审 I4 修复**已改英文**(规避 F12 中文字体 tofu);本日志 line 47/86/113 的中文描述是**历史快照**,未随修复更新,造成报告误读。
- **处置**:代码已统一英文,**不改**;`spec/plan` 中的"过关!"为**早期设计意图**(superpowers 过程产物),保留为历史记录不回改。
- **F12 状态订正**:由"UI 中文字体未配置→'过关'视觉验收未完成"订正为"终局落地英文 Score/Clear!,F12 已通过改英文消解;视觉验收仍受 F9(screenshot analyze 返回 URL 非文字)限制,需人工肉眼"。

### 文档同步项(报告1 I1/I2/I3 + 报告2 I2/I3/I4/I5,均已修)

- 兼容矩阵 enhanced pin `1c03909`→`0b54d1b` + C1 可达性脚注(报告1 I1)
- NOTICE enhanced upstream `本地 ../godot-mcp-enhanced`→GitHub URL(报告1 I2)
- `install.sh` Step5 从 `grep -q` 对齐为解析 settings.json + 逐路径校验(报告1 I3;且语义比 `install.ps1` 更正确:校验 `${REPO_ROOT}` 占位符替换后的真实路径,而非 ps1 的字面占位符路径)
- README 删"跨平台 install.sh 计划 v0.2 提供"→已提供(报告2 I2)
- 项目 `CLAUDE.md` 删"enhanced 是本地相对路径子模块,需 `-c protocol.file.allow=always`"(报告2 I3,C1修复后已 HTTPS,过时)
- `demo/README` 更新 ③④⑤ 已完成可运行 + 修正文件名引用(`03-production.md`→`03-production-log.md`)(报告2 I4)
- `workflow/production.md` 补逐条裂缝引用 #1-#6/#9 + 修正降级语义(报告2 I5,泛泛→具体,按 boundaries 引用约定)

### 报告自身出错的发现(已纠正,不修)

- **报告2 I6**("14 子系统仅 5 个 rule"):是 enhanced 子模块内部规则覆盖问题,套件层无权也无需修(项目 CLAUDE.md 已诚实标注"实际5个:core/bridge/editor/ui/recording")。忽略。
- **报告1 I4**:见上"终局文案订正",归因错误(代码非三套混用,是文档历史快照中文 vs 代码英文)。

### 报告2 C1 暂不处理(用户决策 ⏸)

- enhanced pin `0b54d1b` 未推送 origin(`origin/fix/review-verification` HEAD=`f0384c7`,本地领先 6 commit=沙箱加固补丁A+B),外部 `git submodule update --init` 会失败。
- 用户 2026-06-18 决策:**暂不处理**(不 push、不回退)。兼容矩阵已如实标注该 pin 可达性提示——**公开发布/打 tag 前必须解决**(push `0b54d1b` 或回退到 origin 可达的 `1c03909`)。

### 报告1 Minor 系列(M1-M4)处置状态

报告1 另列 4 个 Minor,本次评估后**均不处理**(附理由):
- **M1**(动态 crystal 连接 helper):当前 demo 不触发动态生成,代码已诚实自注释(`_connect_crystals` 注释说明运行时 instance 需手动重连),YAGNI。
- **M2**(enhanced/`D:` 误建目录):enhanced 子模块内部问题,套件层无权改,建议向 enhanced 报 issue。
- **M3**(`rules/budget-guard.md` 全角括号浪费 byte):当前 3157/8192 远未超限,纯风格,跳过。
- **M4**(缺自动化 CI 冒烟):与"CI v1 上线才标绿"规划重叠的大件,非本次范围;建议作为 v0.2 单独任务。

> 注:报告1 的 I4 见上"终局文案订正"(归因纠正,非真问题);I1/I2/I3 已在"文档同步项"修复。

## 人工实测验证(2026-06-18,WASD 真实按键响应)

WASD 按键实测因 Game Bridge 在 Godot 4.6.2 崩溃(`mcp_bridge.gd:66` `_ready()` 兼容 bug,卡 debugger break,无法自动化)改由用户人工窗口实测。实测**发现并修复 3 个 headless 完全无法暴露的真实 Bug**:

### F14:场景缺光源(灰暗不可辨)🔴→✅ 已修
- **现象**:用户实测画面灰暗,无法分辨角色/平台/水晶。
- **根因**:`Main.tscn` 无 DirectionalLight3D/WorldEnvironment,forward_plus 默认环境光极弱。T5 headless 截图当时判"渲染正常"是误判(色调暗但未细看)。
- **修复**:`Main.tscn` 加 `WorldEnvironment`(天蓝背景 + 环境光填充)+ `DirectionalLight3D`(主光带阴影)。

### F15:移动反馈循环(W 正常、A/S/D 闪烁)🔴→✅ 已修
- **现象**:用户实测 W 正常,A/S/D 移动闪烁。
- **根因**:`player.gd` 用 `transform.basis * input_dir` 把输入按**角色自身朝向**变换,而 `look_at` 又改朝向 → 反馈循环(W 自洽不抖,A/S/D 振荡闪烁)。
- **修复**:移动改世界坐标 `Vector3(input_dir.x, 0, input_dir.y)`,去 `transform.basis`。

### F16:look_at 瞬转 + 相机挂在角色下(转向突兀/视角乱)🟡→✅ 已修(最小跟随)
- **现象**:转向突兀(`look_at` 瞬转);旋转 Player 带 SpringArm/Camera 一起转 → 视角乱、第二次切方向无效。
- **修复**:
  1. `look_at` 瞬转 → `lerp_angle` 平滑(reviewer I1 当初提过未落地,本次补)。
  2. 旋转只作用于 `mesh`(角色胶囊体)而非 Player 根,相机臂稳定。
  3. `SpringArm` 同步平滑转向移动方向 → 第三人称跟随视角。
- **残留打磨(v1 范围)**:完整相机系统(鼠标自由旋转、碰撞回弹、距离自适应)。用户 2026-06-18 决策:当前最小跟随视角先接受,完整打磨留 v1。

### WASD 验收结论

- InputMap 绑定(headless)✅ + `run_and_verify` hasErrors:false ✅ + **人工按键实测四向移动正常、跳跃/计分/集齐正常** → 验收②真正达成(此前仅结构达成)。
- **关键教训**:boundaries #7"headless 无法模拟输入"导致 WASD 这类输入 Bug 一路漏检到人工实测——F14(光照)/F15(反馈循环)/F16(相机)同理,headless 截图/实跑均无法暴露,**只有真实视觉 + 按键才发现**。印证"可玩性验收必须人工,不能靠声明"。
- 自动化盲区扩展记录:Game Bridge 在 Godot 4.6.2 的 `_ready()` 兼容崩溃 → bridge 自动化验证路径当前不可用(待 enhanced 修复 bridge 脚本)。
