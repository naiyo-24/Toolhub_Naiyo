import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';

class NotesMakerScreen extends StatefulWidget {
  const NotesMakerScreen({super.key});

  @override
  State<NotesMakerScreen> createState() => _NotesMakerScreenState();
}

class _NotesMakerScreenState extends State<NotesMakerScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  List<Map<String, dynamic>> _notes = [];
  bool _isEditing = false;
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notesJson = prefs.getString('student_notes');
    if (notesJson != null) {
      final List<dynamic> decoded = json.decode(notesJson);
      setState(() {
        _notes = List<Map<String, dynamic>>.from(decoded);
      });
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('student_notes', json.encode(_notes));
  }

  void _saveCurrentNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    
    if (title.isEmpty && content.isEmpty) return;

    setState(() {
      if (_isEditing && _editingIndex != null) {
        _notes[_editingIndex!] = {
          'title': title.isEmpty ? 'Untitled' : title,
          'content': content,
          'date': DateTime.now().toIso8601String(),
        };
      } else {
        _notes.insert(0, {
          'title': title.isEmpty ? 'Untitled' : title,
          'content': content,
          'date': DateTime.now().toIso8601String(),
        });
      }
      _isEditing = false;
      _editingIndex = null;
    });
    
    _titleController.clear();
    _contentController.clear();
    _saveNotes();
  }

  void _editNote(int index) {
    setState(() {
      _titleController.text = _notes[index]['title'] == 'Untitled' ? '' : _notes[index]['title'];
      _contentController.text = _notes[index]['content'];
      _isEditing = true;
      _editingIndex = index;
    });
  }

  void _deleteNote(int index) {
    setState(() {
      _notes.removeAt(index);
    });
    _saveNotes();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryPurple,
        elevation: 0,
        centerTitle: true,
        title: Text('Notes Maker', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Instructions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: NeoCard(
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
                      "1. Tap the '+' button to create a new digital note.\n2. Add a title and type out your text.\n3. Save the note to access it later.",
                      style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: NeoCard(
                backgroundColor: AppColors.primaryPurple,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      decoration: InputDecoration(
                        hintText: 'Note Title...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _contentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Start typing your notes here...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.black, width: 2)),
                      ),
                      onPressed: _saveCurrentNote,
                      icon: Icon(_isEditing ? Icons.save_rounded : Icons.add_rounded),
                      label: Text(_isEditing ? 'Save Changes' : 'Create Note', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            _editingIndex = null;
                            _titleController.clear();
                            _contentController.clear();
                          });
                        },
                        child: const Text('Cancel Edit', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      )
                    ]
                  ],
                ),
              ),
            ),
            if (_notes.isNotEmpty) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: NeoCard(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Saved Notes (Last 10)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 12),
                      ..._notes.take(10).toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final note = entry.value;
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(note['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_rounded, color: AppColors.primaryBlue, size: 20),
                                        onPressed: () => _editNote(index),
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                      ),
                                      const SizedBox(width: 16),
                                      IconButton(
                                        icon: const Icon(Icons.delete_rounded, color: AppColors.primaryRed, size: 20),
                                        onPressed: () => _deleteNote(index),
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.black26),
                              Text(note['content'], style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ] else ...[
              const SizedBox(height: 40),
              const Center(child: Text('No notes yet! Create one above.', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ],
        ),
      ),
    );
  }
}
