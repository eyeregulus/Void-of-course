allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Java 17 Toolchain 및 호환성 설정 (모든 프로젝트에 강제 적용)
allprojects {
    // Java Plugin 적용 시 즉시 설정
    plugins.withType<JavaPlugin> {
        extensions.configure<JavaPluginExtension> {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
            toolchain {
                languageVersion.set(JavaLanguageVersion.of(17))
            }
        }
    }

    // afterEvaluate로 모든 태스크 강제 설정
    afterEvaluate {
        // Java 컴파일 설정 - 모든 프로젝트에 강제 적용
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = JavaVersion.VERSION_17.toString()
            targetCompatibility = JavaVersion.VERSION_17.toString()
            options.compilerArgs.addAll(listOf("-Xlint:-options"))
        }

        // Kotlin 컴파일 설정 - 모든 프로젝트에 강제 적용
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
}

// 왕께서 설정하신 빌드 디렉터리 경로 유지
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // 플러그인 소스가 다른 드라이브(C:)에 있을 때 경로 충돌 방지
    val projectRoot = project.projectDir.toPath().root?.toString() ?: ""
    val buildRoot = newBuildDir.asFile.toPath().root?.toString() ?: ""
    if (projectRoot.equals(buildRoot, ignoreCase = true)) {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
}

subprojects {
    project.evaluationDependsOn(":app")

    plugins.withId("com.android.library") {
        val androidExt =
            extensions.getByName("android") as com.android.build.gradle.LibraryExtension
        androidExt.ndkVersion = "27.0.12077973"
        androidExt.packaging {
            jniLibs.useLegacyPackaging = true
        }

        val hasNativeCMake = sequenceOf(
            project.file("CMakeLists.txt"),
            project.file("../native/CMakeLists.txt"),
            project.file("src/main/cpp/CMakeLists.txt"),
        ).any { it.exists() }
        if (hasNativeCMake) {
            val cmake = androidExt.defaultConfig.externalNativeBuild.cmake
            val args = cmake.arguments.toMutableList()
            if (!args.contains("-DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON")) {
                args.add("-DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON")
            }
            val linkerFlag = "-DCMAKE_SHARED_LINKER_FLAGS=-Wl,-z,max-page-size=16384"
            if (!args.contains(linkerFlag)) {
                args.add(linkerFlag)
            }
            cmake.arguments(*args.toTypedArray())
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}