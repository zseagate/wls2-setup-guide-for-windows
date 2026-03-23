---

### <a id="installlauncherps1"></a> 2. `InstallLauncher.ps1`
```powershell
<#
.SYNOPSIS
  WSL2 Toolbox 启动器
.DESCRIPTION
  实现一键启动、自检环境、加载视觉层与菜单控制逻辑。
#>
param(
    [Parameter(Mandatory=$false)][string]$Run,
    [Parameter(Mandatory=$false)][string]$Lang,
    [Parameter(Mandatory=$false)][string]$Theme
)

$Global:ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Global:LogFile = "$ProjectRoot\WSL2_Toolbox.log"
$Global:ReportFile = "$ProjectRoot\WSL2_Report.json"
$Global:ProjectVersion = "1.0.0"

function Start-Bootstrap {
    Clear-Host
    Write-Host "🧩 正在初始化 WSL2 Toolbox..." -ForegroundColor Cyan

    $required = @("ui_helpers.ps1", "ui_theme_config.ps1", "ui_config.json", "modules")
    $missing = @()
    foreach ($r in $required) { if (!(Test-Path (Join-Path $ProjectRoot $r))) { $missing += $r } }

    if ($missing.Count -gt 0) {
        Write-Host "`n❌ 缺少必要文件：" -ForegroundColor Red
        $missing | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
        return $false
    }

    if (!(Test-Path $LogFile)) { New-Item -ItemType File -Path $LogFile | Out-Null }
    Add-Content -Path $LogFile -Value "`n==== 启动日志: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===="
    Add-Content -Path $LogFile -Value "项目版本: $ProjectVersion"

    $modCount = (Get-ChildItem "$ProjectRoot\modules" -Filter "*.ps1").Count
    Write-Host "✅ 检测通过, 共 $modCount 个功能模块。" -ForegroundColor Green
    return $true
}

$bootOK = Start-Bootstrap
if (-not $bootOK) {
    Write-Host "初始化失败，程序终止。" -ForegroundColor Red
    exit
}

. "$ProjectRoot\ui_theme_config.ps1"
. "$ProjectRoot\ui_helpers.ps1"

if ($PSBoundParameters.ContainsKey("Lang"))  { $Global:UILang = (Get-Content "$ProjectRoot\ui_config.json" -Raw | ConvertFrom-Json).LanguagePack.$Lang }
if ($PSBoundParameters.ContainsKey("Theme")) { $Global:UITheme = (Get-Content "$ProjectRoot\ui_config.json" -Raw | ConvertFrom-Json).Themes.$Theme }

Initialize-UIConfig
Show-Progress "系统加载中..." -Steps 10 -Delay 80

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info','Warning','Error','Success')]
        [string]$Level = 'Info'
    )
    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line = "[${Level}] $timestamp :: $Message"
    Add-Content -Path $Global:LogFile -Value $line

    switch ($Level) {
        'Error'   { Write-ThemeMessage "❌ $Message" "Error" }
        'Warning' { Write-ThemeMessage "⚠ $Message" "Warning" }
        'Success' { Write-ThemeMessage "✔ $Message" "Success" }
        'Info'    { Write-ThemeMessage "$Message" "Info" }
    }
}

function Start-Timer { return [System.Diagnostics.Stopwatch]::StartNew() }

function Stop-Timer ([System.Diagnostics.Stopwatch]$Timer, [string]$Desc) {
    $Timer.Stop()
    $elapsed = "{0:N2}" -f $Timer.Elapsed.TotalSeconds
    Write-Log "$Desc 用时 ${elapsed}s" "Info"
    return $elapsed
}

function Write-Report {
    param([string]$Mode, [string]$Status, [string]$Duration, [string]$ErrorMsg)

    $divider = "`n----- 执行报告 (Mode=$Mode) -----"
    Add-Content -Path $Global:LogFile -Value $divider
    Add-Content -Path $Global:LogFile -Value ("执行时间: " + (Get-Date))
    Add-Content -Path $Global:LogFile -Value ("执行状态: " + $Status)
    Add-Content -Path $Global:LogFile -Value ("运行耗时: ${Duration}s")
    if ($Status -eq "失败" -and $ErrorMsg) {
        Add-Content -Path $Global:LogFile -Value ("错误信息: " + $ErrorMsg)
    }
    Add-Content -Path $Global:LogFile -Value "----------------------------------`n"
}

function Write-JsonReport {
    param(
        [string]$Mode,
        [string]$Status,
        [double]$Duration,
        [string]$ErrorMsg
    )

    $entry = [ordered]@{
        Timestamp   = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        Mode        = $Mode
        Status      = $Status
        DurationSec = [Math]::Round($Duration,2)
        Error       = $ErrorMsg
        Version     = $Global:ProjectVersion
        PSVersion   = $PSVersionTable.PSVersion.ToString()
    }

    if (!(Test-Path $Global:ReportFile)) {
        @() | ConvertTo-Json -Depth 5 | Set-Content $Global:ReportFile
    }

    $json = Get-Content $Global:ReportFile -Raw | ConvertFrom-Json
    $json += $entry
    $json | ConvertTo-Json -Depth 5 | Set-Content $Global:ReportFile

    Write-Log "✅ 已更新 JSON 报告: $($Global:ReportFile)" "Info"
}

