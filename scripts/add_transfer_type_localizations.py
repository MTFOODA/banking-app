import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]/'frontend/faisal_app/lib/l10n'
values={
 'transferTypeLabel':('Transfer type','نوع التحويل'),
 'transferOwnType':('Between my accounts','بين حساباتي'),
 'transferInternalType':('Within the same bank','داخلي — نفس البنك'),
 'transferDomesticType':('Other banks in Egypt','خارجي — بنوك أخرى داخل مصر'),
 'transferInternationalType':('International transfer','تحويل دولي'),
 'transferWalletType':('Mobile wallet','تحويل إلى محفظة'),
 'transferInstapayType':('InstaPay','تحويل إنستاباي'),
 'transferSimulationOnly':('Local simulation: your demo balance is debited. No payment is sent to a bank, wallet or InstaPay network.','محاكاة محلية: يتم الخصم من رصيدك التجريبي فقط. لا تُرسل دفعة لبنك أو محفظة أو شبكة إنستاباي.'),
 'transferSameCurrency':('Uses the source account currency. Currency conversion is not available.','بنفس عملة حساب المصدر. تحويل العملات غير متاح.'),
 'transferBankName':('Receiving bank name','اسم البنك المستلم'),
 'transferAccountOrIban':('Account number or IBAN','رقم الحساب أو الآيبان'),
 'transferCountry':('Country code (for example US or SA)','رمز الدولة مثل US أو SA'),
 'transferSwift':('SWIFT / BIC','سويفت / BIC'),
 'transferWalletNumber':('Egyptian wallet mobile number','رقم موبايل المحفظة المصرية'),
 'transferIpa':('IPA address or Egyptian mobile','عنوان IPA أو رقم موبايل مصري'),
 'transferIpaHint':('Example: fictionaluser@instapay','مثال: fictionaluser@instapay'),
 'transferDestinationInvalid':('Check the recipient, account/mobile/IPA format, bank and currency.','راجع المستفيد وصيغة الحساب أو الموبايل أو IPA وبيانات البنك والعملة.'),
 'transferProviderMissing':('This route has no configured delivery provider. No money has been debited.','لا يوجد مزوّد تحويل مهيأ لهذا المسار. لم يُخصم أي مبلغ.'),
 'transferUnavailableType':('Not configured','غير مهيأ'),
 'transferSimulationSuccess':('Transfer simulation completed','اكتملت محاكاة التحويل'),
 'transferProviderReference':('Simulation reference','مرجع المحاكاة'),
 'transferDeliveryFailure':('Delivery simulation failed. Refresh your balance and retry safely.','فشلت محاكاة التحويل. حدّث الرصيد ثم أعد المحاولة بأمان.'),
 'transferNoEligibleSource':('No eligible account for this type. Domestic, wallet and InstaPay transfers require EGP.','لا يوجد حساب مؤهل لهذا النوع. التحويل المحلي والمحفظة وإنستاباي تتطلب الجنيه المصري.'),
}
for index,lang in enumerate(('en','ar')):
    path=root/f'app_{lang}.arb';data=json.loads(path.read_text(encoding='utf-8'))
    data.update({key:value[index] for key,value in values.items()})
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Transfer type localizations:',len(values),'keys per language')
