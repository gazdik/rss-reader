import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/rss_store.dart';
import 'services/db_service.dart';
import 'services/rss_service.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbService = DbService.instance;
  final rssService = RssService(dbService: dbService);
  final store = RssStore(dbService: dbService, rssService: rssService);

  await store.init();

  runApp(RssReaderApp(store: store));
}

class RssReaderApp extends StatelessWidget {
  final RssStore store;

  const RssReaderApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final colorSchemeLight = ColorScheme.fromSeed(
      seedColor: Colors.deepOrange,
      brightness: Brightness.light,
    );

    final colorSchemeDark = ColorScheme.fromSeed(
      seedColor: Colors.deepOrange,
      brightness: Brightness.dark,
    );

    return ChangeNotifierProvider<RssStore>.value(
      value: store,
      child: MaterialApp(
        title: 'RSS Reader',
        themeMode: ThemeMode.system,
        theme: ThemeData(
          colorScheme: colorSchemeLight,
          useMaterial3: true,
          scaffoldBackgroundColor: colorSchemeLight.surface,
          appBarTheme: AppBarTheme(
            backgroundColor: colorSchemeLight.surface,
            foregroundColor: colorSchemeLight.onSurface,
            elevation: 0,
            centerTitle: false,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: colorSchemeDark,
          useMaterial3: true,
          scaffoldBackgroundColor: colorSchemeDark.surface,
          appBarTheme: AppBarTheme(
            backgroundColor: colorSchemeDark.surface,
            foregroundColor: colorSchemeDark.onSurface,
            elevation: 0,
            centerTitle: false,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
