import 'package:soundora/data/models/songs/songs_model.dart';

/// Resolves full Quran recitation URLs from mp3quran.net when a song is a
/// surah (e.g. "سورة الفاتحة") by a supported reciter (e.g. المنشاوي).
class QuranResolver {
  static const String _base = 'https://server10.mp3quran.net/download';

  /// mp3quran.net server10 folder codes for supported reciters.
  static const Map<String, String> _reciterFolders = {
    'المنشاوي': 'minsh',
    'منشاوي': 'minsh',
    'minsh': 'minsh',
    'الحصري': 'husary',
    'حصري': 'husary',
    'husary': 'husary',
    'عبدالباسط': 'abdulbasit',
    'عبد الباسط': 'abdulbasit',
    'عبد الباسط عبد الصمد': 'abdulbasit',
    'abdulbasit': 'abdulbasit',
    'السديس': 'sudais',
    'السديس والشريم': 'sudais',
    'sudais': 'sudais',
    'الشريم': 'shuraim',
    'شريم': 'shuraim',
    'shuraim': 'shuraim',
    'ماهر المعيقلي': 'maher',
    'المعيقلي': 'maher',
    'maher': 'maher',
  };

  static const Map<String, int> _surahArabic = {
    'الفاتحة': 1, 'البقرة': 2, 'آل عمران': 3, 'النساء': 4, 'المائدة': 5,
    'الأنعام': 6, 'الأعراف': 7, 'الأنفال': 8, 'التوبة': 9, 'يونس': 10,
    'هود': 11, 'يوسف': 12, 'الرعد': 13, 'إبراهيم': 14, 'الحجر': 15,
    'النحل': 16, 'الإسراء': 17, 'الكهف': 18, 'مريم': 19, 'طه': 20,
    'الأنبياء': 21, 'الحج': 22, 'المؤمنون': 23, 'النور': 24, 'الفرقان': 25,
    'الشعراء': 26, 'النمل': 27, 'القصص': 28, 'العنكبوت': 29, 'الروم': 30,
    'لقمان': 31, 'السجدة': 32, 'الأحزاب': 33, 'سبأ': 34, 'فاطر': 35,
    'يس': 36, 'الصافات': 37, 'ص': 38, 'الزمر': 39, 'غافر': 40,
    'فصلت': 41, 'الشورى': 42, 'الزخرف': 43, 'الدخان': 44, 'الجاثية': 45,
    'الأحقاف': 46, 'محمد': 47, 'الفتح': 48, 'الحجرات': 49, 'ق': 50,
    'الذاريات': 51, 'الطور': 52, 'النجم': 53, 'القمر': 54, 'الرحمن': 55,
    'الواقعة': 56, 'الحديد': 57, 'المجادلة': 58, 'الحشر': 59, 'الممتحنة': 60,
    'الصف': 61, 'الجمعة': 62, 'المنافقون': 63, 'التغابن': 64, 'الطلاق': 65,
    'التحريم': 66, 'الملك': 67, 'القلم': 68, 'الحاقة': 69, 'المعارج': 70,
    'نوح': 71, 'الجن': 72, 'المزمل': 73, 'المدثر': 74, 'القيامة': 75,
    'الإنسان': 76, 'المرسلات': 77, 'النبأ': 78, 'النازعات': 79, 'عبس': 80,
    'التكوير': 81, 'الانفطار': 82, 'المطففين': 83, 'الانشقاق': 84, 'البروج': 85,
    'الطارق': 86, 'الأعلى': 87, 'الغاشية': 88, 'الفجر': 89, 'البلد': 90,
    'الشمس': 91, 'الليل': 92, 'الضحى': 93, 'الشرح': 94, 'التين': 95,
    'العلق': 96, 'القدر': 97, 'البينة': 98, 'الزلزلة': 99, 'العاديات': 100,
    'القارعة': 101, 'التكاثر': 102, 'العصر': 103, 'الهمزة': 104, 'الفيل': 105,
    'قريش': 106, 'الماعون': 107, 'الكوثر': 108, 'الكافرون': 109, 'النصر': 110,
    'المسد': 111, 'الإخلاص': 112, 'الفلق': 113, 'الناس': 114,
  };

