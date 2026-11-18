package main

func safetyWarning() string {
	if uiArabic {
		return "تحذير: Pixlcord مشروع مستقل وغير تابع للفريق الرسمي.\n" +
			"المصادر الرسمية: موقع Pixlcord ومستودعات المشروع على GitHub.\n" +
			"أي موقع آخر ينتحل اسم Pixlcord غير موثوق.\n" +
			"إذا نزّلت نسخة من مصدر غير موثوق، أزلها فورًا، " +
			"وافحص جهازك من البرمجيات الخبيثة وغيّر كلمة مرور Discord.\n" +
			"vencordar.com"
	}
	return "Warning: Pixlcord is an independent project and is not affiliated with the upstream team.\n" +
		"Official sources: our website below and our project's GitHub repositories.\n" +
		"Any other site impersonating Pixlcord is untrusted.\n" +
		"If you downloaded a copy from an untrusted source, uninstall it immediately, " +
		"scan your device for malware and change your Discord password.\n" +
		"vencordar.com"
}
