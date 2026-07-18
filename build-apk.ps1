<#
.SYNOPSIS
    自动构建交割单可视化的 Android APK
.DESCRIPTION
    检查环境、配置路径、构建 Debug APK
.PARAMETER BuildType
    构建类型：Debug 或 Release
.EXAMPLE
    .\build-apk.ps1
    .\build-apk.ps1 -BuildType Release
#>

param(
    [ValidateSet("Debug", "Release")]
    [string]$BuildType = "Debug"
)

$ErrorActionPreference = "Stop"
$ProjectDir = $PSScriptRoot

Write-Host "=== 交割单可视化 APK 构建工具 ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check Java
Write-Host "[1/5] 检查 Java 环境..." -ForegroundColor Yellow
try {
    $javaVer = & java -version 2>&1 | Select-String "version"
    Write-Host "  Java: $javaVer" -ForegroundColor Green
} catch {
    Write-Host "  错误: 未找到 Java，请安装 JDK 17" -ForegroundColor Red
    Write-Host "  下载: https://adoptium.net/temurin/releases/?version=17" -ForegroundColor Cyan
    exit 1
}

# Check JAVA_HOME
if (-not $env:JAVA_HOME) {
    # Try to auto-detect
    $javaPath = (Get-Command java -ErrorAction SilentlyContinue).Source
    if ($javaPath) {
        $env:JAVA_HOME = Split-Path (Split-Path $javaPath)
        Write-Host "  自动检测 JAVA_HOME: $env:JAVA_HOME" -ForegroundColor Green
    } else {
        Write-Host "  警告: JAVA_HOME 未设置" -ForegroundColor Yellow
    }
}

# Step 2: Check Android SDK
Write-Host "[2/5] 检查 Android SDK..." -ForegroundColor Yellow
$sdkPaths = @(
    $env:ANDROID_HOME,
    $env:ANDROID_SDK_ROOT,
    "$env:LOCALAPPDATA\Android\Sdk",
    "C:\Android\Sdk"
)
$sdkPath = $null
foreach ($p in $sdkPaths) {
    if ($p -and (Test-Path $p)) { $sdkPath = $p; break }
}

if (-not $sdkPath) {
    Write-Host "  错误: 未找到 Android SDK" -ForegroundColor Red
    Write-Host "  请安装 Android Studio 或命令行工具" -ForegroundColor Cyan
    Write-Host "  下载: https://developer.android.com/studio" -ForegroundColor Cyan
    exit 1
}
Write-Host "  SDK: $sdkPath" -ForegroundColor Green

# Create/update local.properties
"sdk.dir=$($sdkPath -replace '\\','\\')" | Out-File -FilePath "$ProjectDir\local.properties" -Encoding ASCII -NoNewline
Write-Host "  local.properties 已更新" -ForegroundColor Green

# Step 3: Check Gradle
Write-Host "[3/5] 检查 Gradle..." -ForegroundColor Yellow
if (Test-Path "$ProjectDir\gradlew.bat") {
    Write-Host "  使用项目 Gradle Wrapper" -ForegroundColor Green
    $gradleCmd = "$ProjectDir\gradlew.bat"
} else {
    try {
        $gradleVer = & gradle --version 2>&1 | Select-String "Gradle"
        Write-Host "  Gradle: $gradleVer" -ForegroundColor Green
        $gradleCmd = "gradle"
        
        # Generate wrapper
        Write-Host "  生成 Gradle Wrapper..." -ForegroundColor Yellow
        Push-Location $ProjectDir
        & $gradleCmd wrapper --gradle-version 8.5
        Pop-Location
        $gradleCmd = "$ProjectDir\gradlew.bat"
    } catch {
        Write-Host "  错误: 未找到 Gradle" -ForegroundColor Red
        Write-Host "  请安装 Gradle 或 Android Studio" -ForegroundColor Cyan
        exit 1
    }
}

# Step 4: Copy HTML
Write-Host "[4/5] 更新网页文件..." -ForegroundColor Yellow
$htmlSource = Join-Path $ProjectDir "..\outputs\stock-visualizer.html"
$htmlDest = Join-Path $ProjectDir "app\src\main\assets\index.html"
if (Test-Path $htmlSource) {
    Copy-Item $htmlSource $htmlDest -Force
    Write-Host "  HTML 已更新" -ForegroundColor Green
} else {
    Write-Host "  使用现有 HTML 文件" -ForegroundColor Gray
}

# Step 5: Build
Write-Host "[5/5] 构建 APK ($BuildType)..." -ForegroundColor Yellow
Push-Location $ProjectDir

$buildTask = if ($BuildType -eq "Release") { "assembleRelease" } else { "assembleDebug" }

try {
    & $gradleCmd $buildTask --no-daemon --console=plain
    
    if ($LASTEXITCODE -eq 0) {
        $apkPath = Get-ChildItem -Path "app\build\outputs\apk" -Filter "*.apk" -Recurse | Select-Object -First 1 -ExpandProperty FullName
        Write-Host "" 
        Write-Host "=== 构建成功! ===" -ForegroundColor Green
        Write-Host "APK 位置: $apkPath" -ForegroundColor Cyan
        
        # Copy APK to outputs
        $outputDir = Join-Path $ProjectDir "..\outputs"
        $outputApk = Join-Path $outputDir "stock-visualizer.apk"
        Copy-Item $apkPath $outputApk -Force
        Write-Host "已复制到: $outputApk" -ForegroundColor Cyan
    } else {
        Write-Host "构建失败，请检查错误信息" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "构建错误: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}
