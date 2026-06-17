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
