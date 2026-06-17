#!/usr/bin/env bash
# godot-ai-kit 一键安装(macOS/Linux,bash 等价 install.ps1 七步)
# 用法: 在仓库根目录 bash ./install.sh
set -euo pipefail
repo_root="$(cd "$(dirname "$0")" && pwd)"
ok(){ echo "  OK: $1"; }
fail(){ echo "  失败: $1" >&2; exit 1; }
step(){ echo; echo "[$1/7] $2"; }

step 1 "前置检查(git / Node 20+ / Godot 4.5+)"
command -v git >/dev/null || fail "未找到 git"
command -v node >/dev/null || fail "未找到 Node.js 20+"
node_major="$(node -p 'process.versions.node.split(".")[0]')"
[ "$node_major" -ge 20 ] || fail "Node 版本过低(v${node_major}),需要 20+"
ok "git + Node v${node_major}"
if command -v godot >/dev/null; then ok "Godot: $(godot --version 2>/dev/null)"; else echo "  警告: 未找到 Godot,可后续安装 4.5+"; fi

step 2 "初始化 / 更新子模块(enhanced 已用 GitHub HTTPS URL)"
git -C "$repo_root" submodule update --init --recursive || fail "git submodule update 失败"
ok "子模块就绪"

step 3 "构建 godot-mcp-enhanced(npm install + build)"
enhanced_dir="$repo_root/enhanced"
[ -f "$enhanced_dir/package.json" ] || fail "enhanced/package.json 不存在"
( cd "$enhanced_dir" && npm install --no-audit --no-fund && npm run build ) || fail "enhanced 构建失败"
[ -f "$enhanced_dir/build/index.js" ] || fail "构建产物缺失: build/index.js"
ok "enhanced 构建完成"

step 4 "部署 Claude 配置(.claude/settings.json,\${REPO_ROOT} 替换)"
src_config="$repo_root/config/claude/settings.json"
dest_config="$repo_root/.claude/settings.json"
[ -f "$src_config" ] || fail "源配置缺失: $src_config"
mkdir -p "$(dirname "$dest_config")"
if [ -f "$dest_config" ]; then
  echo "  提示: $dest_config 已存在,请手工合并 mcpServers(路径替换为本机 repo_root)"
else
  sed "s|\${REPO_ROOT}|$repo_root|g" "$src_config" > "$dest_config"
  ok "已生成 -> .claude/settings.json"
fi

step 5 "确认 GODOT_SKILL_LIBRARIES(配置内已含)"
grep -q 'GODOT_SKILL_LIBRARIES' "$src_config" || fail "config 缺少 GODOT_SKILL_LIBRARIES env"
ok "GODOT_SKILL_LIBRARIES 已配置"

step 6 "IDE 集成(Claude Code)"
ok "Claude Code 配置就绪(通过 Step 4)"

step 7 "自检(node build/index.js --version)"
ver="$(node "$enhanced_dir/build/index.js" --version 2>&1)" || fail "自检失败: $ver"
echo "$ver" | grep -q 'godot-mcp-enhanced' || fail "自检失败: $ver"
ok "自检通过($ver)"

echo
echo "========================================"
echo " godot-ai-kit 安装完成"
echo "========================================"
echo "下一步: 1. 启动 Godot 4.5+ 加载项目  2. claude  3. MCP 自动连接"
