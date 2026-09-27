// Release signing (tools/release_apk.sh): the upload keystore and its password
// come ONLY from environment variables, set by the release script from
// .tooling/secrets + the macOS Keychain. Nothing secret is in this repo.
// Without them (e.g. `flutter run --release`) release builds use debug signing;
// tools/release_apk.sh verifies the certificate, so such an APK is never published.
val azmUploadKeystore: String? = System.getenv("AZM_UPLOAD_KEYSTORE")

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "app.azm.gym"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications (java.time APIs on older Android).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "app.azm.gym"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // OWNER-ONLY "personal" flavor (tools/release_personal.sh passes
    // -PazmPersonal=true): bundles the private media copy, installs next to the
    // tester app (.personal), launcher "عزم تجريبي" / "Azm Dev". Defined ONLY
    // when asked for, so every normal build (flutter run/test/drive, iOS,
    // tools/release_apk.sh) stays flavorless and can never include media.
    if (project.hasProperty("azmPersonal")) {
        flavorDimensions += "edition"
        productFlavors {
            create("personal") {
                dimension = "edition"
                applicationIdSuffix = ".personal"
            }
        }
    }

    signingConfigs {
        if (azmUploadKeystore != null) {
            create("upload") {
                storeFile = file(azmUploadKeystore)
                storePassword = System.getenv("AZM_UPLOAD_STORE_PASSWORD")
                keyAlias = System.getenv("AZM_UPLOAD_KEY_ALIAS") ?: "azm-upload"
                keyPassword = System.getenv("AZM_UPLOAD_STORE_PASSWORD") // PKCS12: same password
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (azmUploadKeystore != null) {
                signingConfigs.getByName("upload")
            } else {
                signingConfigs.getByName("debug")
            }
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
