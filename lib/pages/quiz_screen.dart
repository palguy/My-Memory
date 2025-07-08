// quiz_screen.dart
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
  late List<String> _options;
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
        _options = _generateOptions(_currentItem);
        _feedback = '';
      });
    }
  }

  List<String> _generateOptions(MemoryItem correctItem) {
    final random = Random();
    final answers = <String>{correctItem.answer};
    while (answers.length < 4 && answers.length < _items.length) {
      final randomItem = _items[random.nextInt(_items.length)];
      answers.add(randomItem.answer);
    }
    final options = answers.toList();
    options.shuffle();
    return options;
  }

  void _checkAnswer(String selectedAnswer) {
    setState(() {
      if (selectedAnswer == _currentItem.answer) {
        _feedback = '✅ صحيح!';
      } else {
        _feedback = '❌ خطأ. الإجابة الصحيحة: \n${_currentItem.answer}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('الاختبار')),
          body: const Center(child: Text('لا توجد بيانات للاختبار.')),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الاختبار')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _currentItem.question,
                style: const TextStyle(fontSize: 25),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              if (_currentItem.imagePath != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Image.file(File(_currentItem.imagePath!), height: 150),
                ),
              const SizedBox(height: 20),
              ..._options.map(
                (option) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () => _checkAnswer(option),
                    child: Text(
                      option,
                      style: TextStyle(color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _feedback,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.right,
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('سؤال آخر'),
                onPressed: _loadRandomItem,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
