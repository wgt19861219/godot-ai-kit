# ③ 生产阶段执行日志(Crystal Collector)

> 双轨对照:每步 load_skill → enhanced 工具 → 验证 → §裂缝记录

## §裂缝记录(执行时现填;无裂缝写明原因)

| F# | 阶段 | 现象 | 严重度 | 补救 |
|----|------|------|--------|------|
| F0 | 文档对齐 | boundaries 阶段命名(原型/灰盒)≠ workflow(概念/架构) | 🟢 | 统一用 workflow 命名 |
| F1 | ③生产 | 3D CharacterBody 移动无专门 NEVER;query1 散落(百科0.43),query2 召回 2D characterbody-2d(0.63) | 🟡 | 去3D query 召回 2D NEVER 迁移:move_and_slide / _physics_process / is_on_floor |
| F5 | ③生产 | Area3D 收集物同样无 3D 专门 skill;collectible query 召回 godot-2d-physics(2D)+ csharp-signals(C#),无 3D Area3D | 🟡 | 从 godot-2d-physics 迁移 body_entered 模式(Area2D→Area3D 机制同);系统性:套件 3D 知识普遍缺,锁 2D 需迁移 |
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
