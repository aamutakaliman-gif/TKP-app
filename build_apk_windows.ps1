# Build APK TKP Collector tanpa Android Studio.
# Cara pakai: klik kanan file ini > "Run with PowerShell"
# (atau di PowerShell: powershell -ExecutionPolicy Bypass -File .\build_apk_windows.ps1)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$Root    = "C:\src"
$Flutter = "$Root\flutter"
$Sdk     = "C:\Android"
$Project = $PSScriptRoot

function Step($m) { Write-Host "`n=== $m ===" -ForegroundColor Cyan }

Step "1/6 Git & Java 17"
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements
}
$jdk = Get-ChildItem "C:\Program Files\Eclipse Adoptium" -Directory -Filter "jdk-17*" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $jdk) {
    winget install --id EclipseAdoptium.Temurin.17.JDK -e --accept-source-agreements --accept-package-agreements
    $jdk = Get-ChildItem "C:\Program Files\Eclipse Adoptium" -Directory -Filter "jdk-17*" | Select-Object -First 1
}
$env:JAVA_HOME = $jdk.FullName
$env:Path = "$env:JAVA_HOME\bin;C:\Program Files\Git\cmd;$env:Path"

Step "2/6 Flutter SDK"
if (-not (Test-Path "$Flutter\bin\flutter.bat")) {
    New-Item -ItemType Directory -Force $Root | Out-Null
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 $Flutter
}
$env:Path = "$Flutter\bin;$env:Path"

Step "3/6 Android command-line tools"
$sdkmanager = "$Sdk\cmdline-tools\latest\bin\sdkmanager.bat"
if (-not (Test-Path $sdkmanager)) {
    $zip = "$env:TEMP\cmdline-tools.zip"
    Invoke-WebRequest "https://dl.google.com/android/repository/commandlinetools-win-13114758_latest.zip" -OutFile $zip
    Expand-Archive $zip "$env:TEMP\cmdtools" -Force
    New-Item -ItemType Directory -Force "$Sdk\cmdline-tools" | Out-Null
    Move-Item "$env:TEMP\cmdtools\cmdline-tools" "$Sdk\cmdline-tools\latest"
}
$env:ANDROID_HOME = $Sdk

Step "4/6 Lisensi & komponen Android SDK"
("y`n" * 30) | & $sdkmanager --licenses | Out-Null
& $sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0" "ndk;28.2.13676358"

Step "5/6 Simpan PATH permanen (user)"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
foreach ($p in @("$Flutter\bin", "$Sdk\platform-tools")) {
    if ($userPath -notlike "*$p*") { $userPath = "$userPath;$p" }
}
[Environment]::SetEnvironmentVariable("Path", $userPath, "User")
[Environment]::SetEnvironmentVariable("ANDROID_HOME", $Sdk, "User")
[Environment]::SetEnvironmentVariable("JAVA_HOME", $env:JAVA_HOME, "User")
flutter config --android-sdk $Sdk --jdk-dir $env:JAVA_HOME --no-analytics | Out-Null

Step "6/6 Build APK"
Set-Location $Project
flutter pub get
flutter build apk --release

$apk = "$Project\build\app\outputs\flutter-apk\app-release.apk"
Write-Host "`nSELESAI. APK ada di:`n$apk" -ForegroundColor Green
explorer.exe /select,"$apk"
