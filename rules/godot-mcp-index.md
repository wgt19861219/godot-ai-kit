# enhanced 工具规则索引

enhanced 子模块提供 130+ 工具，通过三层架构操作 Godot：

## 模式选择决策树
```
需要操作什么？
├─ .tscn/.gd 文件（静态读写）→ Headless模式
├─ 编辑器中打开的场景（实时）→ Editor模式（需插件）
├─ 运行中的游戏（动态状态）→ Bridge模式（需游戏运行）
└─ 一次性验证 → Headless模式
```

## 实际规则文件列表
enhanced 子模块 `.claude/rules/` 实际包含 **5 个规则文件**（2026-06-17 Glob 确认）：

| 规则文件 | 内容概要 |
|---------|---------|
| `godot-mcp-core.md` | 模式选择、核心工具决策、运行时vs持久化、2D截图限制、常见陷阱 |
| `godot-mcp-bridge.md` | Game Bridge（运行时查询/输入/写入/等待/监控/信号/UI发现） |
| `godot-mcp-editor.md` | Editor模式（WebSocket连接编辑器插件、实时场景操作） |
| `godot-mcp-ui.md` | UI布局（CSS Flexbox/Grid翻译、29种Control子类、声明式布局） |
| `godot-mcp-recording.md` | 录制系统（输入事件捕获→JSON→回放） |

## 使用指南
**详细规则在 enhanced 子模块的 `.claude/rules/` 目录中，按需读取上述5个文件。**

**其他子系统规则**：particles/tilemap/animation/navigation/material/audio/signal 等工具的规则散落在 enhanced CLAUDE.md 中或待建。

**实际清单确认**：执行时用 Glob `enhanced/.claude/rules/*.md` 确认当前实际规则文件。

## 注意事项
- 粘合层只用指针/索引引用，不复制规则内容
- 遇到未规则覆盖的工具，参考 enhanced CLAUDE.md 的工具速查表
- 2D 截图限制：headless 模式下2D CanvasItem截图可能空白，用Bridge或人工截图替代