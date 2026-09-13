# gemini-web2api-launcher

gemini-web2api 服务的 Windows 启动管理工具。

## 功能

- 启动/停止/查看 gemini-web2api 服务状态
- 双端口双实例：项目目录同时存在 `.env.anon` / `.env.cookie` 时，自动同时启动 8081 匿名实例 + 8082 cookie 认证实例
- 首次运行自动引导配置项目目录和 Python 路径
- 配置持久化到 `config.cfg`
- 支持菜单交互和命令行参数两种模式

## 使用方式

### 双击运行

直接双击 `start-gemini-web2api.cmd` 进入交互菜单。

### 命令行

```cmd
start-gemini-web2api.cmd start    # 启动服务
start-gemini-web2api.cmd stop     # 停止服务
start-gemini-web2api.cmd status   # 查看状态
start-gemini-web2api.cmd folder   # 打开项目目录
start-gemini-web2api.cmd config   # 重新配置
```

## 首次配置

首次运行会提示输入：
1. **项目目录** - `gemini_web2api.py` 所在文件夹路径
2. **Python 路径** - `python.exe` 的完整路径

配置保存后无需重复输入。如需修改，选择菜单中的「重新配置」。

## 依赖

- Windows 10+
- PowerShell 5.1+
- Python 3.x
- [gemini-web2api](https://github.com/goehou/gemini-web2api) 项目

## 🤝 友情链接

- [Linux Do](https://linux.do/)

## 更新记录

### 2026-09-13

- **双端口支持**：检测到 `.env.anon` / `.env.cookie` 时自动双实例模式（8081 匿名 + 8082 认证），`start`/`stop`/`status` 全部支持双实例；无 `.env` 文件时保持原单实例行为
- **修复**：netstat 端口进程匹配 `0.0.0.0`/`127.0.0.1` 两种绑定；`config.cfg` 改写为 LF-only，绕开 `chcp 65001` 下 CRLF 残留 `\r` 导致路径检查失败的 quirk
