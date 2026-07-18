# 交割单可视化 - Android APK

将 stock-visualizer.html 打包为 Android 原生 APK 应用。

## 项目结构

`
android-app/
├── app/
│   └── src/main/
│       ├── assets/index.html      ← 网页源文件
│       ├── java/.../MainActivity   ← WebView 容器
│       ├── res/                    ← 图标、布局、样式
│       └── AndroidManifest.xml     ← 权限配置
├── build.gradle                    ← 根构建脚本
├── settings.gradle
├── gradle.properties
└── local.properties.template       ← SDK 路径模板
`

## 前置条件

### 1. 安装 JDK 17

下载 Eclipse Temurin JDK 17：
https://adoptium.net/temurin/releases/?version=17

安装后设置环境变量：
`powershell
# PowerShell (永久设置)
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Eclipse Adoptium\jdk-17.x.x-hotspot", "User")
`

### 2. 安装 Android SDK

**方式一：Android Studio（推荐）**
1. 下载 Android Studio：https://developer.android.com/studio
2. 安装后打开，自动下载 SDK
3. SDK 默认安装在：C:\Users\<用户名>\AppData\Local\Android\Sdk

**方式二：仅命令行工具**
1. 下载 Android Command Line Tools：
   https://developer.android.com/studio#command-line-tools-only
2. 解压到 C:\Android\cmdline-tools\
3. 运行 SDK 安装：
   `powershell
   cd C:\Android\cmdline-tools\bin
   .\sdkmanager.bat "platforms;android-34" "build-tools;34.0.0" "platform-tools"
   `

### 3. 配置 local.properties

复制模板并修改 SDK 路径：
`powershell
Copy-Item local.properties.template local.properties
# 编辑 local.properties，确保 sdk.dir 指向你的 Android SDK 路径
`

## 构建 APK

### 方式一：Android Studio（推荐）

1. 打开 Android Studio
2. File → Open → 选择 ndroid-app 文件夹
3. 等待 Gradle 同步完成
4. Build → Build Bundle(s) / APK(s) → Build APK(s)
5. APK 输出位置：pp/build/outputs/apk/debug/app-debug.apk

### 方式二：命令行构建

`powershell
cd android-app

# 确保 JAVA_HOME 和 ANDROID_HOME 已设置
 = "C:\Program Files\Eclipse Adoptium\jdk-17.x.x-hotspot"
 = "C:\Users\Tao\AppData\Local\Android\Sdk"
C:\Users\Tao\.codex\tmp\arg0\codex-arg0OUmR4E;C:\Users\Tao\.cache\codex-runtimes\codex-primary-runtime\dependencies\bin\override;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Windows\System32\OpenSSH\;C:\Program Files (x86)\NVIDIA Corporation\PhysX\Common;C:\Program Files\NVIDIA Corporation\NVIDIA NvDLISR;D:\Bandizip;D:\AProgram\Bandizip;C:\WINDOWS\system32;C:\WINDOWS;C:\WINDOWS\System32\Wbem;C:\WINDOWS\System32\WindowsPowerShell\v1.0\;C:\WINDOWS\System32\OpenSSH\;C:\Program Files\dotnet\;D:\node.js\node_global;D:\node.js;D:\node.js\;C:\Program Files (x86)\Windows Kits\8.1\Windows Performance Toolkit\;C:\Users\Tao\AppData\Local\Programs\Python\Python311\Scripts\;C:\Users\Tao\AppData\Local\Programs\Python\Python311\;C:\Users\Tao\AppData\Local\Microsoft\WindowsApps;C:\Users\Tao\AppData\Local\Programs\cursor\resources\app\bin;D:\AProgram\IntelliJ IDEA 2024.2.4\bin;C:\Users\Tao\AppData\Roaming\npm;C:\Users\Tao\.cache\codex-runtimes\codex-primary-runtime\dependencies\bin\fallback;C:\Users\Tao\AppData\Local\OpenAI\Codex\bin\ada252862d154cdd;C:\Program Files\WindowsApps\OpenAI.Codex_26.707.3748.0_x64__2p2nqsd0c76g0\app\resources += ";\platform-tools"

# 下载 Gradle Wrapper（首次需要）
# 如果没有 gradlew，需要先生成
gradle wrapper --gradle-version 8.5

# 构建 Debug APK
.\gradlew assembleDebug

# APK 位于：
# app\build\outputs\apk\debug\app-debug.apk
`

### 方式三：构建 Release APK（签名版）

`powershell
# 1. 生成签名密钥（首次）
keytool -genkey -v -keystore release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias stock-visualizer

# 2. 构建 Release APK
.\gradlew assembleRelease

# 3. 签名 APK
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 -keystore release-key.jks app\build\outputs\apk\release\app-release-unsigned.apk stock-visualizer

# 4. 对齐
zipalign -v 4 app\build\outputs\apk\release\app-release-unsigned.apk stock-visualizer.apk
`

## 应用功能

| 功能 | 支持情况 |
|------|---------|
| 离线访问 | 部分支持（ECharts 需联网加载） |
| 股票数据 | 需联网（东方财富 API） |
| CSV 导入 | 支持（通过文件选择器） |
| 横竖屏 | 自适应 |
| 全屏模式 | 支持 |
| 返回键 | 网页内导航 |

## 权限说明

| 权限 | 用途 |
|------|------|
| INTERNET | 获取股票行情数据、加载 ECharts |
| READ_EXTERNAL_STORAGE | 导入 CSV 交割单文件 |

## 自定义修改

### 修改应用名称
编辑 pp/src/main/res/values/strings.xml

### 修改应用图标
替换 pp/src/main/res/drawable/ 下的图标文件

### 修改包名
1. 编辑 pp/build.gradle 中的 pplicationId
2. 编辑 pp/src/main/AndroidManifest.xml
3. 重命名 java/com/stockvisualizer/app/ 目录

## 常见问题

### Gradle 同步失败
- 检查网络连接（需要下载依赖）
- 检查 JAVA_HOME 是否正确设置
- 尝试 File → Invalidate Caches → Restart

### APK 安装失败
- 确保手机允许安装未知来源应用
- 检查 Android 版本是否 >= 7.0 (API 24)

### 网页加载空白
- 检查手机网络连接
- ECharts CDN 需要能访问 cdn.jsdelivr.net
