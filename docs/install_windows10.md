# Windows 10 专属 WSL2 安装指南

## 系统要求
Windows 10 版本 ≥ 1903 (Build 18362)，按 `Win + R` 输入 `winver` 查看版本。

## 安装步骤
1. 开启 WSL 和虚拟机平台功能（管理员 PowerShell 执行）：
```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```



1. 重启计算机。
2. 下载并安装 WSL2 内核更新包：[官方下载地址](https://aka.ms/wsl2kernel)。
3. 设置 WSL 默认版本为 2：

powershell

```
wsl --set-default-version 2
```

1. 安装 Linux 发行版（推荐 Ubuntu）：

powershell

```
wsl --install -d Ubuntu
```

## 常见问题

若提示 `wsl --install` 命令不存在，请升级 Windows 10 到 21H1 及以上版本。



```
---
 
### <a id="docsinstall_windows11md"></a> 9. `docs/install_windows11.md`
​```markdown
# Windows 11 专属 WSL2 安装指南
 
## 系统要求
Windows 11 原生支持 WSL2，无需额外版本限制。
 
## 安装步骤
1. 管理员权限 PowerShell 执行：
​```powershell
wsl --install
```

1. 按提示重启计算机，等待系统自动完成安装。
2. 首次启动 Ubuntu 时设置用户名和密码即可。

## 可选配置

如需自定义发行版，可执行：

powershell

```
wsl --install -d <发行版名称>
```

查看可用发行版列表：

powershell

```
wsl --list --online
```



```
---
 
### <a id="docscommon_issuesmd"></a> 10. `docs/common_issues.md`
​```markdown
# 常见问题与解决方案
 
| 问题描述 | 解决办法 |
|----------|----------|
| “WSL 2 requires an update to its kernel component” | 手动安装 WSL2 内核更新：[官方下载页](https://aka.ms/wsl2kernel) |
| 无法联网 | 公司内网环境下，在 WSL 中执行 `sudo dhclient` 或修改 `/etc/resolv.conf` 添加 DNS 地址 |
| 文件系统操作慢 | 执行 `wsl --shutdown` 后重启 WSL，释放内存与缓存 |
| `wsl --install` 命令不存在 | 升级 Windows 10 到 21H1 及以上版本 |
| GPU 不识别 | 升级 NVIDIA 驱动到 ≥ 470.14 版本，更新 WSL 到最新版 |
| 虚拟磁盘占用空间过大 | 使用 `Optimize-VHD` 命令压缩虚拟磁盘文件 |
```