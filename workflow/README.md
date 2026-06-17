# Godot AI Kit 工作流

## 概述
这是 godot-ai-kit 的 Godot 专版 5 阶段工作流，结合 enhanced 工具、GodotPrompter 和 gd-agentic-skills，实现从概念到交付的完整游戏开发流程。

## 5 阶段工作流

### 1. 概念阶段 (concept.md)
- **目标**: 定义游戏核心概念和玩法
- **知识输入**: gd-agentic 蓝图检索
- **执行**: `load_skill(query="3D platformer collectible")` + `validate_gdd`

### 2. 架构阶段 (architecture.md)  
- **目标**: 设计技术架构和场景结构
- **知识输入**: gd-agentic 决策矩阵
- **执行**: `load_skill(query="scene split autoload signal architecture")` + `read_scene`/`add_node`/`save_scene`

### 3. 生产阶段 (production.md)
- **目标**: 实现核心游戏功能
- **知识输入**: gd-agentic NEVER + GodotPrompter
- **执行**: `load_skill(query="CharacterBody3D movement NEVER")` + `write_script`/`batch_add_nodes`/`run_and_verify`

### 4. 精修阶段 (polish.md)
- **目标**: 优化性能和用户体验
- **知识输入**: GodotPrompter 性能指南
- **执行**: `load_skill(query="performance draw call")` + `profiler`/`validate_scripts`

### 5. 交付阶段 (delivery.md)
- **目标**: 完成版本发布准备
- **知识输入**: CCGS checklist
- **执行**: `load_skill(query="release review checklist")` + `verify_delivery`

## 硬闭环诚实化机制

每阶段**约定调用 enhanced 验证工具 + 阶段门禁**(靠 AI 遵守约定 + 文档要求贴验证结果)。enhanced 工具能验证、不能阻止跳阶段。与 CCGS 区别:CCGS 靠 AI 自觉读 markdown,本工作流每阶段强制调用验证工具。

### 关键特点
1. **强制性验证**: 每个阶段必须调用相应的 enhanced 验证工具
2. **文档集成**: 验证结果直接集成到阶段文档中
3. **AI 自律**: 依靠 AI 自觉遵守流程约定，无法强制跳过验证步骤
4. **工具支持**: enhanced 工具提供客观的验证标准，确保质量门槛

### 与传统流程对比
- **CCGS**: 依赖 AI 读取 markdown 文档，流程执行较松散
- **本工作流**: 强制调用验证工具，每阶段都有明确的工具验证点

---
*文档遵循 spec §6.3 设计要求*