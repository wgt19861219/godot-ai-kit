# 精修阶段 (Polish Stage)

## ① 阶段目标
优化游戏性能、用户体验和视觉效果，确保游戏流畅运行。

## ② 知识输入
```text
# 使用 GodotPrompter 检索性能优化方案
load_skill(query="performance draw call")
```

## ③ 执行闭环
调用 enhanced 工具进行性能优化：
- 使用 `profiler` 分析性能瓶颈
- 使用 `validate_scripts` 验证脚本质量
- 识别并解决性能问题

## ④ 产出
- 性能优化后的游戏构建
- 优化后的脚本文件
- 性能测试报告

## ⑤ 降级方案
参考 `docs/enhanced-boundaries.md` 中的边界限制，当无法访问增强工具时：
- 手动执行性能分析
- 使用 Godot 内置性能工具
- 遵循最佳实践手动优化

---
*引用: docs/enhanced-boundaries.md*