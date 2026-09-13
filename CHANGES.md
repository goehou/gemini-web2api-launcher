# gemini-web2api-launcher 更改汇总

> 提交: `a1fe16e` feat: 启动器支持双端口 (.env.anon 匿名 + .env.cookie 认证)
> 日期: 2026-09-13 | 改动: `start-gemini-web2api.cmd` 1 个文件, +58 / -14 行

## 背景

`gemini-web2api` 主项目新增了**双端口链路**能力: 一个匿名实例 + 一个带 cookie 认证实例,
通过项目目录下的 `.env.anon` / `.env.cookie` 两个配置文件区分。启动器需要跟着支持。

## 功能改动

### 1. 双实例模式 (自动检测)

项目目录**同时存在** `.env.anon` 和 `.env.cookie` 时, 自动进入双端口模式:

| 实例 | 配置文件 | 缺省端口 | 路由行为 |
|------|---------|---------|---------|
| 匿名实例 | `.env.anon` | 8081 | 所有模型路由到 Flash-Lite |
| cookie实例 | `.env.cookie` | 8082 | cookie 认证, 模型类别真实生效 |

- 端口号从各自 `.env` 文件的 `PORT=` 读取, 不写死
- 缺少任一 `.env` 文件时, 保持原有单实例行为 (完全向下兼容)

### 2. start / stop / status 全面支持双实例

- **start**: 一次启动两个实例, 各自带 `--env-file` 参数, 分别等待两个端口就绪
- **stop**: 停止两个实例 (双 PID 文件 + 双端口 netstat 扫描)
- **status**: 分栏显示两个实例的运行状态 / HTTP / 进程 / 可用模型
- **PID 文件**: 拆分为 `%TEMP%\gemini-web2api.pid` 和 `%TEMP%\gemini-web2api-2.pid`

### 3. Bug 修复

#### netstat 匹配不到进程

服务绑定 `0.0.0.0`, 但脚本 netstat 过滤只匹配 `127.0.0.1`, 导致
stop / status 找不到端口进程。改为两者都匹配:

```
(?:0\.0\.0\.0|127\.0\.0\.1):<port>\s+.*LISTENING\s+(\d+)
```

#### config.cfg 残留回车符导致路径检查失败

`chcp 65001` (UTF-8) 代码页下, `for /f` 读取 CRLF 文件有已知 quirk:
行尾回车符 (`\r`) 不会被剥掉, 混入 `PROJECT_DIR` 变量末尾——
`if exist "!PROJECT_DIR!\gemini_web2api\__main__.py"` 因路径含不可见 `\r` 永远失败,
报"未找到 gemini_web2api 包目录"。

修复: `:setup` 改用 PowerShell 写 **LF-only** 的 config.cfg
(`[IO.File]::WriteAllText`), 无 `\r` 可残留, 从根源绕开 quirk。

## 使用方法

```
1. 首次运行 start-gemini-web2api.cmd, 配置项目目录和 Python 路径
2. 在 gemini-web2api 项目目录放置 .env.anon / .env.cookie
   (参考主项目 .env.example, 端口分别写 8081 / 8082)
3. 菜单 [1] 启动 → 两个端口同时就绪
   8081 → 匿名, 8082 → 真路由 (需 cookie 有效)
4. 客户端指向 http://127.0.0.1:8082/v1 即走认证实例
```

## 验证记录

```
start   → 匿名实例 8081 ✅ + cookie实例 8082 ✅ (各报启动成功)
status  → 两实例运行中, HTTP 正常, 端口进程可见, 模型列表正常
stop    → 已停止进程 44332, 44008 ✅ (两实例一起停)
再启动  → 循环正常 ✅
```
