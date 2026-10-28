"""Mechanically resize the generated master into platform build resources.

Does not draw/edit the logo artwork. Existing resources are archived once,
the transparent generated master is preserved, and opaque icons use white.
"""
from pathlib import Path
import hashlib
import json
import shutil
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
APP=ROOT/'frontend/faisal_app'
MASTER=APP/'assets/branding/banking_app_logo_master.png'
ARCHIVE=ROOT/'admin/branding_archive/faisal_original_20261028'


def main():
    manifest={}
    generated=[]
    with Image.open(MASTER) as source:
        master=source.convert('RGBA')
    def write(path,size,*,scale=1,transparent=False,ico=False):
        if path.is_file():
            archived=ARCHIVE/path.relative_to(APP)
            if not archived.exists():
                archived.parent.mkdir(parents=True,exist_ok=True)
                shutil.copy2(path,archived)
            manifest[str(path.relative_to(APP))]=hashlib.sha256(archived.read_bytes()).hexdigest()
        canvas=Image.new('RGBA',(size,size),(0,0,0,0) if transparent else (255,255,255,255))
        target=round(size*scale)
        logo=master.resize((target,target),Image.Resampling.LANCZOS)
        canvas.alpha_composite(logo,((size-target)//2,(size-target)//2))
        path.parent.mkdir(parents=True,exist_ok=True)
        if ico:canvas.convert('RGB').save(path,format='ICO',sizes=[(n,n) for n in [16,24,32,48,64,128,256]])
        else:(canvas if transparent else canvas.convert('RGB')).save(path,format='PNG')
        generated.append(str(path.relative_to(ROOT)))
    res=APP/'android/app/src/main/res'
    for density,size in {'mdpi':48,'hdpi':72,'xhdpi':96,'xxhdpi':144,'xxxhdpi':192}.items():
        for name in ['ic_launcher.png','ic_launcher_round.png']:write(res/f'mipmap-{density}'/name,size)
    for density,size in {'mdpi':108,'hdpi':162,'xhdpi':216,'xxhdpi':324,'xxxhdpi':432}.items():
        # Master already has generous padding; .85 stays inside adaptive safe bounds.
        write(res/f'mipmap-{density}'/'ic_launcher_foreground.png',size,scale=.85,transparent=True)
    for density,size in {'mdpi':96,'hdpi':144,'xhdpi':192,'xxhdpi':288,'xxxhdpi':384}.items():
        write(res/f'drawable-{density}'/'splash_logo.png',size)
    write(APP/'web/favicon.png',32)
    for size in (192,512):
        write(APP/f'web/icons/Icon-{size}.png',size)
        write(APP/f'web/icons/Icon-maskable-{size}.png',size,scale=.85)
    for folder in ['ios/Runner/Assets.xcassets/AppIcon.appiconset','macos/Runner/Assets.xcassets/AppIcon.appiconset']:
        for path in sorted((APP/folder).glob('*.png')):
            with Image.open(path) as old:size=old.width
            write(path,size)
    write(APP/'windows/runner/resources/app_icon.ico',256,ico=True)
    ARCHIVE.mkdir(parents=True,exist_ok=True)
    (ARCHIVE/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    (ROOT/'.tmp/banking_identity_generated.json').write_text(json.dumps(generated,indent=2),encoding='utf-8')
    print(f'Generated {len(generated)} platform resources; previous artwork archived. Master unchanged.')


if __name__=='__main__':
    main()
