allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Force a consistent JVM target across every module, including plugins
// like tflite_flutter that ship with mismatched Java/Kotlin settings.
// Uses plugins.withId (fires when the plugin is applied) instead of
// afterEvaluate, since evaluationDependsOn(":app") below forces early
// evaluation that breaks a plain afterEvaluate callback.
subprojects {
    // Both tflite_flutter AND tflite_flutter_custom (the internal fork
    // face_detection_tflite depends on) ship with Java hardcoded to 11
    // in their own build files. Match Kotlin down to 11 for both,
    // rather than touching compileOptions (which is finalized/locked).
    //
    // NOTE: configuring tasks.withType directly here, NOT gated behind
    // plugins.withId("org.jetbrains.kotlin.android") — that gate didn't
    // reliably fire for tflite_flutter_custom, likely because it applies
    // Kotlin under a different alias/id. tasks.withType<KotlinCompile>
    // matches the actual task class regardless of how the plugin was
    // applied, so it's more robust here.
    if (project.name != "tflite_flutter" && project.name != "tflite_flutter_custom") {
        return@subprojects
    }

    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
        }
    }
}

// camera_android_camerax's OWN compileDebugJavaWithJavac fails with "class
// file for androidx.concurrent.futures.CallbackToFutureAdapter not found"
// while attaching a @NonNull type annotation from camera-core 1.6.1's
// SurfaceRequest.class. That class isn't on this module's own resolved
// compile classpath (an AGP 9 "api jar" stub-transform gap in camera-core
// 1.6.1, not a version conflict) — adding the dependency to :app doesn't
// help because dependencies only flow app -> library, never the reverse,
// and :app's own compile never touches SurfaceRequest.class directly. Must
// be added to the project that actually compiles against camera-core.
subprojects {
    if (project.name != "camera_android_camerax") {
        return@subprojects
    }
    plugins.withId("com.android.library") {
        dependencies.add("implementation", "androidx.concurrent:concurrent-futures:1.2.0")
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}