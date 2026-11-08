# PowerShell Script to Build Android APK without Android Studio GUI
$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " HPS Patient Follow-up - Build APK       " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan

$javaHome = "C:\Users\Nasser\.antigravity-ide\extensions\redhat.java-1.58.0-win32-x64\jre\25.0.4.1-win32-x86_64"
if (-not (Test-Path "$javaHome\bin\java.exe")) {
    $found = Get-ChildItem -Path "C:\Users\Nasser\.antigravity-ide\extensions", "C:\Users\Nasser\.vscode\extensions" -Filter "java.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $javaHome = Split-Path (Split-Path $found.FullName -Parent) -Parent
    }
}
$env:JAVA_HOME = $javaHome
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
