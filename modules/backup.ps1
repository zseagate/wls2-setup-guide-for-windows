function Backup-WSL {
    Write-ThemeMessage "WSL 分发系统备份工具" "Title"

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
}