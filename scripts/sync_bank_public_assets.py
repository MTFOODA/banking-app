"""Download reviewed official bank logos for compiled UI assets (not launcher icons).

No AI-generated substitutes, third-party Maps keys, or runtime image URLs.
Review each downloaded logo and commit its provenance manifest with the asset.
"""
import argparse
import asyncio
import hashlib
import io
import json
import re
from pathlib import Path
from urllib.parse import urljoin
from xml.etree import ElementTree as ET

import httpx
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
MANIFEST=ROOT/'backend/app/data/bank_public_assets.json'
ASSETS=ROOT/'frontend/faisal_app/assets/banks'


def inline_svg_styles(data:bytes):
    """Flatten simple official CSS classes for flutter_svg, preserving geometry.

    This is a vector compatibility transform, not replacement bank artwork.
    Unsupported selectors fail instead of silently changing an official logo.
    """
    root=ET.fromstring(data)
    styles=[node for node in root.iter() if node.tag.split('}')[-1]=='style']
    if not styles:return data
    rules=[]
    for style in styles:
        css=re.sub(r'/\*.*?\*/','',style.text or '',flags=re.S)
        for selectors,body in re.findall(r'([^{}]+)\{([^{}]*)\}',css):
            attributes={key.strip():value.strip() for declaration in body.split(';') if ':' in declaration for key,value in [declaration.split(':',1)]}
            for selector in selectors.split(','):
                selector=selector.strip()
                if not re.fullmatch(r'\.[a-zA-Z_][a-zA-Z0-9_-]*',selector):raise ValueError('Unsupported SVG CSS selector')
                rules.append((selector[1:],attributes))
    for node in root.iter():
        classes=node.attrib.get('class','').split()
        for name,attributes in rules:
            if name in classes:node.attrib.update(attributes)
    for parent in root.iter():
        for node in list(parent):
            if node.tag.split('}')[-1]=='style':parent.remove(node)
    ET.register_namespace('','http://www.w3.org/2000/svg')
    ET.register_namespace('xlink','http://www.w3.org/1999/xlink')
    return ET.tostring(root,encoding='utf-8')


def validated_asset(data:bytes):
    if not data or len(data)>2_000_000:raise ValueError('Logo size exceeds limit')
    if b'<svg' in data[:2000]:
        xml=ET.fromstring(data)
        if xml.tag.split('}')[-1]!='svg':raise ValueError('Expected SVG')
        for node in xml.iter():
            if node.tag.split('}')[-1] in {'script','foreignObject'}:raise ValueError('Unsafe SVG element')
            for key,value in node.attrib.items():
                if key.lower().startswith('on'):raise ValueError('Unsafe SVG handler')
                if key.split('}')[-1]=='href' and not value.startswith(('#','data:image/')):raise ValueError('External SVG reference')
        return 'svg',inline_svg_styles(data)
    with Image.open(io.BytesIO(data)) as image:
        if image.width*image.height>4_000_000:raise ValueError('Logo image is too large')
        image.load()
        # Format conversion only: preserve the official image pixels/aspect ratio.
        output=io.BytesIO();image.convert('RGBA').save(output,format='PNG')
        return 'png',output.getvalue()


async def refresh(plan:dict):
    ASSETS.mkdir(parents=True,exist_ok=True);MANIFEST.parent.mkdir(parents=True,exist_ok=True)
    previous=json.loads(MANIFEST.read_text(encoding='utf-8')) if MANIFEST.exists() else {}
    semaphore=asyncio.Semaphore(5)
    async with httpx.AsyncClient(follow_redirects=True,timeout=45) as client:
        async def fetch(code,entry):
            async with semaphore:
                try:
                    assert re.fullmatch(r'[a-z][a-z0-9_]{1,31}',code)
                    url=entry['source_url']
                    if not url.startswith('https://'):raise ValueError('Only reviewed HTTPS sources')
                    response=await client.get(url);response.raise_for_status()
                    raw=response.content
                    if entry.get('embedded_svg_class'):
                        matches=re.findall(r'<svg\b.*?</svg>',response.text,re.S)
                        raw=next(item for item in matches if entry['embedded_svg_class'] in item[:300]).encode('utf-8')
                    extension,data=validated_asset(raw)
                    asset=f'assets/banks/{code}.{extension}'
                    (ROOT/'frontend/faisal_app'/asset).write_bytes(data)
                    return code,{**entry,'asset':asset,'sha256':hashlib.sha256(data).hexdigest(),'source_sha256':hashlib.sha256(raw).hexdigest(),'reviewed_at':'2026-10-29'}
                except (httpx.HTTPError,ValueError,ET.ParseError,AssertionError,OSError,StopIteration) as error:
                    print(code,type(error).__name__)
                    return code,previous.get(code)
        results=await asyncio.gather(*(fetch(code,entry) for code,entry in plan.items()))
    value={**previous, **{code:item for code,item in results if item}}
    MANIFEST.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(f'Official logo assets available: {len(value)}; no invalid response replaced a valid logo.')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--plan',type=Path,required=True,help='Reviewed code/source_url manifest; public assets only')
    args=parser.parse_args()
    asyncio.run(refresh(json.loads(args.plan.read_text(encoding='utf-8'))))
