// add_info_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import '../models/memory_item.dart';

class AddInfoScreen extends StatefulWidget {
  const AddInfoScreen({super.key});

  @override
  State<AddInfoScreen> createState() => _AddInfoScreenState();
}

class _AddInfoScreenState extends State<AddInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  File? _image;

  List<String> _categories = [];
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  void loadCategories() {
    final box = Hive.box<String>('categoriesBox');
    setState(() {
      _categories = box.values.toList();
    });
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void saveData() {
    if (_formKey.currentState!.validate()) {
      final memoryItem = MemoryItem(
        category: selectedCategory ?? '',
        question: _questionController.text,
        answer: _answerController.text,
        imagePath: _image?.path,
      );
      Hive.box<MemoryItem>('memoryBox').add(memoryItem);
      Navigator.pop(context);
    }
  }

  void showAddCategoryDialog() {
    final newCategoryController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'إضافة تصنيف جديد',
              textDirection: TextDirection.rtl,
            ),
            content: TextField(
              controller: newCategoryController,
              decoration: const InputDecoration(hintText: 'اسم التصنيف'),
              textDirection: TextDirection.rtl,
            ),
            actions: [
              TextButton(
                child: const Text('إلغاء', textDirection: TextDirection.rtl),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text('إضافة', textDirection: TextDirection.rtl),
                onPressed: () async {
                  final newCat = newCategoryController.text.trim();
                  final box = Hive.box<String>('categoriesBox');
                  if (newCat.isNotEmpty && !_categories.contains(newCat)) {
                    await box.add(newCat);
                    loadCategories();
                    setState(() {
                      selectedCategory = newCat;
                    });
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إضافة معلومة')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'اختر التصنيف',
                        ),
                        value: selectedCategory,
                        items:
                            _categories.map((String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedCategory = newValue;
                          });
                        },
                        validator:
                            (value) => value == null ? 'اختر تصنيفًا' : null,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'إضافة تصنيف جديد',
                      onPressed: showAddCategoryDialog,
                    ),
                  ],
                ),
                TextFormField(
                  controller: _questionController,
                  decoration: const InputDecoration(labelText: 'السؤال'),
                  textDirection: TextDirection.rtl,
                  validator: (value) => value!.isEmpty ? 'أدخل السؤال' : null,
                ),
                TextFormField(
                  controller: _answerController,
                  decoration: const InputDecoration(labelText: 'الإجابة'),
                  textDirection: TextDirection.rtl,
                  validator: (value) => value!.isEmpty ? 'أدخل الإجابة' : null,
                ),
                const SizedBox(height: 10),
                _image != null
                    ? Image.file(_image!, height: 150)
                    : const SizedBox.shrink(),
                TextButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text('اختيار صورة'),
                  onPressed: pickImage,
                ),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: saveData, child: const Text('حفظ')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
