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

      drawer: Drawer(
        backgroundColor: Colors.grey[900],
        child: Column(
          children: [
            // logo
            // DrawerHeader(child: Image.asset('lib/images/my_memory.png')),
            DrawerHeader(
              decoration: const BoxDecoration(
                color:
                    Colors.transparent, // اختياري: لو حابب تبقي الخلفية شفافة
              ),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: Image.asset(
                  'lib/images/my_memory_nav.png',
                  fit: BoxFit.cover, // لتملأ الصورة كامل المساحة
                ),
              ),
            ),

            // other pages
            Padding(
              padding: const EdgeInsets.only(left: 25),
              child: ListTile(
                leading: Icon(Icons.home, color: Colors.white),
                title: Text(
                  'Home',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 25),
              child: ListTile(
                leading: Icon(Icons.info, color: Colors.white),
                title: Text(
                  'About',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Expanded ليدفع الـ Logout لأسفل
            Expanded(child: Container()),

            // Logout في الأسفل
            Padding(
              padding: const EdgeInsets.only(left: 25, bottom: 25),
              child: ListTile(
                leading: Icon(Icons.logout, color: Colors.white),
                title: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  // Add logout functionality here
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
