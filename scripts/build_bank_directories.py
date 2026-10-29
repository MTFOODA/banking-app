"""Compile reviewed public location snapshots. Never accesses customer databases.

Use --sources with a directory containing saved official responses. Existing
bank snapshots are retained when a source is unavailable or its parser fails.
No third-party map keys or full website scripts are included in the result.
"""
import argparse
import hashlib
import html
import json
import re
import sys
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlencode
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'backend'))
from app.services.bank_catalogue_data import catalogue

class Tables(HTMLParser):
    def __init__(self):
        super().__init__();self.row=None;self.cell=None;self.rows=[]
    def handle_starttag(self,tag,attrs):
        if tag=='tr':self.row=[]
        elif tag in ('td','th') and self.row is not None:self.cell=[]
    def handle_data(self,data):
        if self.cell is not None:self.cell.append(data)
    def handle_endtag(self,tag):
        if tag in ('td','th') and self.cell is not None:
            self.row.append(' '.join(' '.join(self.cell).split()));self.cell=None
        elif tag=='tr' and self.row is not None:self.rows.append(self.row);self.row=None

def tables(text):
    parser=Tables();parser.feed(text);return parser.rows

def clean(value):
    return ' '.join(html.unescape(re.sub(r'<[^>]*>',' ',str(value or ''))).split()).strip()

def json_state(text):
    match=re.search(r'<script[^>]+id="__JSS_STATE__"[^>]*>(.*?)</script>',text,re.S)
    return json.loads(match[1])

def walk(value):
    if isinstance(value,dict):
        yield value
        for child in value.values():yield from walk(child)
    elif isinstance(value,list):
        for child in value:yield from walk(child)

def record(bank,kind,name,address,governorate='',lat=None,lng=None,source_id=None):
    name,address,governorate=map(clean,(name,address,governorate))
    if not name or not address or len(name)>300 or len(address)>1500:raise ValueError('Invalid public address')
    # Banks sometimes publish rounded/placeholder/wrong-city coordinates. Use
    # the full street address rather than present an unverified precise pin.
    query=f"{bank['name_en']} {name} {address} {governorate} Egypt"
    try:
        y,x=float(lat),float(lng)
        precise=21.8<=y<=31.8 and 24.5<=x<=36.9 and abs(y-round(y))>.00001 and abs(x-round(x))>.00001
        if any(w in (name+' '+address+' '+governorate).lower() for w in ['cairo','القاهرة','القاهره','giza','الجيزة','الجيزه','zamalek','الزمالك']):
            precise=precise and 29.5<=y<=30.5 and 30.7<=x<=31.9
        if precise:query=f'{y:.7f},{x:.7f}'
    except (ValueError,TypeError):pass
    key=hashlib.sha256(f'{kind}:{name}:{address}'.encode()).hexdigest()[:16]
    return {'id':f"{bank['code']}-{key}",'name':name,'address':address,'governorate':governorate,
            'maps_url':'https://www.google.com/maps/search/?'+urlencode({'api':'1','query':query})}

