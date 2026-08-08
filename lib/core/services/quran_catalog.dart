/// Model + static catalog of the 114 surahs of the Quran.
///
/// Page numbers follow the standard Madani mushaf pagination (604 pages).
class QuranSurah {
  final int number;
  final String arabicName;
  final String englishName;
  final String transliteration;
  final int ayahCount;
  final bool isMeccan;
  final int pageStart;
  final int pageEnd;

  const QuranSurah({
    required this.number,
    required this.arabicName,
    required this.englishName,
    required this.transliteration,
    required this.ayahCount,
    required this.isMeccan,
    required this.pageStart,
    required this.pageEnd,
  });
}

class QuranCatalog {
  static const String _meccan = 'مكية';
  static const String _medinan = 'مدنية';

  static const List<QuranSurah> surahs = [
    QuranSurah(number: 1, arabicName: 'الفاتحة', englishName: 'The Opener', transliteration: 'Al-Fatihah', ayahCount: 7, isMeccan: true, pageStart: 1, pageEnd: 1),
    QuranSurah(number: 2, arabicName: 'البقرة', englishName: 'The Cow', transliteration: "Al-Baqarah", ayahCount: 286, isMeccan: false, pageStart: 2, pageEnd: 49),
    QuranSurah(number: 3, arabicName: 'آل عمران', englishName: 'The Family of Imran', transliteration: "Ali 'Imran", ayahCount: 200, isMeccan: false, pageStart: 50, pageEnd: 76),
    QuranSurah(number: 4, arabicName: 'النساء', englishName: 'The Women', transliteration: "An-Nisa'", ayahCount: 176, isMeccan: false, pageStart: 77, pageEnd: 106),
    QuranSurah(number: 5, arabicName: 'المائدة', englishName: 'The Table Spread', transliteration: "Al-Ma'idah", ayahCount: 120, isMeccan: false, pageStart: 106, pageEnd: 127),
    QuranSurah(number: 6, arabicName: 'الأنعام', englishName: 'The Cattle', transliteration: "Al-An'am", ayahCount: 165, isMeccan: true, pageStart: 128, pageEnd: 150),
    QuranSurah(number: 7, arabicName: 'الأعراف', englishName: 'The Heights', transliteration: "Al-A'raf", ayahCount: 206, isMeccan: true, pageStart: 151, pageEnd: 176),
    QuranSurah(number: 8, arabicName: 'الأنفال', englishName: 'The Spoils of War', transliteration: "Al-Anfal", ayahCount: 75, isMeccan: false, pageStart: 177, pageEnd: 186),
    QuranSurah(number: 9, arabicName: 'التوبة', englishName: 'The Repentance', transliteration: "At-Tawbah", ayahCount: 129, isMeccan: false, pageStart: 187, pageEnd: 207),
    QuranSurah(number: 10, arabicName: 'يونس', englishName: 'Jonah', transliteration: 'Yunus', ayahCount: 109, isMeccan: true, pageStart: 208, pageEnd: 221),
    QuranSurah(number: 11, arabicName: 'هود', englishName: 'Hud', transliteration: 'Hud', ayahCount: 123, isMeccan: true, pageStart: 221, pageEnd: 235),
    QuranSurah(number: 12, arabicName: 'يوسف', englishName: 'Joseph', transliteration: 'Yusuf', ayahCount: 111, isMeccan: true, pageStart: 235, pageEnd: 248),
    QuranSurah(number: 13, arabicName: 'الرعد', englishName: 'The Thunder', transliteration: "Ar-Ra'd", ayahCount: 43, isMeccan: false, pageStart: 249, pageEnd: 255),
    QuranSurah(number: 14, arabicName: 'إبراهيم', englishName: 'Abraham', transliteration: 'Ibrahim', ayahCount: 52, isMeccan: true, pageStart: 255, pageEnd: 262),
    QuranSurah(number: 15, arabicName: 'الحجر', englishName: 'The Rocky Tract', transliteration: "Al-Hijr", ayahCount: 99, isMeccan: true, pageStart: 262, pageEnd: 267),
    QuranSurah(number: 16, arabicName: 'النحل', englishName: 'The Bee', transliteration: "An-Nahl", ayahCount: 128, isMeccan: true, pageStart: 267, pageEnd: 281),
    QuranSurah(number: 17, arabicName: 'الإسراء', englishName: 'The Night Journey', transliteration: "Al-Isra'", ayahCount: 111, isMeccan: true, pageStart: 281, pageEnd: 293),
    QuranSurah(number: 18, arabicName: 'الكهف', englishName: 'The Cave', transliteration: "Al-Kahf", ayahCount: 110, isMeccan: true, pageStart: 293, pageEnd: 304),
    QuranSurah(number: 19, arabicName: 'مريم', englishName: 'Mary', transliteration: 'Maryam', ayahCount: 98, isMeccan: true, pageStart: 305, pageEnd: 312),
    QuranSurah(number: 20, arabicName: 'طه', englishName: 'Ta-Ha', transliteration: 'Ta-Ha', ayahCount: 135, isMeccan: true, pageStart: 312, pageEnd: 321),
    QuranSurah(number: 21, arabicName: 'الأنبياء', englishName: 'The Prophets', transliteration: "Al-Anbiya'", ayahCount: 112, isMeccan: true, pageStart: 322, pageEnd: 331),
    QuranSurah(number: 22, arabicName: 'الحج', englishName: 'The Pilgrimage', transliteration: 'Al-Hajj', ayahCount: 78, isMeccan: false, pageStart: 332, pageEnd: 341),
    QuranSurah(number: 23, arabicName: 'المؤمنون', englishName: 'The Believers', transliteration: "Al-Mu'minun", ayahCount: 118, isMeccan: true, pageStart: 342, pageEnd: 349),
    QuranSurah(number: 24, arabicName: 'النور', englishName: 'The Light', transliteration: 'An-Nur', ayahCount: 64, isMeccan: false, pageStart: 350, pageEnd: 359),
    QuranSurah(number: 25, arabicName: 'الفرقان', englishName: 'The Criterion', transliteration: "Al-Furqan", ayahCount: 77, isMeccan: true, pageStart: 359, pageEnd: 366),
    QuranSurah(number: 26, arabicName: 'الشعراء', englishName: 'The Poets', transliteration: "Ash-Shu'ara'", ayahCount: 227, isMeccan: true, pageStart: 367, pageEnd: 376),
    QuranSurah(number: 27, arabicName: 'النمل', englishName: 'The Ant', transliteration: 'An-Naml', ayahCount: 93, isMeccan: true, pageStart: 377, pageEnd: 385),
    QuranSurah(number: 28, arabicName: 'القصص', englishName: 'The Stories', transliteration: 'Al-Qasas', ayahCount: 88, isMeccan: true, pageStart: 385, pageEnd: 396),
    QuranSurah(number: 29, arabicName: 'العنكبوت', englishName: 'The Spider', transliteration: 'Al-Ankabut', ayahCount: 69, isMeccan: true, pageStart: 396, pageEnd: 404),
    QuranSurah(number: 30, arabicName: 'الروم', englishName: 'The Romans', transliteration: "Ar-Rum", ayahCount: 60, isMeccan: true, pageStart: 404, pageEnd: 410),
    QuranSurah(number: 31, arabicName: 'لقمان', englishName: 'Luqman', transliteration: 'Luqman', ayahCount: 34, isMeccan: true, pageStart: 411, pageEnd: 414),
    QuranSurah(number: 32, arabicName: 'السجدة', englishName: 'The Prostration', transliteration: 'As-Sajdah', ayahCount: 30, isMeccan: true, pageStart: 415, pageEnd: 417),
    QuranSurah(number: 33, arabicName: 'الأحزاب', englishName: 'The Combined Forces', transliteration: "Al-Ahzab", ayahCount: 73, isMeccan: false, pageStart: 418, pageEnd: 427),
    QuranSurah(number: 34, arabicName: 'سبأ', englishName: 'Sheba', transliteration: "Saba'", ayahCount: 54, isMeccan: true, pageStart: 428, pageEnd: 434),
    QuranSurah(number: 35, arabicName: 'فاطر', englishName: 'The Originator', transliteration: 'Fatir', ayahCount: 45, isMeccan: true, pageStart: 434, pageEnd: 440),
    QuranSurah(number: 36, arabicName: 'يس', englishName: 'Ya-Sin', transliteration: 'Ya-Sin', ayahCount: 83, isMeccan: true, pageStart: 440, pageEnd: 445),
    QuranSurah(number: 37, arabicName: 'الصافات', englishName: 'Those Ranged in Ranks', transliteration: 'As-Saffat', ayahCount: 182, isMeccan: true, pageStart: 446, pageEnd: 452),
    QuranSurah(number: 38, arabicName: 'ص', englishName: 'Sad', transliteration: 'Sad', ayahCount: 88, isMeccan: true, pageStart: 453, pageEnd: 458),
    QuranSurah(number: 39, arabicName: 'الزمر', englishName: 'The Groups', transliteration: 'Az-Zumar', ayahCount: 75, isMeccan: true, pageStart: 458, pageEnd: 467),
    QuranSurah(number: 40, arabicName: 'غافر', englishName: 'The Forgiver', transliteration: 'Ghafir', ayahCount: 85, isMeccan: true, pageStart: 467, pageEnd: 476),
    QuranSurah(number: 41, arabicName: 'فصلت', englishName: 'Explained in Detail', transliteration: 'Fussilat', ayahCount: 54, isMeccan: true, pageStart: 477, pageEnd: 482),
    QuranSurah(number: 42, arabicName: 'الشورى', englishName: 'The Consultation', transliteration: 'Ash-Shura', ayahCount: 53, isMeccan: true, pageStart: 483, pageEnd: 489),
    QuranSurah(number: 43, arabicName: 'الزخرف', englishName: 'The Ornaments of Gold', transliteration: 'Az-Zukhruf', ayahCount: 89, isMeccan: true, pageStart: 489, pageEnd: 498),
    QuranSurah(number: 44, arabicName: 'الدخان', englishName: 'The Smoke', transliteration: 'Ad-Dukhan', ayahCount: 59, isMeccan: true, pageStart: 496, pageEnd: 498),
    QuranSurah(number: 45, arabicName: 'الجاثية', englishName: 'The Crouching', transliteration: 'Al-Jathiyah', ayahCount: 37, isMeccan: true, pageStart: 499, pageEnd: 502),
    QuranSurah(number: 46, arabicName: 'الأحقاف', englishName: 'The Wind-Curved Sandhills', transliteration: "Al-Ahqaf", ayahCount: 35, isMeccan: true, pageStart: 502, pageEnd: 506),
    QuranSurah(number: 47, arabicName: 'محمد', englishName: 'Muhammad', transliteration: 'Muhammad', ayahCount: 38, isMeccan: false, pageStart: 507, pageEnd: 510),
    QuranSurah(number: 48, arabicName: 'الفتح', englishName: 'The Victory', transliteration: 'Al-Fath', ayahCount: 29, isMeccan: false, pageStart: 511, pageEnd: 515),
    QuranSurah(number: 49, arabicName: 'الحجرات', englishName: 'The Rooms', transliteration: 'Al-Hujurat', ayahCount: 18, isMeccan: false, pageStart: 515, pageEnd: 517),
    QuranSurah(number: 50, arabicName: 'ق', englishName: 'Qaf', transliteration: 'Qaf', ayahCount: 45, isMeccan: true, pageStart: 518, pageEnd: 520),
    QuranSurah(number: 51, arabicName: 'الذاريات', englishName: 'The Winnowing Winds', transliteration: 'Adh-Dhariyat', ayahCount: 60, isMeccan: true, pageStart: 521, pageEnd: 523),
    QuranSurah(number: 52, arabicName: 'الطور', englishName: 'The Mount', transliteration: 'At-Tur', ayahCount: 49, isMeccan: true, pageStart: 523, pageEnd: 525),
    QuranSurah(number: 53, arabicName: 'النجم', englishName: 'The Star', transliteration: 'An-Najm', ayahCount: 62, isMeccan: true, pageStart: 526, pageEnd: 528),
    QuranSurah(number: 54, arabicName: 'القمر', englishName: 'The Moon', transliteration: 'Al-Qamar', ayahCount: 55, isMeccan: true, pageStart: 528, pageEnd: 531),
    QuranSurah(number: 55, arabicName: 'الرحمن', englishName: 'The Most Merciful', transliteration: "Ar-Rahman", ayahCount: 78, isMeccan: false, pageStart: 531, pageEnd: 534),
    QuranSurah(number: 56, arabicName: 'الواقعة', englishName: 'The Inevitable', transliteration: "Al-Waqi'ah", ayahCount: 96, isMeccan: true, pageStart: 534, pageEnd: 537),
    QuranSurah(number: 57, arabicName: 'الحديد', englishName: 'The Iron', transliteration: 'Al-Hadid', ayahCount: 29, isMeccan: false, pageStart: 537, pageEnd: 541),
    QuranSurah(number: 58, arabicName: 'المجادلة', englishName: 'The Pleading Woman', transliteration: 'Al-Mujadilah', ayahCount: 22, isMeccan: false, pageStart: 542, pageEnd: 545),
    QuranSurah(number: 59, arabicName: 'الحشر', englishName: 'The Exile', transliteration: 'Al-Hashr', ayahCount: 24, isMeccan: false, pageStart: 545, pageEnd: 548),
    QuranSurah(number: 60, arabicName: 'الممتحنة', englishName: 'The Examined Woman', transliteration: 'Al-Mumtahanah', ayahCount: 13, isMeccan: false, pageStart: 549, pageEnd: 551),
    QuranSurah(number: 61, arabicName: 'الصف', englishName: 'The Ranks', transliteration: 'As-Saff', ayahCount: 14, isMeccan: false, pageStart: 551, pageEnd: 552),
    QuranSurah(number: 62, arabicName: 'الجمعة', englishName: 'The Congregation, Friday', transliteration: "Al-Jumu'ah", ayahCount: 11, isMeccan: false, pageStart: 553, pageEnd: 554),
    QuranSurah(number: 63, arabicName: 'المنافقون', englishName: 'The Hypocrites', transliteration: 'Al-Munafiqun', ayahCount: 11, isMeccan: false, pageStart: 554, pageEnd: 555),
    QuranSurah(number: 64, arabicName: 'التغابن', englishName: 'The Mutual Disillusion', transliteration: 'At-Taghabun', ayahCount: 18, isMeccan: false, pageStart: 556, pageEnd: 557),
    QuranSurah(number: 65, arabicName: 'الطلاق', englishName: 'The Divorce', transliteration: 'At-Talaq', ayahCount: 12, isMeccan: false, pageStart: 558, pageEnd: 559),
    QuranSurah(number: 66, arabicName: 'التحريم', englishName: 'The Prohibition', transliteration: 'At-Tahrim', ayahCount: 12, isMeccan: false, pageStart: 560, pageEnd: 561),
    QuranSurah(number: 67, arabicName: 'الملك', englishName: 'The Sovereignty', transliteration: 'Al-Mulk', ayahCount: 30, isMeccan: true, pageStart: 562, pageEnd: 564),
    QuranSurah(number: 68, arabicName: 'القلم', englishName: 'The Pen', transliteration: 'Al-Qalam', ayahCount: 52, isMeccan: true, pageStart: 564, pageEnd: 566),
    QuranSurah(number: 69, arabicName: 'الحاقة', englishName: 'The Reality', transliteration: "Al-Haqqah", ayahCount: 52, isMeccan: true, pageStart: 566, pageEnd: 568),
    QuranSurah(number: 70, arabicName: 'المعارج', englishName: 'The Ascending Stairways', transliteration: "Al-Ma'arij", ayahCount: 44, isMeccan: true, pageStart: 568, pageEnd: 570),
    QuranSurah(number: 71, arabicName: 'نوح', englishName: 'Noah', transliteration: 'Nuh', ayahCount: 28, isMeccan: true, pageStart: 570, pageEnd: 572),
    QuranSurah(number: 72, arabicName: 'الجن', englishName: 'The Jinn', transliteration: 'Al-Jinn', ayahCount: 28, isMeccan: true, pageStart: 572, pageEnd: 575),
    QuranSurah(number: 73, arabicName: 'المزمل', englishName: 'The Enshrouded One', transliteration: 'Al-Muzzammil', ayahCount: 20, isMeccan: true, pageStart: 574, pageEnd: 577),
    QuranSurah(number: 74, arabicName: 'المدثر', englishName: 'The Cloaked One', transliteration: 'Al-Muddaththir', ayahCount: 56, isMeccan: true, pageStart: 575, pageEnd: 577),
    QuranSurah(number: 75, arabicName: 'القيامة', englishName: 'The Resurrection', transliteration: 'Al-Qiyamah', ayahCount: 40, isMeccan: true, pageStart: 577, pageEnd: 578),
    QuranSurah(number: 76, arabicName: 'الإنسان', englishName: 'The Man', transliteration: 'Al-Insan', ayahCount: 31, isMeccan: false, pageStart: 578, pageEnd: 580),
    QuranSurah(number: 77, arabicName: 'المرسلات', englishName: 'The Emissaries', transliteration: 'Al-Mursalat', ayahCount: 50, isMeccan: true, pageStart: 580, pageEnd: 583),
    QuranSurah(number: 78, arabicName: 'النبأ', englishName: 'The Tidings', transliteration: "An-Naba'", ayahCount: 40, isMeccan: true, pageStart: 582, pageEnd: 583),
    QuranSurah(number: 79, arabicName: 'النازعات', englishName: 'Those Who Drag Forth', transliteration: "An-Nazi'at", ayahCount: 46, isMeccan: true, pageStart: 584, pageEnd: 585),
    QuranSurah(number: 80, arabicName: 'عبس', englishName: 'He Frowned', transliteration: "'Abasa", ayahCount: 42, isMeccan: true, pageStart: 585, pageEnd: 586),
    QuranSurah(number: 81, arabicName: 'التكوير', englishName: 'The Overthrowing', transliteration: 'At-Takwir', ayahCount: 29, isMeccan: true, pageStart: 586, pageEnd: 587),
    QuranSurah(number: 82, arabicName: 'الانفطار', englishName: 'The Cleaving', transliteration: 'Al-Infitar', ayahCount: 19, isMeccan: true, pageStart: 587, pageEnd: 587),
    QuranSurah(number: 83, arabicName: 'المطففين', englishName: 'The Defrauding', transliteration: 'Al-Mutaffifin', ayahCount: 36, isMeccan: true, pageStart: 587, pageEnd: 589),
    QuranSurah(number: 84, arabicName: 'الانشقاق', englishName: 'The Sundering', transliteration: 'Al-Inshiqaq', ayahCount: 25, isMeccan: true, pageStart: 589, pageEnd: 589),
    QuranSurah(number: 85, arabicName: 'البروج', englishName: 'The Constellations', transliteration: 'Al-Buruj', ayahCount: 22, isMeccan: true, pageStart: 590, pageEnd: 591),
    QuranSurah(number: 86, arabicName: 'الطارق', englishName: 'The Nightcomer', transliteration: 'At-Tariq', ayahCount: 17, isMeccan: true, pageStart: 591, pageEnd: 591),
    QuranSurah(number: 87, arabicName: 'الأعلى', englishName: 'The Most High', transliteration: "Al-A'la", ayahCount: 19, isMeccan: true, pageStart: 591, pageEnd: 592),
    QuranSurah(number: 88, arabicName: 'الغاشية', englishName: 'The Overwhelming', transliteration: 'Al-Ghashiyah', ayahCount: 26, isMeccan: true, pageStart: 592, pageEnd: 592),
    QuranSurah(number: 89, arabicName: 'الفجر', englishName: 'The Dawn', transliteration: 'Al-Fajr', ayahCount: 30, isMeccan: true, pageStart: 593, pageEnd: 594),
    QuranSurah(number: 90, arabicName: 'البلد', englishName: 'The City', transliteration: 'Al-Balad', ayahCount: 20, isMeccan: true, pageStart: 594, pageEnd: 594),
    QuranSurah(number: 91, arabicName: 'الشمس', englishName: 'The Sun', transliteration: 'Ash-Shams', ayahCount: 15, isMeccan: true, pageStart: 595, pageEnd: 595),
    QuranSurah(number: 92, arabicName: 'الليل', englishName: 'The Night', transliteration: 'Al-Lail', ayahCount: 21, isMeccan: true, pageStart: 595, pageEnd: 596),
    QuranSurah(number: 93, arabicName: 'الضحى', englishName: 'The Morning Hours', transliteration: 'Ad-Duha', ayahCount: 11, isMeccan: true, pageStart: 596, pageEnd: 596),
    QuranSurah(number: 94, arabicName: 'الشرح', englishName: 'The Relief', transliteration: 'Ash-Sharh', ayahCount: 8, isMeccan: true, pageStart: 596, pageEnd: 596),
    QuranSurah(number: 95, arabicName: 'التين', englishName: 'The Fig', transliteration: 'At-Tin', ayahCount: 8, isMeccan: true, pageStart: 597, pageEnd: 597),
    QuranSurah(number: 96, arabicName: 'العلق', englishName: 'The Clot', transliteration: "Al-'Alaq", ayahCount: 19, isMeccan: true, pageStart: 597, pageEnd: 597),
    QuranSurah(number: 97, arabicName: 'القدر', englishName: 'The Power', transliteration: 'Al-Qadr', ayahCount: 5, isMeccan: true, pageStart: 598, pageEnd: 598),
    QuranSurah(number: 98, arabicName: 'البينة', englishName: 'The Clear Proof', transliteration: 'Al-Bayyinah', ayahCount: 8, isMeccan: false, pageStart: 598, pageEnd: 599),
    QuranSurah(number: 99, arabicName: 'الزلزلة', englishName: 'The Earthquake', transliteration: 'Az-Zalzalah', ayahCount: 8, isMeccan: false, pageStart: 599, pageEnd: 599),
    QuranSurah(number: 100, arabicName: 'العاديات', englishName: 'The Courser', transliteration: "Al-'Adiyat", ayahCount: 11, isMeccan: true, pageStart: 599, pageEnd: 600),
    QuranSurah(number: 101, arabicName: 'القارعة', englishName: 'The Calamity', transliteration: "Al-Qari'ah", ayahCount: 11, isMeccan: true, pageStart: 600, pageEnd: 600),
    QuranSurah(number: 102, arabicName: 'التكاثر', englishName: 'The Rivalry in World Increase', transliteration: 'At-Takathur', ayahCount: 8, isMeccan: true, pageStart: 601, pageEnd: 601),
    QuranSurah(number: 103, arabicName: 'العصر', englishName: 'The Declining Day', transliteration: "Al-'Asr", ayahCount: 3, isMeccan: true, pageStart: 601, pageEnd: 601),
    QuranSurah(number: 104, arabicName: 'الهمزة', englishName: 'The Traducer', transliteration: 'Al-Humazah', ayahCount: 9, isMeccan: true, pageStart: 601, pageEnd: 602),
    QuranSurah(number: 105, arabicName: 'الفيل', englishName: 'The Elephant', transliteration: 'Al-Fil', ayahCount: 5, isMeccan: true, pageStart: 601, pageEnd: 601),
    QuranSurah(number: 106, arabicName: 'قريش', englishName: 'Quraysh', transliteration: 'Quraish', ayahCount: 4, isMeccan: true, pageStart: 602, pageEnd: 602),
    QuranSurah(number: 107, arabicName: 'الماعون', englishName: 'The Small Kindnesses', transliteration: "Al-Ma'un", ayahCount: 7, isMeccan: true, pageStart: 602, pageEnd: 602),
    QuranSurah(number: 108, arabicName: 'الكوثر', englishName: 'The Abundance', transliteration: 'Al-Kawthar', ayahCount: 3, isMeccan: true, pageStart: 602, pageEnd: 602),
    QuranSurah(number: 109, arabicName: 'الكافرون', englishName: 'The Disbelievers', transliteration: 'Al-Kafirun', ayahCount: 6, isMeccan: true, pageStart: 603, pageEnd: 603),
    QuranSurah(number: 110, arabicName: 'النصر', englishName: 'The Divine Support', transliteration: 'An-Nasr', ayahCount: 3, isMeccan: false, pageStart: 603, pageEnd: 603),
    QuranSurah(number: 111, arabicName: 'المسد', englishName: 'The Palm Fiber', transliteration: 'Al-Masad', ayahCount: 5, isMeccan: true, pageStart: 603, pageEnd: 603),
    QuranSurah(number: 112, arabicName: 'الإخلاص', englishName: 'The Sincerity', transliteration: 'Al-Ikhlas', ayahCount: 4, isMeccan: true, pageStart: 604, pageEnd: 604),
    QuranSurah(number: 113, arabicName: 'الفلق', englishName: 'The Daybreak', transliteration: 'Al-Falaq', ayahCount: 5, isMeccan: true, pageStart: 604, pageEnd: 604),
    QuranSurah(number: 114, arabicName: 'الناس', englishName: 'Mankind', transliteration: 'An-Nas', ayahCount: 6, isMeccan: true, pageStart: 604, pageEnd: 604),
  ];

