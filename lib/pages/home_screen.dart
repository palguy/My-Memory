import 'package:flutter/material.dart';
import 'package:my_memory/models/backup_to_drive.dart';
import 'package:my_memory/models/restore_from_drive.dart';
import 'package:my_memory/pages/backup_restore_screen.dart';
import 'package:my_memory/pages/import_json_screen.dart';

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
              child: CircleAvatar(
                radius: 100,
                backgroundImage: AssetImage(
                  'assets/images/my_memory.png',
                  //fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 25),
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
                'نسخة احتياطية Drive',
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
            //  backup
            ListTile(
              leading: const Icon(Icons.file_copy, color: Colors.white),
              title: const Text(
                'back up data',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BackupRestoreScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.file_upload, color: Colors.white),
              title: const Text(
                'استيراد ملف JSON',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ImportJsonScreen(),
                  ),
                );
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
