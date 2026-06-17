# 概念阶段 (Concept Stage)

## ① 阶段目标
定义游戏核心概念、主要玩法和基础机制，输出轻量级游戏设计文档(GDD)。

## ② 知识输入
```text
# 使用 gd-agentic 检索游戏蓝图示例
load_skill(query="3D platformer collectible")
```

## ③ 执行闭环
调用 enhanced 验证工具确保概念设计质量：
- 使用 `validate_gdd` 验证 GDD 的完整性和可行性

## ④ 产出
- 轻量级游戏设计文档 (GDD)
- 核心游戏机制说明
- 基础概念原型

## ⑤ 降级方案
参考 `docs/enhanced-boundaries.md` 中的边界限制，当无法访问增强工具时：
- 使用预设模板手动创建基础 GDD
- 借助社区标准化的游戏设计文档格式

---
*引用: docs/enhanced-boundaries.md*