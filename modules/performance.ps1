function Check-Performance {
    Write-ThemeMessage "性能检测模块" "Title"
    if (-not (wsl --status 2>$null)) {
        Write-Host "未检测到 WSL，请先安装。"
        return
    }

    Write-Host "`n[GPU 检测]"
    try {
        $gpu = wsl --exec lspci 2>$null | Select-String -Pattern "NVIDIA|AMD|Intel"
        if ($gpu) { Write-Host "检测到 WSL 可用 GPU。" }
        else { Write-Host "未检测到 WSL GPU 支持。" }
    } catch { Write-Host "无法获取 GPU 信息。" }
    
    Write-Host "`n[系统资源]"
    $cpu = [Environment]::ProcessorCount
    $memGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory /1GB,2)
    Write-Host "主机 CPU 核数: $cpu"
    Write-Host "主机内存: $memGB GB"
    
    $cfgPath = "$env:USERPROFILE\.wslconfig"
    if (Test-Path $cfgPath) {
        Write-Host "`n.wslconfig 配置:"
        Get-Content $cfgPath | ForEach-Object { Write-Host $_ }
    }
    
    Write-Host "`n[虚拟磁盘]"
    $disks = Get-ChildItem "$env:USERPROFILE\AppData\Local\Packages" -Directory |
        Where-Object { $_.Name -match "CanonicalGroupLimited" } |
        ForEach-Object { Get-ChildItem "$($_.FullName)\LocalState" -Filter "ext4.vhdx" -ErrorAction SilentlyContinue }
    foreach ($d in $disks) {
        $gb = [math]::Round(($d.Length/1GB),2)
        Write-Host "磁盘: $($d.FullName)"
        Write-Host "大小: $gb GB"
    }
    
    try {
        Write-Host "`n[内核验证]"
        $k = wsl --exec uname -r
        Write-Host "WSL Kernel: $k"
    } catch {
        Write-Host "无法查询内核版本。"
    }
    Write-Host "`n✅ 性能检测报告完成。"
}