allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val tempBuildDir = File(System.getProperty("java.io.tmpdir"), "segari_build")
rootProject.layout.buildDirectory.set(tempBuildDir)

subprojects {
    project.layout.buildDirectory.set(File(tempBuildDir, project.name))
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
