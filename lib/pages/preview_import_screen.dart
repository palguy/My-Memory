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
  // This list will hold the preview data and will be updated as images are downloaded
  late List<Map<String, dynamic>> _previewItems;
  final Uuid _uuid = const Uuid();

  // A list to track the download status for each image
  // Values: 0 = not started, 1 = downloading, 2 = downloaded, -1 = error/no image
  late List<int> _imageDownloadStatus;

  @override
  void initState() {
    super.initState();
    _previewItems = List.from(widget.items);
    // Initialize download status for each item
    _imageDownloadStatus = List.generate(
      widget.items.length,
      (index) =>
          (widget.items[index]['imageUrl'] != null &&
                  widget.items[index]['imageUrl'].toString().startsWith('http'))
              ? 0 // Needs download
              : -1, // No image or local, no download needed
    );

    // Start downloading images as soon as the screen loads for preview
    _startImageDownloads();
  }

  // Function to start downloading images for preview
  void _startImageDownloads() async {
    for (int i = 0; i < _previewItems.length; i++) {
      if (_imageDownloadStatus[i] == 0) {
        // Only download if status is 'not started'
        final item = _previewItems[i];
        final imageUrl = item['imageUrl'];

        if (imageUrl != null && imageUrl.toString().startsWith('http')) {
          setState(() {
            _imageDownloadStatus[i] = 1; // Set status to 'downloading'
          });

          final imagePath = await _downloadImage(imageUrl);

          if (mounted) {
            setState(() {
              if (imagePath != null) {
                _previewItems[i]['imagePath'] =
                    imagePath; // Update with local path
                _imageDownloadStatus[i] = 2; // Set status to 'downloaded'
              } else {
                _imageDownloadStatus[i] = -1; // Set status to 'error'
              }
            });
          }
        }
      }
    }
  }

  Future<String?> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();

        String fileExtension = '';
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          final lastSegment = pathSegments.last;
          final dotIndex = lastSegment.lastIndexOf('.');
          if (dotIndex != -1 && dotIndex < lastSegment.length - 1) {
            fileExtension = lastSegment.substring(dotIndex);
          }
        }

        final uniqueFilename = '${_uuid.v4()}$fileExtension';
        final file = File('${dir.path}/$uniqueFilename');

        await file.writeAsBytes(response.bodyBytes);
        debugPrint('Image downloaded to: ${file.path}');
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
      String? finalImagePath; // Use this for the actual item to be saved

      // Check if image was downloaded during preview or if it's already a local path
      if (_previewItems[i]['imagePath'] != null &&
          File(_previewItems[i]['imagePath']).existsSync()) {
        finalImagePath = _previewItems[i]['imagePath'];
      } else if (item['imageUrl'] != null &&
          item['imageUrl'].toString().startsWith('http')) {
        // If for some reason it wasn't downloaded during preview (e.g., error),
        // try to download it again during save. This is a fallback.
        finalImagePath = await _downloadImage(item['imageUrl']);
      }

      final newItem = MemoryItem(
        question: item['question'] ?? '',
        answer: item['answer'] ?? '',
        category: widget.category,
        imagePath: finalImagePath, // This is the local unique path
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
                  final downloadStatus = _imageDownloadStatus[index];

                  Widget imageDisplayWidget;
                  final String? localPath =
                      item['imagePath']; // Path if downloaded
                  final String? imageUrl = item['imageUrl']; // Original URL

                  if (downloadStatus == 1) {
                    // Image is currently downloading
                    imageDisplayWidget = const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    );
                  } else if (localPath != null &&
                      File(localPath).existsSync()) {
                    // Image is downloaded and file exists locally
                    imageDisplayWidget = Image.file(
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
                    // Fallback to Image.network if not downloaded yet or failed,
                    // or if it's the initial display before download starts.
                    // This will also show its own loading indicator.
                    imageDisplayWidget = Image.network(
                      imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      key: ValueKey(imageUrl), // Key for network image
                      errorBuilder:
                          (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 50),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                            strokeWidth: 2.0,
                          ),
                        );
                      },
                    );
                  } else {
                    // No image URL or local path found
                    imageDisplayWidget = const Icon(
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
                      key: ValueKey(item['question'] + index.toString()),
                      leading: SizedBox(
                        width: 50,
                        height: 50,
                        child: imageDisplayWidget, // Use the determined widget
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
