# 版本兼容矩阵

> 本套件由 4 个组件 + 1 个运行时组合而成。子模块 bump 后,组合是否仍能跑通,**不靠人工声明**——**CI 实跑 demo 全流程通过才标绿**(spec §8.4)。
>
> 本矩阵记录每个已发布版本的实际 pin 组合 + 验证状态。MVP 阶段无 CI,验证状态为**手动验证**;v1 起 CI 自动重测,矩阵随子模块 bump 自动更新。

---

## 验证状态图例

| 标记 | 含义 |
|------|------|
| 🟢 绿 | CI 实跑 demo 全流程通过(spec §8.4 定义) |
| 🟡 手动 | 无 CI,人工跑通 demo 全流程;未做自动化回归 |
| 🔴 红 | 已知不兼容 / demo 跑不通 |
| ⚠️ 未验证 | 该组合未测,不保证可用 |

**重要**:MVP 及之前所有行均为 🟡 手动——CI v1 上线后才会出现 🟢 绿。不要把 🟡 当 🟢 用。

---

## MVP 版本(v0.1.0)

| 组件 | 版本 | commit pin | 成熟度 | 验证状态 |
|------|------|-----------|--------|---------|
| **godot-ai-kit**(本套件) | v0.1.0 | — | MVP | 🟡 手动验证 |
| enhanced | v0.18.1+(fix/review-verification 分支) | `1c03909` | 🟢 稳定(~950 测试) | 🟡 手动验证 |
| GodotPrompter | v1.9.0(master) | `e09aa6d` | 🟡 较新 | 🟡 手动验证 |
| gd-agentic-skills | main HEAD | `7fa21da` | 🔴 实验性(v0.0.6 预发布,API 可能变) | ⚠️ 未验证(实验性,仅引用不深度依赖) |
| **Godot 引擎** | 4.5+ | — | — | 🟡 手动验证 |

### MVP pin 说明

- **enhanced `1c03909`**:pin 在 `fix/review-verification` 分支的特定 commit(非分支 HEAD),避免分支漂移。describe 显示 `v0.18.1-15-g1c03909`,即 v0.18.1 之后第 15 个 commit。
- **GodotPrompter `e09aa6d`**:pin 在 master 的 v1.9.0 之后第 1 个 commit(`v1.9.0-1-ge09aa6d`)。用户指令标注 v1.9.0。
- **gd-agentic-skills `7fa21da`**:pin 在 main HEAD。该子模块无 tag(`git describe` 报错),按 main 分支 commit pin。**实验性**,套件仅做指针/索引引用,不修改其源文件(规避 LGPLv3 派生义务,见 NOTICE 与 spec §8.1)。
- **Godot 4.5+**:enhanced v0.18.x 要求 Godot 4.4+,套件 MVP 锁 4.5+ 以用上 4.5 的新 API。

### MVP 手动验证范围

demo(`demo/`)跑了"概念 + 架构"两阶段(3D 项目):
- enhanced 调用链:project → scene → script → validation 通跑
- GodotPrompter 生成提示词链路通
- gd-agentic-skills 仅做引用展示,未深度调用其蓝图/技能

**未覆盖**(标 ⚠️):
- gd-agentic-skills 的具体蓝图/技能调用(实验性,MVP 不承诺)
- 2D 项目的视觉验证(headless 不可用,见 [enhanced-boundaries.md](./enhanced-boundaries.md) #7,需人工介入)
- CI 自动回归(CI v1 上线后才建)

---

## 维护流程(spec §8.5)

子模块升级标准流程:

1. **bump 子模块**到新 commit/tag(非 branch,除非实验性子模块无 tag)
2. **CI 重跑 demo 全流程**(v1 起)+ **矩阵重测**
3. **全绿才发新版套件**;任一环节红,回滚 bump 或修粘合层
4. 矩阵新增一行,旧行保留(历史可追溯)

### 实验性子模块(gd-agentic-skills)的特殊处理

gd-agentic 当前 v0.0.6 预发布,API 可能变:
- 破坏性升级时,套件**可能需跟改粘合层引用**(指针/索引引用方式)
- bump 后必须手动验证粘合层仍有效,不能盲信子模块自述的向后兼容
- 套件本体 MIT,gd-agentic LGPLv3——**绝不修改 gd-agentic 源文件**(见 NOTICE)

---

## 历史版本

(暂无。MVP v0.1.0 是首版。后续版本在此追加,旧行不删。)

| 套件版本 | 发布日期 | enhanced | GodotPrompter | gd-agentic | Godot | 验证状态 |
|---------|---------|----------|---------------|-----------|-------|---------|
| v0.1.0 | 2026-06-17 | `1c03909` | `e09aa6d` | `7fa21da` | 4.5+ | 🟡 手动 |

---

## 相关文档

- [enhanced-boundaries.md](./enhanced-boundaries.md) — enhanced 已知裂缝 + 降级方案(本矩阵假设这些裂缝的降级已就位)
- spec §8.4 — 质量分级标注 + CI 兼容矩阵定义
- spec §8.5 — 维护与版本流程
- `NOTICE` — 各组件来源、版本、许可证、上游仓库
