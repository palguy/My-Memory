import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تطبيق تقوية الذاكرة')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('إضافة معلومة'),
              onPressed: () => Navigator.pushNamed(context, '/add'),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text('عرض المعلومات'),
              onPressed: () => Navigator.pushNamed(context, '/view'),
            ),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.quiz),
              label: const Text('ابدأ الاختبار'),
              onPressed: () => Navigator.pushNamed(context, '/quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
