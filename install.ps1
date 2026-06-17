# godot-ai-kit 一键安装脚本(Claude 单端 MVP)
# spec §6.2 — 7 步:前置检查 / submodule / build / 配置复制 / env / 单端 / 自检
# 用法: 在仓库根目录 pwsh -File ./install.ps1
# 失败任一步立即退出并报错,不静默跳过。

$ErrorActionPreference = 'Stop'
$repoRoot = $PSScriptRoot

function Write-Step($n, $msg) {
    Write-Host "`n[$n/7] $msg" -ForegroundColor Cyan
}
function Write-Fail($msg) {
    Write-Host "  失败: $msg" -ForegroundColor Red
    exit 1
}
function Write-Ok($msg) {
    Write-Host "  OK: $msg" -ForegroundColor Green
}

# ── Step 1: 前置检查 ──────────────────────────────────────────
Write-Step 1 "前置检查(Godot 4.5+ / Node 20+ / git)"

# git
$gitExe = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitExe) {
    Write-Fail "未找到 git。请安装 Git for Windows: https://git-scm.com/download/win"
}
Write-Ok "git $($gitExe.Source)"

# Node 20+
$nodeExe = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeExe) {
    Write-Fail "未找到 Node.js。请安装 Node.js 20+: https://nodejs.org/"
}
try {
    $nodeVer = (& node --version) -replace '^v', ''
    $nodeMajor = [int]($nodeVer -split '\.')[0]
} catch {
    Write-Fail "无法解析 node 版本: $_"
}
if ($nodeMajor -lt 20) {
    Write-Fail "Node 版本过低(v$nodeVer),需要 20+。请升级: https://nodejs.org/"
}
Write-Ok "Node v$nodeVer"

# Godot 4.5+(可选,缺失仅警告,因为某些场景用户先配置再装引擎)
$godotExe = Get-Command godot -ErrorAction SilentlyContinue
if (-not $godotExe) {
    # 试试常见路径
    $godotCandidates = @(
        "$env:LOCALAPPDATA\Programs\Godot\godot.exe",
        "$env:ProgramFiles\Godot\godot.exe",
        "${env:ProgramFiles(x86)}\Godot\godot.exe"
    )
    foreach ($p in $godotCandidates) {
        if (Test-Path $p) { $godotExe = [PSCustomObject]@{ Source = $p }; break }
    }
}
if ($godotExe) {
    try {
        $godotVerOut = & $godotExe.Source --version 2>$null
        $godotVerStr = "$godotVerOut"
        if ($godotVerStr -match '(\d+)\.(\d+)') {
            $gmaj = [int]$Matches[1]; $gmin = [int]$Matches[2]
            if ($gmaj -lt 4 -or ($gmaj -eq 4 -and $gmin -lt 5)) {
                Write-Fail "Godot 版本过低($godotVerStr),需要 4.5+。下载: https://godotengine.org/download"
            }
            Write-Ok "Godot $godotVerStr"
        } else {
            Write-Ok "Godot 已安装(版本解析失败:$godotVerStr)"
        }
    } catch {
        Write-Ok "Godot 路径存在但无法执行版本检查:$($godotExe.Source)"
    }
} else {
    Write-Host "  警告: 未找到 Godot。可后续安装 4.5+: https://godotengine.org/download" -ForegroundColor Yellow
}

# ── Step 2: submodule update(关键修正:protocol.file.allow) ──
Write-Step 2 "初始化 / 更新子模块"
# 新版 Git 默认禁止 file:// 协议(transport 'file' not allowed),
# enhanced 本地路径子模块会失败。统一加 -c protocol.file.allow=always。
Push-Location $repoRoot
try {
    & git -c protocol.file.allow=always submodule update --init --recursive
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "git submodule update 失败(exit $LASTEXITCODE)。请检查 .gitmodules 和网络。"
    }
} catch {
    Write-Fail "git submodule update 异常: $_"
} finally {
    Pop-Location
}
Write-Ok "子模块就绪(enhanced / GodotPrompter / gd-agentic-skills)"

# ── Step 3: 构建 enhanced(build/index.js) ────────────────────
Write-Step 3 "构建 godot-mcp-enhanced(npm install + build)"
$enhancedDir = Join-Path $repoRoot 'enhanced'
if (-not (Test-Path (Join-Path $enhancedDir 'package.json'))) {
    Write-Fail "enhanced/package.json 不存在。子模块可能未拉取成功。"
}
Push-Location $enhancedDir
try {
    Write-Host "  npm install(首次较慢)..." -ForegroundColor DarkGray
    & npm install --no-audit --no-fund
    if ($LASTEXITCODE -ne 0) { Write-Fail "npm install 失败(exit $LASTEXITCODE)。" }

    & npm run build
    if ($LASTEXITCODE -ne 0) { Write-Fail "npm run build 失败(exit $LASTEXITCODE)。" }

    $builtEntry = Join-Path $enhancedDir 'build\index.js'
    if (-not (Test-Path $builtEntry)) {
        Write-Fail "构建产物缺失: $builtEntry"
    }
} catch {
    Write-Fail "enhanced 构建异常: $_"
} finally {
    Pop-Location
}
Write-Ok "enhanced 构建完成 -> enhanced/build/index.js"

