# godot-ai-kit

AI Godot 开发环境套装——把 godot-mcp-enhanced(执行层)+ GodotPrompter/gd-agentic-skills(知识层)装进开箱即用的 Claude Code 工作区,用 Godot 专版 5 阶段工作流编排。

> [!warning] gd-agentic-skills 为实验性子模块(v0.0.6 预发布,API 可能变)
> 本套件对其仅做指针/索引引用(LGPLv3 真聚合,不修改其源文件)。深度调用其蓝图/技能可能在后续版本失效,详见 `docs/compatibility-matrix.md`。

## 快速开始
```powershell
.\install.ps1
```
> **平台**:MVP 仅提供 Windows PowerShell 安装脚本。macOS/Linux 参照 `install.ps1` 七步手工执行(submodule update → `cd enhanced && npm install && npm run build` → 部署 `config/claude/settings.json`)。跨平台 `install.sh` 计划 v0.2 提供。

> [!tip] 供应链安全
> `install.ps1` 执行 `npm install`(enhanced 依赖已由 `package-lock.json` 锁定)。建议安装后 `cd enhanced && npm audit --audit-level=high` 复核。

## 四家分工
- **enhanced**(子模块,https://github.com/wgt19861219/godot-mcp-enhanced):动手 + 验证(读场景/写脚本/运行/验证)
- **GodotPrompter**(子模块):教 AI 写 Godot(写法规范,C# 双语)
- **gd-agentic-skills**(子模块,实验性):专家经验(NEVER 规则 + 27 游戏蓝图)
- **本仓库粘合层**:统一规则 + 5 阶段工作流 + install + demo

详见 spec:`enhanced/docs/superpowers/specs/2026-06-17-godot-ai-kit-design.md`。
