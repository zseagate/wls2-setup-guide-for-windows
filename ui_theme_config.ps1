<#
.SYNOPSIS
  UI 主题色 + 语言配置模块
.DESCRIPTION
  从外部 JSON 读取主题与语言，统一提供颜色与文字资源。
#>

$Global:UITheme = @{}
$Global:UILang = @{}
$Global:ConfigPath = "$PSScriptRoot\ui_config.json"

function Initialize-UIConfig {
    if (Test-Path $ConfigPath) {
        try {
            $json = Get-Content $ConfigPath -Raw | ConvertFrom-Json
            $themeName = $json.Theme
            $langName  = $json.Language
            $Global:UITheme = $json.Themes.$themeName
            $Global:UILang  = $json.LanguagePack.$langName
            Write-Host "✅ 已加载配置: 主题=$themeName, 语言=$langName" -ForegroundColor Green
        } catch {
            Write-Warning "无法解析配置文件，使用默认主题。"
            Set-DefaultTheme
        }
    } else {
        Write-Warning "未找到配置文件，使用默认主题。"
        Set-DefaultTheme
    }
}

function Set-DefaultTheme {
    $Global:UITheme = @{
        TitleColor = "Cyan"
        InfoColor = "White"
        SuccessColor = "Green"
        WarningColor = "Yellow"
        ErrorColor = "Red"
        SeparatorColor = "Gray"
        HighlightColor = "Cyan"
    }
    $Global:UILang = @{
        Title = "WSL2 Toolbox"
        Welcome = "欢迎使用交互界面"
        SelectOption = "请选择操作"
        Exit = "退出"
        Invalid = "无效输入，请重试。"
    }
}

function Write-ThemeMessage {
    param(
        [string]$Message,
        [ValidateSet("Title","Info","Success","Warning","Error","Separator")]
        [string]$Type = "Info"
    )
    $color = $Global:UITheme["${Type}Color"]
    if (-not $color) { $color = "White" }
    switch ($Type) {
        "Separator" { Write-Host ("-" * 50) -ForegroundColor $color }
        "Title" {
            Write-Host ""
            Write-Host "==== $Message ====" -ForegroundColor $color
            Write-Host ""
        }
        default { Write-Host $Message -ForegroundColor $color }
    }
}

function Get-LangText {
    param([string]$Key)
    if ($Global:UILang.ContainsKey($Key)) {
        return $Global:UILang[$Key]
    } else {
        return $Key
    }
}