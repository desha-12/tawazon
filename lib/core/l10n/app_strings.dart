class AppStrings {
  AppStrings(this.localeCode);

  final String localeCode;

  bool get isArabic => localeCode == 'ar';

  String get appName => 'Tawazon';
  String get tagline =>
      isArabic ? 'شرارة الذهن والتوازن الرقمي' : 'Mind Spark & Digital Balance';

  String get skip => isArabic ? 'تخطي' : 'Skip';
  String get next => isArabic ? 'التالي' : 'Next';
  String get start => isArabic ? 'ابدأ' : 'Get started';
  String get enable => isArabic ? 'تفعيل' : 'Enable';
  String get save => isArabic ? 'حفظ' : 'Save';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get english => isArabic ? 'الإنجليزية' : 'English';
  String get arabic => isArabic ? 'العربية' : 'Arabic';
  String get language => isArabic ? 'اللغة' : 'Language';

  String get onboardingDetoxTitle =>
      isArabic ? 'إزالة السموم الرقمية' : 'Digital Detox';
  String get onboardingDetoxBody => isArabic
      ? 'راقب وقت الشاشة، اقطع الضوضاء، واستعد انتباهك على مهل.'
      : 'See where your hours go, cut the noise, and take your attention back.';

  String get onboardingGardenTitle =>
      isArabic ? 'حديقة التركيز' : 'Focus Garden';
  String get onboardingGardenBody => isArabic
      ? 'ازرع شجرة أثناء جلسة التركيز. الخروج مبكراً يُذبل النبتة.'
      : 'Grow a tree through a focus sitting. Leave early, and the plant withers.';

  String get onboardingCoachTitle =>
      isArabic ? 'مساعد الذكاء الاصطناعي' : 'AI Assistant';
  String get onboardingCoachBody => isArabic
      ? 'اسأل عن أي موضوع: شرح، كتابة، ترجمة، تخطيط، أو التوازن الرقمي.'
      : 'Ask about anything: explanations, writing, translation, planning, or digital wellbeing.';

  String get prayerPrefTitle => isArabic
      ? 'هل ترغب في تفعيل مواقيت الصلاة وتنبيهات التركيز الإسلامية؟'
      : 'Would you like to enable Prayer Times & Islamic Focus Alerts?';
  String get prayerPrefBody => isArabic
      ? 'نحسب المواقيت حسب موقعك بعد إذنك. إن لم تسمح، نستخدم دمنهور افتراضياً، ونذكّرك بفترة هدوء حول كل صلاة.'
      : 'Prayer times use your location if you allow it; otherwise Damanhour is used by default, with a quiet interval around each prayer.';

  String get navHome => isArabic ? 'الرئيسية' : 'Home';
  String get navGarden => isArabic ? 'الحديقة' : 'Garden';
  String get navCoach => isArabic ? 'المساعد' : 'Assistant';
  String get navSettings => isArabic ? 'الإعدادات' : 'Settings';

  String get todayUsage => isArabic ? 'استخدام اليوم' : 'Today\'s screen time';
  String get usageAccessRequiredForAnalytics => isArabic
      ? 'إحصائيات وقت الشاشة متاحة على Android بعد تفعيل إذن بيانات الاستخدام.'
      : 'Screen-time analytics are available on Android after enabling Usage Access.';
  String get usageCategoryBreakdownUnavailable => isArabic
      ? 'يعرض التطبيق إجمالي وقت الشاشة فقط؛ تقسيم الوقت حسب التطبيقات غير متاح.'
      : 'Only total screen time is available; per-app categories are not collected.';
  String get usageDataUnavailable =>
      isArabic ? 'غير متاح' : 'Not available';
  String get startFocus => isArabic ? 'ابدأ وضع التركيز' : 'Start Focus Mode';
  String get weeklyTrend => isArabic ? 'منحنى الأسبوع' : 'Weekly trend';
  String get byCategory => isArabic ? 'حسب الفئة' : 'By category';
  String get highUsageBanner => isArabic
      ? 'الاستخدام مرتفع اليوم. كيف حالك الآن؟'
      : 'Usage is high today. How are you feeling?';
  String get biologicalTimeline =>
      isArabic ? 'إيقاع يومك' : 'Your day rhythm';
  String get phaseDawn => isArabic ? 'الشروق' : 'Dawn';
  String get phaseDay => isArabic ? 'النهار' : 'Daylight';
  String get phaseSunset => isArabic ? 'الغروب' : 'Sunset';
  String get phaseNight => isArabic ? 'الليل' : 'Night';
  String get timelineMorning =>
      isArabic ? 'تخطيط اليوم والتركيز الصباحي' : 'Plan the day and focus';
  String get timelineDay =>
      isArabic ? 'نافذة تركيز عميق' : 'Deep focus window';
  String get timelineEvening =>
      isArabic ? 'تأمل واسترخاء مسائي' : 'Reflect and unwind';
  String get focusWindow =>
      isArabic ? 'تركيز حتى الصلاة القادمة' : 'Focus until the next prayer';
  String get restWindow =>
      isArabic ? 'وقت مناسب لاستراحة هادئة' : 'A good time for a quiet break';
  String get nowLabel => isArabic ? 'الآن' : 'Now';
  String get focusCardTitle => isArabic ? 'التركيز' : 'Focus';
    String get focusInProgress => isArabic ? 'جلسة التركيز جارية' : 'Focus session in progress';
    String get focusCompleted => isArabic ? 'أحسنت، اكتملت جلستك' : 'Well done, session complete';
  String get prayerCardTitle => isArabic ? 'الصلاة القادمة' : 'Next prayer';
  String get moodCardTitle => isArabic ? 'كيف حالك؟' : 'How are you feeling?';
  String get appearanceMode =>
      isArabic ? 'مظهر الوضع الداكن' : 'Dark appearance';
  String get softDark => isArabic ? 'داكن ناعم' : 'Soft dark';
  String get trueBlack => isArabic ? 'أسود AMOLED' : 'AMOLED black';

  String get catSocial => isArabic ? 'تواصل اجتماعي' : 'Social';
  String get catEntertainment => isArabic ? 'ترفيه' : 'Entertainment';
  String get catProductivity => isArabic ? 'إنتاجية' : 'Productivity';
  String get catSystem => isArabic ? 'نظام ومتفرقات' : 'System & other';

  String get gardenTitle => isArabic ? 'حديقة التركيز' : 'Focus Garden';
  String get gardenIdle => isArabic
      ? 'الأرض بانتظار جلسة جديدة'
      : 'The soil is waiting for a new sitting';
  String get gardenGrowing => isArabic
      ? 'النبتة تنمو مع انتباهك'
      : 'The plant grows with your attention';
  String get gardenSceneDescription => isArabic
      ? 'حديقة ثلاثية الأبعاد تتغير مع نمو تركيزك'
      : 'Three-dimensional garden that grows with your focus';
  String get gardenBloom => isArabic
      ? 'اكتملت الجلسة. الحديقة أقوى اليوم.'
      : 'Session complete. The garden is stronger today.';
  String get gardenWithered => isArabic
      ? 'غادرت مبكراً. ذبلت النبتة.'
      : 'You left early. The plant withered.';
  String get minutes => isArabic ? 'دقيقة' : 'min';
  String get endEarly => isArabic ? 'إنهاء مبكر' : 'End early';
  String get streak => isArabic ? 'سلسلة الأيام' : 'Streak';
  String get withers => isArabic ? 'مرات الذبول' : 'Withers';

  String get coachTitle =>
      isArabic ? 'مساعد توازن الذكي' : 'Tawazon AI assistant';
  String get coachHint => isArabic
      ? 'اسألني عن أي شيء: شرح، كتابة، ترجمة، برمجة، أو غيره…'
      : 'Ask me anything: explain, write, translate, code, and more…';
  String get send => isArabic ? 'إرسال' : 'Send';
  String get moodCheck => isArabic ? 'تفقد المزاج' : 'Mood check-in';
  String get dailyRoutine =>
      isArabic ? 'روتين اليوم' : 'Today\'s detox routine';
  String get offlineIdeas => isArabic ? 'أنشطة بلا شاشة' : 'Offline ideas';

  String get moodCalm => isArabic ? 'هادئ' : 'Calm';
  String get moodRestless => isArabic ? 'قلق' : 'Restless';
  String get moodTired => isArabic ? 'مرهق' : 'Tired';
  String get moodScattered => isArabic ? 'مشتت' : 'Scattered';
  String get moodAnalyticsTitle =>
      isArabic ? 'تحليل المزاج الأسبوعي' : 'Weekly mood';
  String get moodAnalyticsEmpty => isArabic
      ? 'سجّل مزاجك لعرض الاتجاه الأسبوعي.'
      : 'Check in with your mood to see the weekly trend.';
  String get moodCount =>
      isArabic ? 'مرات خلال الأسبوع' : 'check-ins this week';
  String get examShield => isArabic ? 'وضع الامتحانات' : 'Exam shield';
  String get examShieldBody => isArabic
      ? 'جلسة تركيز ٥٠ دقيقة، تليها استراحة ١٠ دقائق.'
      : 'A 50-minute study block followed by a 10-minute break.';
  String get ambientSound => isArabic ? 'الصوت الخلفي' : 'Ambient sound';
  String get soundOff => isArabic ? 'إيقاف الصوت' : 'Sound off';
  String get brownNoise => isArabic ? 'ضوضاء بنية' : 'Brown noise';
  String get pinkNoise => isArabic ? 'ضوضاء وردية' : 'Pink noise';
  String get prayerSyncedPlan =>
      isArabic ? 'خطة متزامنة مع الصلاة' : 'Prayer-synced plan';
  String get prayerRestSuggestion => isArabic
      ? 'استراحة ذهنية قصيرة حول الصلاة.'
      : 'Take a short mental rest around prayer.';
  String prayerFocusSuggestion(int minutes) => isArabic
      ? 'نافذة تركيز مقترحة: $minutes دقيقة قبل الصلاة.'
      : 'Suggested focus window: $minutes minutes before prayer.';
  String get studyRest =>
      isArabic ? 'ابدأ استراحة هادئة' : 'Start a quiet break';
  String get studyBreakTen => isArabic ? 'استراحة ١٠ دقائق' : '10-minute break';
  String get studyFocus =>
      isArabic ? 'ابدأ جلسة التركيز' : 'Start focus session';
  String get gardenResting =>
      isArabic ? 'استراحة ذهنية حول الصلاة' : 'A mindful prayer break';

  String get sleepTitle => isArabic ? 'تتبع النوم' : 'Sleep tracker';
  String get sleepHours => isArabic ? 'ساعات النوم' : 'Hours slept';
  String get logSleep => isArabic ? 'تسجيل نوم الليلة' : 'Log last night';
  String get sleepHint => isArabic
      ? 'نربط ساعات نومك بوقت الشاشة في الأيام نفسها.'
      : 'We correlate hours slept with screen time on the same days.';
  String get correlation =>
      isArabic ? 'العلاقة مع الشاشة' : 'Screen correlation';

  String get studyTitle => isArabic ? 'تتبع المذاكرة' : 'Study tracker';
  String get pomodoro => isArabic ? 'بومودورو ٢٥ / ٥' : 'Pomodoro 25 / 5';
  String get studyStart =>
      isArabic ? 'ابدأ المذاكرة في الحديقة' : 'Study in the garden';
  String get studyBody => isArabic
      ? 'جلسة المذاكرة تُغذّي الحديقة نفسها. الخروج يُذبل النبتة.'
      : 'Study sittings feed the same garden. Leaving still withers the plant.';

  String get prayerTitle => isArabic ? 'مواقيت الصلاة' : 'Prayer times';
  String get prayerScheduleTitle =>
      isArabic ? 'مواقيت اليوم' : 'Today’s prayer times';
  String get prayerLocationTitle =>
      isArabic ? 'موقع حساب المواقيت' : 'Location for prayer times';
  String get prayerLocationUseDevice =>
      isArabic ? 'استخدم موقعي الحالي' : 'Use my current location';
  String get prayerLocationUsingDevice => isArabic
      ? 'تُحسب المواقيت حسب آخر موقع حفظته من جهازك.'
      : 'Times use the most recent location saved from your device.';
  String get prayerLocationUsingDefault => isArabic
      ? 'الموقع الافتراضي: دمنهور، مصر. حدّد موقعك الحالي لمواقيت أدق.'
      : 'Default location: Damanhour, Egypt. Set your current location for more accurate times.';
  String get prayerLocationPrivacy => isArabic
      ? 'يُستخدم الموقع لحساب المواقيت على جهازك ولا يُرسل للخارج.'
      : 'Your location is used on-device to calculate times and is not uploaded.';
  String get prayerLocationUpdated => isArabic
      ? 'تم تحديث مواقيت الصلاة حسب موقعك.'
      : 'Prayer times updated for your location.';
  String get prayerLocationFailed => isArabic
      ? 'تعذر تحديد موقعك. اسمح بإذن الموقع وتأكد من تشغيل خدمات الموقع.'
      : 'Could not get your location. Allow location access and turn on Location Services.';
  String get prayerAlerts =>
      isArabic ? 'تنبيهات التركيز عند الصلاة' : 'Focus alerts around prayer';
  String get phoneUsageAlertTitle =>
      isArabic ? 'تنبيه وقت استخدام الهاتف' : 'Phone usage alert';
  String get phoneUsageAlertDescription => isArabic
      ? 'إشعار مرة يوميًا عند بلوغ ٤ ساعات استخدام. يحتاج إذن الإشعارات والوصول إلى بيانات الاستخدام، ويُحسب الوقت على الجهاز.'
      : 'Get one daily alert after 4 hours of phone use. Requires notification permission and Usage Access; usage is checked on-device.';
  String get phoneUsageAlertAndroidOnly => isArabic
      ? 'تنبيه الاستخدام متاح حاليًا على Android فقط.'
      : 'Phone usage alerts are currently available on Android only.';
  String notificationPermissionStatus(bool granted) {
    final value = isArabic
        ? (granted ? 'مسموح' : 'غير مسموح')
        : (granted ? 'allowed' : 'not allowed');
    return isArabic ? 'الإشعارات: $value' : 'Notifications: $value';
  }

  String usageAccessPermissionStatus(bool granted) {
    final value = isArabic
        ? (granted ? 'مسموح' : 'غير مسموح')
        : (granted ? 'allowed' : 'not allowed');
    return isArabic ? 'بيانات الاستخدام: $value' : 'Usage Access: $value';
  }
  String get phoneUsageAlertNotificationDenied => isArabic
      ? 'يلزم السماح بالإشعارات لتفعيل التنبيه.'
      : 'Allow notifications to enable this alert.';
  String get openAppSettings =>
      isArabic ? 'فتح الإعدادات' : 'Open settings';
  String get phoneUsageAlertOpenUsageSettings => isArabic
      ? 'فعّل Tawazon من شاشة «الوصول إلى بيانات الاستخدام»، ثم ارجع إلى التطبيق.'
      : 'Enable Tawazon on the Usage Access screen, then return to the app.';
  String get phoneUsageAlertEnabled => isArabic
      ? 'تم تفعيل التنبيه اليومي بعد ٤ ساعات استخدام.'
      : 'Daily alert enabled for 4 hours of phone use.';
  String get phoneUsageAlertPermissionError => isArabic
      ? 'لم يكتمل تفعيل التنبيه. تحقق من الصلاحيتين وحاول مجددًا.'
      : 'The alert could not be enabled. Check both permissions and try again.';
  String get nextPrayer => isArabic ? 'الصلاة القادمة' : 'Next prayer';
  String get fajr => isArabic ? 'الفجر' : 'Fajr';
  String get sunrise => isArabic ? 'الشروق' : 'Sunrise';
  String get dhuhr => isArabic ? 'الظهر' : 'Dhuhr';
  String get asr => isArabic ? 'العصر' : 'Asr';
  String get maghrib => isArabic ? 'المغرب' : 'Maghrib';
  String get isha => isArabic ? 'العشاء' : 'Isha';

  String get settingsTitle => isArabic ? 'الإعدادات' : 'Settings';
  String get about => isArabic ? 'حول التطبيق' : 'About';
  String get sleepCard => isArabic ? 'النوم' : 'Sleep';
  String get studyCard => isArabic ? 'المذاكرة' : 'Study';
  String get resetOnboarding =>
      isArabic ? 'إعادة جولة البداية' : 'Replay walkthrough';

  String get coachThinking => isArabic ? 'يكتب…' : 'Typing…';
  String get coachOfflineNotice => isArabic
      ? 'المساعد العام يحتاج اتصالاً بالإنترنت ومفتاح Gemini من الإعدادات. الوضع المحلي محدود بموضوعات التوازن الرقمي.'
      : 'The general assistant needs internet and a Gemini API key in Settings. Offline replies are limited to digital wellbeing.';
  String get coachError => isArabic
      ? 'المساعد غير متاح الآن. تحقق من الاتصال وحاول مرة أخرى.'
      : 'The assistant is temporarily unavailable. Check your connection and try again.';
  String get coachClear => isArabic ? 'محادثة جديدة' : 'New chat';
  String get geminiApiKey => isArabic ? 'مفتاح Gemini API' : 'Gemini API key';
  String get geminiApiKeyHint =>
      isArabic ? 'الصق المفتاح هنا' : 'Paste your key here';
  String get geminiApiKeyBody => isArabic
      ? 'أضف مفتاح Gemini واتصالاً بالإنترنت لتفعيل المساعد العام. يُحفظ المفتاح على جهازك.'
      : 'Add a Gemini API key and internet access to enable the general assistant. The key is stored on this device.';
  String get geminiApiKeySaved => isArabic ? 'تم الحفظ' : 'Saved';
  String get coachPanelTitle => isArabic ? 'مساعد توازن' : 'Tawazon AI';
  String get openCoach => isArabic ? 'افتح المساعد الذكي' : 'Open AI assistant';
  String get aboutBody => isArabic
      ? 'توازن تطبيق محلي لإدارة الانتباه: حديقة تركيز، مدرب رقمي، وتتبع للنوم والمذاكرة.'
      : 'Tawazon is a local attention companion: a focus garden, a digital coach, and sleep/study tracking.';
}
