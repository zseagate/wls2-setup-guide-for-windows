function Install-WSL2 {
    Write-ThemeMessage "自动检测系统版本" "Title"
    $build = [int](Get-CimInstance Win32_OperatingSystem).BuildNumber
    if ($build -lt 18362) {
        Write-Warning "系统版本过低，请升级 Windows 10 到 1903 以上。"
        return
    }
    $sys = if ($build -ge 22000) {"Windows 11"} else {"Windows 10"}
    Write-Log "检测到: $sys Build $build"

    Write-ThemeMessage "启用 Hyper-V 与 WSL 核心组件" "Title"
    dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart | Out-Null
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
    
    Write-ThemeMessage "安装 WSL 内核与发行版" "Title"
    if ($build -ge 22000 -or $build -ge 21364) {
        wsl --install | Out-Null
    } else {
        $kernelUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
        $local = "$env:TEMP\wsl_update.msi"
        Invoke-WebRequest -Uri $kernelUrl -OutFile $local
        Start-Process msiexec.exe -Wait -ArgumentList "/i `"$local`" /quiet"
        wsl --set-default-version 2
    }
    
    Write-ThemeMessage "安装 Ubuntu 子系统" "Title"
    $distros = wsl --list --online
    if ($distros -match "Ubuntu") { wsl --install -d Ubuntu }
    else { Write-Host "未检测到 Ubuntu，可手动执行 wsl --install -d <发行版名>" }
    
    Write-Host "`n✅ 安装完成，请重启计算机。"
}