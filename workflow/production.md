# 生产阶段 (Production Stage)

## ① 阶段目标
实现核心游戏功能和基础玩法，输出可运行的游戏构建。

## ② 知识输入
```gdscript
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

## ⑤ 降级方案
参考 `docs/enhanced-boundaries.md` 中的边界限制，当无法访问增强工具时：
- 手动编写基础游戏逻辑
- 使用 Godot 内置功能实现核心玩法
- 逐步构建可运行原型

---
*引用: docs/enhanced-boundaries.md*