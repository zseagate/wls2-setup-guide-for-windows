<#
.SYNOPSIS
  检查 WSL2 性能状态：GPU 加速 / CPU 内存资源 / 虚拟磁盘占用
.DESCRIPTION
  可独立执行或嵌入 WSL 自动化安装主脚本。
.NOTES
  请用管理员身份运行，需确保已安装 WSL2。
#>

$logFile = "$env:USERPROFILE\WSL2_Performance_Report.log"
Start-Transcript -Path $logFile -Append

Function Write-Section {
    param([string]$Title)
    Write-Host "--------------------------" -ForegroundColor Gray
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "--------------------------" -ForegroundColor Gray
}

Function Write-Result {
    param([string]$Item, [string]$Value)
    Write-Host ("{0,-30}: {1}" -f $Item, $Value)
}

# 检查 WSL 是否存在
try {
    $check = wsl --status 2>$null
    if (-not $check) {
        Write-Host "⚠ 未检测到 WSL，请先运行安装脚本再执行性能分析。"
        Stop-Transcript
        exit
    }
} catch {
    Write-Host "⚠ 无法获取 WSL 状态，请确认已安装 WSL。"
    Stop-Transcript
    exit
}

# ---------------------------
# GPU 检测
# ---------------------------
Write-Section "GPU 加速状态"

try {
    $gpuCheck = wsl --exec lspci 2>$null | Select-String -Pattern "NVIDIA|AMD|Intel"
    if ($gpuCheck) {
        Write-Result "检测结果" "✅ 检测到 GPU 设备"
        $glxInfo = wsl --exec glxinfo | Select-String "OpenGL renderer"
        if ($glxInfo) {
            Write-Result "OpenGL 渲染器" "$glxInfo"
        } else {
            Write-Result "OpenGL 渲染器" "未检测到，可能未安装 mesa-utils"
        }
    } else {
        Write-Result "检测结果" "❌ 未检测到 GPU 支持或未启用 GPU 直通"
        Write-Host "建议：Win11 用户可在 Microsoft Store 中升级到最新 WSL (≥1.2) 支持 GPU。"
    }
} catch {
    Write-Result "GPU 检测" "命令执行失败，可能 WSL 暂未启动。"
}

# ---------------------------
# 资源限制检测（内存/CPU）
# ---------------------------
Write-Section "资源占用信息"

$cpuCount = [Environment]::ProcessorCount
$mem = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB

# 读取 .wslconfig 配置
$wslconfigPath = "$env:USERPROFILE\.wslconfig"
if (Test-Path $wslconfigPath) {
    $configText = Get-Content $wslconfigPath -ErrorAction SilentlyContinue
    $memLimit = ($configText | Select-String "memory").ToString()
    $cpuLimit = ($configText | Select-String "processors").ToString()
} else {
    $memLimit = "未配置"
    $cpuLimit = "未配置"
}

Write-Result "主机 CPU 核心数" "$cpuCount"
Write-Result "主机总内存" ("{0:N2} GB" -f $mem)
Write-Result "WSL2 限制内存" "$memLimit"
Write-Result "WSL2 限制 CPU" "$cpuLimit"

# ---------------------------
# 虚拟磁盘使用情况
# ---------------------------
Write-Section "WSL 虚拟磁盘 (ext4.vhdx) 状态"

$wslDisks = Get-ChildItem "$env:USERPROFILE\AppData\Local\Packages" -Directory | 
    Where-Object { $_.Name -match "CanonicalGroupLimited" } |
    ForEach-Object { Get-ChildItem "$($_.FullName)\LocalState" -Filter "ext4.vhdx" -ErrorAction SilentlyContinue }

foreach ($disk in $wslDisks) {
    $sizeGB = [math]::Round(($disk.Length / 1GB), 2)
    $path = $disk.FullName
    Write-Result "虚拟磁盘路径" $path
    Write-Result "磁盘大小" ("{0} GB" -f $sizeGB)
}

# 获取 WSL 内部磁盘使用率
try {
    $diskInfo = wsl --exec df -h /
    Write-Host "`n--- 来自 WSL 内部 df -h ---"
    Write-Host $diskInfo
} catch {
    Write-Host "⚠ 无法在 WSL 内运行 df，未启动或未安装基础命令。"
}

# ---------------------------
# 生成优化建议
# ---------------------------
Write-Section "智能优化建议"

if ($memLimit -eq "未配置" -or $cpuLimit -eq "未配置") {
    Write-Host "💡 建议创建 ~/.wslconfig 文件限制内存与 CPU，参考："
    Write-Host "[wsl2]`nmemory=4GB`nprocessors=2"
}
if (-not $gpuCheck) {
    Write-Host "💡 若需 GPU 加速（CUDA/AI 训练），请：
1️⃣ 安装最新 NVIDIA 驱动（≥ 470.14）
2️⃣ 更新到最新 WSL 版本
3️⃣ 在 Linux 内测试 nvidia-smi"
}
Write-Host "💡 可执行 'Optimize-VHD' 压缩 WSL 虚拟磁盘以回收空间。"

Write-Host "`n✅ 性能检测完成，报告已保存到：$logFile"
Stop-Transcript