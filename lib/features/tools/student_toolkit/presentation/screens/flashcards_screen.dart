import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  List<Map<String, dynamic>> _flashcards = [];
  bool _isFlipped = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cardsJson = prefs.getString('student_flashcards');
    if (cardsJson != null) {
      final List<dynamic> decoded = json.decode(cardsJson);
      setState(() {
        _flashcards = List<Map<String, dynamic>>.from(decoded);
      });
    }
  }

  Future<void> _saveFlashcards() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('student_flashcards', json.encode(_flashcards));
  }

  void _addFlashcard() {
    final question = _questionController.text.trim();
    final answer = _answerController.text.trim();
    
    if (question.isEmpty || answer.isEmpty) return;

    setState(() {
      _flashcards.add({'question': question, 'answer': answer});
      _questionController.clear();
      _answerController.clear();
      if (_flashcards.length == 1) {
        _currentIndex = 0;
      }
    });
    _saveFlashcards();
    FocusScope.of(context).unfocus();
  }

  void _deleteCurrentCard() {
    if (_flashcards.isEmpty) return;
    
    setState(() {
      _flashcards.removeAt(_currentIndex);
      if (_currentIndex >= _flashcards.length && _flashcards.isNotEmpty) {
        _currentIndex = _flashcards.length - 1;
      }
      _isFlipped = false;
    });
    _saveFlashcards();
  }

  void _nextCard() {
    if (_flashcards.length <= 1) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _flashcards.length;
      _isFlipped = false;
    });
  }

  void _prevCard() {
    if (_flashcards.length <= 1) return;
    setState(() {
      _currentIndex = (_currentIndex - 1) < 0 ? _flashcards.length - 1 : _currentIndex - 1;
      _isFlipped = false;
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        centerTitle: true,
        title: Text('Flashcards', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Instructions
            NeoCard(
              backgroundColor: const Color(0xFFE0FBFC), // Light Blue tint
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.black),
                      const SizedBox(width: 8),
                      Text('How to use', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "1. Tap 'Create Flashcard' to make a new digital sticky note.\n2. Write your question on the front and answer on the back.\n3. Tap a card to flip it and test your memory.",
                    style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Create Section
            NeoCard(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Create New Flashcard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: 'Front (Question)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _answerController,
                    decoration: InputDecoration(
                      hintText: 'Back (Answer)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.black, width: 2)),
                    ),
                    onPressed: _addFlashcard,
                    child: const Text('Add to Deck', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Study Section
            if (_flashcards.isNotEmpty) ...[
              const Text('Study Deck', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isFlipped = !_isFlipped;
                  });
                },
                child: SizedBox(
                  width: double.infinity,
                  height: 250,
                  child: NeoCard(
                    backgroundColor: _isFlipped ? AppColors.primaryYellow : AppColors.primaryBlue,
                    padding: const EdgeInsets.all(20),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            _isFlipped 
                              ? _flashcards[_currentIndex]['answer']
                              : _flashcards[_currentIndex]['question'],
                            style: AppTextStyles.heroTitle.copyWith(fontSize: 24),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.delete_rounded),
                            onPressed: _deleteCurrentCard,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Text(
                              _isFlipped ? 'Answer' : 'Question',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    iconSize: 40,
                    icon: const Icon(Icons.arrow_circle_left_rounded),
                    onPressed: _prevCard,
                  ),
                  Text('${_currentIndex + 1} / ${_flashcards.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(
                    iconSize: 40,
                    icon: const Icon(Icons.arrow_circle_right_rounded),
                    onPressed: _nextCard,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              NeoCard(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Digital Sticky Notes (Last 10)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 12),
                    ..._flashcards.take(10).toList().asMap().entries.map((entry) {
                      final card = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border.all(color: Colors.black, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Q: ${card['question']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Divider(color: Colors.black26),
                            Text('A: ${card['answer']}', style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.all(40.0),
                child: Text('Your deck is empty. Add flashcards above!', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              )
            ]
          ],
        ),
      ),
    );
  }
}
