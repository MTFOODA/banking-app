import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]/'frontend/faisal_app/lib/l10n'
values={
 'ownFxAvailable':('Currency conversion is available only between your own accounts.','تحويل العملة متاح بين حساباتك أنت فقط.'),
 'ownFxRate':('Exchange rate','سعر الصرف'),
 'ownFxReceived':('Amount received','المبلغ الذي سيصل'),
 'ownFxAsOf':('Market data as of','تاريخ بيانات السوق'),
 'ownFxExpires':('Quote valid until','السعر صالح حتى'),
 'ownFxSimulation':('Simulated exchange using indicative buy/sell prices and their spread, which may be delayed. This is not a real bank dealing quote.','تحويل تجريبي بأسعار شراء وبيع استرشادية وهامشها، وقد تكون متأخرة. هذا ليس سعر تنفيذ بنكي حقيقي.'),
 'ownFxExpired':('The exchange quote expired or was already used. Edit the transfer, review a new quote and authorize again.','انتهت صلاحية سعر التحويل أو تم استخدامه. عدّل التحويل وراجع سعرًا جديدًا ثم أعد التفويض.'),
 'ownFxInvalid':('Obtain a new quote for the same customer, accounts and amount before authorizing.','راجع سعرًا جديدًا لنفس العميل والحسابات والمبلغ قبل التفويض.'),
 'ownFxAmountInvalid':('The amount received is too small or exceeds the supported balance range.','المبلغ بعد التحويل أصغر من الحد الدقيق أو يتجاوز نطاق الرصيد المسموح.'),
}
for index,lang in enumerate(('en','ar')):
    path=root/f'app_{lang}.arb';data=json.loads(path.read_text(encoding='utf-8'))
    data.update({key:value[index] for key,value in values.items()})
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Own FX localization updated:',len(values),'keys per language')
