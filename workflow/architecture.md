# 架构阶段 (Architecture Stage)

## ① 阶段目标
设计游戏技术架构、场景结构和模块划分，输出架构决策记录(ADR)。

## ② 知识输入
```gdscript
# 使用 gd-agentic 检索架构决策示例
load_skill(query="scene split autoload signal architecture")
```

## ③ 执行闭环
调用 enhanced 工具构建架构原型：
- 使用 `read_scene` 分析现有场景结构
- 使用 `add_node` 创建基础场景节点
- 使用 `save_scene` 保存架构设计

## ④ 产出
- 架构决策记录 (ADR)
- 场景树设计图
- 基础场景文件骨架

## ⑤ 降级方案
参考 `docs/enhanced-boundaries.md` 中的边界限制，当无法访问增强工具时：
- 使用预设场景模板手动搭建基础架构
- 借助可视化工具绘制架构图

---
*引用: docs/enhanced-boundaries.md*