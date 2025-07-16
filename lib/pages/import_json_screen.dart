import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:my_memory/pages/preview_import_screen.dart';

import '../models/memory_item.dart';

class ImportJsonScreen extends StatefulWidget {
  const ImportJsonScreen({super.key});

  @override
  State<ImportJsonScreen> createState() => _ImportJsonScreenState();
}

class _ImportJsonScreenState extends State<ImportJsonScreen> {
  List<Map<String, dynamic>> _tempItems = [];
  String? _selectedCategory;
  final TextEditingController _newCategoryController = TextEditingController();
  bool _isAddingNewCategory = false;

  List<String> _getExistingCategories() {
    final box = Hive.box<MemoryItem>('memoryBox');
    return box.values.map((e) => e.category).toSet().toList();
  }

  void _pickJsonFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (picked != null && picked.files.single.path != null) {
      final file = File(picked.files.single.path!);
      final content = await file.readAsString();
      try {
        final jsonData = jsonDecode(content);
        if (jsonData is List) {
          setState(() {
            _tempItems = jsonData.cast<Map<String, dynamic>>();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ملف JSON غير صالح: يجب أن يكون قائمة.'),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في تحليل JSON: $e')));
      }
    }
  }

  void _goToPreview() async {
    // Make this async
    final category =
        _isAddingNewCategory
            ? _newCategoryController.text.trim()
            : _selectedCategory;

    if (category == null || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال أو اختيار التصنيف')),
      );
      return;
    }

    // Await the result from PreviewImportScreen
    final importedItems = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PreviewImportScreen(items: _tempItems, category: category!),
      ),
    );

    // After returning from PreviewImportScreen
    if (importedItems != null && importedItems is List<MemoryItem>) {
      // If you want to clear the previewed items after successful import, uncomment this:
      // setState(() {
      //   _tempItems = [];
      //   _selectedCategory = null;
      //   _newCategoryController.clear();
      //   _isAddingNewCategory = false;
      // });

      // Or, if you want to update _tempItems with the local paths for some reason:
      // This part is mostly for demonstration; typically you'd navigate away or
      // clear the preview state after a successful import.
      // setState(() {
      //   _tempItems = importedItems.map((item) => item.toJson()).toList(); // Convert MemoryItem back to Map if needed
      // });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _getExistingCategories();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('استيراد JSON')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'اختر التصنيف أو أضف جديداً:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (!_isAddingNewCategory)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedCategory,
                  hint: const Text('اختر تصنيفاً'),
                  items:
                      categories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
              if (_isAddingNewCategory)
                TextField(
                  controller: _newCategoryController,
                  decoration: const InputDecoration(
                    labelText: 'اسم التصنيف الجديد',
                    border: OutlineInputBorder(),
                  ),
                ),
              TextButton.icon(
                icon: Icon(
                  _isAddingNewCategory ? Icons.arrow_drop_down : Icons.add,
                ),
                label: Text(
                  _isAddingNewCategory
                      ? 'اختر من التصنيفات'
                      : 'إضافة تصنيف جديد',
                ),
                onPressed: () {
                  setState(() {
                    _isAddingNewCategory = !_isAddingNewCategory;
                    if (!_isAddingNewCategory) {
                      _newCategoryController.clear();
                    } else {
                      _selectedCategory = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.file_open),
                label: const Text('اختر ملف JSON'),
                onPressed: _pickJsonFile,
              ),
              const SizedBox(height: 16),
              if (_tempItems.isNotEmpty)
                ElevatedButton.icon(
                  icon: const Icon(Icons.preview),
                  label: const Text('معاينة البيانات'),
                  onPressed: _goToPreview,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
