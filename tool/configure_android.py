from __future__ import annotations

from pathlib import Path
import shutil
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
ANDROID = ROOT / "android"
APP = ANDROID / "app"
PACKAGE = "com.sahand.rad"
OLD_PACKAGE = "com.sahand.rad_browser"
BRAND_LOGO = ROOT / "assets" / "branding" / "rad_logo.png"

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


def configure_branding() -> None:
    if not BRAND_LOGO.exists():
        raise SystemExit(f"Missing official RAD logo: {BRAND_LOGO}")

    main_res = APP / "src" / "main" / "res"
    drawable = main_res / "drawable"
    drawable_v21 = main_res / "drawable-v21"
    drawable_nodpi = main_res / "drawable-nodpi"
    values = main_res / "values"
    values_night = main_res / "values-night"
    for directory in (drawable, drawable_v21, drawable_nodpi, values, values_night):
        directory.mkdir(parents=True, exist_ok=True)

    shutil.copyfile(BRAND_LOGO, drawable_nodpi / "rad_logo.png")

    splash = '''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/rad_splash_background" />
    <item>
        <bitmap
            android:gravity="center"
            android:src="@drawable/rad_logo" />
    </item>
</layer-list>
'''
    (drawable / "launch_background.xml").write_text(splash, encoding="utf-8")
    (drawable_v21 / "launch_background.xml").write_text(splash, encoding="utf-8")

    colors_light = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="rad_splash_background">#FFFFFF</color>
</resources>
'''
    colors_dark = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="rad_splash_background">#0B1020</color>
</resources>
'''
    (values / "rad_colors.xml").write_text(colors_light, encoding="utf-8")
    (values_night / "rad_colors.xml").write_text(colors_dark, encoding="utf-8")


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
    application.set(f"{{{ANDROID_NS}}}icon", "@drawable/rad_logo")
    application.set(f"{{{ANDROID_NS}}}roundIcon", "@drawable/rad_logo")
    application.set(f"{{{ANDROID_NS}}}usesCleartextTraffic", "true")

    ET.indent(tree, space="    ")
    tree.write(manifest_path, encoding="utf-8", xml_declaration=True)


def validate() -> None:
    gradle = (APP / "build.gradle.kts").read_text(encoding="utf-8")
    if PACKAGE not in gradle:
        raise SystemExit("Package configuration failed")
    if (ANDROID / "key.properties").exists() and 'getByName("release")' not in gradle:
        raise SystemExit("Release signing configuration failed")
    if not (APP / "src" / "main" / "res" / "drawable-nodpi" / "rad_logo.png").exists():
        raise SystemExit("Official RAD launcher icon was not installed")


if __name__ == "__main__":
    if not ANDROID.exists():
        raise SystemExit("Run flutter create for Android before this script")
    configure_gradle()
    configure_activity()
    configure_branding()
    configure_manifest()
    validate()
    mode = "release signing" if (ANDROID / "key.properties").exists() else "debug signing"
    print(f"Android configured for {PACKAGE} ({mode})")
