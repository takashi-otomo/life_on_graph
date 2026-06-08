plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "dev.otomo.life_on_graph"
    // Health Connect / 依存プラグイン (health, flutter_secure_storage 等) が要求する
    // AndroidX ライブラリのコンパイルに必要なため compileSdk を明示する。
    // 技術調査資料の推奨値は 34 だが、現行プラグイン群 (health 13 が依存する
    // androidx.health.connect:connect-client, flutter_secure_storage, device_info_plus)
    // が compileSdk 36 を要求するため 36 を採用する。
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "dev.otomo.life_on_graph"
        // Health Connect SDK の動作要件 (Android 8.0 / API 26 以上) を満たすため
        // minSdk を 26 に固定する (技術調査資料 §2)。
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // local_auth (#79) の BiometricPrompt は API 26/27 の互換ダイアログで
    // AppCompat テーマを要求するため appcompat を明示的に追加する。
    implementation("androidx.appcompat:appcompat:1.7.0")
}
