from __future__ import annotations

from pathlib import Path
import re
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
    replace_text(gradle, OLD_PACKAGE, PACKAGE)


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
    root.set("xmlns:tools", TOOLS_NS)

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
    application.set(f"{{{ANDROID_NS}}}usesCleartextTraffic", "false")

    ET.indent(tree, space="    ")
    tree.write(manifest_path, encoding="utf-8", xml_declaration=True)


def validate() -> None:
    gradle = (APP / "build.gradle.kts").read_text(encoding="utf-8")
    if PACKAGE not in gradle:
        raise SystemExit("Package configuration failed")
    manifest = (APP / "src" / "main" / "AndroidManifest.xml").read_text(
        encoding="utf-8"
    )
    if "REQUEST_INSTALL_PACKAGES" in manifest and 'tools:node="remove"' not in manifest:
        raise SystemExit("REQUEST_INSTALL_PACKAGES must not be requested")


if __name__ == "__main__":
    if not ANDROID.exists():
        raise SystemExit("Run flutter create for Android before this script")
    configure_gradle()
    configure_activity()
    configure_manifest()
    validate()
    print(f"Android configured for {PACKAGE}")
