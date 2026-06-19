# enhanced load_skill 工具层 warning 需求(提给 enhanced)

> 来源:gd-agentic disposal spec §4.3。**enhanced-workflow**:此为套件侧需求,enhanced 实现在 `D:/GitHub/godot-mcp-enhanced`(你在本地改,push 决策权在你)。

## 需求

`load_skill`(`enhanced/src/tools/load-skill-search.ts`)召回结果,若 match 的 `path` 命中下方"CRITICAL 脚本清单",在该 match 返回内容末尾附 warning block:

```
⚠️ 参考代码含已知 CRITICAL(<C# + 一句话>),复制到生产前必须人工审。详见 godot-ai-kit docs/enhanced-boundaries.md #12。
```

**不改 gd-agentic 源**(纯 enhanced MIT 行为)。命中的 match 才附,不命中不附。

## CRITICAL 脚本清单(6)

| C# | 脚本路径(gd-agentic-skills/ 内) | 一句话 |
|---|---|---|
| C1 | skills/godot-adapt-desktop-to-mobile/scripts/offline_save_sync.gd | 硬编码密钥 `secure_mobile_key_123!` + 无完整性校验 |
| C2 | skills/godot-adapt-desktop-to-mobile/scripts/<3 个移动端脚本> | 缺 `InputEventMouseButton` 分支(**脚本名核 `D:\workspace\review\.claude\reviews\2026-06-19-godot-ai-kit-skills-scripts-review.md:194-199` 确认**) |
| C3 | skills/godot-adapt-desktop-to-mobile/scripts/touch_camera_pan_zoom.gd | `1.0/zoom.x` 忽略 Y 分量,非等比缩放方向偏移 |
| C4 | skills/godot-3d-lighting/scripts/fake_gi_bounce.gd | 动态光泄漏 |
| C5 | skills/godot-3d-lighting/scripts/light_lod_optimizer.gd | `visible=false` 硬切换与 `distance_fade` 淡出逻辑冲突 |
| C6 | skills/godot-3d-materials/scripts/transparency_sorting_fix.gd | 未判 null 必崩 |

> C2 的 3 个脚本名待核审查报告(godot-adapt-desktop-to-mobile/scripts/ 下,与 InputEventMouseButton 相关)。其余 C1/C3/C4/C5/C6 路径已 Glob 核实。

## 验收

`load_skill` 召回 `offline_save_sync.gd` 等含 CRITICAL 脚本 → 结果含 warning;召回升阶 skill(如 godot-characterbody-2d)不附。

## 落点参考

- `enhanced/src/tools/load-skill-search.ts:110-134` `searchSkills` 返回 matches 处(每个 match 的 snippet/description 后附 warning)
- CRITICAL 清单维护:套件本文件(6 路径)。enhanced 实现时可硬编清单或读套件配置(plan 执行时定,倾向硬编——清单稳定且小)

## enhanced 实现注意(enhanced-workflow)

- 你在 `D:/GitHub/godot-mcp-enhanced` 改 `load-skill-search.ts`
- push 决策权在你(不擅自)
- 实现后套件 pin bump(enhanced 发布批次时,与 P1 修复等一起)
