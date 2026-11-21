# 为 Codex 安装 CAD-MCP 和绘图技能

用户明确要求安装时，从 Windows 本机读取本文件和 [install.ps1](install.ps1)。优先使用已配置并可用的 CAD MCP。默认目标是 AutoCAD，用户指定浩辰 CAD 或中望 CAD 时，分别传入 `-Cad GCAD` 或 `-Cad ZWCAD`。

1. 将本仓库检出或解压到本机，确认根目录包含 `install.ps1`、`SKILL.md` 和 `agents/openai.yaml`。检查 Codex CLI 及本地 CAD 是否可用。安装新 MCP 时还需要 Windows Python 3.10+，以及访问 GitHub 和 Python 包索引的权限。
2. 阅读脚本后，在仓库根目录用 PowerShell 执行 `./install.ps1`。如当前会话无法访问 Windows 主机或写入 Codex 用户配置，请如实说明需要在哪个本地环境执行，并使用客户端正常的授权流程。
3. 脚本成功后执行 `codex mcp list`，确认 `cad-mcp` 已启用，并核对脚本报告的技能目录中有 `SKILL.md`。若当前会话尚未加载新工具，重启 Codex 并开新会话。
4. 在用户打开 CAD 图纸后调用 `list_layers` 等只读工具验证实际连接。报告技能文件是否就位、MCP 是否已注册，以及是否已从 CAD 读到结果。更新或覆盖已有自定义配置前，按 [README.md](README.md) 处理冲突。
