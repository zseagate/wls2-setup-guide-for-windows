function Compress-VHD {
    Write-ThemeMessage "WSL 虚拟磁盘清理与压缩模块" "Title"

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
    } catch {
        Write-Warning "无法执行 Optimize-VHD（可能未启用 Hyper-V 管理模块），请改用手动方式："
        Write-Host "VBoxManage modifymedium disk <ext4.vhdx> --compact"
    }
}