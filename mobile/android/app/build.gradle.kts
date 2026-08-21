plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so flutter run --release works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // camera_android_camerax pulls in androidx.camera:camera-core, whose
    // SurfaceRequest class carries a @NonNull TYPE_USE annotation on a
    // CallbackToFutureAdapter-typed field. javac must resolve that class to
    // attach the annotation, but nothing in the plugin's own dependency
    // chain puts it on this module's compile classpath — hence "class file
    // for androidx.concurrent.futures.CallbackToFutureAdapter not found"
    // during compileDebugJavaWithJavac. Adding it directly closes the gap.
    implementation("androidx.concurrent:concurrent-futures:1.2.0")
}

flutter {
    source = "../.."
}