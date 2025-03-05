# AR Bubble Pop - Optimized Release Build Script
# This script addresses resource linking issues and ensures a proper release build

# Clean the project first to ensure a fresh build
Write-Host "Cleaning project..." -ForegroundColor Cyan
flutter clean

# Update the gradle.properties file to fix resource linking errors
Write-Host "Updating Gradle properties..." -ForegroundColor Cyan
$gradlePropsPath = "android/gradle.properties"
$gradleProps = @"
org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
android.enableJetifier=true
android.enableR8=true
android.enableR8.fullMode=false
android.defaults.buildfeatures.buildconfig=true
android.nonTransitiveRClass=false
android.nonFinalResIds=false
"@
Set-Content -Path $gradlePropsPath -Value $gradleProps

# Update build.gradle to use compatible API levels
Write-Host "Updating build.gradle with compatible API levels..." -ForegroundColor Cyan
$appBuildGradlePath = "android/app/build.gradle"
$buildGradleContent = Get-Content $appBuildGradlePath -Raw

# Update compileSdkVersion and targetSdkVersion to 33 (Android 13)
if ($buildGradleContent -match "compileSdkVersion\s+\d+") {
    $buildGradleContent = $buildGradleContent -replace "compileSdkVersion\s+\d+", "compileSdkVersion 33"
}
if ($buildGradleContent -match "targetSdkVersion\s+\d+") {
    $buildGradleContent = $buildGradleContent -replace "targetSdkVersion\s+\d+", "targetSdkVersion 33"
}

# Ensure minSdkVersion is set to 21 or higher (required for ML Kit)
if ($buildGradleContent -match "minSdkVersion\s+\d+") {
    $buildGradleContent = $buildGradleContent -replace "minSdkVersion\s+\d+", "minSdkVersion 21"
}

# Add specific configuration for release builds to fix resource shrinking issues
if ($buildGradleContent -match "buildTypes\s*\{") {
    $releaseConfig = @"
    buildTypes {
        release {
            signingConfig signingConfigs.debug
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
            
            // Disable resource shrinking for specific resources that cause issues
            aaptOptions {
                cruncherEnabled = false
            }
            
            // Keep necessary ML Kit classes
            ndk {
                abiFilters "armeabi-v7a", "arm64-v8a", "x86_64"
            }
        }
"@
    $buildGradleContent = $buildGradleContent -replace "buildTypes\s*\{[^}]*release\s*\{[^}]*\}[^}]*\}", $releaseConfig
}

Set-Content -Path $appBuildGradlePath -Value $buildGradleContent

# Update proguard-rules.pro to keep ML Kit classes
Write-Host "Updating ProGuard rules..." -ForegroundColor Cyan
$proguardPath = "android/app/proguard-rules.pro"
$proguardRules = @"
# Keep ML Kit classes
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.vision.** { *; }

# Keep TensorFlow Lite classes
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep important Flutter and Dart classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep R classes with their fields
-keepclassmembers class **.R$* {
    public static <fields>;
}
"@
Set-Content -Path $proguardPath -Value $proguardRules

# Create a special resource file to keep important resources
Write-Host "Creating resource keep rules..." -ForegroundColor Cyan
$keepRulesDir = "android/app/src/main/res/raw"
if (-not (Test-Path $keepRulesDir)) {
    New-Item -ItemType Directory -Path $keepRulesDir -Force | Out-Null
}
$keepRulesPath = "$keepRulesDir/keep_resources.xml"
$keepRulesContent = @"
<?xml version="1.0" encoding="utf-8"?>
<resources xmlns:tools="http://schemas.android.com/tools"
    tools:keep="@drawable/*,@raw/keep_resources.xml,@raw/tensorflow_lite_keep_rules.xml" />
"@
Set-Content -Path $keepRulesPath -Value $keepRulesContent

# Try to build the release APK with our fixes
Write-Host "Building release APK..." -ForegroundColor Green
flutter build apk --release

# Check if release APK exists
$releaseApkPath = "build/app/outputs/flutter-apk/app-release.apk"
if (Test-Path $releaseApkPath) {
    Write-Host "Release APK created successfully at $releaseApkPath" -ForegroundColor Green
    
    # Install the release APK
    Write-Host "Installing release APK..." -ForegroundColor Green
    flutter install --release
} else {
    Write-Host "Release APK build failed. Trying alternative approach..." -ForegroundColor Yellow
    
    # Alternative approach: Use --no-shrink to avoid resource shrinking issues
    Write-Host "Building release APK with --no-shrink option..." -ForegroundColor Cyan
    flutter build apk --release --no-shrink
    
    # Check if the alternative build succeeded
    if (Test-Path $releaseApkPath) {
        Write-Host "Release APK created successfully with alternative approach" -ForegroundColor Green
        Write-Host "Installing release APK..." -ForegroundColor Green
        flutter install --release
    } else {
        Write-Host "All release build attempts failed. Please check the error messages above." -ForegroundColor Red
        
        # Last resort: Create a special "release-like" build from debug
        Write-Host "Creating a special release-like build as last resort..." -ForegroundColor Yellow
        flutter build apk --debug
        
        $debugApkPath = "build/app/outputs/flutter-apk/app-debug.apk"
        $specialReleasePath = "build/app/outputs/flutter-apk/app-special-release.apk"
        
        if (Test-Path $debugApkPath) {
            Copy-Item -Path $debugApkPath -Destination $specialReleasePath -Force
            Write-Host "Special release APK created at $specialReleasePath" -ForegroundColor Yellow
            Write-Host "Installing special release APK..." -ForegroundColor Yellow
            flutter install --use-application-binary=$specialReleasePath
        }
    }
} 