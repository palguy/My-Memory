// screens/view_saved_info_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
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
            title: const Text('تأكيد الحذف'),
            content: const Text('هل أنت متأكد أنك تريد حذف هذه المعلومة؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final box = Hive.box<MemoryItem>('memoryBox');
                  await box.delete(key);
                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text('حذف'),
              ),
            ],
          ),
    );
  }

  void editItem(BuildContext context, MemoryItem item) async {
    final questionController = TextEditingController(text: item.question);
    final answerController = TextEditingController(text: item.answer);
    File? updatedImage = item.imagePath != null ? File(item.imagePath!) : null;

    void pickNewImage() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          updatedImage = File(pickedFile.path);
        });
      }
    }

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setLocalState) => AlertDialog(
                  title: const Text('تعديل المعلومة'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: questionController,
                        decoration: const InputDecoration(labelText: 'السؤال'),
                      ),
                      TextField(
                        controller: answerController,
                        decoration: const InputDecoration(labelText: 'الإجابة'),
                      ),
                      const SizedBox(height: 10),
                      updatedImage != null
                          ? Image.file(
                            updatedImage!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                          : const Text('لا توجد صورة'),
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
                              updatedImage = File(pickedFile.path);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        item.question = questionController.text;
                        item.answer = answerController.text;
                        item.imagePath = updatedImage?.path;
                        item.save();
                        Navigator.pop(context);
                        setState(() {});
                      },
                      child: const Text('حفظ'),
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

    return Scaffold(
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
                    title: Text(category),
                    children:
                        filteredItems.map((entry) {
                          final key = entry.key;
                          final item = entry.value;
                          return ListTile(
                            title: Text(item.question),
                            subtitle: Text(item.answer),
                            leading:
                                item.imagePath != null
                                    ? Image.file(
                                      File(item.imagePath!),
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    )
                                    : const Icon(Icons.image_not_supported),
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
                          );
                        }).toList(),
                  );
                },
              ),
    );
  }
}
