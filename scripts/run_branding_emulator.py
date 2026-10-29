"""Opt-in Android emulator QA; private credentials are never build flags or output.
Start backend/serve_branding_qa.py first and install a debug app on emulator-5554.
"""
import json,os,subprocess,sys,shutil,argparse
from pathlib import Path
from urllib.request import urlopen
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--flow',choices=['branding','entry'],default='entry')
args=parser.parse_args()
root=Path(__file__).resolve().parents[1]
with urlopen('http://127.0.0.1:8017/health',timeout=10) as response:assert response.status==200
sdk=Path(os.environ.get('ANDROID_SDK_ROOT') or os.environ.get('ANDROID_HOME') or str(Path(os.environ['LOCALAPPDATA'])/'Android/Sdk'))
adb=str(sdk/'platform-tools/adb.exe')
flutter=shutil.which('flutter')
if flutter is None:raise RuntimeError('Add the Flutter SDK bin directory to PATH')
private=json.loads((root/'.tmp/banking_qa_credentials.local.json').read_text())
base=[adb,'-s','emulator-5554','shell','run-as','eg.faisalbank.faisal_app']
subprocess.run(base+['mkdir','-p','files/qa'],capture_output=True,check=True,timeout=20)
result=subprocess.run(base+['tee','files/qa/branding_login.json'],input=json.dumps(private).encode(),capture_output=True,timeout=20)
assert result.returncode==0,'Private staging failed'
out=root/('screenshots/bank_entry/2026-10-29' if args.flow=='entry' else 'screenshots/banking_app/2026-10-28');out.mkdir(parents=True,exist_ok=True)
command=['cmd','/d','/c',flutter,'--suppress-analytics','--no-version-check','test',('integration_test/bank_entry_registration_test.dart' if args.flow=='entry' else 'integration_test/branding_emulator_test.dart'),
 '-d','emulator-5554','--no-pub','--reporter','expanded','--no-enable-impeller','--dart-define=RUN_BRANDING_QA=true','--dart-define=API_BASE_URL=http://10.0.2.2:8017/api/v1']
with (root/('.tmp/bank_entry_emulator_test.log' if args.flow=='entry' else '.tmp/branding_emulator.log')).open('w',encoding='utf-8') as log:
 process=subprocess.Popen(command,cwd=root/'frontend/faisal_app',stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf-8',errors='replace')
 for line in process.stdout:
  log.write(line);log.flush()
  marker='ENTRY_SCREENSHOT: ' if args.flow=='entry' else 'BRANDING_SCREENSHOT: '
  if marker in line:
   name=line.split(marker,1)[1].strip()
   assert name in ({'01_intro','02_bank_login','03_create_username','04_registered_home','05_misr_branches','06_arabic_bank_home'} if args.flow=='entry' else {'01_saved_draft_en','02_published_en','03_ar_dark','04_registration','05_nbe_home','06_cib_home','07_banque_misr_home','08_fixed_login','09_nbe_dark_ar'})
   screenshot=subprocess.run([adb,'-s','emulator-5554','exec-out','screencap','-p'],capture_output=True,check=True,timeout=20).stdout
   (out/(name+'.png')).write_bytes(screenshot)
 code=process.wait()
print(args.flow+' emulator result:',code)
print('Screenshots:',len(list(out.glob('*.png'))))
sys.exit(code)
