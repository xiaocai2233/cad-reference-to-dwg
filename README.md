# 参考图转 CAD 平面图

`cad-reference-to-dwg` 是用于 Codex 的中文技能。它通过 CAD MCP 将户型图、扫描件或 PDF 平面图复绘为分层、可编辑的二维 DWG，也支持按标注截图修订已有图纸。默认以毫米为单位，在模型空间按 1:1 绘制，交付 AutoCAD 2010 兼容格式（AC1024）。

## 一键安装（Windows + Codex）

配套服务由 [daobataotie/CAD-MCP](https://github.com/daobataotie/CAD-MCP) 提供。技能负责复绘流程和绘图规范，MCP 通过 Windows COM 连接本地 CAD。

先准备本地 AutoCAD、浩辰 CAD 或中望 CAD，以及可在 PowerShell 中调用的 Codex CLI。首次安装 MCP 还需要 Python 3.10+ 和访问 GitHub、Python 包索引的网络。

在仓库首页点击 **Code → Download ZIP**，解压后在项目根目录打开 PowerShell，运行下面的命令。

```powershell
.\install.ps1
```

默认连接 AutoCAD。浩辰 CAD 用 `.\install.ps1 -Cad GCAD`，中望 CAD 用 `.\install.ps1 -Cad ZWCAD`。

如果 Windows 拦截从 ZIP 解压的脚本，先阅读 `install.ps1` 并确认来源，再用 `Unblock-File -LiteralPath .\install.ps1` 解除这个文件的下载标记。当前 PowerShell 禁止运行本地脚本时，可以用 `powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\install.ps1`。这只为新启动的进程指定策略，组织下发的策略优先。

脚本从上游的固定提交下载 CAD-MCP，在独立 Python 虚拟环境中安装依赖，通过 `codex mcp add` 注册本地 `stdio` 服务，并复制技能文件。若已经有启用的 `cad-mcp` 条目，脚本会沿用它及其 CAD 类型。遇到已编辑的同名技能文件时，请备份并移走原技能目录后重试。

完成后，启动 CAD 并打开一张图纸，重启 Codex，再输入 `$cad-reference-to-dwg`。可以先请 Codex 用 CAD MCP 列出图层，确认连接正常。终端中的 `codex mcp list` 可用来检查服务是否已注册。

### 交给 AI 安装

把本仓库链接和下方请求一起发给能在这台 Windows 电脑上执行终端命令的 Codex。

> 请读取这个仓库的 AGENTS.md 和 install.ps1，在本机安装 CAD-MCP 和 cad-reference-to-dwg 技能，默认连接 AutoCAD。完成后检查技能文件和 codex mcp list，并用只读方式验证 CAD 连接。

面向 AI 的完整步骤见 [AGENTS.md](AGENTS.md)。

### 已配置其他 CAD MCP 时手动安装技能

1. 在仓库首页选择 **Code → Download ZIP**，解压后打开含有 `SKILL.md` 的目录。
2. 将这个目录命名为 `cad-reference-to-dwg`，放入 Codex 的个人技能目录。Windows 默认安装示例为 `%USERPROFILE%\.codex\skills\cad-reference-to-dwg\SKILL.md`。保持 `agents/openai.yaml` 的相对位置。
3. 打开一个新对话，输入 `$cad-reference-to-dwg`，确认可以选中「参考图转 CAD 平面图」。如果找不到，先检查解压时是否多嵌套了一层目录。

## 使用

先启动本地 CAD 并打开图纸。可发送「请通过 CAD MCP 列出当前图纸的图层」，将返回结果与 CAD 窗口核对。

附上户型图全图，保留尺寸线及其起止点。图上缺少尺度时，补充一段已知实长，并指出对应两端。然后发送下面的请求。

> 使用 $cad-reference-to-dwg，通过 CAD MCP 连接本地 AutoCAD，按附件复绘平面图。请交付可编辑的 DWG 和整体预览，并说明哪些尺寸是估算的。

修订已有图纸时，指定目标 DWG，附上现状截图和参考细节。例如：

> 使用 $cad-reference-to-dwg，把截图中相接共线的墙边合成一条 LINE，保留门洞和关联填充，另存为新版本。

## 绘图约定

- 连续直墙边使用原生 `LINE`，门垛归入墙体图层。按图例、实黑墙段或用户指定范围建立 `SOLID` 填充。
- 外墙窗框通常取 240 mm，细框通常取 120 mm。转角窗用零半径 `FILLET` 收口，窗扇分格以原图为准。
- 家具依照原图样式、朝向和净空定位，并检查是否穿墙或压窗。
- 尺寸使用原生 `DIMENSION`。交付前核对尺寸链、DWG 格式和实际 CAD 预览。

完整规则及图层标准见 [SKILL.md](SKILL.md)。

## 如何检查成图

打开交付的 DWG，用一组原图总尺寸和一组门窗附近的分段尺寸核对比例。选择一段连续直墙，确认可以一次选中整条直边。放大查看门垛和开启弧，再检查转角窗各道框线是否相接、床和柜体是否越过墙面或窗框。需要调整时，把同一部位的 CAD 截图和参考图裁片一起附上，并说明希望改动的地方。
