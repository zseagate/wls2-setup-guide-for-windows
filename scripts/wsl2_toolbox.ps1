<#
.SYNOPSIS
    WSL2 工具箱：安装 + 优化 + 性能检测一体化脚本
.DESCRIPTION
    菜单操作界面：
      1️⃣ 全自动安装 WSL2
      2️⃣ 自动优化 WSL 配置 (.wslconfig)
      3️⃣ 性能检测分析
.NOTES
    请以管理员身份运行
#>

# 初始化日志
$global:LogFile = "$env:USERPROFILE\WSL2_Toolbox.log"
Start-Transcript -Path $LogFile -Append | Out-Null

function Write-Title($t){Write-Host "`n==== $t ====" -ForegroundColor Cyan}
function Log($m){Write-Host $m; Add-Content -Path $LogFile -Value $m}

# 检查管理员权限
if (-not ([Security.Principal.WindowsPrincipal]
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "请以管理员身份运行该脚本！"
    Stop-Transcript
    exit
}

# =======================
# 模块 1：全自动安装
# =======================
function Install-WSL2 {
    Write-Title "自动检测系统版本"
    $build = [int](Get-CimInstance Win32_OperatingSystem).BuildNumber
    if ($build -lt 18362) {
        Write-Warning "系统版本过低，请升级 Windows 10 到 1903 以上。"
        return
    }
    $sys = if ($build -ge 22000) {"Windows 11"} else {"Windows 10"}
    Log "检测到: $sys Build $build"

    Write-Title "启用 Hyper-V 与 WSL 核心组件"
    dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart | Out-Null
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
    
    Write-Title "安装 WSL 内核与发行版"
    if ($build -ge 22000 -or $build -ge 21364) {
        wsl --install | Out-Null
    } else {
        $kernelUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
        $local = "$env:TEMP\wsl_update.msi"
        Invoke-WebRequest -Uri $kernelUrl -OutFile $local
        Start-Process msiexec.exe -Wait -ArgumentList "/i `"$local`" /quiet"
        wsl --set-default-version 2
    }
    
    Write-Title "安装 Ubuntu 子系统"
    $distros = wsl --list --online
    if ($distros -match "Ubuntu") { wsl --install -d Ubuntu }
    else { Write-Host "未检测到 Ubuntu，可手动执行 wsl --install -d <发行版名>" }
    
    Write-Host "`n✅ 安装完成，请重启计算机。"
}

# =======================
# 模块 2：优化设置
# =======================
function Optimize-WSL {
    Write-Title "自动生成优化版 .wslconfig"
    $path = "$env:USERPROFILE\.wslconfig"
    $cfg = @"
[wsl2]
memory=4GB
processors=2
localhostForwarding=true
nestedVirtualization=true
[experimental]
autoMemoryReclaim=gradual
sparseVhd=true
"@
    $cfg | Out-File -FilePath $path -Encoding UTF8
    Log "生成配置文件: $path"

    Write-Title "检测代理并调整 DNS"
    $proxy = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -ErrorAction SilentlyContinue
    if ($proxy -and $proxy.ProxyServer) {
        Write-Host "检测到代理: $($proxy.ProxyServer)"
        Add-Content -Path $path -Value "`ndns=8.8.8.8"
    } else {
        Write-Host "无代理环境，使用默认配置。"
    }
    Write-Host "✅ 优化已完成，可通过 wsl --shutdown 后重新启动生效。"
}

# =======================
# 模块 3：性能检测
# =======================
function Check-Performance {
    Write-Title "性能检测模块"
    if (-not (wsl --status 2>$null)) {
        Write-Host "未检测到 WSL，请先安装。"
        return
    }

    # GPU 检测
    Write-Host "`n[GPU 检测]"
    try {
        $gpu = wsl --exec lspci 2>$null | Select-String -Pattern "NVIDIA|AMD|Intel"
        if ($gpu) { Write-Host "检测到 WSL 可用 GPU。" }
        else { Write-Host "未检测到 WSL GPU 支持。" }
    } catch { Write-Host "无法获取 GPU 信息。" }
    
    # 内存与 CPU
    Write-Host "`n[系统资源]"
    $cpu = [Environment]::ProcessorCount
    $memGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory /1GB,2)
    Write-Host "主机 CPU 核数: $cpu"
    Write-Host "主机内存: $memGB GB"
    
    $cfgPath = "$env:USERPROFILE\.wslconfig"
    if (Test-Path $cfgPath) {
        Get-Content $cfgPath | ForEach-Object { Write-Host $_ }
    }
    
    # 磁盘检测
    Write-Host "`n[虚拟磁盘]"
    $disks = Get-ChildItem "$env:USERPROFILE\AppData\Local\Packages" -Directory |
        Where-Object { $_.Name -match "CanonicalGroupLimited" } |
        ForEach-Object { Get-ChildItem "$($_.FullName)\LocalState" -Filter "ext4.vhdx" -ErrorAction SilentlyContinue }
    foreach ($d in $disks) {
        $gb = [math]::Round(($d.Length/1GB),2)
        Write-Host "磁盘: $($d.FullName)"
        Write-Host "大小: $gb GB"
    }
    
    # 内核版本验证
    try {
        Write-Host "`n[内核验证]"
        $k = wsl --exec uname -r
        Write-Host "WSL Kernel: $k"
    } catch {
        Write-Host "无法查询内核版本。"
    }
    Write-Host "`n✅ 性能检测报告完成，日志保存: $LogFile"
}



# =======================
# 模块 4：系统备份与恢复
# =======================
function Backup-WSL {
    Write-Title "WSL 分发系统备份工具"

    # 获取分发列表
    $distros = (wsl --list --quiet)
    if (-not $distros) {
        Write-Host "未检测到任何 WSL 分发，请先安装。"
        return
    }
    
    Write-Host "`n当前已安装分发："
    $i = 1
    foreach ($d in $distros) {
        Write-Host "$i. $d"
        $i++
    }
    $num = Read-Host "`n请选择要备份的分发编号"
    $sel = ($distros[$num - 1])
    if (-not $sel) {
        Write-Host "输入无效，请重试。"
        return
    }
    
    $exportDir = "$env:USERPROFILE\WSL_Backups"
    if (!(Test-Path $exportDir)) {New-Item -ItemType Directory -Path $exportDir | Out-Null}
    $fileName = "$exportDir\$($sel)_backup.tar"
    
    Write-Host "开始导出 <$sel>，保存位置：$fileName"
    wsl --export $sel $fileName
    
    Write-Host "`n✅ 备份完成，可在如下目录找到备份文件："
    Write-Host $exportDir
    Log "已备份分发: $sel -> $fileName"
}

function Restore-WSL {
    Write-Title "WSL 分发系统恢复工具"

    $backupDir = "$env:USERPROFILE\WSL_Backups"
    if (!(Test-Path $backupDir)) {
        Write-Host "未检测到任何备份文件，请先执行备份操作。"
        return
    }
    
    $tarFiles = Get-ChildItem $backupDir -Filter "*.tar"
    if (-not $tarFiles) {
        Write-Host "未找到备份文件。"
        return
    }
    
    Write-Host "`n可用备份文件："
    $i = 1
    foreach ($f in $tarFiles) {
        Write-Host "$i. $($f.Name)"
        $i++
    }
    $num = Read-Host "`n请选择要恢复的备份编号"
    $selFile = ($tarFiles[$num - 1])
    if (-not $selFile) {
        Write-Host "输入无效。"
        return
    }
    
    $newName = Read-Host "请输入恢复后的分发名（例如 Ubuntu_Restore）"
    $restorePath = "$env:USERPROFILE\WSL_Restore\$newName"
    if (!(Test-Path $restorePath)) {New-Item -ItemType Directory -Path $restorePath | Out-Null}
    
    Write-Host "导入备份 $($selFile.Name) -> 分发名 $newName"
    wsl --import $newName $restorePath $selFile.FullName
    
    Write-Host "`n✅ 恢复完成，可通过以下命令启动："
    Write-Host "wsl -d $newName"
    Log "恢复新分发: $newName 来自 $($selFile.FullName)"
}



# =======================
# 模块 6：WSL 虚拟磁盘清理与压缩
# =======================
function Compress-VHD {
    Write-Title "WSL 虚拟磁盘清理与压缩模块"

    $diskList = Get-ChildItem "$env:USERPROFILE\AppData\Local\Packages" -Directory |
        Where-Object { $_.Name -match "CanonicalGroupLimited" } |
        ForEach-Object { Get-ChildItem "$($_.FullName)\LocalState" -Filter "ext4.vhdx" -ErrorAction SilentlyContinue }
    
    if (-not $diskList) {
        Write-Host "未检测到 WSL 虚拟磁盘文件。"
        return
    }
    
    Write-Host "`n检测到以下虚拟磁盘文件："
    $i = 1
    foreach ($disk in $diskList) {
        $sizeGB = [math]::Round(($disk.Length / 1GB), 2)
        Write-Host "$i. $($disk.FullName)  [$sizeGB GB]"
        $i++
    }
    
    $num = Read-Host "请选择要压缩的磁盘编号"
    $target = $diskList[$num - 1]
    if (-not $target) {
        Write-Host "选择无效。"
        return
    }
    
    Write-Host "`n⚙ 即将压缩虚拟磁盘：$($target.FullName)"
    Write-Host "提示：压缩过程中会暂时占用 CPU 与磁盘，请勿中断。"
    Write-Host "开始压缩..."
    
    try {
        Optimize-VHD -Path $target.FullName -Mode Full
        Write-Host "✅ 压缩完成。"
        Log "压缩 VHD 成功: $($target.FullName)"
    } catch {
        Write-Warning "无法执行 Optimize-VHD（可能未启用 Hyper-V 管理模块），请改用手动方式："
        Write-Host "VBoxManage modifymedium disk <ext4.vhdx> --compact"
    }
}



# =======================
# 模块 7：WSL 版本更新检测
# =======================
function Check-WSLVersion {
    Write-Title "WSL 版本检测与更新提示"

    Write-Host "正在获取本地 WSL 版本..."
    try {
        $localVer = wsl --version 2>$null | Select-String "WSL"
        if ($localVer) {
            $versionStr = $localVer.ToString() -replace "[^0-9\.]",""
            Write-Host "当前版本：$versionStr"
        } else {
            Write-Host "此系统可能为旧版 WSL，无版本信息可提取。"
            $versionStr = "旧版"
        }
    
        # 检测远程最新版本（通过微软文档 API）
        $url = "https://raw.githubusercontent.com/microsoft/WSL/main/version.txt"
        $latestVer = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content.Trim()
        Write-Host "最新版本：$latestVer"
    
        if ($versionStr -ne "旧版" -and [version]$versionStr -lt [version]$latestVer) {
            Write-Host "`n⚠ 检测到新版本可用！建议执行："
            Write-Host "wsl --update"
        } else {
            Write-Host "`n✅ 当前版本已是最新。"
        }
        Log "WSL 更新检测完成：本地 $versionStr，对比 $latestVer"
    } catch {
        Write-Warning "无法获取版本信息或网络异常。"
    }
}



# 主菜单

# =======================

function Show-Menu {
    Clear-Host
    Write-Host "========= WSL2 工具箱 =========="
    Write-Host "1️⃣  全自动安装"
    Write-Host "2️⃣  优化设置(.wslconfig)"
    Write-Host "3️⃣  性能检测与报告"
    Write-Host "0️⃣  退出"
    Write-Host "==============================="
    $choice = Read-Host "请选择操作 (0-3)"
    switch ($choice) {
        "1" { Install-WSL2 }
        "2" { Optimize-WSL }
        "3" { Check-Performance }
        "0" { Stop-Transcript; exit }
        default { Write-Host "无效输入"; Show-Menu }
    }
}

# 启动菜单



# 

Show-Menu