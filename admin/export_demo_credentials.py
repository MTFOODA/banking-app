"""Write only known, verified fictional credentials; never reset a password."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
for directory in (ROOT / 'backend', ROOT / 'database'):
    sys.path.insert(0, str(directory))

from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session
from app.core.config import settings
from app.core.security import hash_identifier, verify_password, assess_password
from app.models.user import User
from app.models.banking import Account, Card
from app.models.content import BankingProduct
from app.models.investment import InvestmentHolding


def export_credentials(db: Session, destination: Path, *, additional_identifiers=()) -> int:
    if settings.environment not in {'development', 'test'}:
        raise RuntimeError('Local credential export is disabled in production')
    archive = destination.with_name('credentials-source.local.json')
    source = json.loads(archive.read_text(encoding='utf-8')) if archive.exists() else {'text': ''}
    old_text = destination.read_text(encoding='utf-8') if destination.exists() else ''
    source['text'] += '\n' + old_text if old_text not in source['text'] else ''
    archive.write_text(json.dumps(source, ensure_ascii=False), encoding='utf-8')
    text = source['text']
    candidates = set(re.findall(r'^(?:Password|Temporary password):\s*(.+)$', text, re.M))
    identifiers = set(re.findall(r'\b\d{6,24}\b', text))
    identifiers.update(additional_identifiers)
    from demo_banking_data import CUSTOMERS, CARDS
    from demo_common import DEMO_CARD_1, DEMO_CARD_2, DEMO_TEMP_1, DEMO_TEMP_2
    candidates.update([DEMO_TEMP_1, DEMO_TEMP_2])
    identifiers.update([DEMO_CARD_1, DEMO_CARD_2])
    for customer in CUSTOMERS:
        candidates.add(customer['password'])
    identifiers.update(card['pan'] for card in CARDS)
    # These existing integration fixtures contain fictional passwords changed
    # by earlier device runs. Export one only if its current hash verifies.
    for name in ('security_flow_test.dart', 'physical_device_flow_test.dart'):
        fixture = ROOT / 'frontend/faisal_app/integration_test' / name
        candidates.update(re.findall(r"'([^'\n]*#[^'\n]*)'", fixture.read_text(encoding='utf-8')))
    private = destination.with_name('investor_credentials.local.json')
    if private.exists():
        candidates.update(json.loads(private.read_text()).values())
    operator = destination.with_name('operator_credentials.local.json')
    if operator.exists():
        candidates.update(json.loads(operator.read_text()).values())
    candidates = {value for value in candidates if assess_password(value).valid}
    # Try the previously verified password for this exact identity first.
    # Avoid an expensive all-users/all-passwords scan on every local export.
    previous_credentials = []
    for block in re.split(r'\n\s*\n', old_text):
        fields = dict(re.findall(r'^(Username|Card|Password):\s*(.+)$', block, re.M))
        if fields.get('Password') in candidates:
            previous_credentials.append(fields)
    identifiers.update(['4000000000000901', '4000000000000910', '4000000000000911'])
    known_numbers = {hash_identifier(number): number for number in identifiers}
    users = db.scalars(select(User).order_by(User.login_type, User.enrollment_completed, User.username, User.login_identifier_masked)).all()
    accounts = db.scalars(select(Account)).all()
    cards = db.scalars(select(Card)).all()
    holdings = db.execute(select(InvestmentHolding.customer_id, BankingProduct.product_type)
        .join(BankingProduct, BankingProduct.id == InvestmentHolding.product_id)
        .where(InvestmentHolding.status == 'active')).all()
    lines = []
    for user in users:
        own_cards = [card for card in cards if card.customer_id == user.id]
        card_numbers = [known_numbers.get(card.card_number_hash, '**** ' + card.card_last4) for card in own_cards]
        if not user.enrollment_completed:
            password = 'يُنشأ أثناء التسجيل بعد OTP'
        else:
            preferred = [item['Password'] for item in previous_credentials if
                         (user.username and item.get('Username') == user.username) or
                         any(number in item.get('Card', '') for number in card_numbers)]
            ordered = list(dict.fromkeys([*preferred, *sorted(candidates)]))
            password = next((value for value in ordered if verify_password(value, user.password_hash)),
                            'غير محفوظ محليًا؛ كلمة المرور الحالية لم تتغير')
        lines += [
            'Username: ' + (user.username or 'يُختار أثناء التسجيل بعد OTP'),
            *(['Bank: ' + user.profile.bank_code] if user.profile else []),
            'Card: ' + (', '.join(card_numbers) if card_numbers else 'لا يوجد'),
            'Password: ' + password,
            'Accounts: ' + str(sum(account.customer_id == user.id for account in accounts)),
            'Certificates: ' + str(sum(owner == user.id and kind == 'certificate' for owner, kind in holdings)),
            'Funds: ' + str(sum(owner == user.id and kind == 'fund' for owner, kind in holdings)),
            '',
        ]
    lines += ['OTP: رمز عشوائي من 6 أرقام لكل طلب؛ ليس ثابتًا. يظهر أسفل شاشة إدخال OTP في بطاقة «رمز التطوير المحلي» عند تشغيل خادم التجربة. إعادة الإرسال تغيّر الرمز وتلغي السابق. لا تُرسل رسالة SMS أو بريد حقيقية حاليًا.']
    commands = destination.with_name('RUN_COMMANDS.txt')
    if commands.exists():
        lines += ['', commands.read_text(encoding='utf-8-sig')]
    temporary = destination.with_name('credentials-update.local.json')
    temporary.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    temporary.replace(destination)
    return len(users)


if __name__ == '__main__':
    engine = create_engine(settings.test_database_url)
    with Session(engine) as db:
        count = export_credentials(db, ROOT / 'admin/admin.txt')
    engine.dispose()
    print(f'Updated private credentials file for {count} identities. No credentials printed; no database changes.')
