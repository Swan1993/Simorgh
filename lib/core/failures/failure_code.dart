// The catalog is intentionally written as readable data tables. Each entry
// is immutable at runtime and has all three supported translations together.
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

/// Stable, typed failure identifiers used by diagnostics and log entries.
enum FailureCode {
  noInternet,
  dnsFail,
  cloudflareRangesUnreachable,
  allIpsBlocked,
  tlsHandshakeReset,
  sniBlocked,
  workerNotFound,
  workerQuotaExceeded,
  workerBlockedByCloudflare,
  tokenInvalid,
  coreMissing,
  coreCrash,
  coreConfigInvalid,
  portInUse,
  proxySetFailed,
  antivirusQuarantinedCore,
  verifyTimeout,
  unknown;

  static FailureCode? fromWireCode(String value) {
    for (final entry in _wireCodes.entries) {
      if (entry.value == value.toUpperCase()) {
        return entry.key;
      }
    }
    return null;
  }
}

enum FailureLanguage {
  english,
  persian,
  hindi;

  static FailureLanguage fromCode(String code) {
    switch (code.toLowerCase().split('-').first) {
      case 'fa':
        return FailureLanguage.persian;
      case 'hi':
      case 'hindi':
        return FailureLanguage.hindi;
      default:
        return FailureLanguage.english;
    }
  }
}

class FailureMessage {
  const FailureMessage({
    required this.title,
    required this.explanation,
    required this.fixes,
  });

  final String title;
  final String explanation;
  final List<String> fixes;

  String get plainExplanation => explanation;
}

/// Alias useful to callers that prefer to name the localized value as info.
typedef FailureCodeInfo = FailureMessage;

extension FailureCodeProperties on FailureCode {
  String get wireCode => _wireCodes[this]!;

  FailureMessage localized([
    FailureLanguage language = FailureLanguage.english,
  ]) {
    return FailureCodeCatalog.message(this, language: language);
  }

  FailureMessage messageFor(String languageCode) {
    return localized(FailureLanguage.fromCode(languageCode));
  }

  String get code => wireCode;
}

class FailureCodeCatalog {
  const FailureCodeCatalog._();

  static FailureMessage message(
    FailureCode code, {
    FailureLanguage language = FailureLanguage.english,
  }) {
    return _messages[code]![language]!;
  }

  static FailureMessage forLocale(FailureCode code, String languageCode) {
    return message(code, language: FailureLanguage.fromCode(languageCode));
  }

  static FailureCode? fromWireCode(String value) =>
      FailureCode.fromWireCode(value);

  static Iterable<FailureCode> get all => FailureCode.values;
}

const Map<FailureCode, String> _wireCodes = <FailureCode, String>{
  FailureCode.noInternet: 'E_NO_INTERNET',
  FailureCode.dnsFail: 'E_DNS_FAIL',
  FailureCode.cloudflareRangesUnreachable: 'E_CF_RANGES_UNREACHABLE',
  FailureCode.allIpsBlocked: 'E_ALL_IPS_BLOCKED',
  FailureCode.tlsHandshakeReset: 'E_TLS_HANDSHAKE_RESET',
  FailureCode.sniBlocked: 'E_SNI_BLOCKED',
  FailureCode.workerNotFound: 'E_WORKER_404',
  FailureCode.workerQuotaExceeded: 'E_WORKER_QUOTA_EXCEEDED',
  FailureCode.workerBlockedByCloudflare: 'E_WORKER_BLOCKED_BY_CF',
  FailureCode.tokenInvalid: 'E_TOKEN_INVALID',
  FailureCode.coreMissing: 'E_CORE_MISSING',
  FailureCode.coreCrash: 'E_CORE_CRASH',
  FailureCode.coreConfigInvalid: 'E_CORE_CONFIG_INVALID',
  FailureCode.portInUse: 'E_PORT_IN_USE',
  FailureCode.proxySetFailed: 'E_PROXY_SET_FAILED',
  FailureCode.antivirusQuarantinedCore: 'E_AV_QUARANTINED_CORE',
  FailureCode.verifyTimeout: 'E_VERIFY_TIMEOUT',
  FailureCode.unknown: 'E_UNKNOWN',
};

