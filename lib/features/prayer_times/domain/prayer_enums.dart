enum PrayerCalculationMethod {
  karachi,
  makkah,
  egypt,
  isna,
  mwl,
  tehran, // Often used for Shia
  custom,
}

enum Madhab {
  hanafi,
  shafi, // Also Maliki, Hanbali
}

enum Sect { sunni, shia, ahleHadis }

extension SectExtension on Sect {
  String getFiqaLabel(Madhab madhab) {
    switch (this) {
      case Sect.shia:
        return 'Fiqa-e-Jafria';
      case Sect.sunni:
        return madhab == Madhab.hanafi ? 'Fiqa-e-Hanafia' : 'Fiqa-e-Shafii';
      case Sect.ahleHadis:
        return 'Ahl-e-Hadis';
    }
  }
}
