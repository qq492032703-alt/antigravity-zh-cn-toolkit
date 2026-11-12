# Antigravity 简体中文补丁工具包

汉化引擎和基础词典源自 [qqxpee/antigravity2-cn](https://github.com/qqxpee/antigravity2-cn)，此工具包加入了本地维护、回滚和补译规则。上游仓库未标明开源许可证，此副本用于私有备份。

本工具包在目标电脑本机的 Antigravity 原始 `app.asar` 上生成简体中文补丁。它不附带 Antigravity 程序、账号信息、会话数据或其他人的备份文件。

已验证的版本：Antigravity 2.29.0（Windows）。新版会先在临时目录构建并验证；通过后才替换安装文件。

## 使用

1. 退出 Antigravity。
2. 在 PowerShell 运行 `./应用汉化.ps1 -RestartNow`。
3. 脚本会备份当前版本的原始 `app.asar` 到 `backups/`，再启动 Antigravity。

需要 Node.js 与 npm。脚本会使用 npm 获取 `@electron/asar` 作为构建工具；首次运行需要网络。它不会下载或执行其他汉化源码。

## 验证和恢复

脚本会对生成的 ASAR 解包，检查关键注入标记，并对 `preload.js`、`ipcHandlers.js`、`menu.js`、`tray.js`、`loadingOverlay.js`、`updater.js` 执行 JavaScript 语法检查。若任一步失败，安装文件不会被替换。

运行 `./恢复英文.ps1` 可恢复本工具包创建的当前版本原始备份。恢复脚本会先检查补丁和备份哈希，避免覆盖已更新的版本。

## 作用范围

- 翻译桌面界面、设置、菜单、托盘和原生会话右键菜单。
- 包含模型可用性提示与套餐说明的补译规则。
- 不翻译会话标题、聊天内容、代码、文件路径、项目名称或模型专有名称。
- 不安装代理、不改网络设置、不写入账号或凭据。

## 供智能体处理更新

查看 `AGENT_INSTRUCTIONS.md`。更新后必须从该电脑的当前 `app.asar` 重新构建，禁止用旧版 `app.asar` 覆盖新版。
