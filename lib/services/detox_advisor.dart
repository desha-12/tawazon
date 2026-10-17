import '../features/ai_coach/domain/coach_message.dart';
import '../features/dashboard/domain/daily_usage.dart';

class DetoxAdvisor {
  const DetoxAdvisor();

  List<String> offlineIdeas({required bool arabic}) {
    if (arabic) {
      return const [
        'عشر صفحات من كتاب ورقي، بلا هاتف في الغرفة.',
        'مشي ٢٠ دقيقة حول المبنى مع عدّ الأنفاس لا الخطوات على الشاشة.',
        'وضعية جلوس هادئة: ٤ عدّات شهيق، ٦ عدّات زفير، لخمس دقائق.',
        'رتّب مكتباً واحداً فقط. أغلق الأدراج قبل أن تفتح تطبيقاً.',
        'اكتب ثلاثة أسطر بخط اليد: ما سرق وقتك، وما ستعيده غداً.',
      ];
    }
    return const [
      'Ten pages of a paper book. Leave the phone in another room.',
      'A twenty-minute walk. Count breaths, not steps on a screen.',
      'Sit still: inhale for 4, exhale for 6, five minutes.',
      'Clear one desk surface. Close the drawers before you open an app.',
      'Three handwritten lines: what stole the hour, what you reclaim tomorrow.',
    ];
  }

  String routine({
    required bool arabic,
    required DailyUsage today,
    required bool hasUsageData,
    required double? lastSleepHours,
    required bool prayerAlerts,
    required Mood? mood,
  }) {
    if (arabic) {
      final sleepLine = lastSleepHours == null
          ? 'نوّم الليلة قبل أن يفتح الهاتف باباً جديداً.'
          : lastSleepHours < 6.5
              ? 'نومك كان قصيراً. أغلق الشاشة قبل الفراش بستين دقيقة.'
              : 'حافظ على نافذة النوم التي بنيتها.';
      final prayerLine = prayerAlerts
          ? 'اجعل دقائق ما بعد الأذان بلا إشعارات.'
          : 'جرّب فترة هدوء قصيرة بعد العصر.';
      final moodLine = switch (mood) {
        Mood.restless => 'اليوم يحتاج تفريغ حركة لا مزيد تمرير.',
        Mood.tired => 'اختصر الجلسات. حديقة واحدة كافية.',
        Mood.scattered => 'مهمة واحدة قبل أي تطبيق تواصل.',
        Mood.calm => 'ثبّت الهدوء بجلسة تركيز قصيرة.',
        null => 'ابدأ بتفقد مزاج صادق قبل الخطة.',
      };
      return [
        hasUsageData
            ? 'روتين مناسب لاستخدامك اليوم (${today.totalHours.toStringAsFixed(1)}س):'
            : 'روتين توازن عام:',
        '• $moodLine',
        '• خصص أول ٢٥ دقيقة بلا هاتف.',
        '• $prayerLine',
        '• $sleepLine',
        '• اختتم المساء بنشاط من قائمة بلا شاشة.',
      ].join('\n');
    }

    final sleepLine = lastSleepHours == null
        ? 'Put the phone away before bed opens another door.'
        : lastSleepHours < 6.5
            ? 'Sleep ran short. Screens off sixty minutes before bed.'
            : 'Keep the sleep window you already earned.';
    final prayerLine = prayerAlerts
        ? 'Keep the minutes after the adhan free of notifications.'
        : 'Try a short quiet window after late afternoon.';
    final moodLine = switch (mood) {
      Mood.restless => 'Today needs movement, not another scroll.',
      Mood.tired => 'Keep sittings short. One garden is enough.',
      Mood.scattered => 'One real task before any social app.',
      Mood.calm => 'Lock the calm in with a short focus sitting.',
      null => 'Start with an honest mood check before the plan.',
    };
    return [
      hasUsageData
          ? 'A routine for today’s ${today.totalHours.toStringAsFixed(1)}h of screen time:'
          : 'A general digital-balance routine:',
      '• $moodLine',
      '• Set aside the first 25 minutes without your phone.',
      '• $prayerLine',
      '• $sleepLine',
      '• Close the evening with one offline activity.',
    ].join('\n');
  }

  String reply({
    required String prompt,
    required bool arabic,
    required DailyUsage today,
    required bool hasUsageData,
    required double? lastSleepHours,
    required bool prayerAlerts,
    required Mood? mood,
  }) {
    final q = prompt.toLowerCase();
    final ideas = offlineIdeas(arabic: arabic);
    if (_matches(q, ['routine', 'detox', 'روتين', 'سمو'])) {
      return routine(
        arabic: arabic,
        today: today,
        hasUsageData: hasUsageData,
        lastSleepHours: lastSleepHours,
        prayerAlerts: prayerAlerts,
        mood: mood,
      );
    }
    if (_matches(q, ['walk', 'read', 'offline', 'book', 'exercise', 'meditat', 'مشي', 'كتاب', 'رياض', 'تأمل', 'نشاط'])) {
      return arabic ? 'جرّب هذا الآن:\n• ${ideas.first}\n• ${ideas[1]}' : 'Try this now:\n• ${ideas.first}\n• ${ideas[1]}';
    }
    if (_matches(q, ['sleep', 'نوم'])) {
      return arabic
          ? 'الشاشة قرب الفراش تسرق النوم أكثر مما تظن. سجّل ساعاتك من تبويب النوم لنرى الارتباط.'
          : 'Screens near the pillow steal more sleep than they admit. Log last night so we can see the link.';
    }
    if (_matches(q, ['focus', 'garden', 'تركيز', 'حديق'])) {
      return arabic
          ? 'ابدأ الحديقة على ٢٥ دقيقة. إن خرجت من التطبيق تذبل النبتة. هذا هو العقد.'
          : 'Start the garden on 25 minutes. Leave the app and the plant withers. That is the contract.';
    }
    if (_matches(q, ['prayer', 'صلا'])) {
      return arabic
          ? 'إن فُعّلت التنبيهات، اعتبر الأذان حداً: الشاشة تُطوى لدقيقتين حول كل صلاة.'
          : 'If alerts are on, treat the adhan as a border: fold the screen for two minutes around each prayer.';
    }
    if (_matches(q, ['usage', 'screen', 'شاش', 'وقت'])) {
      if (!hasUsageData) {
        return arabic
            ? 'لا أستطيع قراءة وقت استخدامك الآن. هذه الميزة متاحة على Android بعد تفعيل إذن «بيانات الاستخدام».'
            : 'I can’t read your screen time yet. This feature is available on Android after enabling Usage Access.';
      }
      return arabic
          ? 'استخدمت الهاتف نحو ${today.totalHours.toStringAsFixed(1)} ساعة اليوم. لا تتوفر لدينا بيانات مصنفة حسب التطبيقات، لكن يمكنك أخذ استراحة قصيرة الآن.'
          : 'You have used your phone for about ${today.totalHours.toStringAsFixed(1)} hours today. We don’t have per-app categories, but a short break may help.';
    }

    return arabic
        ? 'أنا الآن في الوضع المحلي، لذلك لا أستطيع الإجابة عن هذا الطلب العام دون اتصال. أضف مفتاح Gemini واتصل بالإنترنت لتفعيل المساعد الكامل. أستطيع محلياً مساعدتك في التركيز، النوم، الصلاة، ووقت الشاشة.'
        : 'I am in offline mode, so I cannot answer this general request without a connection. Add a Gemini API key and connect to the internet to use the full assistant. Offline help is limited to focus, sleep, prayer, and screen time.';
  }

  bool _matches(String q, List<String> keys) => keys.any(q.contains);
}
