"""Copy only bank-app QA screenshots from an Android emulator/device."""
import argparse
import os
from pathlib import Path
import re
import subprocess

root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--device',default='emulator-5554')
parser.add_argument('--feature',choices=['admin_portal','card_categories','transfer_types','own_fx','public_portal'],default='admin_portal')
parser.add_argument('--date',default='2026-10-26')
args=parser.parse_args()
from datetime import date
date.fromisoformat(args.date)
adb=Path(os.environ['LOCALAPPDATA'])/'Android/Sdk/platform-tools/adb.exe'
base='/data/user/0/eg.faisalbank.faisal_app/files/qa/'+args.feature
command=[str(adb),'-s',args.device]
listing=subprocess.run(command+['shell','run-as','eg.faisalbank.faisal_app','ls',base],capture_output=True,check=True)
names=[name.strip() for name in listing.stdout.decode().splitlines() if re.fullmatch(r'[0-9]{2}_[a-z0-9_]+\.png',name.strip())]
if not names:raise RuntimeError('No bank-only QA screenshots found')
destination=root/'screenshots'/args.feature/args.date
destination.mkdir(parents=True,exist_ok=True)
for name in names:
    image=subprocess.run(command+['exec-out','run-as','eg.faisalbank.faisal_app','cat',base+'/'+name],capture_output=True,check=True).stdout
    if not image.startswith(b'\x89PNG\r\n\x1a\n'):raise RuntimeError('Invalid PNG for '+name)
    (destination/name).write_bytes(image)
print('Copied',len(names),'bank-app screenshots to',destination.relative_to(root))
