# 🚀 WSL2 Setup Guide for Windows 10/11

## 介绍
本项目旨在帮助 **Windows 10 / Windows 11 用户** 快速、正确地安装和配置 WSL2（Windows Subsystem for Linux 2）。
即使你是完全的小白，也可以按照本指南完成安装！

---

## ✨ 核心特性
✅ 一键启动器 `InstallLauncher.ps1`，自动环境自检
✅ 可视化彩色菜单 + 命令行双模式支持
✅ 自动适配 Windows 10/11 系统差异
✅ 内置常见问题解决方案，自动处理代理、网络等场景
✅ 备份/恢复/磁盘压缩/性能检测全功能覆盖
✅ 自动生成日志与 JSON 性能报告，便于追踪与统计

---

## 🚀 快速开始
### 1️⃣ 以管理员身份运行 PowerShell
### 2️⃣ 进入项目目录
```powershell
cd "C:\path\to\WSL2-Setup-Guide-for-Windows"
```

### 3️⃣ 执行启动脚本

powershell

```
powershell -ExecutionPolicy Bypass -File .\InstallLauncher.ps1
```

------

## 🧩 命令行模式（自动化部署）

跳过菜单直接执行功能，适合批量部署：

| 命令                                                         | 功能                      |
| ------------------------------------------------------------ | ------------------------- |
| `.\InstallLauncher.ps1 -Run install`                         | 全自动安装 WSL2           |
| `.\InstallLauncher.ps1 -Run optimize`                        | 优化 WSL 配置             |
| `.\InstallLauncher.ps1 -Run auto`                            | 自动执行安装+优化流程     |
| `.\InstallLauncher.ps1 -Run summary`                         | 查看历史执行报告汇总      |
| `.\InstallLauncher.ps1 -Run install -Lang en-US -Theme Light` | 指定英文+浅色主题执行安装 |

------

## 📊 输出文件



| 文件               | 用途                             |
| ------------------ | -------------------------------- |
| `WSL2_Toolbox.log` | 文本日志，记录所有操作与异常信息 |
| `WSL2_Report.json` | 结构化 JSON 报告，可用于统计分析 |

---

## 📖 完整图文教程

这个仓库放的是技术实现本身。想看**图文并茂的完整折腾记录**（踩坑过程、对比测试、效果截图），请关注公众号 **绿启未来工坊**——每个项目的完整记录都在那里。

- 🌐 网站：[www.greenzx.com](https://www.greenzx.com) —— 微型技术服务：小团队系统故障排查 / 轻量化网站搭建 / AI 提效落地
- 💻 全部项目：[github.com/zseagate](https://github.com/zseagate)
- ✉️ 联系：zseagate@qq.com

> 一个人做的硬核交付：代码开源、过程留痕、踩坑记录全公开。
