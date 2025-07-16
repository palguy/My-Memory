import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/memory_item.dart';
import 'package:uuid/uuid.dart'; // Add this import

class PreviewImportScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String category;

  const PreviewImportScreen({
    super.key,
    required this.items,
    required this.category,
  });

  @override
  State<PreviewImportScreen> createState() => _PreviewImportScreenState();
}

class _PreviewImportScreenState extends State<PreviewImportScreen> {
  bool _isImporting = false;
  late List<Map<String, dynamic>> _previewItems;
  final Uuid _uuid = const Uuid(); // Initialize Uuid

  @override
  void initState() {
    super.initState();
    _previewItems = List.from(widget.items);
  }

  Future<String?> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();

        // Extract original file extension if available
        String fileExtension = '';
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          final lastSegment = pathSegments.last;
          final dotIndex = lastSegment.lastIndexOf('.');
          if (dotIndex != -1 && dotIndex < lastSegment.length - 1) {
            fileExtension = lastSegment.substring(dotIndex); // Includes the dot
          }
        }

        // Generate a unique filename using UUID and original extension
        final uniqueFilename = '${_uuid.v4()}$fileExtension';
        final file = File('${dir.path}/$uniqueFilename');

        await file.writeAsBytes(response.bodyBytes);
        debugPrint('Image downloaded to: ${file.path}'); // Debug print
        return file.path;
      }
    } catch (e) {
      debugPrint('Error downloading image from $url: $e');
    }
    return null;
  }

  Future<void> _saveData() async {
    setState(() {
      _isImporting = true;
    });

    final box = Hive.box<MemoryItem>('memoryBox');
    List<MemoryItem> importedMemoryItems = [];

    for (int i = 0; i < widget.items.length; i++) {
      var item = widget.items[i];
      String? imagePath;

      if (item['imageUrl'] != null &&
          item['imageUrl'].toString().startsWith('http')) {
        imagePath = await _downloadImage(item['imageUrl']);
        if (imagePath != null) {
          // Update the _previewItems with the local path for better preview feedback
          _previewItems[i]['imagePath'] = imagePath;
        }
      }

      final newItem = MemoryItem(
        question: item['question'] ?? '',
        answer: item['answer'] ?? '',
        category: widget.category,
        imagePath: imagePath, // This is the local unique path
      );

      await box.add(newItem);
      importedMemoryItems.add(newItem);
    }

    if (mounted) {
      Navigator.pop(context, importedMemoryItems);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم استيراد البيانات بنجاح')),
      );
    }

    setState(() {
      _isImporting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مراجعة البيانات')),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _previewItems.length,
                itemBuilder: (context, index) {
                  final item = _previewItems[index];

                  Widget imageWidget;
                  final String? localPath = item['imagePath'];
                  final String? imageUrl = item['imageUrl'];

                  if (localPath != null && File(localPath).existsSync()) {
                    imageWidget = Image.file(
                      File(localPath),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      key: ValueKey(localPath), // Crucial key for Image.file
                      errorBuilder:
                          (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 50),
                    );
                  } else if (imageUrl != null &&
                      imageUrl.toString().startsWith('http')) {
                    imageWidget = Image.network(
                      imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      key: ValueKey(imageUrl), // Key for network image
                      errorBuilder:
                          (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 50),
                    );
                  } else {
                    imageWidget = const Icon(
                      Icons.image_not_supported,
                      size: 50,
                    );
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: ListTile(
                      key: ValueKey(
                        item['question'] + index.toString(),
                      ), // A simple unique key for ListTile
                      leading: SizedBox(
                        width: 50,
                        height: 50,
                        child: imageWidget,
                      ),
                      title: Text(item['question'] ?? ''),
                      subtitle: Text(item['answer'] ?? ''),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(
                  _isImporting ? 'جاري الاستيراد...' : 'تأكيد الاستيراد',
                ),
                onPressed: _isImporting ? null : _saveData,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
