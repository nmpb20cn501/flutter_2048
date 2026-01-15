import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/board_adapter.dart';
import 'models/settings_adapter.dart';
import 'splash_screen.dart';

void main() async {
  //Allow only portrait mode on Android & iOS
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp],
  );
  //Make sure Hive is initialized first and only after register the adapter.
  await Hive.initFlutter();
  Hive.registerAdapter(BoardAdapter());
  Hive.registerAdapter(SettingsAdapter());
  runApp(const ProviderScope(
    child: MaterialApp(
      title: '2048',
      home: SplashScreen(),
    ),
  ));
}
