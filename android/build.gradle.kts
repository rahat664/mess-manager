// android/build.gradle.kts

import org.gradle.api.file.Directory

// 🔹 Plugin versions are resolved in settings.gradle.kts (from Flutter/FlutterFire).
// Keeping this block empty avoids duplicate version declarations.
plugins {}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ---- Flutter custom build dir setup (your existing code) ----
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
