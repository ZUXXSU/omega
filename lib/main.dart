import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'core/utils/logger.dart';
import 'shared/database/omega_database.dart';
import 'shared/services/notification_service.dart';
import 'shared/services/storage_service.dart';
import 'shared/services/background_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.init();

  await Future.wait([
    Firebase.initializeApp(),
    StorageService.initialize(),
  ]);

  await OmegaDatabase.getInstance();

  await NotificationService.initialize();
  await BackgroundSyncService.initialize();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const ProviderScope(child: OmegaApp()));
}
