"""Check formatting only for Dart files in the implementation inventory."""
from pathlib import Path
import shutil
import subprocess

root = Path(__file__).resolve().parents[1]
files = []
for name in (root / "SECURITY_CHANGED_FILES.txt").read_text(encoding="utf-8-sig").splitlines():
    if name.endswith(".dart"):
        path = (root / name).resolve()
        if not path.is_relative_to(root) or not path.is_file():
            raise RuntimeError("Invalid source path in the implementation inventory")
        files.append(str(path))
dart = shutil.which("dart")
if not dart or not files:
    raise RuntimeError("Dart and a nonempty implementation inventory are required")
native = Path(dart).parent / "cache/dart-sdk/bin/dart.exe"
raise SystemExit(subprocess.call([str(native) if native.exists() else dart, "--suppress-analytics", "format",
    "--output=none", "--set-exit-if-changed", *files]))
