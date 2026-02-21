// lib/data/duas.dart

class DuaContent {
  final String title;
  final String arabic;
  final String english;
  final String urdu;
  final String reference;

  const DuaContent({
    required this.title,
    required this.arabic,
    required this.english,
    required this.urdu,
    required this.reference,
  });
}

class Duas {
  /// Sehri (Intention - Niyyah)
  static const DuaContent sehri = DuaContent(
    title: "Sehri Dua",
    arabic: "وَبِصَوْمِ غَدٍ نَّوَيْتُ مِنْ شَهْرِ رَمَضَانَ",
    english:
        "I intend to keep the fast for tomorrow in the month of Ramadan.",
    urdu:
        "میں نے رمضان کے مہینے کے کل کے روزے کی نیت کی۔",
    reference: "Intention (Niyyah)",
  );

  /// Iftar Dua
  static const DuaContent iftar = DuaContent(
    title: "Iftar Dua",
    arabic:
        "اللَّهُمَّ إِنِّي لَكَ صُمْتُ وَبِكَ آمَنْتُ وَعَلَيْكَ تَوَكَّلْتُ وَعَلَىٰ رِزْقِكَ أَفْطَرْتُ",
    english:
        "O Allah, for You I have fasted, in You I believe, upon You I rely, and with Your provision I break my fast.",
    urdu:
        "اے اللہ! میں نے تیرے لیے روزہ رکھا، تجھ پر ایمان لایا، تجھ پر بھروسہ کیا اور تیرے رزق سے افطار کیا۔",
    reference: "Abu Dawood",
  );
}
