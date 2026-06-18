# 安全策略 — godot-ai-kit

## enhanced Game Bridge

套件的 enhanced 子模块提供 Game Bridge(运行时 TCP 桥接,让 MCP 控制运行中的游戏)。安全设计:

- **本地绑定**:TCP 仅监听 `127.0.0.1:9081`,不暴露到网络
- **密钥认证**:每次连接需 32 字符随机密钥(拒绝采样消除 modulo bias)
- **暴力破解防护**:5 次认证失败 → 指数退避锁定(30s~300s)
- **密钥权限收紧**:写入后 `icacls`(Windows)/ `chmod 600`(Unix)收紧为属主只读

## 已知边界

- **多用户/远程环境不安全**:localhost 通信可被同机其他用户嗅探。Bridge 设计为**单用户本地开发**。多用户/远程环境需容器/VM 隔离或改用 Unix Domain Socket。
- **secret 权限循环**(enhanced 已知陷阱):`icacls` 收紧为 R 后,重启时可能写 secret 失败导致 Bridge abort。解决:删 `.godot/mcp_bridge_9081.secret` 让其重生(Git Bash 删除需 `MSYS_NO_PATHCONV=1 icacls <path> /reset` 后 `rm`,否则 `/reset` 被 MSYS 路径转换破坏)。
- **GDScript 沙箱**:仅防**误操作**,不防恶意绕过(字符串拼接 `str("OS")+".cmd()"`、`call()` 间接调用可绕过静态扫描)。不适用于不可信输入场景。

## 漏洞报告

发现安全漏洞请**私密报告**(不要开公开 issue):

- GitHub Security Advisory(仓库 Private vulnerability reporting)
- 或邮件:wgt466583094@126.com

请勿在公开渠道披露未修复漏洞。收到报告后会尽快确认并协调修复时序。
