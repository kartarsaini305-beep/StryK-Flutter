import '../features/share/services/verification_service.dart';
import '../features/streak/models/daily_record.dart';

class MockVerificationService implements VerificationService {
  static const host = 'https://stryk.app/verify';

  @override
  String urlFor(String verificationId) => '$host/$verificationId';

  @override
  DailyRecord stamp(DailyRecord record) {
    final id = record.verificationId ?? _idFor(record);
    return record.copyWith(
      id: record.id ?? id,
      verificationId: id,
      verificationUrl: urlFor(id),
    );
  }

  @override
  DailyRecord? findById(
    Map<String, DailyRecord> records,
    String verificationId,
  ) {
    for (final record in records.values) {
      if (record.verificationId == verificationId) return record;
    }
    return null;
  }

  String _idFor(DailyRecord record) {
    final seed =
        '${record.dateKey}|${record.gymId ?? ''}|${record.arrivalTime?.toIso8601String() ?? ''}';
    var hash = 2166136261;
    for (final unit in seed.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0xFFFFFF;
    }
    return 'SK-${hash.toRadixString(16).toUpperCase().padLeft(6, '0')}';
  }
}
