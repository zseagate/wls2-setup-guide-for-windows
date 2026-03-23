function Restore-WSL {
    Write-ThemeMessage "WSL 分发系统恢复工具" "Title"

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
}