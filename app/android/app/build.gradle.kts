plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing comes from the environment, never from a file in the repository. With
// FT_RELEASE_KEYSTORE unset, the release build type falls back to the debug key, so a
// release-mode smoke run works on any machine.
val releaseKeystore: String? = System.getenv("FT_RELEASE_KEYSTORE")?.takeIf { it.isNotEmpty() }

android {
    namespace = "dev.tarnan.financetracker"
    // SDK levels are explicit integers rather than the flutter.* properties, so a Flutter
    // upgrade cannot move them silently. minSdk 26 covers the Plaid Android SDK (25+) and
    // the biometric and secure-storage libraries (23+) with headroom (PLAN.md §12).
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "dev.tarnan.financetracker"
        minSdk = 26
        targetSdk = 36
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // AGP 9 turns resValue off by default; the flavors set app_name through it.
    buildFeatures {
        resValues = true
    }

    // One flavor per entry point (lib/main_<flavor>.dart). None may be named like a build
    // type (debug, profile, release): AGP refuses that. dev and prod share the application id
    // registered with Plaid; demo never touches Plaid and installs beside them.
    flavorDimensions += "flavor"
    productFlavors {
        create("dev") {
            dimension = "flavor"
            resValue("string", "app_name", "Finance Tracker Dev")
        }
        create("demo") {
            dimension = "flavor"
            applicationIdSuffix = ".demo"
            resValue("string", "app_name", "Finance Tracker Demo")
        }
        create("prod") {
            dimension = "flavor"
            resValue("string", "app_name", "Finance Tracker")
        }
    }

    signingConfigs {
        create("release") {
            if (releaseKeystore != null) {
                storeFile = file(releaseKeystore)
                storePassword = System.getenv("FT_RELEASE_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("FT_RELEASE_KEY_ALIAS")
                keyPassword = System.getenv("FT_RELEASE_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (releaseKeystore != null) {
                    signingConfigs.getByName("release")
                } else {
                    logger.warn(
                        "FT_RELEASE_KEYSTORE is not set: the release build is signed with the debug key.",
                    )
                    signingConfigs.getByName("debug")
                }
            // R8 shrinks and optimizes; proguard-rules.pro keeps what native code looks up
            // by name. Dart code is obfuscated separately by flutter build --obfuscate.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
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
