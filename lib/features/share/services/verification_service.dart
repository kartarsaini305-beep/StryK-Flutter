import '../../streak/models/daily_record.dart';

abstract class VerificationService {
  DailyRecord stamp(DailyRecord record);

  String urlFor(String verificationId);

  DailyRecord? findById(Map<String, DailyRecord> records, String verificationId);
}
