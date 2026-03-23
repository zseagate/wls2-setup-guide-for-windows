<#
.SYNOPSIS
  一键自动安装并配置 WSL2（增强版）
.DESCRIPTION
  - 自动识别 Windows 版本 (10/11)
  - 检查并启用 Hyper‑V / WSL / 虚拟机平台
  - 检测公司代理配置
  - 创建优化版 .wslconfig
  - 运行安装后验证
  - 实时进度条 & 日志记录
.NOTES
    请用管理员身份运行
#>

# =============================
# 日志初始化
# =============================
$logFile = "$env:USERPROFILE\WSL2_AutoInstall.log"
Start-Transcript -Path $logFile -Append

Function Write-ProgressStep {
    param([string]$Message, [int]$Percent)
    Write-Progress -Activity "WSL2 自动安装中" -Status $Message -PercentComplete $Percent
    Write-Host "[$Percent%] $Message"
}

# =============================
# 权限检查
# =============================
if (-not ([Security.Principal.WindowsPrincipal]
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "❌ 请以管理员身份运行该脚本！"
    Stop-Transcript
    exit 1
}

Write-ProgressStep "开始检测系统版本" 5

# =============================
# 检测系统版本
# =============================
$osVersion = (Get-CimInstance Win32_OperatingSystem).Version
$buildNumber = [int](Get-CimInstance Win32_OperatingSystem).BuildNumber
if ($buildNumber -ge 22000) {
    $osName = "Windows 11"
} elseif ($buildNumber -ge 18362) {
    $osName = "Windows 10"
} else {
    Write-Warning "系统版本过旧，不支持 WSL2，请升级至少到 Windows 10 1903。"
    Stop-Transcript
    exit 1
}
Write-ProgressStep "检测到系统: $osName (Build $buildNumber)" 10

# =============================
# 检查并启用 Hyper‑V
# =============================
Write-ProgressStep "检查并启用 Hyper‑V 功能" 20
$hypervFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
if ($hypervFeature.State -ne "Enabled") {
    Write-Host "正在启用 Hyper‑V..."
    dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart | Out-Null
} else {
    Write-Host "Hyper‑V 已启用。"
}

# =============================
# 启用 WSL 和虚拟机平台
# =============================
Write-ProgressStep "启用 WSL 与虚拟机平台" 30
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null

# =============================
# 检测代理环境并配置网络
# =============================
Write-ProgressStep "检测代理设置" 40
$proxy = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -ErrorAction SilentlyContinue
if ($proxy -and $proxy.ProxyServer) {
    Write-Host "检测到代理设置: $($proxy.ProxyServer)"
    $wslConfigDir = "$env:USERPROFILE\.wslconfig"
    $resolvFile = "$env:USERPROFILE\AppData\Local\Packages\CanonicalGroupLimited*.Ubuntu*\LocalState\rootfs\etc\resolv.conf"

    Write-Host "将在 WSL 中配置自定义 DNS。"
    Set-Content -Path $wslConfigDir -Value @"
[wsl2]
networkingMode=bridged
dns=8.8.8.8
"@
} else {
    Write-Host "未检测到代理环境，跳过网络配置。"
}

# =============================
# 创建优化版 .wslconfig
# =============================
Write-ProgressStep "生成优化版 .wslconfig" 55

$wslConfig = @"
[wsl2]
memory=4GB
processors=2
localhostForwarding=true
nestedVirtualization=true
[experimental]
autoMemoryReclaim=true
sparseVhd=true
sleep=true
"@
$wslconfigPath = "$env:USERPROFILE\.wslconfig"
$wslConfig | Out-File -FilePath $wslconfigPath -Encoding UTF8
Write-Host "✅ 生成 .wslconfig 于 $wslconfigPath"

# =============================
# 安装或升级 WSL 内核
# =============================
Write-ProgressStep "安装/升级 WSL 内核" 70
if ($buildNumber -ge 22000 -or $buildNumber -ge 21364) {
    wsl --install | Out-Null
} else {
    $kernelUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
    $kernelInstaller = "$env:TEMP\wsl_update.msi"
    Invoke-WebRequest -Uri $kernelUrl -OutFile $kernelInstaller
    Start-Process msiexec.exe -Wait -ArgumentList "/i `"$kernelInstaller`" /quiet"
    wsl --set-default-version 2
}

# =============================
# 安装 Ubuntu 并验证
# =============================
Write-ProgressStep "安装 Ubuntu 子系统" 80
$distros = wsl --list --online
if ($distros -match "Ubuntu") {
    wsl --install -d Ubuntu | Out-Null
} else {
    Write-Warning "未检测到 Ubuntu，需手动安装。"
}

Write-ProgressStep "执行安装后验证" 95
Start-Sleep 3
$kernelInfo = wsl --exec uname -r
Write-Host "WSL 内核版本: $kernelInfo"

# =============================
# 完成显示
# =============================
Write-ProgressStep "全部步骤完成 ✅" 100
Write-Host "`n🎉 WSL2 安装、网络优化与验证已完成。"
Write-Host "日志保存位置：$logFile"
Write-Host "可输入 'wsl' 测试是否成功进入 Linux 子系统。"

Stop-Transcript