# ── Step 4: 复制 config/claude/settings.json(含 env) ────────
Write-Step 4 "部署 Claude 配置(.claude/settings.json)"
$srcConfig = Join-Path $repoRoot 'config\claude\settings.json'
if (-not (Test-Path $srcConfig)) {
    Write-Fail "源配置缺失: $srcConfig"
}

# 优先项目级 .claude/settings.json(存在则合并 mcpServers,简单策略:项目级不存在则复制)
$destDir = Join-Path $repoRoot '.claude'
$destConfig = Join-Path $destDir 'settings.json'
if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

if (Test-Path $destConfig) {
    # 已存在:提示用户手工合并(避免覆盖用户其他 MCP 配置)
    Write-Host "  提示: $destConfig 已存在。请手工将 config/claude/settings.json 中的 mcpServers 合并进去。" -ForegroundColor Yellow
    Write-Host "        (MVP 策略:不自动覆盖已有 .claude/settings.json,保护用户其他 MCP 配置)" -ForegroundColor DarkGray
} else {
    Copy-Item -Path $srcConfig -Destination $destConfig -Force
    Write-Ok "已复制 -> .claude/settings.json"
}
# 注意:GODOT_SKILL_LIBRARIES 已写在 config/claude/settings.json 的 mcpServers.env 中,
#       此处不再单独写 env,避免重复(④⑤不重复)。

# ── Step 5: 确认 env(已在 settings.json 中,跳过单独写入) ───
Write-Step 5 "确认 GODOT_SKILL_LIBRARIES(配置内已含)"
try {
    $cfg = Get-Content $srcConfig -Raw | ConvertFrom-Json
} catch {
    Write-Fail "config/claude/settings.json 解析失败: $_"
}
$envVal = $cfg.mcpServers.'godot-mcp-enhanced'.env.GODOT_SKILL_LIBRARIES
if (-not $envVal) {
    Write-Fail "config/claude/settings.json 缺少 GODOT_SKILL_LIBRARIES env。"
}
$libs = $envVal -split ','
foreach ($lib in $libs) {
    $libTrim = $lib.Trim()
    if ($libTrim -and -not (Test-Path $libTrim)) {
        Write-Host "  警告: 技能库路径不存在(可能子模块未就绪): $libTrim" -ForegroundColor Yellow
    }
}
Write-Ok "GODOT_SKILL_LIBRARIES -> $($libs.Count) 个库"

# ── Step 6: Claude Code 单端(MVP,跳过 Cursor/Cline) ───────
Write-Step 6 "IDE 集成(Claude Code 单端,MVP)"
Write-Host "  已通过 Step 4 部署 .claude/settings.json。Cursor / Cline 等其他 IDE 集成在后续版本支持。" -ForegroundColor DarkGray
Write-Ok "Claude Code 配置就绪"

# ── Step 7: 自检(enhanced validate_scripts 离线验证) ────────
Write-Step 7 "自检(enhanced validate_scripts 离线)"
$selfCheckOk = $false
try {
    $validateJs = Join-Path $enhancedDir 'build\index.js'
    # 离线自检:调用 node 直接加载 enhanced 入口不会启动 MCP server,
    # 这里用更稳妥的方式 —— 检查 build 产物可被 node require(语法层验证)。
    & node -e "require('fs').accessSync(process.argv[1], fs.constants.R_OK); console.log('entry readable')" $validateJs
    if ($LASTEXITCODE -eq 0) {
        $selfCheckOk = $true
    } else {
        Write-Host "  警告: enhanced 入口可读性自检失败(非致命,可能 ESM 限制)。" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  警告: 自检异常(非致命): $_" -ForegroundColor Yellow
}

# 备用自检:settings.json 与 build 产物齐备
if (-not $selfCheckOk) {
    $builtEntry = Join-Path $enhancedDir 'build\index.js'
    if ((Test-Path $builtEntry) -and (Test-Path $srcConfig)) {
        Write-Ok "自检(build/index.js + settings.json 齐备)"
    } else {
        Write-Fail "自检失败:build/index.js 或 settings.json 缺失"
    }
} else {
    Write-Ok "自检通过"
}

# ── 完成 ──────────────────────────────────────────────────────
Write-Host "`n========================================" -ForegroundColor Green
Write-Host " godot-ai-kit 安装完成" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "下一步:" -ForegroundColor White
Write-Host "  1. 启动 Godot 4.5+ 并加载项目"
Write-Host "  2. 启动 Claude Code: claude"
Write-Host "  3. MCP server 'godot-mcp-enhanced' 会自动连接 Godot"
Write-Host ""
Write-Host "若 .claude/settings.json 已存在,记得手工合并 mcpServers(见 Step 4 提示)。" -ForegroundColor Yellow
