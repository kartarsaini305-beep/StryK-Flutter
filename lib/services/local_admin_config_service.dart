import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../features/admin/models/admin_config.dart';
import '../features/admin/services/admin_config_service.dart';

class LocalAdminConfigService implements AdminConfigService {
  LocalAdminConfigService({this._prefs});

  SharedPreferences? _prefs;
  static const _key = 'admin_config';

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<AdminConfig> load() async {
    await init();
    final raw = _prefs!.getString(_key);
    if (raw == null || raw.isEmpty) return const AdminConfig();
    return AdminConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(AdminConfig config) async {
    await init();
    await _prefs!.setString(_key, jsonEncode(config.toJson()));
  }
}
