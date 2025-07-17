// lib/pages/backup_restore_screen.dart
import 'dart:io';
import 'dart:typed_data'; // <--- أضف هذا الاستيراد
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:my_memory/models/memory_item.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive_io.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  String _message = '';

  Future<String> _getHivePath() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    return appDocumentDir.path;
  }

  // --- دالة النسخ الاحتياطي (Backup) ---
  Future<void> _performBackup() async {
    setState(() {
      _message = 'جاري إنشاء النسخة الاحتياطية...';
    });
    try {
      final hivePath = await _getHivePath();
      final encoder = ZipFileEncoder();
      final tempDir = await getTemporaryDirectory();
      final zipFileName =
          'HiveBackup_${DateTime.now().millisecondsSinceEpoch}.zip';
      final zipFilePath = p.join(tempDir.path, zipFileName);

      encoder.create(zipFilePath);

      final hiveFiles =
          await Directory(hivePath)
              .list()
              .where(
                (item) =>
                    item.path.endsWith('.hive') || item.path.endsWith('.lock'),
              )
              .toList();

      if (hiveFiles.isEmpty) {
        setState(() {
          _message = 'لا توجد بيانات لحفظها في Hive.';
        });
        encoder.close();
        return;
      }

      for (final file in hiveFiles) {
        final fileName = p.basename(file.path);
        encoder.addFile(File(file.path), fileName);
      }

      encoder.close(); // إغلاق ملف ZIP بعد إضافة جميع الملفات

      // اقرأ محتويات ملف ZIP كبايتات
      final Uint8List zipBytes = await File(zipFilePath).readAsBytes();

      // السماح للمستخدم باختيار مكان حفظ ملف ZIP وتمرير البايتات مباشرةً
      String? resultPath = await FilePicker.platform.saveFile(
        dialogTitle: 'اختر مكانًا لحفظ النسخة الاحتياطية',
        fileName: zipFileName, // اسم الملف المقترح
        type: FileType.custom,
        allowedExtensions: ['zip'],
        bytes: zipBytes, // <--- تمرير البايتات هنا مباشرةً
      );

      // قم بحذف الملف المؤقت بعد أن يتم حفظه بواسطة FilePicker
      await File(zipFilePath).delete();

      if (resultPath == null) {
        setState(() {
          _message = 'تم إلغاء عملية النسخ الاحتياطي.';
        });
        return;
      }

      setState(() {
        _message = '✅ تم إنشاء نسخة احتياطية بنجاح في: \n$resultPath';
      });
    } catch (e) {
      setState(() {
        _message = '❌ فشل إنشاء النسخة الاحتياطية: $e';
      });
      debugPrint('Backup error: $e');
    }
  }

  // --- دالة الاستعادة (Restore) ---
  Future<void> _performRestore() async {
    setState(() {
      _message = 'جاري استعادة البيانات...';
    });
    try {
      String? selectedFilePath = await FilePicker.platform
          .pickFiles(
            type: FileType.custom,
            allowedExtensions: ['zip'],
            dialogTitle: 'اختر ملف النسخة الاحتياطية (.zip)',
          )
          .then((result) => result?.files.single.path);

      if (selectedFilePath == null) {
        setState(() {
          _message = 'تم إلغاء عملية الاستعادة.';
        });
        return;
      }

      final hivePath = await _getHivePath();

      await Hive.close();

      final existingHiveFiles =
          await Directory(hivePath)
              .list()
              .where(
                (item) =>
                    item.path.endsWith('.hive') || item.path.endsWith('.lock'),
              )
              .toList();
      for (final file in existingHiveFiles) {
        try {
          await file.delete();
        } catch (e) {
          debugPrint('Could not delete existing Hive file ${file.path}: $e');
        }
      }

      final bytes = File(selectedFilePath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          File(p.join(hivePath, filename))
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        }
      }

      await Hive.openBox<MemoryItem>('memoryBox');

      setState(() {
        _message =
            '✅ تم استعادة البيانات بنجاح. قد تحتاج إلى إعادة تشغيل التطبيق.';
      });
    } catch (e) {
      setState(() {
        _message = '❌ فشلت عملية الاستعادة: $e';
      });
      debugPrint('Restore error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('النسخ الاحتياطي والاستعادة'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushNamed(context, '/');
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _performBackup,
                icon: const Icon(Icons.backup),
                label: const Text('إنشاء نسخة احتياطية للبيانات'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _performRestore,
                icon: const Icon(Icons.restore),
                label: const Text('استعادة البيانات من نسخة احتياطية'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.orange,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      _message.startsWith('✅')
                          ? Colors.green
                          : (_message.startsWith('❌')
                              ? Colors.red
                              : Colors.black),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ملاحظات هامة:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textDirection: TextDirection.rtl,
              ),
              const Text(
                '- تأكد من أن التطبيق لديه أذونات الوصول إلى التخزين (Storage permissions) للنسخ الاحتياطي والاستعادة.',
                textDirection: TextDirection.rtl,
              ),
              const Text(
                '- عند الاستعادة، سيتم استبدال البيانات الحالية بالبيانات من النسخة الاحتياطية.',
                textDirection: TextDirection.rtl,
              ),
              const Text(
                '- يفضل إعادة تشغيل التطبيق بالكامل بعد الاستعادة لضمان تحميل البيانات الجديدة بشكل صحيح.',
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