  static const Map<String, int> _surahEnglish = {
    'fatihah': 1, 'fatiha': 1, 'baqarah': 2, 'baqara': 2, 'aal-imran': 3,
    'al-imran': 3, 'nisa': 4, "nisa'": 4, 'maidah': 5, "an'am": 6,
    'araf': 7, 'anfal': 8, 'tawbah': 9, 'yunus': 10, 'hud': 11, 'yusuf': 12,
    'rad': 13, 'ibrahim': 14, 'hijr': 15, 'nahl': 16, 'isra': 17, 'kahf': 18,
    'maryam': 19, 'ta-ha': 20, 'ta ha': 20, 'anbiya': 21, 'hajj': 22,
    "mu'minun": 23, 'nur': 24, 'furqan': 25, "shu'ara": 26, 'naml': 27,
    'qasas': 28, 'ankabut': 29, 'rum': 30, 'luqman': 31, 'sajdah': 32,
    'ahzab': 33, 'saba': 34, 'fatir': 35, 'ya-sin': 36, 'yasin': 36,
    'saffat': 37, 'sad': 38, 'zumar': 39, 'ghafir': 40, 'fussilat': 41,
    'shura': 42, 'zukhruf': 43, 'dukhan': 44, 'jathiyah': 45, 'ahqaf': 46,
    'muhammad': 47, 'fath': 48, 'hujurat': 49, 'qaaf': 50, 'qaf': 50,
    'dhariyat': 51, 'tur': 52, 'najm': 53, 'qamar': 54, 'rahman': 55,
    "waqi'ah": 56, 'hadid': 57, 'mujadilah': 58, 'hashr': 59,
    'mumtahanah': 60, 'saff': 61, "jumu'ah": 62, 'munafiqun': 63,
    'taghabun': 64, 'talaq': 65, 'tahrim': 66, 'mulk': 67, 'qalam': 68,
    'haqqah': 69, "ma'arij": 70, 'nooh': 71, 'nuh': 71, 'jinn': 72,
    'muzzammil': 73, 'muddaththir': 74, 'qiyamah': 75, 'insan': 76,
    'mursalat': 77, 'naba': 78, "nazi'at": 79, 'abasa': 80, 'takwir': 81,
    'infitar': 82, 'mutaffifin': 83, 'inshiqaq': 84, 'buruj': 85, 'tariq': 86,
    "a'la": 87, 'ghashiyah': 88, 'fajr': 89, 'balad': 90, 'shams': 91,
    'lail': 92, 'duha': 93, 'sharh': 94, 'tin': 95, 'alaq': 96, 'qadr': 97,
    'bayyinah': 98, 'zalzalah': 99, 'adiyat': 100, "qari'ah": 101,
    'takathur': 102, 'asr': 103, 'humazah': 104, 'fil': 105, 'quraish': 106,
    "ma'un": 107, 'kauthar': 108, 'kafirun': 109, 'nasr': 110, 'masad': 111,
    'ikhlas': 112, 'falaq': 113, 'nas': 114,
  };

  /// Returns the mp3quran.net full-recitation URL for [song], or null when the
  /// song is not a surah by a supported reciter.
  static String? resolve(SongModel song) {
    final title = _normalize(song.title);
    final artist = _normalize(song.artist);

    String? folder;
    for (final entry in _reciterFolders.entries) {
      if (artist.contains(entry.key) || title.contains(entry.key)) {
        folder = entry.value;
        break;
      }
    }
    if (folder == null) return null;

    final match = RegExp(r'^سورة\s+(.+)$').firstMatch(title);
    var name = (match?.group(1) ?? title).trim();

    // Strip any reciter mentions that travelled with the surah name
    // (e.g. "سورة يس المنشاوي" -> "يس").
    final reciterKeys = _reciterFolders.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final key in reciterKeys) {
      name = name.replaceAll(key, '').trim();
    }
    if (name.isEmpty) return null;

    final normalizedName = _normalize(name).replaceAll(RegExp(r'\s+'), ' ');
    final int? number = _surahArabic[normalizedName] ??
        _surahEnglish[
            normalizedName.toLowerCase().replaceFirst(RegExp('^al-'), '')];
    if (number == null) return null;

    return '$_base/$folder/${number.toString().padLeft(3, '0')}.mp3';
  }

  static String _normalize(String input) {
    final withoutDiacritics =
        input.replaceAll(RegExp('[\u064B-\u0652\u0670\u0640]'), '');
    final withoutPrefix = withoutDiacritics
        .replaceFirst(RegExp('^الشيخ\\s+'), '')
        .replaceFirst(RegExp('^الاستاذ\\s+'), '')
        .replaceFirst(RegExp('^الأستاذ\\s+'), '');
    return withoutPrefix.trim();
  }

  /// mp3quran.net server10 folder code for [reciter], or null if unsupported.
  static String? reciterFolder(String reciter) =>
      _reciterFolders[_normalize(reciter).trim()];

  /// Builds the mp3quran.net full-recitation URL for [surahNumber] by
  /// [reciter], or null when the reciter is unsupported.
  static String? urlFor(int surahNumber, String reciter) {
    final folder = reciterFolder(reciter);
    if (folder == null) return null;
    return '$_base/$folder/${surahNumber.toString().padLeft(3, '0')}.mp3';
  }
}
