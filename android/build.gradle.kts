allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}

rootProject.layout.buildDirectory = rootProject.layout.buildDirectory.dir("../../build").get()

subprojects {
    project.layout.buildDirectory = rootProject.layout.buildDirectory.dir(project.name).get()
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
