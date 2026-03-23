function Optimize-WSL {
    Write-ThemeMessage "自动生成优化版 .wslconfig" "Title"
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
    Write-Log "生成配置文件: $path"

    Write-ThemeMessage "检测代理并调整 DNS" "Title"
    $proxy = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -ErrorAction SilentlyContinue
    if ($proxy -and $proxy.ProxyServer) {
        Write-Host "检测到代理: $($proxy.ProxyServer)"
        Add-Content -Path $path -Value "`ndns=8.8.8.8"
    } else {
        Write-Host "无代理环境，使用默认配置。"
    }
    Write-Host "✅ 优化已完成，可通过 wsl --shutdown 后重新启动生效。"
}