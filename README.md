# godot-ai-kit

AI Godot 开发环境套装——把 godot-mcp-enhanced(执行层)+ GodotPrompter/gd-agentic-skills(知识层)装进开箱即用的 Claude Code 工作区,用 Godot 专版 6 阶段循环工作流编排。

> [!warning] gd-agentic-skills 为实验性子模块(v0.0.6 预发布,API 可能变)
> 本套件对其仅做指针/索引引用(LGPLv3 真聚合,不修改其源文件)。深度调用其蓝图/技能可能在后续版本失效,详见 `docs/compatibility-matrix.md`。
> **另**:2026-06-19 深审发现技能库 **6 CRITICAL**(含 `offline_save_sync.gd` 硬编码密钥)。`load_skill` 召回的 scripts 是**参考代码,复制到生产前必须人工审**,详见 `docs/enhanced-boundaries.md` #12。

## 快速开始
```powershell
.\install.ps1
```
> **平台**:Windows 用 `.\install.ps1`;macOS/Linux 用 `bash ./install.sh`(已提供,与 ps1 等价的七步流程:前置检查 → submodule update → 构建 enhanced → 部署 `.claude/settings.json` → 校验技能库 → 自检)。

> [!tip] 供应链安全
> `install.ps1` 执行 `npm install`(enhanced 依赖已由 `package-lock.json` 锁定)。建议安装后 `cd enhanced && npm audit --audit-level=high` 复核。

## 四家分工
- **enhanced**(子模块,https://github.com/wgt19861219/godot-mcp-enhanced):动手 + 验证(读场景/写脚本/运行/验证)
- **GodotPrompter**(子模块):教 AI 写 Godot(写法规范,C# 双语)
- **gd-agentic-skills**(子模块,实验性):专家经验(NEVER 规则 + 27 游戏蓝图)
- **本仓库粘合层**:统一规则 + 6 阶段循环工作流 + install + demo

详见 spec:`enhanced/docs/superpowers/specs/2026-06-17-godot-ai-kit-design.md`。
