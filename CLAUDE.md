# godot-ai-kit 套件配置

## 四家分工
- **enhanced(子模块)**:动手 + 验证(读场景/写脚本/运行/验证)
- **GodotPrompter(子模块)**:教 AI 写 Godot(写法规范,C# 双语)
- **gd-agentic-skills(子模块)**:专家经验(NEVER 规则 + 27 游戏蓝图)
- **本仓库粘合层**:统一规则 + 5 阶段工作流 + install + demo

## 何时用谁
- Claude Code(推荐):分层按需生效,tools+skills 真正按需调用
- Cursor/Cline(v2):降级模式,只装顶层+精简 rules,注明 token 成本

## enhanced MCP 工具入口
| 工具 | 用途 | 前提 |
|------|------|------|
| **核心** | mode 决策(Headless/Editor/Bridge) | — |
| read_scene/write_script/execute_gdscript | 读写场景/脚本/动态执行 | headless |
| run_and_verify/validate_scripts | 运行+验证/语法检查 | headless |
| **验证** | get_node_properties/inspect_node | headless |
| validate_gdd/profiler/verify_delivery | GDD验证/性能分析/交付检查 | headless |
| **状态** | query_scene_tree/save_scene | headless |
| dev_loop | 执行→验证→截图→断言一体化 | headless |

## 5 阶段工作流
你在哪个阶段?
→ `workflow/concept.md`(概念→蓝图→轻量 GDD)  
→ `workflow/architecture.md`(架构→场景拆分→ADR)  
→ `workflow/production.md`(生产→NEVER规则→可运行构建)  
→ `workflow/polish.md`(打磨→性能优化→性能达标)  
→ `workflow/delivery.md`(交付→审查清单→发版包)

## 加载约定
重内容用 `load_skill(query="..." libraries=...)` 按需加载,不预载。enhanced 工具详细规则见 `enhanced/.claude/rules/godot-mcp-*.md`(实际5个:core/bridge/editor/ui/recording)。

token 预算:CLAUDE.md≤4KB,rules/≤8KB超限下沉load_skill。