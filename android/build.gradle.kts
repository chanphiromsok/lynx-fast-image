plugins {
  id("com.android.library")
}

android {
  javaClass.methods.firstOrNull { it.name == "setNamespace" }
    ?.invoke(this, "com.example.lynxfastimage")
  compileSdkVersion(35)

  defaultConfig {
    minSdkVersion(23)
  }
}

dependencies {
  // Match the Lynx version the consuming Expo host resolves (4.0.0).
  // `compileOnly` because the host owns the single runtime copy of Lynx.
  compileOnly("org.lynxsdk.lynx:lynx:4.0.0")
  annotationProcessor("org.lynxsdk.lynx:lynx-processor:4.0.0")
}
