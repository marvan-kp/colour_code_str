import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceService {
  static const String _deviceIdKey = 'unique_device_id';

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_deviceIdKey);

    if (id != null) return id;

    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        id = androidInfo.id; // Unique ID on Android
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        id = iosInfo.identifierForVendor; // Unique ID on iOS
      }
    } catch (e) {
      debugPrint('Failed to get hardware device ID: $e');
    }

    // Fallback to UUID if hardware ID fails
    id ??= const Uuid().v4();
    await prefs.setString(_deviceIdKey, id);
    return id;
  }
}
