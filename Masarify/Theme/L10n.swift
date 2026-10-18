import Foundation

enum L10n {
    enum Key: String {
        case appName, tagline, splashSubtitle
        case tabHome, tabExpenses, tabBudgets, tabReport, tabSettings, tabCategories
        case tabInsights, tabGoals, tabMore, moreSubtitle
        case voice, camera, addExpense
        case todayReport, todayReportSubtitle, total, topCategory
        case balance, balanceRemaining, spentToday, balanceNoBudget
        case recentExpenses, seeAll, emptyToday, emptyExpenses, emptyExpensesHint
        case myExpenses, myExpensesHint
        case filterAll, filterToday, filterWeek, filterMonth, filterCategory, filterAllCategories
        case budgetAlerts, manageBudget, categories, budgets, report, expenses
        case settings, settingsSubtitle, language, languageArabic, languageEnglish
        case appearance, darkTheme, darkThemeHint, about, version, currencySuffix
        case cancel, save, delete, voiceCaptureA11y, cameraCaptureA11y
        case emergency, emergencyTitle, emergencyHint, emergencyOn, emergencyOff
        case survivalPlan, daysLeft, dailyCap, payday
        case luxuryBlockTitle, luxuryBlockBody, saveAnyway, keepBlocked
        case insights, insightsSubtitle, peakTime, selfCompare
        case goals, goalsSubtitle, addGoal, goalProgress, goalCloser
        case voicePlan, voicePlanHint, applyPlan, income, savings
        case features, openBudgets
        case roundUp, roundUpTitle, roundUpHint, roundUpPiggy, roundUpExample, roundUpOnSave
        case roundUpPickGoal, roundUpNoGoal, roundUpChallenge
        case trueCost, trueCostTitle, trueCostHint, trueCostIncome, trueCostHours, trueCostGotIt
        case tripMode, tripHint, tripStart, tripEnd, tripBudget, tripCurrency, tripRate
        case tripActive, tripEmpty, tripSeparated, tripExpense
        case ghostHunter, ghostHunterTitle, ghostHunterHint, ghostHunterEmpty
        case ghostRemove, ghostKeep
        case yesterday, yesterdayReport, yesterdayReportSubtitle, emptyYesterday
        case dailySummary, dailySummaryTitle, dailySummaryHint, dailySummaryHour, dailySummaryDay
        case dailySummaryMorning, dailySummaryEvening
        case chartsTitle, chartsSubtitle, chartsWeek, chartsMonth, chartsPie, chartsBar
        case chartsEmpty, chartsMoneyDrain
        case exportTitle, exportHint, exportCSV, exportPDF, exportFailed
        case privacyTitle, privacySubtitle
        case biometricLock, biometricLockHint, biometricFaceID, biometricTouchID
        case biometricUnavailable, biometricUnlock, biometricReason, biometricEnableReason, biometricFailed
        case cloudSync, cloudSyncTitle, cloudSyncHint, cloudSyncRequiresICloud, cloudSyncRestart
        case appleAccount, appleAccountHint, appleSignedIn, appleSignOut, googleNotOnIOS
        case sendTestNotification, notificationsAllowed, notificationsDenied, openNotificationSettings
    }

