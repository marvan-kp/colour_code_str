import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

import 'local_db/local_db_service.dart';
import 'services/connectivity_service.dart';
import 'services/firestore_service.dart';
import 'services/sync_service.dart';
import 'providers/order_provider.dart';
import 'screens/order_list_screen.dart';
import 'screens/pin_lock_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set High Refresh Rate (120Hz+) if supported on Android
  if (Platform.isAndroid) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
      debugPrint('🚀 120Hz High Refresh Rate Enabled');
    } catch (e) {
      debugPrint('⚠️ Could not set high refresh rate: $e');
    }
  }

  // Firebase initialization with generated options for multi-device sync
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase connected — sync enabled');
  } catch (e) {
    debugPrint('⚠️ Firebase not available — running offline: $e');
  }

  // Local database init
  final localDb = LocalDbService();
  await localDb.init();

  // Services
  final connectivity = ConnectivityService();
  final firestore = FirestoreService();
  final syncService = SyncService(localDb, firestore, connectivity);

  // Get device ID
  String deviceId = 'unknown';
  try {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final android = await info.androidInfo;
      deviceId = android.id;
    } else if (Platform.isIOS) {
      final ios = await info.iosInfo;
      deviceId = ios.identifierForVendor ?? 'ios-unknown';
    }
  } catch (_) {}

  runApp(
    ChangeNotifierProvider(
      create: (_) => OrderProvider(
        localDb: localDb,
        syncService: syncService,
        connectivity: connectivity,
        deviceId: deviceId,
      ),
      child: const PaintShopApp(),
    ),
  );
}

class PaintShopApp extends StatelessWidget {
  const PaintShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BRIGHTWAY SALES',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050B0E),
        colorScheme: ColorScheme.dark(
          primary: Colors.cyanAccent,
          surface: const Color(0xFF0D1F2D),
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.white.withOpacity(0.06),
          labelStyle: GoogleFonts.outfit(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: const TextStyle(color: Colors.white54),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const PinLockScreen(
        child: Scaffold(
          body: OrderListScreen(),
        ),
      ),
    );
  }
}
