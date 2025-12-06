// android/app/build.gradle.kts

plugins {
    id("com.android.application")

    // 🔹 Firebase Google services plugin (module level)
    // START: FlutterFire / Firebase Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire / Firebase Configuration

    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // 👉 চাইলে এখানে তোমার নিজের package/namespace দাও
    namespace = "com.example.mess"

    // Flutter extension থেকে values নিচ্ছে (ডিফল্ট টেমপ্লেটের মত)
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: নিজের final applicationId দাও
        applicationId = "com.example.mess"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Use custom Application to install a security provider fallback
        manifestPlaceholders["applicationName"] = "com.example.mess.MainApplication"
    }

    buildTypes {
        release {
            // TODO: পরে নিজের release keystore দিয়ে সাইন করবে
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    // Flutter project root
    source = "../.."
}

dependencies {
    // Kotlin stdlib (optional, template-style)
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.25")
    // Security provider installer and fallback for devices without Play Services
    implementation("com.google.android.gms:play-services-base:18.5.0")
    implementation("org.conscrypt:conscrypt-android:2.5.2")

    // ⚠ Firebase ব্যবহার করলে সাধারণত FlutterFire plugins (pubspec.yaml এর প্যাকেজ)
    // অটো-মেটিকালি Android dependency নিয়ে আসে।
    // তাই এখানে আলাদা করে Firebase SDK না দিলেও চলে।
    //
    // যদি নেটিভ Firebase SDK নিজে থেকে ব্যবহার করতে চাও, তখন নিচের pattern ব্যবহার করবে:
    //
    // implementation(platform("com.google.firebase:firebase-bom:34.6.0"))
    // implementation("com.google.firebase:firebase-analytics")
    //implementation("com.google.firebase:firebase-auth")
    // implementation("com.google.firebase:firebase-firestore")
}