final Map<FailureCode, Map<FailureLanguage, FailureMessage>>
_messages = <FailureCode, Map<FailureLanguage, FailureMessage>>{
  FailureCode.noInternet: _localized(
    en: FailureMessage(
      title: 'No internet connection',
      explanation: 'The device cannot reach the public internet.',
      fixes: <String>[
        'Check Wi-Fi or Ethernet.',
        'Retry after the network is restored.',
      ],
    ),
    fa: FailureMessage(
      title: 'اتصال اینترنت وجود ندارد',
      explanation: 'دستگاه نمی‌تواند به اینترنت عمومی دسترسی پیدا کند.',
      fixes: <String>[
        'اتصال Wi‑Fi یا کابل را بررسی کنید.',
        'پس از برقراری شبکه دوباره تلاش کنید.',
      ],
    ),
    hi: FailureMessage(
      title: 'इंटरनेट कनेक्शन उपलब्ध नहीं है',
      explanation: 'डिवाइस सार्वजनिक इंटरनेट तक नहीं पहुँच पा रहा है।',
      fixes: <String>[
        'Wi‑Fi या Ethernet जाँचें।',
        'नेटवर्क बहाल होने पर फिर प्रयास करें।',
      ],
    ),
  ),
  FailureCode.dnsFail: _localized(
    en: FailureMessage(
      title: 'DNS lookup failed',
      explanation: 'The hostname could not be resolved.',
      fixes: <String>[
        'Check DNS settings.',
        'Try another network or DNS resolver.',
      ],
    ),
    fa: FailureMessage(
      title: 'خطای دریافت DNS',
      explanation: 'نام میزبان قابل تبدیل به نشانی نیست.',
      fixes: <String>[
        'تنظیمات DNS را بررسی کنید.',
        'شبکه یا DNS دیگری را امتحان کنید.',
      ],
    ),
    hi: FailureMessage(
      title: 'DNS खोज विफल',
      explanation: 'होस्टनाम का पता नहीं मिल सका।',
      fixes: <String>[
        'DNS सेटिंग जाँचें।',
        'दूसरा नेटवर्क या DNS रिज़ॉल्वर आज़माएँ।',
      ],
    ),
  ),
  FailureCode.cloudflareRangesUnreachable: _localized(
    en: FailureMessage(
      title: 'Cloudflare ranges are unreachable',
      explanation: 'The IP range sources could not be downloaded.',
      fixes: <String>[
        'Check internet and DNS access.',
        'Retry to use the bundled fallback ranges.',
      ],
    ),
    fa: FailureMessage(
      title: 'محدوده‌های Cloudflare در دسترس نیستند',
      explanation: 'منبع محدوده‌های IP قابل دریافت نیست.',
      fixes: <String>[
        'دسترسی اینترنت و DNS را بررسی کنید.',
        'برای استفاده از فهرست داخلی دوباره تلاش کنید.',
      ],
    ),
    hi: FailureMessage(
      title: 'Cloudflare रेंज उपलब्ध नहीं हैं',
      explanation: 'IP रेंज स्रोत डाउनलोड नहीं हो सके।',
      fixes: <String>[
        'इंटरनेट और DNS जाँचें।',
        'बंडल की गई वैकल्पिक सूची के लिए फिर प्रयास करें।',
      ],
    ),
  ),
  FailureCode.allIpsBlocked: _localized(
    en: FailureMessage(
      title: 'All candidate IPs are blocked',
      explanation:
          'No scanned Cloudflare address passed the connectivity checks.',
      fixes: <String>['Retry the scan later.', 'Try another relay or port.'],
    ),
    fa: FailureMessage(
      title: 'همه IPهای پیشنهادی مسدود هستند',
      explanation: 'هیچ نشانی Cloudflare از آزمون اتصال عبور نکرد.',
      fixes: <String>[
        'اسکن را بعداً تکرار کنید.',
        'رله یا درگاه دیگری را امتحان کنید.',
      ],
    ),
    hi: FailureMessage(
      title: 'सभी IP अवरुद्ध हैं',
      explanation: 'स्कैन किया गया कोई भी Cloudflare पता कनेक्ट नहीं हुआ।',
      fixes: <String>[
        'कुछ देर बाद स्कैन दोहराएँ।',
        'दूसरा रिले या पोर्ट आज़माएँ।',
      ],
    ),
  ),
  FailureCode.tlsHandshakeReset: _localized(
    en: FailureMessage(
      title: 'TLS handshake was reset',
      explanation: 'The secure connection was closed during negotiation.',
      fixes: <String>[
        'Try another port.',
        'Retry with a different candidate IP.',
      ],
    ),
    fa: FailureMessage(
      title: 'مذاکره TLS قطع شد',
      explanation: 'اتصال امن هنگام مذاکره بسته شد.',
      fixes: <String>[
        'درگاه دیگری را امتحان کنید.',
        'با IP پیشنهادی دیگری دوباره تلاش کنید.',
      ],
    ),
    hi: FailureMessage(
      title: 'TLS हैंडशेक रीसेट हुआ',
      explanation: 'सुरक्षित कनेक्शन बातचीत के दौरान बंद हो गया।',
      fixes: <String>[
        'दूसरा पोर्ट आज़माएँ।',
        'दूसरे IP के साथ फिर प्रयास करें।',
      ],
    ),
  ),
  FailureCode.sniBlocked: _localized(
    en: FailureMessage(
      title: 'SNI is blocked',
      explanation: 'The requested server name was filtered during TLS setup.',
      fixes: <String>[
        'Try another relay hostname.',
        'Retry with another candidate IP.',
      ],
    ),
    fa: FailureMessage(
      title: 'SNI مسدود است',
      explanation: 'نام سرور هنگام راه‌اندازی TLS فیلتر شد.',
      fixes: <String>[
        'نام میزبان رله دیگری را امتحان کنید.',
        'با IP دیگری دوباره تلاش کنید.',
      ],
    ),
    hi: FailureMessage(
      title: 'SNI अवरुद्ध है',
      explanation: 'TLS सेटअप के दौरान सर्वर नाम फ़िल्टर किया गया।',
      fixes: <String>[
        'दूसरा रिले होस्टनाम आज़माएँ।',
        'दूसरे IP के साथ फिर प्रयास करें।',
      ],
    ),
  ),
  FailureCode.workerNotFound: _localized(
    en: FailureMessage(
      title: 'Worker was not found',
      explanation: 'The relay endpoint returned HTTP 404.',
      fixes: <String>[
        'Verify the Worker hostname and path.',
        'Deploy the relay again if it was removed.',
      ],
    ),
    fa: FailureMessage(
      title: 'Worker پیدا نشد',
      explanation: 'نقطه پایانی رله پاسخ HTTP 404 داد.',
      fixes: <String>[
        'نام میزبان و مسیر Worker را بررسی کنید.',
        'اگر حذف شده است رله را دوباره مستقر کنید.',
      ],
    ),
    hi: FailureMessage(
      title: 'Worker नहीं मिला',
      explanation: 'रिले एंडपॉइंट ने HTTP 404 लौटाया।',
      fixes: <String>[
        'Worker होस्टनाम और पथ जाँचें।',
        'हटाए जाने पर रिले फिर तैनात करें।',
      ],
    ),
  ),
  FailureCode.workerQuotaExceeded: _localized(
    en: FailureMessage(
      title: 'Worker quota exceeded',
      explanation: 'The Cloudflare Worker or account quota has been reached.',
      fixes: <String>[
        'Wait for the quota window to reset.',
        'Use another relay or account.',
      ],
    ),
    fa: FailureMessage(
      title: 'سهمیه Worker تمام شده است',
      explanation: 'سهمیه Worker یا حساب Cloudflare به پایان رسیده.',
      fixes: <String>[
        'تا بازنشانی سهمیه صبر کنید.',
        'از رله یا حساب دیگری استفاده کنید.',
      ],
    ),
    hi: FailureMessage(
      title: 'Worker कोटा पार हो गया',
      explanation: 'Cloudflare Worker या खाते की सीमा पूरी हो गई है।',
      fixes: <String>[
        'कोटा रीसेट होने तक प्रतीक्षा करें।',
        'दूसरा रिले या खाता उपयोग करें।',
      ],
    ),
  ),
  FailureCode.workerBlockedByCloudflare: _localized(
    en: FailureMessage(
      title: 'Worker was blocked by Cloudflare',
      explanation: 'Cloudflare rejected the Worker request or deployment.',
      fixes: <String>[
        'Review the Worker status and account policy.',
        'Retry after resolving the Cloudflare restriction.',
      ],
    ),
    fa: FailureMessage(
      title: 'Worker توسط Cloudflare مسدود شد',
      explanation: 'Cloudflare درخواست یا استقرار Worker را رد کرد.',
      fixes: <String>[
        'وضعیت Worker و سیاست حساب را بررسی کنید.',
        'پس از رفع محدودیت دوباره تلاش کنید.',
      ],
    ),
    hi: FailureMessage(
      title: 'Worker को Cloudflare ने ब्लॉक किया',
      explanation: 'Cloudflare ने Worker अनुरोध या परिनियोजन अस्वीकार किया।',
      fixes: <String>[
        'Worker स्थिति और खाता नीति देखें।',
        'प्रतिबंध हटने के बाद फिर प्रयास करें।',
      ],
    ),
  ),
  FailureCode.tokenInvalid: _localized(
    en: FailureMessage(
      title: 'API token is invalid',
      explanation: 'The supplied Cloudflare token was rejected.',
      fixes: <String>[
        'Create or copy a valid token.',
        'Check the token permissions and account.',
      ],
    ),
    fa: FailureMessage(
      title: 'توکن API معتبر نیست',
      explanation: 'توکن Cloudflare ارائه‌شده رد شد.',
      fixes: <String>[
        'توکن معتبر بسازید یا دوباره کپی کنید.',
        'مجوزها و حساب توکن را بررسی کنید.',
      ],
    ),
    hi: FailureMessage(
      title: 'API टोकन अमान्य है',
      explanation: 'दिया गया Cloudflare टोकन अस्वीकार किया गया।',
      fixes: <String>[
        'मान्य टोकन बनाएँ या फिर कॉपी करें।',
        'टोकन की अनुमति और खाता जाँचें।',
      ],
    ),
  ),
  FailureCode.coreMissing: _localized(
    en: FailureMessage(
      title: 'Core executable is missing',
      explanation: 'The sing-box sidecar executable could not be found.',
      fixes: <String>[
        'Run the core download or repair step.',
        'Check antivirus quarantine and installation files.',
      ],
    ),
    fa: FailureMessage(
      title: 'فایل اجرایی هسته وجود ندارد',
      explanation: 'فایل اجرایی sing-box پیدا نشد.',
      fixes: <String>[
        'مرحله دریافت یا تعمیر هسته را اجرا کنید.',
        'قرنطینه آنتی‌ویروس و فایل‌های نصب را بررسی کنید.',
      ],
    ),
    hi: FailureMessage(
      title: 'कोर निष्पादन फ़ाइल गायब है',
      explanation: 'sing-box साइडकार फ़ाइल नहीं मिली।',
      fixes: <String>[
        'कोर डाउनलोड या मरम्मत चलाएँ।',
        'एंटीवायरस क्वारंटीन और इंस्टॉलेशन फ़ाइलें जाँचें।',
      ],
    ),
  ),
  FailureCode.coreCrash: _localized(
    en: FailureMessage(
      title: 'Core process crashed',
      explanation: 'The sing-box sidecar stopped unexpectedly.',
      fixes: <String>[
        'Review the core error log.',
        'Retry with a fresh configuration or core binary.',
      ],
    ),
    fa: FailureMessage(
      title: 'فرآیند هسته متوقف شد',
      explanation: 'فرآیند sing-box به‌طور غیرمنتظره بسته شد.',
      fixes: <String>[
        'گزارش خطای هسته را بررسی کنید.',
        'با پیکربندی یا فایل هسته تازه دوباره تلاش کنید.',
      ],
    ),
    hi: FailureMessage(
      title: 'कोर प्रक्रिया क्रैश हुई',
      explanation: 'sing-box साइडकार अनपेक्षित रूप से रुक गया।',
      fixes: <String>[
        'कोर त्रुटि लॉग देखें।',
        'नई कॉन्फ़िगरेशन या कोर फ़ाइल के साथ फिर प्रयास करें।',
      ],
    ),
  ),
  FailureCode.coreConfigInvalid: _localized(
    en: FailureMessage(
      title: 'Core configuration is invalid',
      explanation: 'sing-box rejected the generated configuration.',
      fixes: <String>[
        'Regenerate the configuration.',
        'Check server, port and credential settings.',
      ],
    ),
    fa: FailureMessage(
      title: 'پیکربندی هسته نامعتبر است',
      explanation: 'sing-box پیکربندی تولیدشده را رد کرد.',
      fixes: <String>[
        'پیکربندی را دوباره بسازید.',
        'تنظیمات سرور، درگاه و اعتبارنامه را بررسی کنید.',
      ],
    ),
    hi: FailureMessage(
      title: 'कोर कॉन्फ़िगरेशन अमान्य है',
      explanation: 'sing-box ने बनाई गई कॉन्फ़िगरेशन अस्वीकार की।',
      fixes: <String>[
        'कॉन्फ़िगरेशन फिर बनाएँ।',
        'सर्वर, पोर्ट और क्रेडेंशियल जाँचें।',
      ],
    ),
  ),
  FailureCode.portInUse: _localized(
    en: FailureMessage(
      title: 'Port is already in use',
      explanation: 'Another process owns the local listening port.',
      fixes: <String>[
        'Close the process using the port.',
        'Choose another local port.',
      ],
    ),
    fa: FailureMessage(
      title: 'درگاه از قبل استفاده می‌شود',
      explanation: 'فرآیند دیگری درگاه محلی را در اختیار دارد.',
      fixes: <String>[
        'فرآیند استفاده‌کننده از درگاه را ببندید.',
        'درگاه محلی دیگری انتخاب کنید.',
      ],
    ),
    hi: FailureMessage(
      title: 'पोर्ट पहले से उपयोग में है',
      explanation: 'कोई अन्य प्रक्रिया स्थानीय पोर्ट उपयोग कर रही है।',
      fixes: <String>[
        'पोर्ट उपयोग करने वाली प्रक्रिया बंद करें।',
        'दूसरा स्थानीय पोर्ट चुनें।',
      ],
    ),
  ),
  FailureCode.proxySetFailed: _localized(
    en: FailureMessage(
      title: 'System proxy could not be set',
      explanation: 'Windows rejected the proxy update.',
      fixes: <String>[
        'Check permissions and proxy policy.',
        'Restore settings, then retry.',
      ],
    ),
    fa: FailureMessage(
      title: 'تنظیم پروکسی سیستم ناموفق بود',
      explanation: 'ویندوز تغییر پروکسی را نپذیرفت.',
      fixes: <String>[
        'مجوزها و سیاست پروکسی را بررسی کنید.',
        'تنظیمات را بازگردانید و دوباره تلاش کنید.',
      ],
    ),
    hi: FailureMessage(
      title: 'सिस्टम प्रॉक्सी सेट नहीं हो सका',
      explanation: 'Windows ने प्रॉक्सी बदलाव अस्वीकार किया।',
      fixes: <String>[
        'अनुमति और प्रॉक्सी नीति जाँचें।',
        'सेटिंग बहाल करके फिर प्रयास करें।',
      ],
    ),
  ),
  FailureCode.antivirusQuarantinedCore: _localized(
    en: FailureMessage(
      title: 'Antivirus quarantined the core',
      explanation:
          'Security software removed or blocked the sidecar executable.',
      fixes: <String>[
        'Review the antivirus event and restore the verified binary.',
        'Add a narrowly scoped exception if appropriate.',
      ],
    ),
    fa: FailureMessage(
      title: 'آنتی‌ویروس هسته را قرنطینه کرد',
      explanation: 'نرم‌افزار امنیتی فایل اجرایی را حذف یا مسدود کرده است.',
      fixes: <String>[
        'رویداد آنتی‌ویروس را بررسی و فایل تأییدشده را بازیابی کنید.',
        'در صورت لزوم استثنای محدود اضافه کنید.',
      ],
    ),
    hi: FailureMessage(
      title: 'एंटीवायरस ने कोर क्वारंटीन किया',
      explanation: 'सुरक्षा सॉफ़्टवेयर ने साइडकार फ़ाइल हटाई या ब्लॉक की।',
      fixes: <String>[
        'एंटीवायरस घटना देखें और सत्यापित फ़ाइल बहाल करें।',
        'उचित होने पर सीमित अपवाद जोड़ें।',
      ],
    ),
  ),
  FailureCode.verifyTimeout: _localized(
    en: FailureMessage(
      title: 'Connection verification timed out',
      explanation:
          'The connection did not answer within the verification deadline.',
      fixes: <String>[
        'Retry with another candidate IP.',
        'Increase the verification timeout if the network is slow.',
      ],
    ),
    fa: FailureMessage(
      title: 'مهلت بررسی اتصال تمام شد',
      explanation: 'اتصال تا پایان مهلت بررسی پاسخ نداد.',
      fixes: <String>[
        'با IP پیشنهادی دیگری تلاش کنید.',
        'اگر شبکه کند است مهلت بررسی را افزایش دهید.',
      ],
    ),
    hi: FailureMessage(
      title: 'कनेक्शन सत्यापन का समय समाप्त',
      explanation: 'कनेक्शन ने निर्धारित समय में उत्तर नहीं दिया।',
      fixes: <String>[
        'दूसरे IP के साथ फिर प्रयास करें।',
        'नेटवर्क धीमा हो तो सत्यापन समय बढ़ाएँ।',
      ],
    ),
  ),
  FailureCode.unknown: _localized(
    en: FailureMessage(
      title: 'Unknown failure',
      explanation: 'The operation failed for an unclassified reason.',
      fixes: <String>[
        'Review the redacted logs.',
        'Retry and export diagnostics if it continues.',
      ],
    ),
    fa: FailureMessage(
      title: 'خطای ناشناخته',
      explanation: 'عملیات به دلیلی طبقه‌بندی‌نشده ناموفق شد.',
      fixes: <String>[
        'گزارش‌های پاک‌سازی‌شده را بررسی کنید.',
        'دوباره تلاش کنید و در صورت تداوم گزارش عیب‌یابی بگیرید.',
      ],
    ),
    hi: FailureMessage(
      title: 'अज्ञात विफलता',
      explanation: 'ऑपरेशन का कारण वर्गीकृत नहीं किया जा सका।',
      fixes: <String>[
        'साफ़ किए गए लॉग देखें।',
        'जारी रहने पर फिर प्रयास कर निदान निर्यात करें।',
      ],
    ),
  ),
};

Map<FailureLanguage, FailureMessage> _localized({
  required FailureMessage en,
  required FailureMessage fa,
  required FailureMessage hi,
}) => <FailureLanguage, FailureMessage>{
  FailureLanguage.english: en,
  FailureLanguage.persian: fa,
  FailureLanguage.hindi: hi,
};
