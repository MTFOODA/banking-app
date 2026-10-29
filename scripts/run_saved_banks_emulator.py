"""Opt-in saved-bank QA using fictional private fixtures and emulator finger 1.

Requires backend/serve_branding_qa.py, an installed debug package, and a real
enrolled emulator fingerprint. No passwords/tokens enter build arguments/logs.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from urllib.request import urlopen

root = Path(__file__).resolve().parents[1]
adb = str(Path(os.environ['LOCALAPPDATA']) / 'Android/Sdk/platform-tools/adb.exe')
flutter = shutil.which('flutter')
if flutter is None:
    raise RuntimeError('Add the Flutter SDK bin directory to PATH')
with urlopen('http://127.0.0.1:8017/health', timeout=10) as response:
    assert response.status == 200
private = json.loads((root / '.tmp/banking_qa_credentials.local.json').read_text())

def device(*arguments):
    return subprocess.run([adb, '-s', 'emulator-5554', *arguments],
                          capture_output=True, check=True, timeout=25).stdout

device('shell', 'run-as', 'eg.faisalbank.faisal_app', 'mkdir', '-p', 'files/qa')
subprocess.run([adb, '-s', 'emulator-5554', 'shell', 'run-as', 'eg.faisalbank.faisal_app',
                'tee', 'files/qa/branding_login.json'], input=json.dumps(private).encode(),
               capture_output=True, check=True, timeout=20)
out = root / 'screenshots/saved_banks/2026-10-29'
out.mkdir(parents=True, exist_ok=True)
names = {'01_three_saved_banks', '02_biometric_enabled', '03_cold_bootstrap_chooser',
         '04_single_fingerprint_cib_home', '05_nbe_password_switch',
         '06_arabic_dark_chooser', '07_revoked_password_fallback'}
command = ['cmd', '/d', '/c', flutter, '--suppress-analytics', '--no-version-check',
           'test', 'integration_test/saved_banks_test.dart', '-d', 'emulator-5554',
           '--no-pub', '--reporter', 'expanded', '--no-enable-impeller',
           '--dart-define=RUN_BRANDING_QA=true',
           '--dart-define=API_BASE_URL=http://10.0.2.2:8017/api/v1']
touches = []
titles = {json.loads((root / f'frontend/faisal_app/lib/l10n/app_{locale}.arb').read_text(encoding='utf-8'))['biometricReason']
          for locale in ('en', 'ar')}
with (root / '.tmp/saved_banks_emulator_test.log').open('w', encoding='utf-8') as log:
    process = subprocess.Popen(command, cwd=root / 'frontend/faisal_app',
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               text=True, encoding='utf-8', errors='replace')
    for line in process.stdout:
        log.write(line)
        log.flush()
        if 'SAVED_BIOMETRIC: ' in line:
            stage = line.split('SAVED_BIOMETRIC: ', 1)[1].strip()
            assert stage in {'enable', 'sign_in', 'revoked'} and stage not in touches
            for attempt in range(15):
                device('shell', 'uiautomator', 'dump', '/sdcard/qa_prompt.xml')
                tree = ET.fromstring(device('shell', 'cat', '/sdcard/qa_prompt.xml'))
                if any(n.get('package') == 'com.android.systemui' and
                       n.get('text') in titles
                       for n in tree.iter('node')):
                    device('emu', 'finger', 'touch', '1')
                    touches.append(stage)
                    break
                time.sleep(.5)
            else:
                process.terminate()
                raise RuntimeError('Expected native biometric prompt did not appear: ' + stage)
        if 'SAVED_SCREENSHOT: ' in line:
            name = line.split('SAVED_SCREENSHOT: ', 1)[1].strip()
            assert name in names
            (out / (name + '.png')).write_bytes(device('exec-out', 'screencap', '-p'))
    code = process.wait()
print('Saved banks emulator exit:', code)
print('Single native finger touches:', ', '.join(touches))
print('Screenshots:', len(list(out.glob('*.png'))))
sys.exit(code)
