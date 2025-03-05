# AR Bubble Pop - Downgrade Dependencies Build Script
# This script addresses compatibility issues by downgrading dependencies

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

# Create a special version of the app/build.gradle file that forces dependency versions
Write-Host "Updating build.gradle to force compatible dependency versions..." -ForegroundColor Cyan
$appBuildGradlePath = "android/app/build.gradle"
$buildGradleContent = Get-Content $appBuildGradlePath -Raw

# Ensure we're using SDK 33
if ($buildGradleContent -match "compileSdkVersion\s+\d+") {
    $buildGradleContent = $buildGradleContent -replace "compileSdkVersion\s+\d+", "compileSdkVersion 33"
}
if ($buildGradleContent -match "targetSdkVersion\s+\d+") {
    $buildGradleContent = $buildGradleContent -replace "targetSdkVersion\s+\d+", "targetSdkVersion 33"
}

# Add dependency overrides to force older versions that are compatible with SDK 33
$dependencyOverrides = @"
    // Force specific dependency versions compatible with SDK 33
    configurations.all {
        resolutionStrategy {
            force 'androidx.core:core:1.9.0'
            force 'androidx.core:core-ktx:1.9.0'
            force 'androidx.fragment:fragment:1.5.7'
            force 'androidx.fragment:fragment-ktx:1.5.7'
            force 'androidx.window:window:1.0.0'
            force 'androidx.window:window-java:1.0.0'
            force 'androidx.activity:activity:1.6.1'
            force 'androidx.activity:activity-ktx:1.6.1'
            force 'androidx.lifecycle:lifecycle-runtime:2.5.1'
            force 'androidx.lifecycle:lifecycle-runtime-ktx:2.5.1'
            force 'androidx.lifecycle:lifecycle-livedata:2.5.1'
            force 'androidx.lifecycle:lifecycle-livedata-core:2.5.1'
            force 'androidx.lifecycle:lifecycle-livedata-core-ktx:2.5.1'
            force 'androidx.lifecycle:lifecycle-viewmodel:2.5.1'
            force 'androidx.lifecycle:lifecycle-viewmodel-ktx:2.5.1'
            force 'androidx.lifecycle:lifecycle-viewmodel-savedstate:2.5.1'
            force 'androidx.lifecycle:lifecycle-service:2.5.1'
            force 'androidx.lifecycle:lifecycle-process:2.5.1'
            force 'androidx.annotation:annotation-experimental:1.3.0'
            force 'androidx.datastore:datastore-core-android:1.0.0'
            force 'androidx.datastore:datastore-preferences-android:1.0.0'
            force 'androidx.datastore:datastore-android:1.0.0'
        }
    }
"@

# Insert the dependency overrides before the android block
if ($buildGradleContent -match "android\s*\{") {
    $buildGradleContent = $buildGradleContent -replace "android\s*\{", "$dependencyOverrides`n`nandroid {"
}

# Configure the release build type
$releaseConfig = @"
    buildTypes {
        release {
            signingConfig signingConfigs.debug
            minifyEnabled false
            shrinkResources false
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
"@

if ($buildGradleContent -match "buildTypes\s*\{[^}]*release\s*\{[^}]*\}[^}]*\}") {
    $buildGradleContent = $buildGradleContent -replace "buildTypes\s*\{[^}]*release\s*\{[^}]*\}[^}]*\}", $releaseConfig
}

Set-Content -Path $appBuildGradlePath -Value $buildGradleContent

# Create a special version of the app that doesn't use the debug tag
Write-Host "Creating a special version of AndroidManifest.xml..." -ForegroundColor Cyan
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
    
    # Install the APK
    flutter install --use-application-binary=$noDebugApkPath
} else {
    Write-Host "Build failed. No APK was created." -ForegroundColor Red
} 