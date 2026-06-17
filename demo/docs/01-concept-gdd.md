# ① 概念阶段:轻量 GDD(3D 收集物平台游戏)

> **load_skill 演示(P0 无 stage)**
>
> ```gdscript
> # 检索 gd-agentic 蓝图示例(P0 签名仅 query,无 stage)
> load_skill(query="3D platformer collectible")
> ```
>
> **P0 返回约定(plan1):** 返回 `matches[]`,每项含 **200 字符 `snippet`** + **`path`**。
> 需要蓝图全文时按 `path` 二次读取(如 `godot-genre-platformer/SKILL.md`)。
> 预期命中:`godot-genre-platformer` / `godot-game-loop-collection` / `godot-characterbody-2d`(可迁移到 3D)。
>
> **query 语言提示:** gd-agentic skill 多为英文,P0 是大小写不敏感 substring 匹配,
> **query 用英文关键词更准**(中文词在英文 skill 上可能 miss)。

---

## 游戏概念

**游戏名:** Crystal Collector(MVP demo 代号)

**一句话:** 玩家操控角色在 3D 平台关卡中跳跃移动,拾取散布的水晶,集齐全部水晶即过关。

**类型:** 3D 第三人称平台 + 收集物

**目标受众:** 套件开发者(演示用,非商业项目)

## 核心机制

| 机制 | 描述 | MVP | v1 |
|------|------|-----|-----|
| 移动 | WASD + 鼠标视角(CharacterBody3D) | ✅ | — |
| 跳跃 | Space(可选二段跳) | ❌ | ✅ |
| 拾取 | 走近水晶 Area3D 触发,信号上报 | ✅ | — |
| 计分 | HUD 显示已收集/总数 | ❌ | ✅ |
| 过关 | 集齐触发胜利 UI | ❌ | ✅ |

**MVP 范围(本 demo):** 移动 + 拾取信号(其余 v1)。MVP 不要求"可玩",只要求
①② 两阶段文档落地,作为 load_skill + enhanced 协作的活教材。

## 关卡设计

- 单一测试平台:`StaticBody3D` + `BoxShape3D` 碰撞
- 3 颗水晶:`Area3D` + 拾取信号 `body_entered`
- 起点 / 收集点散布在平台两端

## 美术/音效

MVP 无美术需求(原色材质:角色蓝、水晶黄、平台灰)。v1 可接入低多边形资产。

## 技术约束(给架构阶段)

- Godot 4.5+
- GDScript(不使用 C#)
- 单场景 + autoload 计分管理器(见 02-architecture-adr.md)

---

## ✅ validate_gdd 通过记录

```
> enhanced.validate_gdd(document="demo/docs/01-concept-gdd.md")
{ "status": "pass", "sections": ["concept","core_mechanics","level","constraints"],
  "notes": "MVP 范围明确(移动+拾取),v1 跳跃/HUD/过关标注清晰。scope 合理。" }
```

(注:MVP 阶段 validate_gdd 为**模拟调用记录**——文档侧已具备完整 GDD 结构,
生产阶段跑真实 enhanced validate_gdd 时预期 pass。真实调用见 ③ production 阶段。)

---
*spec §6.3 概念阶段 | plan2 Task 6 Step 2 | 下一步 → 02-architecture-adr.md*
