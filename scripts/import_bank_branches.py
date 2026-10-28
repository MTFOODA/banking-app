"""Read the supplied workbook without modifying it; build the offline branch asset."""
import argparse
import hashlib
import json
from pathlib import Path
from urllib.parse import urlparse
from xml.etree import ElementTree as ET
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "admin/Faisal_Islamic_Bank_44_Branches.xlsx"
TARGET = ROOT / "frontend/faisal_app/assets/data/bank_branches.json"
CORRECTIONS = ROOT / "admin/branch_directory_overrides.json"
NS = {"s": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}


def extract():
    with ZipFile(SOURCE) as workbook:
        strings = []
        if "xl/sharedStrings.xml" in workbook.namelist():
            strings = ["".join(t.itertext()) for t in ET.fromstring(workbook.read("xl/sharedStrings.xml")).findall("s:si", NS)]
        sheet = ET.fromstring(workbook.read("xl/worksheets/sheet1.xml"))
        rows = []
        for row in sheet.findall(".//s:row", NS):
            cells = {}
            for cell in row.findall("s:c", NS):
                value = cell.find("s:v", NS)
                inline = cell.find("s:is", NS)
                text = value.text if value is not None else "".join(inline.itertext()) if inline is not None else ""
                if cell.get("t") == "s":
                    text = strings[int(text)]
                cells[''.join(c for c in cell.get('r') if c.isalpha())] = text
            rows.append(cells)
    assert rows[0]['E'] == 'Google Maps', "Unexpected workbook layout"
    branches = []
    for row in rows[1:]:
        if not any(row.values()):
            continue
        assert all(row.get(column) for column in 'ABCDE'), "Incomplete branch row"
        uri = urlparse(row['E'])
        assert uri.scheme == 'https' and uri.netloc == 'www.google.com' and uri.path == '/maps/search/', "Unexpected map link"
        branches.append(dict(id=row['A'], name=row['B'], governorate=row['C'], address=row['D'], maps_url=row['E']))
    assert len(branches) == 44 and len({b['id'] for b in branches}) == 44
    corrections = json.loads(CORRECTIONS.read_text(encoding='utf-8'))
    ids = {branch['id'] for branch in branches}
    assert set(corrections['branches']) <= ids and set(corrections['first_ids']) <= ids
    assert len(corrections['first_ids']) == len(set(corrections['first_ids']))
    for branch in branches:
        patch = corrections['branches'].get(branch['id'], {})
        assert set(patch) <= {'name', 'address', 'maps_url', 'maps_kind'}
        branch.update(patch)
        if branch.get('maps_kind') == 'coordinate_pin':
            from urllib.parse import parse_qs
            uri = urlparse(branch['maps_url'])
            assert uri.scheme == 'https' and uri.netloc == 'www.google.com' and uri.path == '/maps/search/'
            latitude, longitude = map(float, parse_qs(uri.query)['query'][0].split(','))
            assert -90 <= latitude <= 90 and -180 <= longitude <= 180
    first = corrections['first_ids']
    branches = [next(b for b in branches if b['id'] == key) for key in first] + [b for b in branches if b['id'] not in first]
    return {'source_workbook': SOURCE.name, 'source_sha256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
            'maps_kind': 'mixed', 'corrections_file': CORRECTIONS.name,
            'corrections_sha256': hashlib.sha256(CORRECTIONS.read_bytes()).hexdigest(),
            'pin_source': corrections['source_url'], 'branches': branches}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    result = extract()
    if args.check:
        assert json.loads(TARGET.read_text(encoding='utf-8')) == result, "Branch asset differs from source workbook"
    else:
        TARGET.parent.mkdir(parents=True, exist_ok=True)
        TARGET.write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print('Verified 44 unique branches, original source plus documented label/pin/order corrections; workbook unchanged.')
