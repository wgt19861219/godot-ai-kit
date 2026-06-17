# enhanced 已知边界与各阶段降级方案

> 本套件把 [godot-mcp-enhanced](https://github.com/...) 当验证工具挂到工作流(workflow/)`① 原型 → ② 灰盒 → ③ 生产 → ④ 打磨 → ⑤ 发布` 五阶段每一步。enhanced 不是无瑕地基,M2–M5 评估已积累 9 条已知裂缝。某工具在某场景失效,验证链就会断。
>
> **本文件逐条列边界 + 降级方案 + 降级方案自身的可靠性。工作流每阶段应引用对应行。**

---

## 原则

**降级路径自身不可靠时,标"需人工介入",不假装自动化。**

地基有缝,上面必须有逃生梯。但逃生梯本身也要标清楚能不能用——如果逃生梯(Bridge take_screenshot)本身有隐患,就如实说 MVP 阶段需人工介入,不要套一层"自动化"的壳子掩盖。

每条裂缝的写法:
- **影响阶段**:工作流 ①–⑤ 哪几阶段会踩到
- **降级方案**:踩到后怎么绕过
- **降级可靠性**:降级方案本身能不能信(🟢 可靠 / 🟡 有条件 / 🔴 不可靠,需人工介入)

---

## 裂缝清单(对应 spec §7 全表)

### 1. autoload 盲区 ⚠️M4/M5 评估有争议

- **现象**:enhanced 在某些调用方式下不会自动加载项目的 autoload 单例/全局类,导致涉及 autoload 的场景验证结果偏离实际运行时。
- **影响阶段**:③ 生产(主要)
- **争议**:
  - **M4 评估认为**:这是真实的 autoload 盲区,run_and_verify 等工具看到的类空间与 Godot 编辑器/导出版本不一致。
  - **M5 评估认为**:部分"autoload 盲区"实为脚本编译错误的连锁反应——autoload 引用的脚本本身就编译失败,导致 autoload 注册失败,表象像盲区,但 `run_and_verify` 本身在 autoload 正常时是可靠的。
  - **结论**:**此边界需 enhanced 侧最终核实**,套件文档不替 enhanced 下定论。
- **降级方案**:需要 autoload 上下文时,工具调用显式传 `load_autoloads=true`,走完整类加载模式,而不是依赖默认的轻量探测。
- **降级可靠性**:🟡 有条件——`load_autoloads=true` 能覆盖大部分场景,但若 autoload 脚本本身有编译错误,无论如何都加载不了;需先用 `validate_scripts` 确认脚本无错。

---

### 2. Edit tab 不匹配(内置 Edit 工具改 .gd 失败)

- **现象**:Claude Code 内置 Edit 工具用 Tab 缩进假设去匹配 GDScript 源,而 GDScript 缩进规则与 Edit 的归一化逻辑不严格匹配,导致 old_string 匹配失败或替换后缩进错乱。
- **影响阶段**:③ 生产(主要,凡是改 .gd 文件的步骤)
- **降级方案**:
  1. 强制走 enhanced 的 `edit_script`(`search_and_replace` 模式,非行号模式)——它有 CRLF 归一化 + GDScript 缩进感知。
  2. CLAUDE.md / rules 已明确**禁用内置 Edit 改 .gd**,只允许 enhanced `edit_script`。
- **降级可靠性**:🟢 可靠——`edit_script search_and_replace` 是 enhanced 专门为 GDScript 设计的路径,M2–M5 一致认可。

---

### 3. CRLF 行尾(Windows 下 edit/批量替换匹配失败)

- **现象**:Windows 开发者仓库若混入 CRLF,enhanced 的字符串匹配(批量替换、search_and_replace、行号定位)会因 CRLF/LF 不一致而失配。
- **影响阶段**:③ 生产(Windows 用户)
- **降级方案**:
  1. 仓库强制 LF 规范化(`.gitattributes` 里 `* text=auto eol=lf`)。
  2. 优先用 `search_and_replace`(它内部做了 CRLF 归一化匹配),不用行号模式。
  3. Windows 用户文档(install.ps1 输出 / README)显式警示 CRLF 风险,建议配 VSCode/Git 的 LF 默认。
- **降级可靠性**:🟢 可靠——只要仓库 `.gitattributes` 正确 + 走 `search_and_replace`,CRLF 不再是验证断点。

---

### 4. validate_scripts 结果不一致 ⚠️最致命

- **现象**:enhanced 的 `validate_scripts` 在不同调用方式下(单文件 vs 批量 vs 项目级),与 Godot 编辑器/导出时的解析结果**存在不一致**——同一脚本 enhanced 说通过,Godot 实际运行却报错;或反过来。
- **影响阶段**:**全阶段验证**——①–⑤ 每一步的"验证"动作几乎都依赖 validate_scripts 下结论。
- **为什么最致命**:它是验证链的根。如果 validate_scripts 本身不可信,那么 "脚本已验证通过" 这个结论本身就要打问号,所有依赖它推进到下一阶段的决策都建立在沙地上。
- **降级方案**:
  1. **交叉确认**:验证结论不单凭一次 `validate_scripts` 下结论,至少用两种方式比对:
     - enhanced `validate_scripts`(单文件)
     - enhanced `run_and_verify`(实际跑场景,看运行时报错)
     - 必要时 Godot 编辑器人工开一下看是否有红波浪线
  2. **不一致时以 `run_and_verify` 实跑为准**——它实际加载并运行,比静态解析更接近真相。
  3. 套件 CLAUDE.md / 工作流文档标注此不一致,提醒每次"脚本通过"结论都要交叉确认。
- **降级可靠性**:🟡 有条件——交叉确认能堵住大部分不一致,但成本高(每次验证要多跑一次 run_and_verify);MVP 阶段接受这个成本换取结论可信。

---

### 5. 重复调用幂等性(batch + 单独 add 产生重复节点)

- **现象**:`batch_add_nodes` 批量加节点后,再用单独 `add_node` 加同名节点,enhanced 不总是报冲突,可能产生重复节点(尤其父路径相同时)。
- **影响阶段**:② 灰盒、③ 生产(场景构建密集阶段)
- **降级方案**:
  1. **add 前先 query**:任何 `add_node` / `batch_add_nodes` 前,先 `query_scene_tree` 查目标父路径下是否已有同名节点。
  2. batch 操作文档警示幂等陷阱——同一脚本里不要对同一父路径既 batch 又单独 add 同名子。
  3. 套件工作流的场景构建步骤强制 "query → 条件 add" 模式。
- **降级可靠性**:🟢 可靠——"query → 条件 add" 是确定性的,不依赖 enhanced 自身的幂等保证。

---

### 6. 超时(大项目 run_and_verify / bake_mesh)

- **现象**:中大型 Godot 项目(几百场景 / 复杂导航网格)下,`run_and_verify` 启动 + 验证、`bake_mesh` 烘焙导航,会超出 enhanced 默认超时(通常 20–30s)被 kill,留下"验证失败"假象。
- **影响阶段**:③ 生产、④ 打磨(大项目)
- **降级方案**:
  1. 文档标注大项目超时风险,`run_and_verify` / `bake_mesh` 调用时显式传更大的 `timeout`(如 60–120s)。
  2. 推荐分块验证——不一次性 `run_and_verify` 整个项目,而是按场景/模块逐个验证。
  3. `bake_mesh` 在 CI 里单独跑,不塞进主验证流程。
- **降级可靠性**:🟢 可靠——显式 timeout + 分块验证是确定性的工程实践。

---

### 7. 2D 截图 headless 不可用 🔴 Bridge 降级自身不可靠,MVP 需人工介入

- **现象**:enhanced 的 `screenshot capture` 在 headless 模式下对 2D 项目不可用(无 GPU 渲染上下文);2D 项目要做视觉验证(布局、UI、精灵位置)时,headless 截图拿不到真实画面。
- **降级尝试**:Game Bridge 的 `take_screenshot` 作为替代——**但 Bridge 自身有已知隐患**:
  - 手动运行 Bridge 常连不上(端口/握手问题)
  - 进程槽死锁(上一次运行没清干净)
  - 端口冲突(9081 被占)
  - 错误信息误导(报"连接失败"实则是 Bridge 没装)
  - 脚本覆盖丢修复(game_bridge.gd 被 enhanced 版本管理覆盖掉用户手改)
- **影响阶段**:④ 打磨(2D 项目)
- **降级方案**:**MVP 阶段 2D 视觉验证标"需人工介入"**——不承诺自动化。开发者在编辑器或手动运行游戏时肉眼检查,把结论记到日志。
- **降级可靠性**:🔴 **不可靠 → 需人工介入**。Bridge 不能作为可靠的自动化降级路径。**这是 MVP 明确接受的边界**——套件不假装能自动验证 2D 视觉,如实标注人工介入。
- **后续**:v2 评估 headless 2D 渲染方案(如 `--rendering-driver opengl3` headless 截图,或离屏渲染),Bridge 隐患单独修。

---

### 8. 确认令牌 / GateGuard 流程中断自动化

- **现象**:部分 enhanced 工具(如危险操作)会返回 `confirmation_token`,要求调用 `confirm_and_execute` 二次确认;GateGuard 规则也会拦截 Edit/Write/Bash 要求事实依据。这在自动化脚本/dev_loop 里会中断流程。
- **影响阶段**:全阶段(凡是走自动化的步骤)
- **降级方案**:
  1. dev_loop / 自动化脚本**预判**哪些操作会要确认,提前在脚本里排好确认点。
  2. 非交互场景(CI、批量)用 `confirm_and_execute` 预授权——拿到 token 后立即在同一脚本里执行。
  3. 文档化常见确认点(如删除节点、修改项目设置),让开发者知道哪里会停。
- **降级可靠性**:🟢 可靠——`confirm_and_execute` 是确定的 API,预授权流程稳定;GateGuard 拦的是"没调查就改",调查完就放行,不是硬阻塞。

---

### 9. run_and_verify 残留进程

- **现象**:`run_and_verify` 启动 Godot 实例做验证,若中途超时/异常,Godot 进程不一定被清理,留在后台占端口/锁文件,下一次运行受影响。
- **影响阶段**:③ 生产、⑤ 发布(CI 里最明显)
- **降级方案**:
  1. 每次 `run_and_verify` 后**显式 `stop_project`** 清理,不等自动 GC。
  2. CI 里加进程清理钩子(workflow 结尾 `taskkill /IM godot.exe /F` 或 POSIX `pkill -f godot`)。
  3. 工作流文档把 "run → verify → stop" 作为原子三步骤,不拆开。
- **降级可靠性**:🟢 可靠——显式 `stop_project` + CI 进程清理钩子是确定性方案。

---

## 快速参考表

| # | 裂缝 | 影响阶段 | 降级可靠性 |
|---|------|---------|-----------|
| 1 | autoload 盲区(⚠️M4/M5 争议) | ③ | 🟡 有条件(需 enhanced 核实) |
| 2 | Edit tab 不匹配 | ③ | 🟢 可靠(走 edit_script) |
| 3 | CRLF 行尾 | ③(Windows) | 🟢 可靠(LF + search_and_replace) |
| 4 | validate_scripts 不一致(最致命) | 全阶段 | 🟡 有条件(交叉确认) |
| 5 | 重复调用幂等 | ②③ | 🟢 可靠(query 前置) |
| 6 | 超时 | ③④ | 🟢 可靠(显式 timeout + 分块) |
| 7 | 2D 截图 headless | ④(2D) | 🔴 **不可靠,需人工介入** |
| 8 | 确认令牌/GateGuard | 全阶段 | 🟢 可靠(confirm_and_execute) |
| 9 | run_and_verify 残留进程 | ③⑤ | 🟢 可靠(stop + 钩子) |

---

## 工作流引用约定

`workflow/` 下每个阶段文档应在"验证"小节引用本文件对应行:
- ① 原型:主要看 #4(validate_scripts 交叉确认)
- ② 灰盒:#4、#5
- ③ 生产:#1–#6、#9(几乎全踩)
- ④ 打磨:#6、#7(2D 项目特别看 #7)
- ⑤ 发布:#9(CI 进程清理)

**遇到 🔴 不可靠项(#7),工作流必须写明"人工介入"步骤,不塞给 enhanced 自动化。**
