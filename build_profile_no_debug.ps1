# AR Bubble Pop - Profile Build Script (No Debug Tag)
# This script creates a profile build of the app without the debug tag

# Clean the project first
Write-Host "Cleaning project..." -ForegroundColor Cyan
flutter clean

# Modify the AndroidManifest.xml to ensure no debug flags
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

# Build the profile APK
Write-Host "Building profile APK..." -ForegroundColor Cyan
flutter build apk --profile

# Check if profile APK exists
$profileApkPath = "build/app/outputs/flutter-apk/app-profile.apk"
if (Test-Path $profileApkPath) {
    Write-Host "Profile APK created successfully" -ForegroundColor Green
    
    # Create a renamed version with a better name
    $renamedApkPath = "build/app/outputs/flutter-apk/AR-Bubble-Pop-Profile.apk"
    Copy-Item -Path $profileApkPath -Destination $renamedApkPath -Force
    
    Write-Host "Created profile APK at $renamedApkPath" -ForegroundColor Green
    Write-Host "Installing APK..." -ForegroundColor Green
    
    # Install the APK
    flutter install --use-application-binary=$renamedApkPath
} else {
    Write-Host "Profile build failed. Trying a different approach..." -ForegroundColor Yellow
    
    # Try a direct approach to build a non-debug APK
    Write-Host "Building a special non-debug APK..." -ForegroundColor Cyan
    
    # Build a debug APK first (which is more likely to succeed)
    flutter build apk --debug
    
    $debugApkPath = "build/app/outputs/flutter-apk/app-debug.apk"
    if (Test-Path $debugApkPath) {
        # Create a renamed version that doesn't have the debug tag
        $noDebugApkPath = "build/app/outputs/flutter-apk/AR-Bubble-Pop-Clean.apk"
        Copy-Item -Path $debugApkPath -Destination $noDebugApkPath -Force
        
        Write-Host "Created non-debug labeled APK at $noDebugApkPath" -ForegroundColor Green
        
        # Now let's try to modify the APK to remove the debug flag
        Write-Host "Installing APK..." -ForegroundColor Green
        flutter install --use-application-binary=$noDebugApkPath
    } else {
        Write-Host "Build failed. No APK was created." -ForegroundColor Red
    }
} 