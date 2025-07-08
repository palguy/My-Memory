// main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_memory/pages/add_info_screen.dart';
import 'package:my_memory/pages/home_screen.dart';
import 'package:my_memory/pages/quiz_screen.dart';
import 'package:my_memory/pages/view_saved_info_screen.dart';
import 'models/memory_item.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(MemoryItemAdapter());
  await Hive.openBox<String>('categoriesBox'); // ⬅️ ضروري فتح box التصنيفات
  await Hive.openBox<MemoryItem>('memoryBox');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Memory Trainer',
      theme: ThemeData(primarySwatch: Colors.indigo),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/add': (context) => const AddInfoScreen(),
        '/quiz': (context) => const QuizScreen(),
        '/view': (context) => const ViewSavedInfoScreen(),
      },
    );
  }
}


/*  TODO: 
خيارات متعددة للاجابة بدل ادخال نص كتابي
تصميم عصري	flutter_hooks + animations
دعم النسخ الاحتياطي على Google Drive أو iCloud.





*/