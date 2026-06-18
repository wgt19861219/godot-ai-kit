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

# ── Step 2: submodule update ──
Write-Step 2 "初始化 / 更新子模块"
# C1 修复:enhanced 子模块 URL 已改为 GitHub HTTPS(见 .gitmodules),无需 file 协议放行。
Push-Location $repoRoot
try {
    & git submodule update --init --recursive
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

# ── Step 4: 生成 .claude/settings.json(基于 repoRoot 替换占位符) ──
Write-Step 4 "部署 Claude 配置(.claude/settings.json,基于 repoRoot 生成)"
$srcConfig = Join-Path $repoRoot 'config\claude\settings.json'
if (-not (Test-Path $srcConfig)) {
    Write-Fail "源配置缺失: $srcConfig"
}

$destDir = Join-Path $repoRoot '.claude'
$destConfig = Join-Path $destDir 'settings.json'
if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

if (Test-Path $destConfig) {
    # 已存在:提示手工合并(避免覆盖用户其他 MCP 配置)
    Write-Host "  提示: $destConfig 已存在。请手工将 config/claude/settings.json 中的 mcpServers 合并进去(路径需替换为本机 repoRoot)。" -ForegroundColor Yellow
    Write-Host "        (策略:不自动覆盖已有 .claude/settings.json,保护用户其他 MCP 配置)" -ForegroundColor DarkGray
} else {
    # C2 修复:config 用 ${REPO_ROOT} 占位符模板,install 时替换为本机 $repoRoot(正斜杠跨平台,node 接受)
    $tpl = Get-Content $srcConfig -Raw
    $repoRootFwd = $repoRoot -replace '\\', '/'
    $tpl = $tpl -replace '\$\{REPO_ROOT\}', $repoRootFwd
    Set-Content -Path $destConfig -Value $tpl -NoNewline
    Write-Ok "已生成 -> .claude/settings.json (路径基于 $repoRootFwd)"
}

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
# 与 install.sh Step5 语义对等:源模板 $srcConfig 含 ${REPO_ROOT} 占位符,
# 必须替换为本机实际路径后再 Test-Path,否则字面校验占位符路径永远告警(狼来了)。
$repoRootFwd = $repoRoot -replace '\\', '/'
$envResolved = $envVal -replace '\$\{REPO_ROOT\}', $repoRootFwd
$libs = $envResolved -split ','
foreach ($lib in $libs) {
    $libTrim = $lib.Trim()
    if ($libTrim -and -not (Test-Path $libTrim)) {
        Write-Host "  警告: 技能库路径不存在(可能子模块未就绪): $libTrim" -ForegroundColor Yellow
    }
}
Write-Ok "GODOT_SKILL_LIBRARIES -> $($libs.Count) 个库(占位符已替换为本机路径校验)"

# ── Step 6: Claude Code 单端(MVP,跳过 Cursor/Cline) ───────
Write-Step 6 "IDE 集成(Claude Code 单端,MVP)"
Write-Host "  已通过 Step 4 部署 .claude/settings.json。Cursor / Cline 等其他 IDE 集成在后续版本支持。" -ForegroundColor DarkGray
Write-Ok "Claude Code 配置就绪"

# ── Step 7: 自检(真实启动 node build/index.js --version) ───
Write-Step 7 "自检(node build/index.js --version)"
# I1 修复:原 Step7 仅查文件可读(accessSync),名不副实(自检通过 ≠ MCP 可启动)。
# 改为真实启动入口 --version(index.ts:135 支持),验证 build 产物能跑。
$builtEntry = Join-Path $enhancedDir 'build\index.js'
if (-not (Test-Path $builtEntry)) {
    Write-Fail "自检失败:build/index.js 缺失"
}
if (-not (Test-Path $srcConfig)) {
    Write-Fail "自检失败:config/claude/settings.json 缺失"
}
try {
    $verOut = (& node $builtEntry --version 2>&1) -join "`n"
    if ($LASTEXITCODE -eq 0 -and "$verOut" -match 'godot-mcp-enhanced') {
        Write-Ok "自检通过($($verOut.Trim()))"
    } else {
        Write-Fail "自检失败:node build/index.js --version 异常(exit $LASTEXITCODE): $verOut"
    }
} catch {
    Write-Fail "自检异常: $_"
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
