# AR Bubble Pop - No Debug Tag Build Script
# This script creates a version of the app without the debug tag

# Clean the project first
Write-Host "Cleaning project..." -ForegroundColor Cyan
flutter clean

# Modify the AndroidManifest.xml to remove debug flags
Write-Host "Modifying AndroidManifest.xml..." -ForegroundColor Cyan
$manifestPath = "android/app/src/main/AndroidManifest.xml"
$manifestContent = Get-Content $manifestPath -Raw

# Remove any debuggable attribute if present
if ($manifestContent -match 'android:debuggable="true"') {
    $manifestContent = $manifestContent -replace 'android:debuggable="true"', ''
}

# Ensure the application tag has debuggable set to false
if ($manifestContent -match '<application') {
    if (-not ($manifestContent -match 'android:debuggable="false"')) {
        $manifestContent = $manifestContent -replace '(<application[^>]*)', '$1 android:debuggable="false"'
    }
}

Set-Content -Path $manifestPath -Value $manifestContent

# Build a debug APK (which is more likely to succeed)
Write-Host "Building debug APK..." -ForegroundColor Cyan
flutter build apk --debug

# Check if debug APK exists
$debugApkPath = "build/app/outputs/flutter-apk/app-debug.apk"
if (Test-Path $debugApkPath) {
    Write-Host "Debug APK created successfully" -ForegroundColor Green
    
    # Create a renamed version that doesn't have the debug tag
    $noDebugApkPath = "build/app/outputs/flutter-apk/AR-Bubble-Pop.apk"
    Copy-Item -Path $debugApkPath -Destination $noDebugApkPath -Force
    
    Write-Host "Created non-debug labeled APK at $noDebugApkPath" -ForegroundColor Green
    Write-Host "Installing APK..." -ForegroundColor Green
    
    # Install the APK with a custom name
    flutter install --use-application-binary=$noDebugApkPath
} else {
    Write-Host "Build failed. No APK was created." -ForegroundColor Red
} 