  static const Map<int, String> revelationType = {
    1: _meccan, 2: _medinan, 3: _medinan, 4: _medinan, 5: _medinan,
    6: _meccan, 7: _meccan, 8: _medinan, 9: _medinan, 10: _meccan,
    11: _meccan, 12: _meccan, 13: _medinan, 14: _meccan, 15: _meccan,
    16: _meccan, 17: _meccan, 18: _meccan, 19: _meccan, 20: _meccan,
    21: _meccan, 22: _medinan, 23: _meccan, 24: _medinan, 25: _meccan,
    26: _meccan, 27: _meccan, 28: _meccan, 29: _meccan, 30: _meccan,
    31: _meccan, 32: _meccan, 33: _medinan, 34: _meccan, 35: _meccan,
    36: _meccan, 37: _meccan, 38: _meccan, 39: _meccan, 40: _meccan,
    41: _meccan, 42: _meccan, 43: _meccan, 44: _meccan, 45: _meccan,
    46: _meccan, 47: _medinan, 48: _medinan, 49: _medinan, 50: _meccan,
    51: _meccan, 52: _meccan, 53: _meccan, 54: _meccan, 55: _medinan,
    56: _meccan, 57: _medinan, 58: _medinan, 59: _medinan, 60: _medinan,
    61: _medinan, 62: _medinan, 63: _medinan, 64: _medinan, 65: _medinan,
    66: _medinan, 67: _meccan, 68: _meccan, 69: _meccan, 70: _meccan,
    71: _meccan, 72: _meccan, 73: _meccan, 74: _meccan, 75: _meccan,
    76: _medinan, 77: _meccan, 78: _meccan, 79: _meccan, 80: _meccan,
    81: _meccan, 82: _meccan, 83: _meccan, 84: _meccan, 85: _meccan,
    86: _meccan, 87: _meccan, 88: _meccan, 89: _meccan, 90: _meccan,
    91: _meccan, 92: _meccan, 93: _meccan, 94: _meccan, 95: _meccan,
    96: _meccan, 97: _meccan, 98: _medinan, 99: _medinan, 100: _meccan,
    101: _meccan, 102: _meccan, 103: _meccan, 104: _meccan, 105: _meccan,
    106: _meccan, 107: _meccan, 108: _meccan, 109: _meccan, 110: _medinan,
    111: _meccan, 112: _meccan, 113: _meccan, 114: _meccan,
  };

