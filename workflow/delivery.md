# 交付阶段 (Delivery Stage)

## ① 阶段目标
完成最终版本打包、发布准备和质量保证，输出可发布的游戏版本。

## ② 知识输入
```gdscript
# 使用 CCGS checklist 检索发布清单
load_skill(query="release review checklist")
```

## ③ 执行闭环
调用 enhanced 工具进行最终验证：
- 使用 `verify_delivery` 执行完整交付验证
- 确保场景树完整性
- 验证脚本健康度
- 检查性能指标
- 执行自定义断言

## ④ 产出
- 可发布的游戏版本
- 发布包和文档
- 质量验证报告

## ⑤ 降级方案
参考 `docs/enhanced-boundaries.md` 中的边界限制，当无法访问增强工具时：
- 手动执行发布前检查
- 使用标准发布流程
- 人工验证关键功能

---
*引用: docs/enhanced-boundaries.md*