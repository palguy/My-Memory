// backup_to_drive.dart
import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/memory_item.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class BackupHelper {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/drive.file'],
  );

  Future<void> backupToDrive() async {
    try {
      GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      if (account == null) {
        account = await _googleSignIn.signIn();
        if (account == null) return; // المستخدم رفض تسجيل الدخول
      }

      final authHeaders = await account.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      final box = Hive.box<MemoryItem>('memoryBox');
      final items = box.values.toList();
      final jsonList =
          items
              .map(
                (item) => {
                  'question': item.question,
                  'answer': item.answer,
                  'imagePath': item.imagePath,
                  'category': item.category,
                },
              )
              .toList();

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/memory_backup.json';
      final file = File(filePath);
      await file.writeAsString(jsonEncode(jsonList));

      final fileToUpload = await driveApi.files.create(
        drive.File()
          ..name = 'memory_backup.json'
          ..parents = ['appDataFolder'],
        uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
      );

      // تحديث الملف إذا وجد ملف بنفس الاسم في Drive root
      final existingFiles = await driveApi.files.list(
        q: "name = 'memory_backup.json'",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (existingFiles.files != null && existingFiles.files!.isNotEmpty) {
        final fileId = existingFiles.files!.first.id;
        await driveApi.files.update(
          drive.File(),
          fileId!,
          uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
        );
      }
    } catch (e) {
      print('فشل النسخ الاحتياطي: $e');
    }
  }
}
