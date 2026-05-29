# gemini-web2api-launcher

gemini-web2api 服务的 Windows 启动管理工具。

## 功能

- 启动/停止/查看 gemini-web2api 服务状态
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
