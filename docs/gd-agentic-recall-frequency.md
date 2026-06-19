# gd-agentic skill 召回频率初表(Phase 2 排期依据)

> **数据源**:dogfood 日志(`demo/docs/03-production-log.md` 的 load_skill 召回记录)。
> **性质**:初表 + **数据不足**——dogfood 仅覆盖 demo Crystal Collector 3D 收集(①②③④⑤),gd-agentic 96 skill 召回覆盖极低。Phase 2 排期**以 CRITICAL 集中度 + 盲区价值为主,频率为辅**(频率数据不足)。

## 已知召回(03-production-log)

| gd-agentic skill | 召回场景 | score | 含 CRITICAL |
|---|---|---|---|
| godot-characterbody-2d | F1 `CharacterBody movement NEVER` | 0.63 | 无(2D) |
| godot-2d-physics | F5 `Area3D body_entered signal collectible pickup` | 0.24 | 无(2D) |
| godot-performance-optimization | T6 性能 query | 0.80 | 无 |
| godot-optimization | T6 | 0.68 | 无 |
| godot-code-review | T7 发布 query | 0.43 | 无 |
| godot-master(references) | 多 query 散落召回 | 散落 | 无 |

## 数据不足说明

dogfood(demo 3D 收集)仅召回上述少数 skill。gd-agentic **96 skill 大多未召回**(demo 未覆盖移动端/genre/光照/材质等)。

**6 CRITICAL 所在 skill** 在 dogfood **零召回**(demo 不涉及):
- `godot-adapt-desktop-to-mobile`(C1/C2/C3 集中)——移动端适配,demo 是桌面 3D
- `godot-3d-lighting`(C4)/ `godot-3d-materials`(C5/C6)——3D 光照/材质,demo 未深用

→ **频率维度数据不足,Phase 2 排期不依赖频率**,改以 CRITICAL 集中度 + 盲区价值排序。

## Phase 2 首批原创候选(按 CRITICAL 集中度 + 盲区价值)

1. **`godot-adapt-desktop-to-mobile`**——C1/C2/C3 三连(6 CRITICAL 的一半),强首批
2. `godot-3d-lighting`(C4)/ `godot-3d-materials`(C5/C6)——3D 光照/材质,demo 3D 延伸
3. (频率维度待 enhanced 计数补全后调整)

## Phase 1 末评估:enhanced load_skill 计数

频率数据不足 → Phase 1 末评估是否上 enhanced load_skill 计数(改 `load-skill-search.ts` 轻量 log 召回 skill 名),积累真实频率数据。spec §4.2 fallback。
