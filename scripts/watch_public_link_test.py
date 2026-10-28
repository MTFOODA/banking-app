"""Observe four external handlers during the public-portal emulator test and return to the bank app."""
import json,os,re,subprocess,time
from pathlib import Path
root=Path(__file__).resolve().parents[1]
log=root/'.tmp/public_portal_emulator.log'
adb=[str(Path(os.environ['LOCALAPPDATA'])/'Android/Sdk/platform-tools/adb.exe'),'-s','emulator-5554']
results=[];seen=set();deadline=time.monotonic()+600
while len(results)<4 and time.monotonic()<deadline:
    if log.exists():
        raw=log.read_bytes();text=raw.decode('utf-16',errors='ignore') if raw.startswith(b'\xff\xfe') else raw.decode('utf-8',errors='ignore')
        for match in re.finditer(r'PUBLIC_EXTERNAL_READY: ([1-4]) (opened|unavailable)',text):
            index=int(match[1])
            if index in seen:continue
            seen.add(index);time.sleep(2)
            state=subprocess.run(adb+['shell','dumpsys','activity','activities'],capture_output=True,text=True,check=True).stdout
            resumed=next((line.strip() for line in state.splitlines() if 'topResumedActivity=' in line),'')
            foreground=re.search(r' ([a-zA-Z0-9_.]+)/(?:[a-zA-Z0-9_.$]+)',resumed)
            package=foreground[1] if foreground else 'unknown'
            results.append({'action':index,'launch':match[2],'foreground_package':package,'external_foreground':package not in {'unknown','eg.faisalbank.faisal_app'}})
            subprocess.run(adb+['shell','am','start','-n','eg.faisalbank.faisal_app/.MainActivity'],capture_output=True,check=True)
            (root/'.tmp/public_portal_external_result.json').write_text(json.dumps(results,indent=2))
    time.sleep(.25)
assert len(results)==4 and all(r['launch']=='opened' and r['external_foreground'] for r in results), 'External handler observation incomplete; inspect QA result.'
print('Four native maps/browser/dialer launches observed; no call was placed; banking app restored.')
