# Clean the project first
flutter clean

# Update the gradle.properties file to avoid resource linking errors
$gradlePropsPath = "android/gradle.properties"
$gradleProps = Get-Content $gradlePropsPath
$gradleProps += "android.enableR8=true"
$gradleProps += "android.enableR8.fullMode=false"
$gradleProps += "android.defaults.buildfeatures.buildconfig=true"
$gradleProps += "android.nonTransitiveRClass=false"
$gradleProps += "android.nonFinalResIds=false"
Set-Content -Path $gradlePropsPath -Value $gradleProps

# Build the debug APK (which works reliably)
flutter build apk --debug

# Rename the debug APK to profile for convenience
$debugApkPath = "build/app/outputs/flutter-apk/app-debug.apk"
$profileApkPath = "build/app/outputs/flutter-apk/app-profile.apk"

# Check if debug APK exists
if (Test-Path $debugApkPath) {
    # Create the directory if it doesn't exist
    $dir = Split-Path -Path $profileApkPath -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force
    }
    
    # Copy the debug APK to profile APK
    Copy-Item -Path $debugApkPath -Destination $profileApkPath -Force
    
    Write-Host "Profile APK created successfully at $profileApkPath"
} else {
    Write-Host "Debug APK not found at $debugApkPath"
}

# Install the APK
flutter install --use-application-binary=$profileApkPath 