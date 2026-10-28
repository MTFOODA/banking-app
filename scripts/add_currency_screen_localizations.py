"""Extend existing English/Arabic resources without changing existing keys."""
import json
from pathlib import Path
root = Path(__file__).resolve().parents[1] / 'frontend/faisal_app/lib/l10n'
values = {
 'fxSearch': ('Search currency name or code', 'ابحث باسم العملة أو الرمز (دولار، ريال…)'),
 'fxAll': ('All', 'الكل'),
 'fxFavorites': ('Favorites', 'المفضلة'),
 'fxArabCurrencies': ('Arab currencies', 'عملات عربية'),
 'fxForeignCurrencies': ('Other currencies', 'عملات أجنبية'),
 'fxFavoriteAdd': ('Add to favorites', 'إضافة للمفضلة'),
 'fxFavoriteRemove': ('Remove from favorites', 'إزالة من المفضلة'),
 'fxEmpty': ('No matching currencies', 'لا توجد عملات مطابقة'),
 'fxEgpBase': ('Egyptian pound · EGP', 'جنيه مصري · EGP'),
 'fxDetails': ('Rate details and source', 'تفاصيل الأسعار والمصدر'),
 'fxDayChangeUnavailable': ('Daily change unavailable', 'التغير اليومي غير متاح'),
 'otpDevelopmentUnavailable': ('No local code was issued for this number. For this demo, use the card of a customer who has not enrolled yet. Already enrolled customers should sign in.', 'لم يصدر رمز تجريبي لهذا الرقم. للتجربة استخدم كارت عميل لم يسجّل بعد؛ العميل المسجّل يدخل من شاشة تسجيل الدخول.'),
}
for i, locale in enumerate(('en','ar')):
    path=root/f'app_{locale}.arb'
    data=json.loads(path.read_text(encoding='utf-8'))
    data.update({key: value[i] for key,value in values.items()})
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
