# نشر الـ backend على Koyeb (مجاني للأبد، بدون فيزا)

الهدف: تشغيل `backend/main.py` على خادم دائم بحيث تعمل الأغاني الكاملة من أي مكان بدون فتح اللابتوب.

## لماذا Koyeb
- مجاني بشكل دائم (free instance: 512MB رام / 0.1 vCPU / 2GB تخزين) — بدون بطاقة عادةً.
- يدعم Dockerfile مباشرة، ويبقى الـ `/stream` شغالًا لأن الروابط تُوقّع بـ IP الخادم نفسه.
- التحذير الوحيد: الخادم يدخل نومًا بعد ساعة بدون طلبات، ويصحى تلقائيًا خلال 1-5 ثواني. الحل في خطوة 6.

## الخطوات

1. **أنشئ مستودع GitHub** فيه ملفات الـ backend فقط:
   ```
   main.py
   requirements.txt
   Dockerfile
   ```
   (انسخهم من `backend/` — لا ترفع الـ logs.)

2. **سجّل في https://app.koyeb.com/auth/signup** — بدون بطاقة.

3. من لوحة التحكم: **Create Web Service** ← اختر **GitHub** ← اختر المستودع.

4. Region: **Frankfurt** أو **Washington D.C.** — Instance: **Free** (Nano/0.1 vCPU).
   *انتبه: الـ instance المجاني لا يقبل غير منطقة واحدة والخدمة تُسحب إن اخترت غير ذلك.*

5. اضغط **Deploy**. بعد ما تخلص، انسخ الرابط:
   ```
   https://<app-name>-<org>.koyeb.app
   ```
   تأكد أنه يعمل: افتح `https://<app-name>-<org>.koyeb.app/health` يجب أن يرجع `{"status":"ok"}`.

6. **إبقاء الخادم مستيقظًا (اختياري لكن مفيد):**
   - أنشئ Monitor في **UptimeRobot** (مجاني) على `/health` كل 5 دقائق — هذا يمنع النوم نهائيًا.

## الربط مع التطبيق

غيّر رابط الـ resolver عند البناء فقط (الكود لا يتغير):

```bash
flutter build apk --release --dart-define=RESOLVER_URL=https://<app-name>-<org>.koyeb.app
```

- الـ default في الكود يبقى رابط ngrok المحلي — فـ builds محلية تعمل كما هي بدون الـ define.
- هيدر `ngrok-skip-browser-warning` لا يضر أي host آخر.

## الرجوع للعمل المحلي (للتطوير)
شغّل `start-backend-tunnel.bat` كالمعتاد — الجهاز المحلي يظل صالحًا.

## ملاحظة صادقة
استضافة سحابية = IP سيرفر، وYouTube يتعامل بحذر مع IP السيرفرات أحيانًا؛ قد يفشل البحث (resolve) من وقت لآخر. لو حصل، التشغيل من `start-backend-tunnel.bat` (IP منزلي) يظل بديلًا موثوقًا. الخيار الوحيد المجاني 100% والموثوق دائمًا لـ YouTube هو جهاز منزلي شغال 24/7.
