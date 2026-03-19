plugins {
    // Change 8.1.0 to 8.11.1 as requested by your error log
    id("com.android.application") version "8.11.1" apply false
    
    // Change 1.9.22 to 2.2.20 as requested by your error log
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    
    // Keep the Firebase plugin
    id("com.google.gms.google-services") version "4.4.2" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
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
