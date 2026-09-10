# PowerShell Script to Build Android APK without Android Studio GUI
$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " HPS Patient Follow-up - Build APK       " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan

$env:JAVA_HOME = "C:\Users\Nasser\.antigravity-ide\extensions\redhat.java-1.56.0-win32-x64\jre\21.0.12.1-win32-x86_64"
$env:Path = "$env:JAVA_HOME\bin;" + $env:Path

$flutterBin = "C:\Users\Nasser\flutter\bin\flutter.bat"

Write-Host "1. Fetching dependencies..." -ForegroundColor Yellow
& $flutterBin pub get

Write-Host "2. Building Release APK..." -ForegroundColor Yellow
& $flutterBin build apk --release

$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apkPath) {
    Write-Host "SUCCESS! APK created successfully at:" -ForegroundColor Green
    Write-Host "$apkPath" -ForegroundColor Cyan
} else {
    Write-Host "Build failed or APK output missing." -ForegroundColor Red
}