def compile_bank(bank,sources,previous):
    code=bank['code'];data=dict(previous or {'bank_code':code,'branches':[],'atms':[],
        'branches_status':'unavailable','atms_status':'unavailable','source_urls':[],
        'branch_locator_url':bank['website'],'atm_locator_url':bank['website'],
        'hotline':None,'contact_url':bank['website'],'reviewed_at':None})
    folder=sources/code
    def read(name):return (folder/name).read_text(encoding='utf-8-sig')
    def put(kind,rows,source):
        if not rows:raise ValueError('Empty/unavailable source cannot replace a valid snapshot')
        data[kind]=list({row['id']:row for row in rows}.values())
        data[kind+'_status']='published';data['reviewed_at']='2026-10-29'
        data['source_urls']=list(dict.fromkeys([*data['source_urls'],source]));data['branch_locator_url' if kind=='branches' else 'atm_locator_url']=source
    if code=='faisal':
        # Preserve the user's original 44-branch directory/order and Giza pin.
        original=json.loads((ROOT/'frontend/faisal_app/assets/data/bank_branches.json').read_text(encoding='utf-8'))
        put('branches',original['branches'],'https://www.faisalbank.com.eg/ar/Branches')
        rows=json.loads(read('locator2.html'))['Items']
        put('atms',[record(bank,'atms',x['AtmName'],x['Address'],x['Governorate'],x['Latitude'],x['Longitude']) for x in rows if x.get('Address')],
            'https://www.faisalbank.com.eg/api/sitecore/AtmBranches/GetATMListJson')
    elif code=='nbe':
        rows=json.loads(read('verified_branches.json'))
        put('branches',[record(bank,'branches',x['name'],x['address'],x['governorate']) for x in rows],
            'https://www.nbe.com.eg/AssetsManager/99eef9a2-d128-477e-892b-a3c57561bda3.pdf')
        data['branches_status']='partial' # Official accessibility subset, not the entire network.
    elif code=='bank_nxt':
        for kind,file in [('branches','locator0.html'),('atms','locator1.html')]:
            rows=[row for row in tables(read(file)) if len(row)>=3 and row[0] not in ['أسم الفرع','اسم الفرع']]
            put(kind,[record(bank,kind,row[0],row[1],row[-1]) for row in rows],f'https://www.banknxteg.com/locations/{kind}/')
    elif code=='mashreq':
        rows=[x for x in walk(json_state(read('locator0.html'))) if 'branchid' in x and x.get('addresstext')]
        for kind,t in [('branches','Branch'),('atms','ATM')]:
            put(kind,[record(bank,kind,x['branchatmtitletext'],x['addresstext'],x.get('locationtext'),x.get('latitude'),x.get('longitute')) for x in rows if x.get('atmbranch')==t],
                'https://www.mashreq.com/en/egypt/personal/locators/')
    elif code=='fab':
        rows=[x for x in walk(json_state(read('locator0.html'))) if 'latitude' in x and 'address' in x]
        for kind,type_name in [('branches','Branches'),('atms','ATMs')]:
            chosen=[x for x in rows if any(s.get('name')==type_name for s in x.get('branchServices',[])) and not x.get('isClosedTemporarily',{}).get('value')]
            put(kind,[record(bank,kind,x['title']['value'],x['address']['value'],x.get('location',{}).get('displayName'),x['latitude']['value'],x['longitude']['value']) for x in chosen if x['address']['value']],
                'https://www.fabmisr.com.eg/en/about-fabmisr/branch-locator')
    elif code=='aib':
        rows=json.loads(read('aib_branches_ar.html'))
        put('branches',[record(bank,'branches',x['title'],x['street'],x.get('city'),x.get('lat'),x.get('lng')) for x in rows],
            'https://www.aib.com.eg/src/json/arbranches.json')
    elif code=='adib':
        text=read('locator0.html');tag=re.search(r'<input[^>]*MapTest_4\$txtname[^>]*>',text)[0]
        value=html.unescape(re.search(r'value="([^"]*)"',tag)[1]);rows=[]
        for item in value.split('*'):
            cols=item.split(',')
            if len(cols)>=8:
                # First three columns and last four flags delimit an address
                # that may itself contain commas.
                rows.append((cols[0],','.join(cols[3:-4]),cols[1],cols[2],cols[-4:]))
        for kind,flag in [('branches',1),('atms',3)]:
            put(kind,[record(bank,kind,n,a,'',y,x) for n,a,x,y,f in rows if f[flag].lower()=='true'],
                'https://www.adib.eg/ATMsandBranches')
    elif code=='banque_caire':
        text=read('locator0.html');start=text.index('[',text.index('var allLocations'))
        rows=json.JSONDecoder().raw_decode(text[start:])[0]
        # This official page lists ATMs only. Do not infer a branch from a
        # colocated machine or use rounded CMS coordinates as precise pins.
        put('atms',[record(bank,'atms',x['adrs1'],x['adrs2'],x.get('gov')) for x in rows if x.get('adrs2')],
            'https://www.bdc.com.eg/bdcwebsite/find-atm.html')
    elif code=='credit_agricole':
        rows=json.loads(read('ca_atms.html'))
        for kind in ('branches','atms'):
            keyword='branch' if kind=='branches' else 'atm'
            selected=[x for x in rows if keyword in str(x.get('terms','')).lower()]
            put(kind,[record(bank,kind,x['store'],x['address']+' '+x.get('address2',''),x.get('city'),x.get('lat'),x.get('lng')) for x in selected],
                'https://www.ca-egypt.com/en/map-details/')
    elif code=='suez_canal':
        tags=re.findall(r'<article[^>]*class="location-card"[^>]*>',read('suez_locations.html'),re.S)
        rows=[dict(re.findall(r'data-([a-z]+)="([^"]*)"',tag)) for tag in tags]
        for kind,t in [('branches','Branch'),('atms','ATM')]:
            put(kind,[record(bank,kind,x['title'],x['address'],x.get('zone'),x.get('lat'),x.get('lng')) for x in rows if x.get('type')==t],
                'https://scbank.com.eg/Locator.aspx')
    elif code=='kfh':
        for kind,file in [('branches','kfh_data0.html'),('atms','kfh_data1.html')]:
            rows=[x['value'] for x in json.loads(read(file))]
            put(kind,[record(bank,kind,x.get('name',x.get('branch')),x.get('postaladdress',x.get('address'))) for x in rows],
                'https://www.eg.kfh.com/atm-branch-locator/')
        # The bank labels its second table "Offsite ATMs"; it is a subset.
        data['atms_status']='partial'
    elif code=='adcb':
        for kind,file in [('branches','adcb_branch.json'),('atms','adcb_atm.json')]:
            rows=json.loads(read(file))['data']
            put(kind,[record(bank,kind,x['title'],x['content'],'',x.get('lat'),x.get('lng')) for x in rows if clean(x.get('content')) and len(clean(x['content']))<=1500 and len(clean(x['title']))<=300],
                'https://www.adcb.com.eg/branches-atms/')
    elif code in {'banque_misr','albaraka'}:
        snapshot=json.loads(read('all_locations.json'))
        for kind in ('branches','atms'):
            rows=snapshot[kind]
            if code=='banque_misr':
                records=[record(bank,kind,x['name'],x['address'],x['governorate'],x.get('lat'),x.get('lng')) for x in rows if x.get('isBranch')==(kind=='branches') and x.get('address')]
                source='https://www.banquemisr.com/Home/ABOUT%20US/Locations?sc_lang=en'
            else:
                records=[record(bank,kind,x['NameAr'] or x['NameEn'],x['AddressAr'] or x['AddressEn'],x['governorate'],x.get('Lat'),x.get('Lang')) for x in rows if x.get('IsBranch' if kind=='branches' else 'IsAtm')]
                source='https://www.albaraka.com.eg/search-result/'
            put(kind,records,source);data[kind+'_status']=snapshot['coverage']
    locators={
        'nbe':'https://www.nbe.com.eg/NBE/E/#/EN/ATMsAndBranches',
        'cib':'https://www.cibeg.com/en/branch-and-atm-finder',
        'qnb':'https://www.qnb.com.eg/sites/qnb/qnbegypt/page/en/enatmbranches.html',
        'nbk':'https://www.nbk.com/egypt/personal/ways-to-bank/branch-network.html',
        'hsbc':'https://www.hsbc.com.eg/branch-finder/',
        'aib':'https://www.aib.com.eg/find-us',
        'credit_agricole':'https://www.ca-egypt.com/en/map-details/',
        'albaraka':'https://www.albaraka.com.eg/search-result/',
        'faisal':'https://www.faisalbank.com.eg/ar/Branches'}
    for key in ['branch_locator_url','atm_locator_url']:
        if code in locators:data[key]=locators[code]
    contacts={'faisal':'19851','adcb':'16862','adib':'19951','alexbank':'19033',
        'arab_bank':'19100','bank_nxt':'16697','banque_caire':'16990',
        'banque_misr':'19888','idb':'19320','kfh':'19072','nbk':'19336','saib':'16668',
        'qnb':'19700','ebank':'16710','hdb':'19995','cib':'19666','nbe':'19623','aaib':'19555','credit_agricole':'19191'}
    if code in contacts:data['hotline']=contacts[code]
    contact_sources={
        'cib':'https://www.cibeg.com/ar/contact-us',
        'nbe':'https://www.nbe.com.eg/NBEPlatinum/PlatinumPlus.aspx?lang=AR',
        'aaib':'https://aaib.com/pdfs/account-opening-english-booklet-individuals.pdf',
        'credit_agricole':'https://www.ca-egypt.com/en/security/?bank_segment=personal-banking',
        'qnb':'https://www.qnb.com.eg/sites/qnb/qnbegypt/page/en/enretailbanking.html',
        'ebank':'https://ebank.com.eg/',
        'hdb':'https://www.hdb-egy.com/en/'}
    if code in contacts:
        data['source_urls']=list(dict.fromkeys([*data['source_urls'],contact_sources.get(code,bank['website'])]))
        data['reviewed_at']='2026-10-29'
    data['version']=hashlib.sha256(json.dumps({k:v for k,v in data.items() if k!='version'},sort_keys=True,ensure_ascii=False).encode()).hexdigest()[:16]
    return data

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--sources',required=True,type=Path);args=parser.parse_args()
    output=ROOT/'backend/app/data/bank_directories.json';previous=json.loads(output.read_text(encoding='utf-8')) if output.exists() else {}
    result={}
    for bank in catalogue()['banks']:
        try:result[bank['code']]=compile_bank(bank,args.sources,previous.get(bank['code']))
        except (ValueError,KeyError,OSError,TypeError) as e:
            print(bank['code'],type(e).__name__)
            result[bank['code']]=previous.get(bank['code']) or compile_bank({**bank,'code':'_unavailable'},args.sources,None)
            result[bank['code']]['bank_code']=bank['code']
    text=json.dumps(result,ensure_ascii=False,indent=2)+'\n'
    pending=output.with_suffix('.pending');pending.write_text(text,encoding='utf-8');pending.replace(output)
    folder=ROOT/'frontend/faisal_app/assets/data/bank_directories'
    folder.mkdir(parents=True,exist_ok=True)
    for code,data in result.items():
        target=folder/f'{code}.json';pending=target.with_suffix('.pending')
        pending.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');pending.replace(target)
    print(json.dumps({code:{'branches':len(x['branches']),'atms':len(x['atms'])} for code,x in result.items() if x['branches'] or x['atms']},indent=2))
if __name__=='__main__':main()
