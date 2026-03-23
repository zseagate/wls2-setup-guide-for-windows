function Check-WSLVersion {
    Write-ThemeMessage "WSL 版本检测与更新提示" "Title"

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
    
        $url = "https://raw.githubusercontent.com/microsoft/WSL/main/version.txt"
        $latestVer = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content.Trim()
        Write-Host "最新版本：$latestVer"
    
        if ($versionStr -ne "旧版" -and [version]$versionStr -lt [version]$latestVer) {
            Write-Host "`n⚠ 检测到新版本可用！建议执行："
            Write-Host "wsl --update"
        } else {
            Write-Host "`n✅ 当前版本已是最新。"
        }
    } catch {
        Write-Warning "无法获取版本信息或网络异常。"
    }
}