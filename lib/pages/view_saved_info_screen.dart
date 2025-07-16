import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_memory/pages/image_preview_screen.dart';
import '../models/memory_item.dart';

class ViewSavedInfoScreen extends StatefulWidget {
  const ViewSavedInfoScreen({super.key});

  @override
  State<ViewSavedInfoScreen> createState() => _ViewSavedInfoScreenState();
}

class _ViewSavedInfoScreenState extends State<ViewSavedInfoScreen> {
  void deleteItemConfirm(int key) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('تأكيد الحذف', textDirection: TextDirection.rtl),
            content: const Text(
              'هل أنت متأكد أنك تريد حذف هذه المعلومة؟',
              textDirection: TextDirection.rtl,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء', textDirection: TextDirection.rtl),
              ),
              ElevatedButton(
                onPressed: () async {
                  final box = Hive.box<MemoryItem>('memoryBox');
                  // Get the item before deleting to remove its image file
                  final itemToDelete = box.get(key);
                  if (itemToDelete != null && itemToDelete.imagePath != null) {
                    final file = File(itemToDelete.imagePath!);
                    if (await file.exists()) {
                      try {
                        await file.delete();
                        debugPrint(
                          'Deleted image file: ${itemToDelete.imagePath}',
                        );
                      } catch (e) {
                        debugPrint('Error deleting image file: $e');
                      }
                    }
                  }
                  await box.delete(key);
                  Navigator.pop(context);
                  setState(() {}); // Rebuild to reflect changes
                },
                child: const Text('حذف', textDirection: TextDirection.rtl),
              ),
            ],
          ),
    );
  }

  void editItem(BuildContext context, MemoryItem item) async {
    final questionController = TextEditingController(text: item.question);
    final answerController = TextEditingController(text: item.answer);
    File? updatedImageFile =
        item.imagePath != null ? File(item.imagePath!) : null;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setLocalState) => AlertDialog(
                  title: const Text(
                    'تعديل المعلومة',
                    textDirection: TextDirection.rtl,
                  ),
                  content: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: questionController,
                          decoration: const InputDecoration(
                            labelText: 'السؤال',
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        TextField(
                          controller: answerController,
                          decoration: const InputDecoration(
                            labelText: 'الإجابة',
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 10),
                        // Display the current or newly selected image
                        if (updatedImageFile != null &&
                            updatedImageFile!.existsSync())
                          Image.file(
                            updatedImageFile!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        else
                          const Text(
                            'لا توجد صورة',
                            textDirection: TextDirection.rtl,
                          ),
                        TextButton.icon(
                          icon: const Icon(Icons.image),
                          label: const Text('تغيير الصورة'),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (pickedFile != null) {
                              setLocalState(() {
                                updatedImageFile = File(pickedFile.path);
                              });
                            }
                          },
                        ),
                        // Optional: Button to remove image
                        if (updatedImageFile != null)
                          TextButton.icon(
                            icon: const Icon(Icons.clear),
                            label: const Text('إزالة الصورة'),
                            onPressed: () {
                              setLocalState(() {
                                updatedImageFile = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'إلغاء',
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Handle deletion of old image file if a new one is selected or cleared
                        if (item.imagePath != null &&
                            updatedImageFile?.path != item.imagePath) {
                          final oldFile = File(item.imagePath!);
                          if (oldFile.existsSync()) {
                            try {
                              oldFile
                                  .deleteSync(); // Use sync delete for simplicity in dialog
                              debugPrint(
                                'Deleted old image file: ${item.imagePath}',
                              );
                            } catch (e) {
                              debugPrint('Error deleting old image file: $e');
                            }
                          }
                        }

                        item.question = questionController.text;
                        item.answer = answerController.text;
                        item.imagePath =
                            updatedImageFile?.path; // Save new path or null
                        item.save(); // Save changes to Hive

                        Navigator.pop(context);
                        setState(() {}); // Rebuild to reflect changes
                      },
                      child: const Text(
                        'حفظ',
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memoryBox = Hive.box<MemoryItem>('memoryBox');
    final items = memoryBox.toMap();
    final categories = items.values.map((e) => e.category).toSet().toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('المعلومات المحفوظة')),
        body:
            categories.isEmpty
                ? const Center(child: Text('لا توجد بيانات محفوظة'))
                : ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final filteredItems =
                        items.entries
                            .where((entry) => entry.value.category == category)
                            .toList();

                    return ExpansionTile(
                      key: ValueKey(
                        category,
                      ), // Add a key to the ExpansionTile as well
                      title: Text(category),
                      children:
                          filteredItems.map((entry) {
                            final key = entry.key;
                            final item = entry.value;
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              // Add a unique key to the ListTile
                              child: ListTile(
                                key: ValueKey(
                                  key,
                                ), // <--- THIS IS THE KEY CHANGE
                                title: Text(item.question),
                                subtitle: Text(item.answer),
                                leading:
                                    (item.imagePath != null &&
                                            File(item.imagePath!).existsSync())
                                        ? GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        ImagePreviewScreen(
                                                          imagePath:
                                                              item.imagePath!,
                                                        ),
                                              ),
                                            );
                                          },
                                          child: SizedBox(
                                            width: 50,
                                            height: 50,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: Image.file(
                                                File(item.imagePath!),
                                                fit: BoxFit.cover,
                                                // Optional: Add a key to Image.file for extra robustness
                                                // key: ValueKey(item.imagePath!),
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const Icon(
                                                      Icons.broken_image,
                                                      size: 50,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        )
                                        : const Icon(
                                          Icons.image_not_supported,
                                          size: 40,
                                        ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => editItem(context, item),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => deleteItemConfirm(key),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    );
                  },
                ),
      ),
    );
  }
}
