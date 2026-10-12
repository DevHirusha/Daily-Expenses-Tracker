plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.flutter_frontend"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.flutter_frontend"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Phones use ARM ABIs. Exclude x86_64 from production artifacts; emulator/debug
        // builds can still be produced separately when x86_64 support is needed.
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a")
        }
    }

    buildTypes {
        release {
            // TODO: Replace the debug signing config before publishing to Google Play.
            signingConfig = signingConfigs.getByName("debug")

            // Remove unused Java/Kotlin bytecode and Android resources from release builds.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Flutter copies APKs to the flutter-apk directory using the generic app-*.apk name.
// Keep that compatibility output and also create an app-branded release filename.
val releaseArtifactName = "pocket-crew"
val copyBrandedReleaseApk by tasks.registering {
    doLast {
        val flutterApkDirectory = layout.buildDirectory.dir("outputs/flutter-apk").get().asFile
        if (!flutterApkDirectory.exists()) return@doLast

        flutterApkDirectory
            .listFiles { file ->
                file.isFile && file.name.startsWith("app") && file.name.endsWith("-release.apk")
            }
            ?.forEach { apk ->
                val brandedName = apk.name.replaceFirst("app", releaseArtifactName)
                apk.copyTo(flutterApkDirectory.resolve(brandedName), overwrite = true)
            }
    }
}

// Flutter/AGP creates assembleRelease lazily, so configure it when it becomes available.
tasks.configureEach {
    if (name == "assembleRelease") {
        finalizedBy(copyBrandedReleaseApk)
    }
}
