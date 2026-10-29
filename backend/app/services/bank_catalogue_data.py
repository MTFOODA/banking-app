"""Reviewed public bank identities; source for server and generated offline catalogue.

Palettes are original accessible application interpretations of bank identities,
not claimed to be official design systems or evidence of network integration.
Registry baseline: CBE IPN participants, excluding CBE itself; current names are
cross-checked against official bank sites. Standard Chartered and onebank are
included from their official Egypt sites. Review date: 2026-10-28.
"""
from __future__ import annotations

import hashlib
import json

# code, English name, Arabic name, official website, identity primary/accent.
BANK_ROWS = [
    ("nbe", "National Bank of Egypt", "البنك الأهلي المصري", "https://www.nbe.com.eg/", "#006B4F", "#F58220"),
    ("banque_misr", "Banque Misr", "بنك مصر", "https://www.banquemisr.com/", "#871E35", "#C4A76A"),
    ("cib", "Commercial International Bank (CIB)", "البنك التجاري الدولي CIB", "https://www.cibeg.com/en", "#003B71", "#F58220"),
    ("faisal", "Faisal Islamic Bank of Egypt", "بنك فيصل الإسلامي المصري", "https://www.faisalbank.com.eg/", "#075C46", "#C8A44D"),
    ("qnb", "QNB Egypt", "بنك QNB مصر", "https://www.qnb.com.eg/", "#6E0F44", "#003DA6"),
    ("aaib", "Arab African International Bank", "البنك العربي الأفريقي الدولي", "https://www.aaib.com/", "#006A52", "#CF5F2E"),
    ("arab_bank", "Arab Bank", "البنك العربي", "https://www.arabbank.com.eg/", "#D71920", "#565656"),
    ("banque_caire", "Banque du Caire", "بنك القاهرة", "https://www.bdc.com.eg/", "#E55226", "#003A70"),
    ("alexbank", "ALEXBANK", "بنك الإسكندرية", "https://www.alexbank.com/", "#E4541B", "#0A5A37"),
    ("egbank", "EGBANK", "البنك المصري الخليجي", "https://www.eg-bank.com/", "#E44B35", "#112B4D"),
    ("saib", "saib", "بنك saib", "https://www.saib.com.eg/", "#005BAA", "#ED7D23"),
    ("ebank", "Export Development Bank of Egypt", "البنك المصري لتنمية الصادرات", "https://www.ebank.com.eg/", "#70245B", "#F5A623"),
    ("aib", "Arab International Bank", "المصرف العربي الدولي", "https://www.aib.com.eg/", "#043B6B", "#B5985A"),
    ("albaraka", "Al Baraka Bank Egypt", "بنك البركة مصر", "https://www.albaraka.com.eg/", "#006B4D", "#C8A45A"),
    ("attijariwafa", "Attijariwafa bank Egypt", "التجاري وفا بنك إيجيبت", "https://www.attijariwafabank.com.eg/", "#E9561A", "#7C1A35"),
    ("adib", "Abu Dhabi Islamic Bank Egypt", "مصرف أبوظبي الإسلامي مصر", "https://www.adib.eg/", "#005B46", "#C7AF76"),
    ("abk", "Al Ahli Bank of Kuwait Egypt", "البنك الأهلي الكويتي مصر", "https://www.abkegypt.com/", "#254A78", "#C69D54"),
    ("hdb", "Housing and Development Bank", "بنك التعمير والإسكان", "https://www.hdb-egy.com/", "#005B99", "#F28C28"),
    ("nbk", "National Bank of Kuwait Egypt", "بنك الكويت الوطني مصر", "https://www.nbk.com/egypt", "#003A70", "#C8102E"),
    ("ealbank", "Egyptian Arab Land Bank", "البنك العقاري المصري العربي", "https://www.eal-bank.com/", "#1F3E70", "#C1272D"),
    ("suez_canal", "Suez Canal Bank", "بنك قناة السويس", "https://scbank.com.eg/", "#0075A9", "#0A977B"),
    ("kfh", "Kuwait Finance House Egypt", "بيت التمويل الكويتي مصر", "https://www.eg.kfh.com/en/", "#006A52", "#B19A55"),
    ("united_bank", "The United Bank", "المصرف المتحد", "https://www.theubeg.com/", "#2C326E", "#A08755"),
    ("hsbc", "HSBC Egypt", "بنك HSBC مصر", "https://www.hsbc.com.eg/", "#DB0011", "#333333"),
    ("adcb", "Abu Dhabi Commercial Bank Egypt", "بنك أبوظبي التجاري مصر", "https://www.adcb.com.eg/", "#C41632", "#1A2D50"),
    ("fab", "First Abu Dhabi Bank Misr", "بنك أبوظبي الأول مصر", "https://www.fabmisr.com.eg/", "#003DA6", "#009CD9"),
    ("citi", "Citibank Egypt", "سيتي بنك مصر", "https://www.citibank.com/icg/sa/emea/egypt/", "#004B76", "#E31B54"),
    ("credit_agricole", "Crédit Agricole Egypt", "بنك كريدي أجريكول مصر", "https://www.ca-egypt.com/", "#006E53", "#8DBE28"),
    ("mashreq", "Mashreq Egypt", "بنك المشرق مصر", "https://www.mashreq.com/en/egypt/", "#ED6B23", "#163A5F"),
    ("emirates_nbd", "Emirates NBD Egypt", "بنك الإمارات دبي الوطني مصر", "https://www.emiratesnbd.com.eg/", "#062C57", "#F6A11A"),
    ("bank_nxt", "BANK NXT", "بنك نكست", "https://www.banknxteg.com/", "#162645", "#00AC69"),
    ("abc", "Bank ABC Egypt", "بنك ABC مصر", "https://www.bank-abc.com/en/CountrySites/Egypt", "#00675B", "#16B8A6"),
    ("midbank", "MIDBANK", "ميد بنك", "https://www.midbank.com.eg/", "#682D85", "#F7951D"),
    ("idb", "Industrial Development Bank", "بنك التنمية الصناعية", "https://www.idb.com.eg/", "#00745F", "#1B75BC"),
    ("agricultural", "Agricultural Bank of Egypt", "البنك الزراعي المصري", "https://www.abe.com.eg/", "#337C41", "#C1A65B"),
    ("standard_chartered", "Standard Chartered Egypt", "ستاندرد تشارترد مصر", "https://www.sc.com/eg/", "#0072AA", "#38D200"),
    ("onebank", "onebank", "وان بنك", "https://www.onebank.eg/", "#005EA7", "#28C2E4"),
]


