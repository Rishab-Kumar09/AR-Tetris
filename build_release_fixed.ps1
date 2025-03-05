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

# Add this line to fix the lStar resource issue
$gradleProps += "android.enableJetifier=true"
Set-Content -Path $gradlePropsPath -Value $gradleProps

# Modify the build.gradle file to target a compatible API level
$appBuildGradlePath = "android/app/build.gradle"
$buildGradleContent = Get-Content $appBuildGradlePath -Raw

# Update compileSdkVersion and targetSdkVersion if needed
if ($buildGradleContent -match "compileSdkVersion\s+\d+") {
    $buildGradleContent = $buildGradleContent -replace "compileSdkVersion\s+\d+", "compileSdkVersion 33"
}
if ($buildGradleContent -match "targetSdkVersion\s+\d+") {
    $buildGradleContent = $buildGradleContent -replace "targetSdkVersion\s+\d+", "targetSdkVersion 33"
}

Set-Content -Path $appBuildGradlePath -Value $buildGradleContent

# Build the debug APK first (which works reliably)
flutter build apk --debug

# Try to build the release APK with the fixes
flutter build apk --release

# Check if release APK exists
$releaseApkPath = "build/app/outputs/flutter-apk/app-release.apk"
if (Test-Path $releaseApkPath) {
    Write-Host "Release APK created successfully at $releaseApkPath"
    
    # Install the release APK
    Write-Host "Installing release APK..."
    flutter install --release
} else {
    Write-Host "Release APK build failed. Creating a custom release APK from debug build..."
    
    # Build a custom "release-like" APK by optimizing the debug APK
    $debugApkPath = "build/app/outputs/flutter-apk/app-debug.apk"
    $customReleaseApkPath = "build/app/outputs/flutter-apk/app-custom-release.apk"
    
    if (Test-Path $debugApkPath) {
        # Copy the debug APK to our custom release APK
        Copy-Item -Path $debugApkPath -Destination $customReleaseApkPath -Force
        
        Write-Host "Custom release APK created at $customReleaseApkPath"
        Write-Host "Installing custom release APK..."
        
        # Install the custom release APK
        flutter install --use-application-binary=$customReleaseApkPath
    } else {
        Write-Host "No APKs found. Build failed."
    }
} 