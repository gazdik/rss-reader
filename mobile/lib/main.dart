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
    return ChangeNotifierProvider<RssStore>.value(
      value: store,
      child: MaterialApp(
        title: 'RSS Reader',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