def mix(color: str, target: str, amount: float) -> str:
    return "#" + "".join(f"{round(int(color[i:i+2],16)*(1-amount)+int(target[i:i+2],16)*amount):02X}" for i in (1,3,5))


def luminance(color):
    values=[int(color[i:i+2],16)/255 for i in (1,3,5)]
    return sum((v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4)*w for v,w in zip(values,(.2126,.7152,.0722)))


def ratio(a,b):
    x,y=sorted((luminance(a),luminance(b)))
    return (y+.05)/(x+.05)


def readable(color, backgrounds, *, light):
    current=color
    for _ in range(60):
        if all(ratio(current,bg)>=4.5 for bg in backgrounds):return current
        current=mix(current,"#FFFFFF" if light else "#000000",.08)
    return "#FFFFFF" if light else "#000000"


def palette(primary,accent,*,dark):
    background=mix(primary,"#000000",.91) if dark else mix(primary,"#FFFFFF",.97)
    surface=mix(primary,"#000000",.86) if dark else "#FFFFFF"
    card=mix(primary,"#000000",.80) if dark else mix(primary,"#FFFFFF",.995)
    backgrounds=[background,surface,card]
    readable_primary=readable(primary,backgrounds,light=dark)
    error=readable("#F0737A" if dark else "#B42332",backgrounds,light=dark)
    return dict(primary=readable_primary,secondary=accent,accent=accent,
        background=background,surface=surface,card=card,
        text_primary=readable("#F3F6F7" if dark else "#17232B",backgrounds,light=dark),
        text_secondary=readable("#B7C2CA" if dark else "#52616D",backgrounds,light=dark),
        error=error,button_background=readable_primary,
        button_text="#FFFFFF" if ratio(readable_primary,"#FFFFFF")>=4.5 else "#000000",
        border=mix(primary,"#FFFFFF" if not dark else "#000000",.83 if not dark else .45))


def catalogue():
    from app.services.bank_public_identity import IDENTITIES
    from pathlib import Path
    manifest_path=Path(__file__).resolve().parents[1]/'data'/'bank_public_assets.json'
    assets=json.loads(manifest_path.read_text(encoding='utf-8')) if manifest_path.is_file() else {}
    banks=[]
    for code,en,ar,url,primary,accent in BANK_ROWS:
        localized,abbreviation=IDENTITIES[code]
        banks.append(dict(code=code,name_en=en,name_ar=localized,abbreviation=abbreviation,
            logo_asset=assets.get(code,{}).get('asset'),website=url,source_url=url,
            identity_primary=primary,identity_accent=accent,
            light=palette(primary,accent,dark=False),dark=palette(primary,accent,dark=True),
            # Corporate-only local operations remain available for appearance preview.
            registration_enabled=code not in {"citi","standard_chartered"}))
    version=hashlib.sha256(json.dumps(banks,sort_keys=True).encode()).hexdigest()[:16]
    return dict(version=version,reviewed_at="2026-10-28",banks=banks,
        sources=["https://www.cbe.org.eg/en/payment-systems-and-services/instant-payment-network",
                 "https://www.onebank.eg/pages/news.php", "https://www.sc.com/eg/"],
        simulation=True)
