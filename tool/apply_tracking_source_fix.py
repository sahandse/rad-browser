from pathlib import Path

path = Path("lib/features/browser/presentation/pages/browser_page.dart")
text = path.read_text(encoding="utf-8")

old_header = """  List<ContentBlocker> _contentBlockers(AppSettings settings) {\n    final blockers = <ContentBlocker>[];\n"""
new_header = """  List<ContentBlocker> _contentBlockers(AppSettings settings) {\n    final blockers = <ContentBlocker>[];\n    final exceptionTopUrls = <String>[];\n    for (final host in TrackingExceptionRegistry.hosts) {\n      final escaped = RegExp.escape(host);\n      exceptionTopUrls.add(\n        '^https?://(?:[^/]+\\\\.)?$escaped(?:/.*)?\\$',\n      );\n    }\n"""

old_trigger = """        ContentBlocker(\n          trigger: ContentBlockerTrigger(urlFilter: filter),\n          action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),\n        ),\n"""
new_trigger = """        ContentBlocker(\n          trigger: ContentBlockerTrigger(\n            urlFilter: filter,\n            unlessTopUrl: exceptionTopUrls,\n          ),\n          action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),\n        ),\n"""

if old_header not in text:
    if "final exceptionTopUrls = <String>[];" in text:
        print("Tracking source header already patched")
    else:
        raise SystemExit("Could not find _contentBlockers header")
else:
    text = text.replace(old_header, new_header, 1)

if old_trigger not in text:
    if "unlessTopUrl: exceptionTopUrls" in text:
        print("Tracking ContentBlocker already patched")
    else:
        raise SystemExit("Could not find tracker ContentBlocker trigger")
else:
    text = text.replace(old_trigger, new_trigger, 1)

path.write_text(text, encoding="utf-8")
print("Applied per-site tracking exception source fix")
