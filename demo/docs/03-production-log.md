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
- **Minor-1**:`_collected` Dict 内存小泄漏 —— crystal `queue_free()` 后 key 悬挂(Object 引用不自动 erase)。demo 3 个 crystal 可忽略,但教材应清。建议 `sender.tree_exited.connect(func(): _collected.erase(sender))`。
- **Minor-2**:`_connect_crystals` 仅覆盖**初始静态** crystal(call_deferred 解初始时序);运行时动态 `instance` 的 crystal 不会自动连 → 需手动调 `_connect_crystals()` 或 crystal 主动连 main group。建议注释说明 C1 限定的覆盖范围。
