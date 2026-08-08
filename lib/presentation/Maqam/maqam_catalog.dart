import 'package:flutter/material.dart';
import 'package:soundora/core/services/maqam_detector.dart';

/// Metadata for the eight maqamat supported by the detector and the catalog.
/// [key] is the canonical English id used by both the DB (`song_maqams`) and
/// the detector templates.
class MaqamInfo {
  final String key;
  final String arabicName;
  final String englishName;
  final String description;
  final String jins;
  final Color color;
  final IconData icon;

  const MaqamInfo({
    required this.key,
    required this.arabicName,
    required this.englishName,
    required this.description,
    required this.jins,
    required this.color,
    required this.icon,
  });

  static const List<MaqamInfo> all = [
    MaqamInfo(
      key: 'Rast',
      arabicName: 'راست',
      englishName: 'Rast',
      description: 'أشهر مقامات الموسيقى العربية وأكثرها جلالاً، يمنح اللحن إحساساً مهيباً ومستقراً.',
      jins: 'جنس راست: ¾ - ¾ - 1',
      color: Color(0xFFF2B33D),
      icon: Icons.star,
    ),
    MaqamInfo(
      key: 'Nahawand',
      arabicName: 'نهاوند',
      englishName: 'Nahawand',
      description: 'مقام حزين وأنيق على السلم الصغير، شائع جداً في الأغاني والقصائد.',
      jins: 'السلم الصغير الطبيعي',
      color: Color(0xFFA78BFA),
      icon: Icons.music_note,
    ),
    MaqamInfo(
      key: 'Ajam',
      arabicName: 'عجم',
      englishName: 'Ajam',
      description: 'مقام مبهج ومشرق على السلم الكبير، يبعث على التفاؤل والفرح.',
      jins: 'السلم الكبير',
      color: Color(0xFFFB923C),
      icon: Icons.wb_sunny,
    ),
    MaqamInfo(
      key: 'Hijaz',
      arabicName: 'حجاز',
      englishName: 'Hijaz',
      description: 'مقام درامي شجيّ بفاصل نصف-واحد-نصف الشهير، يعطي طابعاً شرقياً مميزاً ومؤثراً.',
      jins: 'جنس حجاز: ½ - 1½ - ½',
      color: Color(0xFFFB7185),
      icon: Icons.local_fire_department,
    ),
    MaqamInfo(
      key: 'Saba',
      arabicName: 'صبا',
      englishName: 'Saba',
      description: 'مقام حزين عميق بنغمة الفراغ المميزة، من أكثر المقامات تأثيراً في الشجن.',
      jins: 'جنس صبا: ¾ - ¾ - ½',
      color: Color(0xFF2DD4BF),
      icon: Icons.water_drop,
    ),
    MaqamInfo(
      key: 'Kurd',
      arabicName: 'كرد',
      englishName: 'Kurd',
      description: 'مقام غامض وحميم على السلم الفريجي، يمنح اللحن لوناً عاطفياً دافئاً.',
      jins: 'السلم الفريجي',
      color: Color(0xFF60A5FA),
      icon: Icons.eco,
    ),
    MaqamInfo(
      key: 'Sikah',
      arabicName: 'سيكاه',
      englishName: 'Sikah',
      description: 'مقام رشيق يعتمد على ربع النغمة الشهير، من رموز الهوية الموسيقية الشرقية.',
      jins: 'جنس سيكاه: ¾ - 1',
      color: Color(0xFFF472B6),
      icon: Icons.blur_on,
    ),
    MaqamInfo(
      key: 'Bayati',
      arabicName: 'بياتي',
      englishName: 'Bayati',
      description: 'المقام الأكثر شعبية في الغناء العربي، عاطفي ودافئ وهو أساس معظم الأغاني الشرقية.',
      jins: 'جنس بياتي: ¾ - ¾ - 1',
      color: Color(0xFF4ADE80),
      icon: Icons.favorite,
    ),
  ];

  static MaqamInfo? byKey(String? key) {
    if (key == null || key.isEmpty) return null;
    for (final info in all) {
      if (info.key == key || info.arabicName == key || info.englishName == key) {
        return info;
      }
    }
    return null;
  }

  /// Maps a live [MaqamResult] from the detector to its catalog entry.
  static MaqamInfo? fromResult(MaqamResult? result) {
    if (result == null) return null;
    return byKey(result.englishName);
  }
}
