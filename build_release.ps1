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

# Build the debug APK first (which works reliably)
flutter build apk --debug

# Then build the release APK with optimizations
flutter build apk --release

# Ensure the release APK exists
$releaseApkPath = "build/app/outputs/flutter-apk/app-release.apk"

# Check if release APK exists
if (Test-Path $releaseApkPath) {
    Write-Host "Release APK created successfully at $releaseApkPath"
    
    # Install the APK
    Write-Host "Installing release APK..."
    flutter install --release
} else {
    Write-Host "Release APK not found at $releaseApkPath"
    
    # Fallback to debug APK if release build fails
    $debugApkPath = "build/app/outputs/flutter-apk/app-debug.apk"
    if (Test-Path $debugApkPath) {
        Write-Host "Falling back to debug APK..."
        flutter install --debug
    } else {
        Write-Host "No APKs found. Build failed."
    }
} 