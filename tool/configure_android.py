from __future__ import annotations

from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
ANDROID = ROOT / "android"
APP = ANDROID / "app"
PACKAGE = "com.sahand.rad"
OLD_PACKAGE = "com.sahand.rad_browser"

ANDROID_NS = "http://schemas.android.com/apk/res/android"
TOOLS_NS = "http://schemas.android.com/tools"
ET.register_namespace("android", ANDROID_NS)
ET.register_namespace("tools", TOOLS_NS)


def replace_text(path: Path, old: str, new: str) -> None:
    if not path.exists():
        return
    text = path.read_text(encoding="utf-8")
    if old in text:
        path.write_text(text.replace(old, new), encoding="utf-8")


def configure_gradle() -> None:
    gradle = APP / "build.gradle.kts"
    if not gradle.exists():
        raise SystemExit(f"Missing {gradle}")

    text = gradle.read_text(encoding="utf-8").replace(OLD_PACKAGE, PACKAGE)
    key_properties = ANDROID / "key.properties"

    if key_properties.exists():
        imports = "import java.io.FileInputStream\nimport java.util.Properties\n\n"
        if "import java.util.Properties" not in text:
            text = imports + text

        marker = "android {"
        setup = (
            'val keystoreProperties = Properties()\n'
            'val keystorePropertiesFile = rootProject.file("key.properties")\n'
            'keystoreProperties.load(FileInputStream(keystorePropertiesFile))\n\n'
            'android {'
        )
        if "val keystoreProperties = Properties()" not in text:
            text = text.replace(marker, setup, 1)

        signing_block = '''    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

'''
        if 'create("release")' not in text:
            text = text.replace("    buildTypes {", signing_block + "    buildTypes {", 1)

        text = text.replace(
            'signingConfig = signingConfigs.getByName("debug")',
            'signingConfig = signingConfigs.getByName("release")',
        )

    gradle.write_text(text, encoding="utf-8")


def configure_activity() -> None:
    candidates = list((APP / "src" / "main" / "kotlin").rglob("MainActivity.kt"))
    for activity in candidates:
        replace_text(activity, f"package {OLD_PACKAGE}", f"package {PACKAGE}")


def configure_manifest() -> None:
    manifest_path = APP / "src" / "main" / "AndroidManifest.xml"
    if not manifest_path.exists():
        raise SystemExit(f"Missing {manifest_path}")

    tree = ET.parse(manifest_path)
    root = tree.getroot()

    existing = {
        node.get(f"{{{ANDROID_NS}}}name"): node
        for node in root.findall("uses-permission")
    }

    required = [
        "android.permission.INTERNET",
        "android.permission.ACCESS_NETWORK_STATE",
        "android.permission.CAMERA",
        "android.permission.RECORD_AUDIO",
        "android.permission.ACCESS_COARSE_LOCATION",
        "android.permission.ACCESS_FINE_LOCATION",
        "android.permission.POST_NOTIFICATIONS",
    ]
    for name in required:
        if name not in existing:
            node = ET.Element("uses-permission")
            node.set(f"{{{ANDROID_NS}}}name", name)
            root.insert(0, node)

    for name in [
        "android.permission.READ_EXTERNAL_STORAGE",
        "android.permission.WRITE_EXTERNAL_STORAGE",
        "android.permission.REQUEST_INSTALL_PACKAGES",
    ]:
        node = existing.get(name)
        if node is None:
            node = ET.Element("uses-permission")
            node.set(f"{{{ANDROID_NS}}}name", name)
            root.insert(0, node)
        node.set(f"{{{TOOLS_NS}}}node", "remove")

    application = root.find("application")
    if application is None:
        raise SystemExit("AndroidManifest.xml has no <application>")
    application.set(f"{{{ANDROID_NS}}}label", "راد")
    # A browser must still be able to open a user-requested HTTP site when
    # HTTPS-first is disabled. HTTPS-first remains enforced in app logic.
    application.set(f"{{{ANDROID_NS}}}usesCleartextTraffic", "true")

    ET.indent(tree, space="    ")
    tree.write(manifest_path, encoding="utf-8", xml_declaration=True)


def validate() -> None:
    gradle = (APP / "build.gradle.kts").read_text(encoding="utf-8")
    if PACKAGE not in gradle:
        raise SystemExit("Package configuration failed")
    if (ANDROID / "key.properties").exists() and 'getByName("release")' not in gradle:
        raise SystemExit("Release signing configuration failed")


if __name__ == "__main__":
    if not ANDROID.exists():
        raise SystemExit("Run flutter create for Android before this script")
    configure_gradle()
    configure_activity()
    configure_manifest()
    validate()
    mode = "release signing" if (ANDROID / "key.properties").exists() else "debug signing"
    print(f"Android configured for {PACKAGE} ({mode})")
