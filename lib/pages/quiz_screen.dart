import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/memory_item.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<MemoryItem> _items;
  late MemoryItem _currentItem;
  final _answerController = TextEditingController();
  String _feedback = '';

  @override
  void initState() {
    super.initState();
    final box = Hive.box<MemoryItem>('memoryBox');
    _items = box.values.toList();
    _loadRandomItem();
  }

  void _loadRandomItem() {
    if (_items.isNotEmpty) {
      final random = Random();
      setState(() {
        _currentItem = _items[random.nextInt(_items.length)];
        _feedback = '';
        _answerController.clear();
      });
    }
  }

  void _checkAnswer() {
    final userAnswer = _answerController.text.trim();
    setState(() {
      if (userAnswer.toLowerCase() == _currentItem.answer.toLowerCase()) {
        _feedback = '✅ صحيح!';
      } else {
        _feedback = '❌ خطأ. الإجابة الصحيحة: ${_currentItem.answer}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('الاختبار')),
        body: const Center(child: Text('لا توجد بيانات للاختبار.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('الاختبار')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_currentItem.question, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            if (_currentItem.imagePath != null)
              Image.file(File(_currentItem.imagePath!), height: 150),
            TextField(
              controller: _answerController,
              decoration: const InputDecoration(labelText: 'الإجابة'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _checkAnswer, child: const Text('تحقق')),
            const SizedBox(height: 10),
            Text(_feedback, style: const TextStyle(fontSize: 18)),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('سؤال آخر'),
              onPressed: _loadRandomItem,
            ),
          ],
        ),
      ),
    );
  }
}
