import '../models/admin_config.dart';

/// Abstraction for admin-configurable runtime settings.
/// Local MVP persists on-device; later swap to a backend config source.
abstract class AdminConfigService {
  Future<AdminConfig> load();

  Future<void> save(AdminConfig config);
}
