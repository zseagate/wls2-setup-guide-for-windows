<#
.SYNOPSIS
    WSL Toolbox 交互视觉 UI 模块
.DESCRIPTION
    用于在终端中显示彩色标题、进度条和消息状态，提升交互体验。
#>

function Write-UIMessage {
    param(
        [string]$Message,
        [ValidateSet("Info","Success","Warning","Error","Title")]
        [string]$Type = "Info"
    )
    switch ($Type) {
        "Info"    { Write-Host "[i] $Message" -ForegroundColor White }
        "Success" { Write-Host "[✓] $Message" -ForegroundColor Green }
        "Warning" { Write-Host "[!] $Message" -ForegroundColor Yellow }
        "Error"   { Write-Host "[✗] $Message" -ForegroundColor Red }
        "Title"   {
            Write-Host ""
            Write-Host "==== $Message ====" -ForegroundColor Cyan
            Write-Host ""
        }
    }
}

function Write-Separator {
    Write-Host ("-" * 50) -ForegroundColor DarkGray
}

function Show-Progress {
    param(
        [string]$Activity,
        [int]$Steps = 10,
        [int]$Delay = 150
    )

    Write-Host ""
    Write-Host $Activity -ForegroundColor Cyan
    for ($i = 1; $i -le $Steps; $i++) {
        $bar = "#" * $i + " " * ($Steps - $i)
        $percent = [math]::Round(($i / $Steps) * 100)
        Write-Host ("[{0}] {1}%" -f $bar, $percent) -NoNewline
        Start-Sleep -Milliseconds $Delay
        Write-Host "`r" -NoNewline
    }
    Write-Host "`n"
}

function Show-OperationStatus {
    param(
        [string]$ActionDesc,
        [scriptblock]$Operation
    )

    try {
        Write-UIMessage "开始: $ActionDesc" "Info"
        $Operation.Invoke()
        Write-UIMessage "完成: $ActionDesc" "Success"
    } catch {
        Write-UIMessage "失败: $ActionDesc" "Error"
        Write-Host $_.Exception.Message -ForegroundColor DarkRed
    }
}

function Show-LoadingAnimation {
    param(
        [string]$Text = "正在执行"
    )
    $frames = @("|","/","-","\")
    for ($i=0; $i -lt 10; $i++) {
        foreach ($f in $frames) {
            Write-Host "$Text $f" -NoNewline
            Start-Sleep -Milliseconds 100
            Write-Host "`r" -NoNewline
        }
    }
    Write-Host "`r完成！     "
}