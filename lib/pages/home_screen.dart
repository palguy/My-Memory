import 'package:flutter/material.dart';
import 'package:my_memory/models/backup_to_drive.dart';
import 'package:my_memory/models/restore_from_drive.dart';

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
            DrawerHeader(
              child: Image.asset(
                'lib/images/my_memory_nav.png',
                fit: BoxFit.cover,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.white),
              title: const Text(
                'الرئيسية',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.backup, color: Colors.white),
              title: const Text(
                'نسخة احتياطية على Drive',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(context);
                final backupHelper = BackupHelper();
                await backupHelper.backupToDrive();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم النسخ الاحتياطي بنجاح')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.white),
              title: const Text(
                'استعادة من Drive',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(context);
                final restoreHelper = RestoreHelper();
                await restoreHelper.restoreFromDrive();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تمت الاستعادة من النسخة الاحتياطية'),
                    ),
                  );
                }
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(left: 25, bottom: 25),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: const Text(
                  'تسجيل الخروج',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
