enum TimingMode { calculation, calculationWithOffset, mosqueManual }

class PrayerTimeModel {
  final DateTime calculated;
  final int offsetMinutes;
  final DateTime finalTime;
  final String prayerName;

  PrayerTimeModel({
    required this.calculated,
    required this.offsetMinutes,
    required this.finalTime,
    required this.prayerName,
  });

  Map<String, dynamic> toJson() => {
    'calculated': calculated.toIso8601String(),
    'offsetMinutes': offsetMinutes,
    'finalTime': finalTime.toIso8601String(),
    'prayerName': prayerName,
  };

  factory PrayerTimeModel.fromJson(Map<String, dynamic> json) =>
      PrayerTimeModel(
        calculated: DateTime.parse(json['calculated']),
        offsetMinutes: json['offsetMinutes'],
        finalTime: DateTime.parse(json['finalTime']),
        prayerName: json['prayerName'],
      );
}