  /// 1-based mushaf page on which [number] starts (standard Madani edition).
  static int pageOf(int number) => byNumber(number)?.pageStart ?? 1;

  static QuranSurah? byNumber(int number) {
    if (number < 1 || number > surahs.length) return null;
    return surahs[number - 1];
  }

  static String revelationLabel(int number) =>
      revelationType[number] ?? _meccan;

  /// Full ayah text (Uthmani script) bundled for the short surahs so karaoke
  /// and reading work offline. Larger surahs are fetched from the API.
  static const Map<int, List<String>> bundledAyahs = {
    1: [
      'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
      'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ',
      'ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
      'مَـٰلِكِ يَوْمِ ٱلدِّينِ',
      'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
      'ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ',
      'صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ',
    ],
    103: [
      'وَٱلْعَصْرِ',
      'إِنَّ ٱلْإِنسَـٰنَ لَفِى خُسْرٍ',
      'إِلَّا ٱلَّذِينَ ءَامَنُوا۟ وَعَمِلُوا۟ ٱلصَّـٰلِحَـٰتِ وَتَوَاصَوْا۟ بِٱلْحَقِّ وَتَوَاصَوْا۟ بِٱلصَّبْرِ',
    ],
    104: [
      'وَيْلٌ لِّكُلِّ هُمَزَةٍ لُّمَزَةٍ',
      'ٱلَّذِى جَمَعَ مَالًا وَعَدَّدَهُۥ',
      'يَحْسَبُ أَنَّ مَالَهُۥٓ أَخْلَدَهُۥ',
      'كَلَّا ۖ لَيُنۢبَذَنَّ فِى ٱلْحُطَمَةِ',
      'وَمَآ أَدْرَىٰكَ مَا ٱلْحُطَمَةُ',
      'نَارُ ٱللَّهِ ٱلْمُوقَدَةُ',
      'ٱلَّتِى تَطَّلِعُ عَلَى ٱلْأَفْـِٔدَةِ',
      'إِنَّهَا عَلَيْهِم مُّؤْصَدَةٌ',
      'فِى عَمَدٍ مُّمَدَّدَةٍ',
    ],
    105: [
      'أَلَمْ تَرَ كَيْفَ فَعَلَ رَبُّكَ بِأَصْحَـٰبِ ٱلْفِيلِ',
      'أَلَمْ يَجْعَلْ كَيْدَهُمْ فِى تَضْلِيلٍ',
      'وَأَرْسَلَ عَلَيْهِمْ طَيْرًا أَبَابِيلَ',
      'تَرْمِيهِم بِحِجَارَةٍ مِّن سِجِّيلٍ',
      'فَجَعَلَهُمْ كَعَصْفٍ مَّأْكُولٍۭ',
    ],
    106: [
      'لِإِيلَـٰفِ قُرَيْشٍ',
      'إِۦلَـٰفِهِمْ رِحْلَةَ ٱلشِّتَآءِ وَٱلصَّيْفِ',
      'فَلْيَعْبُدُوا۟ رَبَّ هَـٰذَا ٱلْبَيْتِ',
      'ٱلَّذِىٓ أَطْعَمَهُم مِّن جُوعٍ وَءَامَنَهُم مِّنْ خَوْفٍۭ',
    ],
    107: [
      'أَرَءَيْتَ ٱلَّذِى يُكَذِّبُ بِٱلدِّينِ',
      'فَذَٰلِكَ ٱلَّذِى يَدُعُّ ٱلْيَتِيمَ',
      'وَلَا يَحُضُّ عَلَىٰ طَعَامِ ٱلْمِسْكِينِ',
      'فَوَيْلٌ لِّلْمُصَلِّينَ',
      'ٱلَّذِينَ هُمْ عَن صَلَاتِهِمْ سَاهُونَ',
      'ٱلَّذِينَ هُمْ يُرَآءُونَ',
      'وَيَمْنَعُونَ ٱلْمَاعُونَ',
    ],
    108: [
      'إِنَّآ أَعْطَيْنَـٰكَ ٱلْكَوْثَرَ',
      'فَصَلِّ لِرَبِّكَ وَٱنْحَرْ',
      'إِنَّ شَانِئَكَ هُوَ ٱلْأَبْتَرُ',
    ],
    109: [
      'قُلْ يَـٰٓأَيُّهَا ٱلْكَـٰفِرُونَ',
      'لَآ أَعْبُدُ مَا تَعْبُدُونَ',
      'وَلَآ أَنتُمْ عَـٰبِدُونَ مَآ أَعْبُدُ',
      'وَلَآ أَنَا۠ عَابِدٌ مَّا عَبَدتُّمْ',
      'وَلَآ أَنتُمْ عَـٰبِدُونَ مَآ أَعْبُدُ',
      'لَكُمْ دِينُكُمْ وَلِىَ دِينِ',
    ],
    110: [
      'إِذَا جَآءَ نَصْرُ ٱللَّهِ وَٱلْفَتْحُ',
      'وَرَأَيْتَ ٱلنَّاسَ يَدْخُلُونَ فِى دِينِ ٱللَّهِ أَفْوَاجًا',
      'فَسَبِّحْ بِحَمْدِ رَبِّكَ وَٱسْتَغْفِرْهُ ۚ إِنَّهُۥ كَانَ تَوَّابًۢا',
    ],
    111: [
      'تَبَّتْ يَدَآ أَبِى لَهَبٍ وَتَبَّ',
      'مَآ أَغْنَىٰ عَنْهُ مَالُهُۥ وَمَا كَسَبَ',
      'سَيَصْلَىٰ نَارًا ذَاتَ لَهَبٍ',
      'وَٱمْرَأَتُهُۥ حَمَّالَةَ ٱلْحَطَبِ',
      'فِى جِيدِهَا حَبْلٌ مِّن مَّسَدٍۭ',
    ],
    112: [
      'قُلْ هُوَ ٱللَّهُ أَحَدٌ',
      'ٱللَّهُ ٱلصَّمَدُ',
      'لَمْ يَلِدْ وَلَمْ يُولَدْ',
      'وَلَمْ يَكُن لَّهُۥ كُفُوًا أَحَدٌۢ',
    ],
    113: [
      'قُلْ أَعُوذُ بِرَبِّ ٱلْفَلَقِ',
      'مِن شَرِّ مَا خَلَقَ',
      'وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ',
      'وَمِن شَرِّ ٱلنَّفَّـٰثَـٰتِ فِى ٱلْعُقَدِ',
      'وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ',
    ],
    114: [
      'قُلْ أَعُوذُ بِرَبِّ ٱلنَّاسِ',
      'مَلِكِ ٱلنَّاسِ',
      'إِلَـٰهِ ٱلنَّاسِ',
      'مِن شَرِّ ٱلْوَسْوَاسِ ٱلْخَنَّاسِ',
      'ٱلَّذِى يُوَسْوِسُ فِى صُدُورِ ٱلنَّاسِ',
      'مِنَ ٱلْجِنَّةِ وَٱلنَّاسِ',
    ],
  };

  static List<String>? bundledAyahsFor(int number) =>
      bundledAyahs[number];
}