function Get-ReportSummary {
    param([string]$ReportPath = $Global:ReportFile)

    if (!(Test-Path $ReportPath)) {
        Write-Log "未找到报告文件：$ReportPath" "Warning"
        return $null
    }

    $data = Get-Content $ReportPath -Raw | ConvertFrom-Json
    if ($null -eq $data -or $data.Count -eq 0) {
        Write-Log "报告文件为空，无统计数据。" "Warning"
        return $null
    }

    $total    = $data.Count
    $success  = ($data | Where-Object { $_.Status -eq "成功" }).Count
    $failed   = ($data | Where-Object { $_.Status -eq "失败" }).Count
    $avgTime  = [Math]::Round(($data | Measure-Object DurationSec -Average).Average,2)

    $successRate = if ($total -gt 0) { [Math]::Round(($success / $total) * 100,2) } else { 0 }

    return [ordered]@{
        总执行次数 = $total
        成功次数   = $success
        失败次数   = $failed
        成功率     = ("{0}%" -f $successRate)
        平均耗时   = ("{0:N2}s" -f $avgTime)
        报告文件   = $ReportPath
    }
}

function Show-ReportSummary {
    param([hashtable]$Summary)

    if ($null -eq $Summary) {
        Write-ThemeMessage "暂无可用统计数据。" "Warning"
        return
    }

    Write-Separator
    Write-ThemeMessage "📊 总体执行报告汇总" "Title"
    Write-Host ("总执行次数 : {0}" -f $Summary["总执行次数"]) -ForegroundColor $UITheme.InfoColor
    Write-Host ("成功次数   : {0}" -f $Summary["成功次数"]) -ForegroundColor $UITheme.SuccessColor
    Write-Host ("失败次数   : {0}" -f $Summary["失败次数"]) -ForegroundColor $UITheme.ErrorColor
    Write-Host ("成功率     : {0}" -f $Summary["成功率"]) -ForegroundColor $UITheme.HighlightColor
    Write-Host ("平均耗时   : {0}" -f $Summary["平均耗时"]) -ForegroundColor $UITheme.InfoColor
    Write-Host ("报告文件   : {0}" -f $Summary["报告文件"]) -ForegroundColor $UITheme.HighlightColor
    Write-Separator
}

function Invoke-Action {
    param([string]$ActionKey)

    $timer = Start-Timer()
    $status = "成功"
    $errMessage = ""

    try {
        switch ($ActionKey.ToLower()) {
            "1"|"install"  { . "$ProjectRoot\modules\install.ps1"; Install-WSL2 }
            "2"|"optimize" { . "$ProjectRoot\modules\optimize.ps1"; Optimize-WSL }
            "3"|"performance" { . "$ProjectRoot\modules\performance.ps1"; Check-Performance }
            "4"|"backup"   { . "$ProjectRoot\modules\backup.ps1"; Backup-WSL }
            "5"|"restore"  { . "$ProjectRoot\modules\restore.ps1"; Restore-WSL }
            "6"|"compress" { . "$ProjectRoot\modules\compress.ps1"; Compress-VHD }
            "7"|"update"   { . "$ProjectRoot\modules\update.ps1"; Check-WSLVersion }
            "8"|"summary"  { $summary = Get-ReportSummary; Show-ReportSummary $summary }
            "0"|"exit"     { Write-ThemeMessage (Get-LangText "Exit") "Info"; exit }
            "auto" {
                Show-OperationStatus "自动部署流程" {
                    . "$ProjectRoot\modules\install.ps1"; Install-WSL2
                    . "$ProjectRoot\modules\optimize.ps1"; Optimize-WSL
                }
                Write-ThemeMessage "自动流程完成。" "Success"
            }
            default {
                Write-ThemeMessage (Get-LangText "Invalid") "Warning"
                $status = "失败"
                $errMessage = "指令无效或未定义：$ActionKey"
            }
        }
    }
    catch {
        $status = "失败"
        $errMessage = $_.Exception.Message
        Write-Log "执行 $ActionKey 时发生异常: $errMessage" "Error"
    }

    $duration = Stop-Timer $timer "执行任务 [$ActionKey]"
    Write-Report $ActionKey $status $duration $errMessage
    Write-JsonReport $ActionKey $status $timer.Elapsed.TotalSeconds $errMessage

    if ($status -eq "成功") {
        Write-Log "任务 [$ActionKey] 执行成功 ✅" "Success"
    } else {
        Write-Log "任务 [$ActionKey] 执行失败 ❌" "Error"
    }
}

function Start-MainMenu {
    Write-ThemeMessage (Get-LangText "Title") "Title"
    Write-ThemeMessage (Get-LangText "Welcome") "Info"
    Write-Separator

    Write-Host "1️⃣  全自动安装" -ForegroundColor $UITheme.InfoColor
    Write-Host "2️⃣  优化设置" -ForegroundColor $UITheme.InfoColor
    Write-Host "3️⃣  性能检测" -ForegroundColor $UITheme.InfoColor
    Write-Host "4️⃣  分发备份" -ForegroundColor $UITheme.InfoColor
    Write-Host "5️⃣  分发恢复" -ForegroundColor $UITheme.InfoColor
    Write-Host "6️⃣  虚拟磁盘压缩" -ForegroundColor $UITheme.InfoColor
    Write-Host "7️⃣  版本检测" -ForegroundColor $UITheme.InfoColor
    Write-Host "8️⃣  查看执行汇总" -ForegroundColor $UITheme.InfoColor
    Write-Host "0️⃣  " + (Get-LangText "Exit") -ForegroundColor $UITheme.WarningColor
    Write-Separator

    $ch = Read-Host (Get-LangText "SelectOption")
    Invoke-Action $ch
    Pause
    Start-MainMenu
}

if ($Run) {
    Write-ThemeMessage "检测到参数运行模式: $Run" "Title"
    Invoke-Action $Run
}
else {
    Start-MainMenu
}
```