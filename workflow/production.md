# 生产阶段 (Production Stage)

## ① 阶段目标
实现核心游戏功能和基础玩法，输出可运行的游戏构建。

## ② 知识输入
```text
# 使用 gd-agentic NEVER 规则 + GodotPrompter 检索实现方案
load_skill(query="CharacterBody3D movement NEVER")
```

## ③ 执行闭环
调用 enhanced 工具实现核心功能：
- 使用 `write_script` 编写游戏逻辑脚本
- 使用 `batch_add_nodes` 批量添加场景节点
- 使用 `run_and_verify` 验证功能实现

## ④ 产出
- 可运行的游戏构建
- 核心功能脚本文件
- 基础游戏场景

## ⑤ 降级方案(enhanced 裂缝应对)

enhanced 不是无瑕地基,本阶段(③生产)按 `docs/enhanced-boundaries.md` 引用约定**几乎全踩**,逐条应对:

| 裂缝 | 本阶段应对 | 降级可靠性 |
|------|-----------|-----------|
| [#1](../docs/enhanced-boundaries.md) autoload 盲区 | 涉及 autoload 上下文时显式传 `load_autoloads=true`,且先用 `validate_scripts` 确认 autoload 脚本无编译错 | 🟡 有条件 |
| [#2](../docs/enhanced-boundaries.md) Edit tab 改 .gd 失败 | **禁用内置 Edit 改 `.gd`**,只用 enhanced `edit_script`(`search_and_replace`) | 🟢 可靠 |
| [#3](../docs/enhanced-boundaries.md) CRLF 行尾 | 仓库 `.gitattributes` 强制 LF + 走 `search_and_replace`(内部 CRLF 归一化) | 🟢 可靠 |
| [#4](../docs/enhanced-boundaries.md) validate_scripts 不一致(最致命) | "脚本通过"结论不单凭 `validate_scripts`,须与 `run_and_verify` **交叉确认**,不一致以实跑为准 | 🟡 有条件 |
| [#5](../docs/enhanced-boundaries.md) 重复调用幂等 | 任何 `add_node`/`batch_add_nodes` 前先 `query_scene_tree` 查同名节点,走 "query → 条件 add" | 🟢 可靠 |
| [#6](../docs/enhanced-boundaries.md) 超时 | 大项目 `run_and_verify` 显式传更大 timeout(60-120s)+ 按场景分块验证 | 🟢 可靠 |
| [#9](../docs/enhanced-boundaries.md) run_and_verify 残留进程 | 每次 `run_and_verify` 后**显式 `stop_project`**,"run → verify → stop" 原子三步 | 🟢 可靠 |

当 enhanced 完全不可用时(非单条裂缝,而是工具失联):
- 手动编写基础游戏逻辑
- 使用 Godot 内置功能实现核心玩法
- 逐步构建可运行原型

> 🔴 #7(2D 截图 headless 不可用)主要影响 ④ 打磨的 2D 视觉验收,MVP 需人工介入——本阶段若涉及 2D 视觉结论,标注人工复核,不假装自动化。

---
*逐条依据: docs/enhanced-boundaries.md(本阶段引用 #1-#6、#9)*
