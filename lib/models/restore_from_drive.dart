import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:my_memory/models/memory_item.dart';

class RestoreHelper {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/drive.file'],
  );

  Future<void> restoreFromDrive() async {
    try {
      GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      if (account == null) {
        account = await _googleSignIn.signIn(); // عرض نافذة تسجيل الدخول
        if (account == null) return; // المستخدم ألغى تسجيل الدخول
      }

      final authHeaders = await account.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      // البحث عن ملف النسخة الاحتياطية
      final fileList = await driveApi.files.list(
        q: "name='memory_backup.json'",
      );
      if (fileList.files == null || fileList.files!.isEmpty) {
        throw Exception('لا توجد نسخة احتياطية على Drive');
      }

      final fileId = fileList.files!.first.id!;
      final media =
          await driveApi.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      final List<int> dataBytes = [];
      await for (final chunk in media.stream) {
        dataBytes.addAll(chunk);
      }

      final jsonString = utf8.decode(dataBytes);
      final List<dynamic> jsonList = jsonDecode(jsonString);

      // حفظ البيانات في Hive
      final box = Hive.box('memoryBox');
      await box.clear();
      for (var itemMap in jsonList) {
        final memoryItem = MemoryItem(
          category: itemMap['category'],
          question: itemMap['question'],
          answer: itemMap['answer'],
          imagePath: itemMap['imagePath'],
        );
        await box.add(memoryItem);
      }
    } catch (e) {
      debugPrint('Restore failed: $e');
      rethrow;
    }
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