    private static let table: [Key: (ar: String, en: String)] = [
        .appName: ("مصاريفي", "Masarify"),
        .tagline: ("فلوسك… بخطة أوضح.", "Your money, with a clearer plan."),
        .splashSubtitle: ("تتبّع · خطط · وفّر", "Track · Plan · Save"),
        .tabHome: ("الرئيسية", "Home"),
        .tabExpenses: ("المصروفات", "Expenses"),
        .tabBudgets: ("الميزانية", "Budgets"),
        .tabReport: ("تقرير", "Report"),
        .tabSettings: ("الإعدادات", "Settings"),
        .tabCategories: ("الفئات", "Categories"),
        .tabInsights: ("رؤى", "Insights"),
        .tabGoals: ("أهداف", "Goals"),
        .tabMore: ("المزيد", "More"),
        .moreSubtitle: ("الإعدادات والأدوات في مكان واحد.", "Settings and tools in one place."),
        .voice: ("صوت", "Voice"),
        .camera: ("كاميرا", "Camera"),
        .addExpense: ("إضافة مصروف", "Add expense"),
        .todayReport: ("تقرير اليوم", "Today"),
        .todayReportSubtitle: ("ملخص سريع لما صرفته النهاردة.", "A quick look at what you spent today."),
        .balance: ("الرصيد", "Balance"),
        .balanceRemaining: ("المتبقي من ميزانية الشهر", "Left in this month's budget"),
        .spentToday: ("صرفت النهاردة", "Spent today"),
        .balanceNoBudget: ("حدّد ميزانية شهرية عشان يظهر الرصيد هنا", "Set a monthly budget to show your balance here"),
        .total: ("الإجمالي", "Total"),
        .topCategory: ("أعلى فئة", "Top category"),
        .recentExpenses: ("آخر المصروفات", "Recent expenses"),
        .seeAll: ("عرض الكل", "See all"),
        .myExpenses: ("مصاريفي", "My expenses"),
        .myExpensesHint: ("كل مصروف بتاريخه وفئته", "Every expense with its date & category"),
        .filterAll: ("الكل", "All"),
        .filterToday: ("النهاردة", "Today"),
        .filterWeek: ("الأسبوع", "Week"),
        .filterMonth: ("الشهر", "Month"),
        .filterCategory: ("الفئة", "Category"),
        .filterAllCategories: ("كل الفئات", "All categories"),
        .emptyToday: ("لسه مفيش مصروفات النهاردة. سجّل بالصوت أو الكاميرا.", "No expenses today yet. Log with voice or camera."),
        .emptyExpenses: ("لسه مفيش مصروفات", "No expenses yet"),
        .emptyExpensesHint: ("أضف مصروف يدويًا أو استخدم الصوت والكاميرا.", "Add manually or use voice and camera."),
        .budgetAlerts: ("تنبيهات الميزانية", "Budget alerts"),
        .manageBudget: ("إدارة الميزانية", "Manage budgets"),
        .categories: ("الفئات", "Categories"),
        .budgets: ("الميزانية", "Budgets"),
        .report: ("تقرير", "Report"),
        .expenses: ("المصروفات", "Expenses"),
        .settings: ("الإعدادات", "Settings"),
        .settingsSubtitle: ("اللغة، المظهر، وعن التطبيق.", "Language, appearance, and about."),
        .language: ("اللغة", "Language"),
        .languageArabic: ("العربية", "Arabic"),
        .languageEnglish: ("English", "English"),
        .appearance: ("المظهر", "Appearance"),
        .darkTheme: ("الوضع الداكن", "Dark theme"),
        .darkThemeHint: ("خلفيات أغمق ونصوص أوضح ليلًا.", "Darker surfaces and clearer text at night."),
        .about: ("عن التطبيق", "About"),
        .version: ("الإصدار", "Version"),
        .currencySuffix: ("ج.م", "EGP"),
        .cancel: ("إلغاء", "Cancel"),
        .save: ("حفظ", "Save"),
        .delete: ("حذف", "Delete"),
        .voiceCaptureA11y: ("تسجيل بالصوت", "Voice capture"),
        .cameraCaptureA11y: ("تصوير فاتورة", "Capture receipt"),
        .emergency: ("صديق الطوارئ", "Emergency net"),
        .emergencyTitle: ("فلوس الأزمات", "Crisis money mode"),
        .emergencyHint: ("يقفل الرفاهيات ويعمل خطة نجاة لحد المرتب.", "Blocks luxuries and builds a survival plan until payday."),
        .emergencyOn: ("مفعّل", "On"),
        .emergencyOff: ("إيقاف", "Off"),
        .survivalPlan: ("خطة النجاة", "Survival plan"),
        .daysLeft: ("يوم لحد المرتب", "days to payday"),
        .dailyCap: ("الحد اليومي", "Daily cap"),
        .payday: ("يوم المرتب", "Payday"),
        .luxuryBlockTitle: ("رفاهية في وضع الطوارئ", "Luxury during emergency"),
        .luxuryBlockBody: ("البند ده رفاهيات. تقدر تلغي أو تسجّله على مسؤوليتك.", "This looks like a luxury. Cancel or save anyway."),
        .saveAnyway: ("تسجيل على مسؤوليتي", "Save anyway"),
        .keepBlocked: ("إلغاء", "Keep blocked"),
        .insights: ("رؤى ذكية", "Smart insights"),
        .insightsSubtitle: ("ساعة الصفر + قارن مع نفسك.", "Peak time + compare with yourself."),
        .peakTime: ("ساعة الصفر", "Peak spending"),
        .selfCompare: ("قارن مع نفسك", "Compare with yourself"),
        .goals: ("الهدف الكبير", "Big goal"),
        .goalsSubtitle: ("اربط كل مصروف بحلمك.", "Tie every spend to your dream."),
        .addGoal: ("هدف جديد", "New goal"),
        .goalProgress: ("التقدّم", "Progress"),
        .goalCloser: ("يقربك من هدفك", "closer to your goal"),
        .voicePlan: ("صوت → خطة", "Voice → Plan"),
        .voicePlanHint: ("قول المرتب والتقسيمات… نعمل الميزانية والمصاريف.", "Say salary and splits… we build budgets and expenses."),
        .applyPlan: ("تطبيق الخطة", "Apply plan"),
        .income: ("الدخل", "Income"),
        .savings: ("التحويش", "Savings"),
        .features: ("أدوات مصاريفي", "Masarify tools"),
        .openBudgets: ("الميزانيات", "Budgets"),
        .roundUp: ("تحدي الفكة", "Round-up challenge"),
        .roundUpTitle: ("الصدمة الخفيفة", "Soft shock save"),
        .roundUpHint: ("كل مصروف يتقرّب لأقرب ١٠ ج.م، والفرق يتحوش لهدفك من غير ما تحس.", "Each spend rounds up to the next 10 EGP — the spare quietly funds your goal."),
        .roundUpPiggy: ("الحصالة الخفية", "Hidden piggy bank"),
        .roundUpExample: ("مثال: ٢٣ ج.م → ٣٠، والـ ٧ تروح للهدف.", "Example: 23 EGP → 30, and 7 goes to your goal."),
        .roundUpOnSave: ("هيتوحّش من الفكة", "Round-up spare"),
        .roundUpPickGoal: ("الهدف المستفيد", "Goal receiving spare"),
        .roundUpNoGoal: ("اعمل هدف الأول عشان الفكة تروح لحلمك.", "Create a goal first so spare funds your dream."),
        .roundUpChallenge: ("تحدي الأيام الصعبة", "Tough-days challenge"),
        .trueCost: ("تكلفة الحقيقة", "True cost"),
        .trueCostTitle: ("فلوسك = وقت شغلك", "Your money = your work time"),
        .trueCostHint: ("مصروف كبير أو رفاهية؟ هنقولك قد إيه شغل وراه قبل ما تدفع.", "Big or luxury spend? We’ll show the work hours behind it."),
        .trueCostIncome: ("دخلك الشهري التقريبي", "Approx. monthly income"),
        .trueCostHours: ("ساعات الشغل في الشهر", "Work hours / month"),
        .trueCostGotIt: ("فاهم، كمّل", "Got it, continue"),
        .tripMode: ("وضع الرحلة", "Trip mode"),
        .tripHint: ("فصل مصاريف السفر عن ميزانية الشهر، مع تحويل العملة لو برة مصر.", "Keep trip spends off your monthly budget, with FX conversion abroad."),
        .tripStart: ("بدء رحلة", "Start trip"),
        .tripEnd: ("إنهاء الرحلة", "End trip"),
        .tripBudget: ("ميزانية الرحلة", "Trip budget"),
        .tripCurrency: ("عملة الرحلة", "Trip currency"),
        .tripRate: ("سعر التحويل للجنيه", "Rate to EGP"),
        .tripActive: ("رحلة شغّالة", "Trip active"),
        .tripEmpty: ("مفيش رحلة دلوقتي. ابدأ واحدة بميزانية لوحدها.", "No active trip. Start one with its own budget."),
        .tripSeparated: ("المصروفات دي مش هتخش في ميزانية الشهر.", "These expenses won’t hit your monthly budget."),
        .tripExpense: ("مصروف رحلة", "Trip expense"),
        .ghostHunter: ("الاشتراكات المنسية", "Ghost subscriptions"),
        .ghostHunterTitle: ("صيّاد الاشتراكات", "Subscription hunter"),
        .ghostHunterHint: ("بنراجع المدفوعات المتكررة وننبّهك لو فيه اشتراك شكله مش مستخدم.", "We scan recurring charges and flag subscriptions that look unused."),
        .ghostHunterEmpty: ("لسه مفيش اشتراكات متكررة واضحة — كمّل التسجيل شهرين وهنصطادهم.", "No clear recurring subscriptions yet — keep logging for a couple months."),
        .ghostRemove: ("اشيلها من لستتي", "Remove from my list"),
        .ghostKeep: ("سيبها", "Keep it"),
        .yesterday: ("امبارح", "Yesterday"),
        .yesterdayReport: ("تقرير امبارح", "Yesterday"),
        .yesterdayReportSubtitle: ("ملخص اللي صرفته امبارح، وأكتر بند، والمتبقي من الميزانية.", "What you spent yesterday, top category, and budget left."),
        .emptyYesterday: ("مفيش مصروفات متسجّلة لامبارح.", "No expenses logged for yesterday."),
        .dailySummary: ("الملخص اليومي", "Daily summary"),
        .dailySummaryTitle: ("إشعار ملخص اليوم", "Daily summary notification"),
        .dailySummaryHint: ("رسالة في الوقت اللي تختاره بإجمالي النهاردة أو امبارح، وأكتر بند، والمتبقي من الميزانية.", "A note at your chosen time with today or yesterday total, top category, and budget left."),
        .dailySummaryHour: ("وقت الإشعار", "Notification time"),
        .dailySummaryDay: ("ملخص أي يوم؟", "Summarize which day?"),
        .dailySummaryMorning: ("الصباح (٩)", "Morning (9)"),
        .dailySummaryEvening: ("المساء (٢١)", "Evening (21)"),
        .chartsTitle: ("رسوم وتحليلات", "Charts & analytics"),
        .chartsSubtitle: ("شوف فلوسك بتروح فين — أسبوعي وشهري.", "See where your money goes — weekly and monthly."),
        .chartsWeek: ("الأسبوع", "Week"),
        .chartsMonth: ("الشهر", "Month"),
        .chartsPie: ("دائري", "Pie"),
        .chartsBar: ("أعمدة", "Bars"),
        .chartsEmpty: ("لسه مفيش مصروفات في الفترة دي.", "No expenses in this period yet."),
        .chartsMoneyDrain: ("مصاصة الفلوس", "Biggest money drain"),
        .exportTitle: ("تصدير البيانات", "Export data"),
        .exportHint: ("صدّر كل المصاريف CSV (إكسل) أو PDF للمراجعة والاحتفاظ.", "Export all expenses as CSV (Excel) or PDF to review and keep."),
        .exportCSV: ("CSV / إكسل", "CSV / Excel"),
        .exportPDF: ("PDF", "PDF"),
        .exportFailed: ("فشل التصدير", "Export failed"),
        .privacyTitle: ("الأمان والخصوصية", "Security & privacy"),
        .privacySubtitle: ("قفل Face ID ونسخ احتياطي على iCloud.", "Face ID lock and iCloud backup."),
        .biometricLock: ("قفل التطبيق", "App lock"),
        .biometricLockHint: ("اطلب البصمة أو Face ID قبل فتح مصاريفي.", "Require Touch ID or Face ID before opening Masarify."),
        .biometricFaceID: ("Face ID", "Face ID"),
        .biometricTouchID: ("بصمة الإصبع", "Touch ID"),
        .biometricUnavailable: ("الجهاز لا يدعم البصمة / Face ID", "Biometrics unavailable on this device"),
        .biometricUnlock: ("فتح القفل", "Unlock"),
        .biometricReason: ("افتح مصاريفي لحماية بياناتك المالية", "Unlock Masarify to protect your finances"),
        .biometricEnableReason: ("أكّد هويتك لتفعيل قفل التطبيق", "Confirm your identity to enable app lock"),
        .biometricFailed: ("فشل التعرّف — حاول تاني", "Authentication failed — try again"),
        .cloudSync: ("النسخ الاحتياطي", "Cloud backup"),
        .cloudSyncTitle: ("مزامنة iCloud", "iCloud sync"),
        .cloudSyncHint: ("مصاريفك وميزانياتك تتزامن مع iCloud عشان متضيعش لو غيّرت الموبايل.", "Expenses and budgets sync via iCloud so you don’t lose them on a new phone."),
        .cloudSyncRequiresICloud: ("لازم تكون مسجّل دخول على iCloud من إعدادات الآيفون.", "Sign in to iCloud in iPhone Settings for sync to work."),
        .cloudSyncRestart: ("أعد تشغيل التطبيق لتطبيق تغيير المزامنة.", "Relaunch the app to apply the sync change."),
        .appleAccount: ("حساب Apple", "Apple Account"),
        .appleAccountHint: ("سجّل بـ Sign in with Apple لربط هويتك بالنسخ الاحتياطي.", "Sign in with Apple to link your identity to backup."),
        .appleSignedIn: ("تم تسجيل الدخول", "Signed in"),
        .appleSignOut: ("تسجيل الخروج", "Sign out"),
        .googleNotOnIOS: ("مزامنة Google مش متاحة في نسخة الآيفون — استخدم iCloud + Sign in with Apple.", "Google sync isn’t on this iOS build — use iCloud + Sign in with Apple."),
        .sendTestNotification: ("إرسال إشعار تجريبي", "Send test notification"),
        .notificationsAllowed: ("الإشعارات مسموحة لهذا التطبيق.", "Notifications are allowed for this app."),
        .notificationsDenied: ("الإشعارات مقفولة — افتح إعدادات النظام وفعّلها.", "Notifications are blocked — enable them in system Settings."),
        .openNotificationSettings: ("فتح إعدادات الإشعارات", "Open notification settings")
    ]

    static func string(_ key: Key, language: AppLanguage) -> String {
        let pair = table[key] ?? (key.rawValue, key.rawValue)
        switch language {
        case .arabic: return pair.ar
        case .english: return pair.en
        }
    }
}
