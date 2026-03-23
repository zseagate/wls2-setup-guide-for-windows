<#
.SYNOPSIS
    自动检测系统版本并安装/升级 WSL2 环境
.DESCRIPTION
    本脚本将自动执行：
      1. 检查系统版本（Win10 / Win11）
      2. 启用 WSL 与虚拟机平台功能
      3. 下载并安装 WSL2 内核（如需要）
      4. 设置默认 WSL 版本为 2
      5. 提供自动安装 Ubuntu 子系统选项
.NOTES
    需以管理员身份运行
#>

# -------------------------------
# 检查是否以管理员身份运行
# -------------------------------
if (-not ([Security.Principal.WindowsPrincipal]
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "请以管理员身份运行该脚本！"
    exit 1
}

Write-Host "=== 检测系统版本 ==="

# 获取系统版本
$osVersion = (Get-CimInstance Win32_OperatingSystem).Version
$buildNumber = [int](Get-CimInstance Win32_OperatingSystem).BuildNumber

if ($buildNumber -ge 22000) {
    $osName = "Windows 11"
} elseif ($buildNumber -ge 18362) {
    $osName = "Windows 10"
} else {
    Write-Warning "系统版本过旧，不支持 WSL2，请升级至少到 Windows 10 1903 (Build 18362)。"
    exit 1
}

Write-Host "检测到系统：$osName (Build $buildNumber)"
Write-Host "正在启用必要的系统组件..."

# -------------------------------
# 启用 WSL 和虚拟化平台
# -------------------------------
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null

# 在 Windows 11 及新版本 Windows 10 使用统一安装命令
if ($buildNumber -ge 22000 -or $buildNumber -ge 21364) {
    Write-Host "使用 wsl --install 触发一键安装..."
    wsl --install
} else {
    Write-Host "执行旧版安装逻辑..."
    
    # 安装 WSL2 内核手动更新包
    $kernelInstaller = "$env:TEMP\\wsl_update.msi"
    $kernelUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
    
    if (!(Test-Path $kernelInstaller)) {
        Write-Host "下载 WSL2 内核更新包..."
        Invoke-WebRequest -Uri $kernelUrl -OutFile $kernelInstaller
    }
    Start-Process msiexec.exe -Wait -ArgumentList "/i `"$kernelInstaller`" /quiet"
    
    Write-Host "设置默认版本为 WSL2..."
    wsl --set-default-version 2
}

Write-Host "正在检查是否已安装 Ubuntu..."

$distributions = wsl --list --online
if ($distributions -match "Ubuntu") {
    Write-Host "检测到 Ubuntu 可用发行版，开始安装..."
    wsl --install -d Ubuntu
} else {
    Write-Warning "未检测到 Ubuntu，可手动在商店下载或运行： wsl --install -d <发行版名>"
}

Write-Host "`n✅ WSL2 安装与配置完成！"
Write-Host "请重启计算机以使更改生效。"
Write-Host "重启后可在 PowerShell 中输入 'wsl' 进入 Linux 子系统。"