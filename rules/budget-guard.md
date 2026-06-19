# Token 预算门守

## 硬约束
- `CLAUDE.md` 顶层 ≤ 4,096 bytes
- `rules/` 总体积 ≤ 8,192 bytes（含所有.md文件）
- 超限内容必须下沉到 skills/(按需) 或 load_skill(运行时)

## 验证方法
```powershell
# 验证 script
$content = (Get-Content $PSScriptRoot/../CLAUDE.md -Raw).Length
Write-Host "CLAUDE.md: $content bytes (限 4096)"

$rules = (Get-ChildItem $PSScriptRoot/../rules -Recurse -Filter *.md | ForEach-Object { (Get-Content $_.FullName -Raw).Length } | Measure-Object -Sum).Sum
Write-Host "rules/: $rules bytes (限 8192)"

if ($content -gt 4096 -or $rules -gt 8192) {
    Write-Host "❌ 超限! 精简内容到达标"
} else {
    Write-Host "✅ token 预算合规"
}
```

## CI 集成
MVP 套件构建时执行上述 script，超限则 fail：

```yaml
# .github/workflows/token-budget-check.yml
- name: 验证 token 预算
  shell: pwsh
  run: |
    $content = (Get-Content CLAUDE.md -Raw).Length
    $rules = (Get-ChildItem rules -Recurse -Filter *.md | ForEach-Object { (Get-Content $_.FullName -Raw).Length } | Measure-Object -Sum).Sum
    if ($content -gt 4096 -or $rules -gt 8192) { exit 1 }
```

## 设计理念
- **精简至上**：只保留必要指针和索引，重内容用 load_skills 按需加载
- **指向性引用**：rules/ 目录仅包含索引和门禁，详细规则在子模块中
- **LGPLv3 合规**：真聚合，无内容复制，避免派生义务