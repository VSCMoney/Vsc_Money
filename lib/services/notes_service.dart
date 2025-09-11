// File: lib/services/notes_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:rxdart/rxdart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../models/notes_modal.dart';


class NotesService {
  static final NotesService _instance = NotesService._internal();
  factory NotesService() => _instance;
  NotesService._internal();

  static const String _notesKey = 'notes_storage';
  final Uuid _uuid = Uuid();
  final ImagePicker _imagePicker = ImagePicker();

  // Streams for reactive state management
  final BehaviorSubject<List<Note>> _notes = BehaviorSubject<List<Note>>.seeded([]);
  final BehaviorSubject<Note?> _currentNote = BehaviorSubject<Note?>.seeded(null);
  final BehaviorSubject<bool> _isLoading = BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<bool> _isSaving = BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<bool> _isProcessingFile = BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<double> _uploadProgress = BehaviorSubject<double>.seeded(0.0);
  final BehaviorSubject<String> _error = BehaviorSubject<String>.seeded('');
  final BehaviorSubject<String> _searchQuery = BehaviorSubject<String>.seeded('');

  // Getters for streams
  Stream<List<Note>> get notes$ => _notes.stream;
  Stream<Note?> get currentNote$ => _currentNote.stream;
  Stream<bool> get isLoading$ => _isLoading.stream;
  Stream<bool> get isSaving$ => _isSaving.stream;
  Stream<bool> get isProcessingFile$ => _isProcessingFile.stream;
  Stream<double> get uploadProgress$ => _uploadProgress.stream;
  Stream<String> get error$ => _error.stream;
  Stream<String> get searchQuery$ => _searchQuery.stream;

  // Filtered notes stream based on search
  Stream<List<Note>> get filteredNotes$ =>
      Rx.combineLatest2<List<Note>, String, List<Note>>(
        _notes.stream,
        _searchQuery.stream,
            (notes, query) {
          if (query.isEmpty) return notes;

          return notes.where((note) =>
          note.title.toLowerCase().contains(query.toLowerCase()) ||
              note.content.toLowerCase().contains(query.toLowerCase())
          ).toList();
        },
      );

  // Initialize service - load notes from storage
  Future<void> initialize() async {
    try {
      _isLoading.add(true);
      await _loadNotes();
    } catch (e) {
      _error.add('Failed to initialize notes: ${e.toString()}');
    } finally {
      _isLoading.add(false);
    }
  }

  // Load notes from SharedPreferences
  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_notesKey);

      if (notesJson != null) {
        final List<dynamic> notesList = json.decode(notesJson);
        final notes = notesList.map((noteData) => Note.fromJson(noteData)).toList();

        // Sort by updated date (most recent first)
        notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        _notes.add(notes);
      }
    } catch (e) {
      _error.add('Failed to load notes: ${e.toString()}');
    }
  }

  // Save notes to SharedPreferences
  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = json.encode(_notes.value.map((note) => note.toJson()).toList());
      await prefs.setString(_notesKey, notesJson);
    } catch (e) {
      _error.add('Failed to save notes: ${e.toString()}');
    }
  }

  // Create a new note
  Future<Note> createNote({String title = '', String content = ''}) async {
    try {
      _isSaving.add(true);

      final now = DateTime.now();
      final note = Note(
        id: _uuid.v4(),
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
      );

      final currentNotes = List<Note>.from(_notes.value);
      currentNotes.insert(0, note);
      _notes.add(currentNotes);
      _currentNote.add(note);

      await _saveNotes();
      return note;
    } catch (e) {
      _error.add('Failed to create note: ${e.toString()}');
      rethrow;
    } finally {
      _isSaving.add(false);
    }
  }

  // Update an existing note
  Future<Note> updateNote(String noteId, {String? title, String? content, List<NoteAttachment>? attachments}) async {
    try {
      _isSaving.add(true);

      final currentNotes = List<Note>.from(_notes.value);
      final noteIndex = currentNotes.indexWhere((note) => note.id == noteId);

      if (noteIndex == -1) {
        throw Exception('Note not found');
      }

      final existingNote = currentNotes[noteIndex];
      final updatedNote = existingNote.copyWith(
        title: title,
        content: content,
        attachments: attachments,
        updatedAt: DateTime.now(),
      );

      currentNotes[noteIndex] = updatedNote;

      // Sort by updated date (most recent first)
      currentNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      _notes.add(currentNotes);
      _currentNote.add(updatedNote);

      await _saveNotes();
      return updatedNote;
    } catch (e) {
      _error.add('Failed to update note: ${e.toString()}');
      rethrow;
    } finally {
      _isSaving.add(false);
    }
  }

  // Delete a note
  Future<void> deleteNote(String noteId) async {
    try {
      _isSaving.add(true);

      final currentNotes = List<Note>.from(_notes.value);
      final noteToDelete = currentNotes.firstWhere(
            (note) => note.id == noteId,
        orElse: () => throw Exception('Note not found'),
      );

      // Delete all attachments
      for (final attachment in noteToDelete.attachments) {
        await _deleteAttachmentFile(attachment);
      }

      currentNotes.removeWhere((note) => note.id == noteId);
      _notes.add(currentNotes);

      // Clear current note if it's the one being deleted
      if (_currentNote.value?.id == noteId) {
        _currentNote.add(null);
      }

      await _saveNotes();
    } catch (e) {
      _error.add('Failed to delete note: ${e.toString()}');
      rethrow;
    } finally {
      _isSaving.add(false);
    }
  }

  // Set current note
  void setCurrentNote(Note? note) {
    _currentNote.add(note);
  }

  // Get note by ID
  Note? getNoteById(String noteId) {
    try {
      return _notes.value.firstWhere((note) => note.id == noteId);
    } catch (e) {
      return null;
    }
  }

  // Search notes
  void searchNotes(String query) {
    _searchQuery.add(query);
  }

  // Clear search
  void clearSearch() {
    _searchQuery.add('');
  }

  // ========== FILE ATTACHMENT METHODS ==========

  // Get the app's document directory for storing files
  Future<Directory> get _documentsDirectory async {
    final directory = await getApplicationDocumentsDirectory();
    final notesDir = Directory('${directory.path}/notes_attachments');
    if (!await notesDir.exists()) {
      await notesDir.create(recursive: true);
    }
    return notesDir;
  }

  // Pick image from camera
  Future<NoteAttachment?> pickImageFromCamera(String noteId) async {
    try {
      _isProcessingFile.add(true);
      _error.add('');

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image == null) return null;

      final attachment = await _processFile(File(image.path));
      if (attachment != null) {
        await _addAttachmentToNote(noteId, attachment);
      }

      return attachment;
    } catch (e) {
      _error.add('Failed to capture image: ${e.toString()}');
      return null;
    } finally {
      _isProcessingFile.add(false);
    }
  }

  // Pick image from gallery
  Future<NoteAttachment?> pickImageFromGallery(String noteId) async {
    try {
      _isProcessingFile.add(true);
      _error.add('');

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return null;

      final attachment = await _processFile(File(image.path));
      if (attachment != null) {
        await _addAttachmentToNote(noteId, attachment);
      }

      return attachment;
    } catch (e) {
      _error.add('Failed to pick image: ${e.toString()}');
      return null;
    } finally {
      _isProcessingFile.add(false);
    }
  }

  // Pick multiple images from gallery
  Future<List<NoteAttachment>> pickMultipleImages(String noteId) async {
    try {
      _isProcessingFile.add(true);
      _error.add('');

      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
      );

      if (images.isEmpty) return [];

      final List<NoteAttachment> attachments = [];
      for (int i = 0; i < images.length; i++) {
        _uploadProgress.add((i + 1) / images.length);
        final attachment = await _processFile(File(images[i].path));
        if (attachment != null) {
          attachments.add(attachment);
          await _addAttachmentToNote(noteId, attachment);
        }
      }

      return attachments;
    } catch (e) {
      _error.add('Failed to pick images: ${e.toString()}');
      return [];
    } finally {
      _isProcessingFile.add(false);
      _uploadProgress.add(0.0);
    }
  }

  // Pick document files
  Future<List<NoteAttachment>> pickDocuments(String noteId) async {
    try {
      _isProcessingFile.add(true);
      _error.add('');

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
          'txt', 'rtf', 'odt', 'ods', 'odp'
        ],
      );

      if (result == null || result.files.isEmpty) return [];

      final List<NoteAttachment> attachments = [];
      for (int i = 0; i < result.files.length; i++) {
        final file = result.files[i];
        if (file.path != null) {
          _uploadProgress.add((i + 1) / result.files.length);
          final attachment = await _processFile(File(file.path!));
          if (attachment != null) {
            attachments.add(attachment);
            await _addAttachmentToNote(noteId, attachment);
          }
        }
      }

      return attachments;
    } catch (e) {
      _error.add('Failed to pick documents: ${e.toString()}');
      return [];
    } finally {
      _isProcessingFile.add(false);
      _uploadProgress.add(0.0);
    }
  }

  // Pick any file type
  Future<List<NoteAttachment>> pickAnyFiles(String noteId) async {
    try {
      _isProcessingFile.add(true);
      _error.add('');

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return [];

      final List<NoteAttachment> attachments = [];
      for (int i = 0; i < result.files.length; i++) {
        final file = result.files[i];
        if (file.path != null) {
          _uploadProgress.add((i + 1) / result.files.length);
          final attachment = await _processFile(File(file.path!));
          if (attachment != null) {
            attachments.add(attachment);
            await _addAttachmentToNote(noteId, attachment);
          }
        }
      }

      return attachments;
    } catch (e) {
      _error.add('Failed to pick files: ${e.toString()}');
      return [];
    } finally {
      _isProcessingFile.add(false);
      _uploadProgress.add(0.0);
    }
  }

  // Process and save file
  Future<NoteAttachment?> _processFile(File file) async {
    try {
      final documentsDir = await _documentsDirectory;
      final fileName = path.basename(file.path);
      final fileExtension = path.extension(fileName);
      final fileId = _uuid.v4();
      final newFileName = '$fileId$fileExtension';
      final newPath = '${documentsDir.path}/$newFileName';

      // Copy file to app directory
      final newFile = await file.copy(newPath);
      final fileStats = await newFile.stat();

      // Determine file type
      final attachmentType = _getAttachmentType(fileExtension);

      // Create attachment
      final attachment = NoteAttachment(
        id: fileId,
        name: fileName,
        path: newPath,
        type: attachmentType,
        size: fileStats.size,
        createdAt: DateTime.now(),
        mimeType: _getMimeType(fileExtension),
      );

      return attachment;
    } catch (e) {
      _error.add('Failed to process file: ${e.toString()}');
      return null;
    }
  }

  // Add attachment to note
  Future<void> _addAttachmentToNote(String noteId, NoteAttachment attachment) async {
    final note = getNoteById(noteId);
    if (note != null) {
      final updatedAttachments = List<NoteAttachment>.from(note.attachments);
      updatedAttachments.add(attachment);
      await updateNote(noteId, attachments: updatedAttachments);
    }
  }

  // Remove attachment from note
  Future<void> removeAttachmentFromNote(String noteId, String attachmentId) async {
    try {
      final note = getNoteById(noteId);
      if (note == null) return;

      final attachmentToRemove = note.attachments.firstWhere(
            (attachment) => attachment.id == attachmentId,
        orElse: () => throw Exception('Attachment not found'),
      );

      // Delete the file
      await _deleteAttachmentFile(attachmentToRemove);

      // Remove from note
      final updatedAttachments = note.attachments
          .where((attachment) => attachment.id != attachmentId)
          .toList();

      await updateNote(noteId, attachments: updatedAttachments);
    } catch (e) {
      _error.add('Failed to remove attachment: ${e.toString()}');
    }
  }

  // Delete attachment file
  Future<bool> _deleteAttachmentFile(NoteAttachment attachment) async {
    try {
      final file = File(attachment.path);
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (e) {
      _error.add('Failed to delete file: ${e.toString()}');
      return false;
    }
  }

  // Get attachment type from file extension
  AttachmentType _getAttachmentType(String extension) {
    final ext = extension.toLowerCase();

    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      return AttachmentType.image;
    } else if (['.mp4', '.avi', '.mov', '.wmv', '.flv', '.mkv'].contains(ext)) {
      return AttachmentType.video;
    } else if (['.mp3', '.wav', '.aac', '.ogg', '.m4a'].contains(ext)) {
      return AttachmentType.audio;
    } else if (['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt'].contains(ext)) {
      return AttachmentType.document;
    } else {
      return AttachmentType.other;
    }
  }

  // Get MIME type from file extension
  String? _getMimeType(String extension) {
    final ext = extension.toLowerCase();

    final mimeTypes = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.pdf': 'application/pdf',
      '.doc': 'application/msword',
      '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      '.txt': 'text/plain',
      '.mp4': 'video/mp4',
      '.mp3': 'audio/mpeg',
      '.wav': 'audio/wav',
      '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      '.pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    };

    return mimeTypes[ext];
  }

  // ========== ADDITIONAL UTILITY METHODS ==========

  // Export note as text
  Future<String> exportNoteAsText(String noteId) async {
    try {
      final note = getNoteById(noteId);
      if (note == null) throw Exception('Note not found');

      final buffer = StringBuffer();
      buffer.writeln(note.title);
      buffer.writeln('=' * note.title.length);
      buffer.writeln();
      buffer.writeln(note.content);

      if (note.attachments.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('Attachments:');
        for (final attachment in note.attachments) {
          buffer.writeln('- ${attachment.name} (${_formatFileSize(attachment.size)})');
        }
      }

      buffer.writeln();
      buffer.writeln('Created: ${note.createdAt}');
      buffer.writeln('Updated: ${note.updatedAt}');

      return buffer.toString();
    } catch (e) {
      _error.add('Failed to export note: ${e.toString()}');
      rethrow;
    }
  }

  // Duplicate note
  Future<Note> duplicateNote(String noteId) async {
    try {
      final originalNote = getNoteById(noteId);
      if (originalNote == null) throw Exception('Note not found');

      final now = DateTime.now();
      final duplicatedNote = Note(
        id: _uuid.v4(),
        title: '${originalNote.title} (Copy)',
        content: originalNote.content,
        attachments: [], // Don't copy attachments for simplicity
        createdAt: now,
        updatedAt: now,
      );

      final currentNotes = List<Note>.from(_notes.value);
      currentNotes.insert(0, duplicatedNote);
      _notes.add(currentNotes);

      await _saveNotes();
      return duplicatedNote;
    } catch (e) {
      _error.add('Failed to duplicate note: ${e.toString()}');
      rethrow;
    }
  }

  // Get notes statistics
  Map<String, dynamic> getNotesStatistics() {
    final notes = _notes.value;
    final totalAttachments = notes.fold<int>(
      0,
          (sum, note) => sum + note.attachments.length,
    );

    final totalSize = notes.fold<int>(
      0,
          (sum, note) => sum + note.attachments.fold<int>(
        0,
            (attachmentSum, attachment) => attachmentSum + attachment.size,
      ),
    );

    return {
      'totalNotes': notes.length,
      'totalAttachments': totalAttachments,
      'totalSize': totalSize,
      'formattedSize': _formatFileSize(totalSize),
      'notesWithAttachments': notes.where((note) => note.attachments.isNotEmpty).length,
    };
  }

  // Format file size
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Backup all notes
  Future<Map<String, dynamic>> createBackup() async {
    try {
      return {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'notes': _notes.value.map((note) => note.toJson()).toList(),
      };
    } catch (e) {
      _error.add('Failed to create backup: ${e.toString()}');
      rethrow;
    }
  }

  // Restore from backup
  Future<void> restoreFromBackup(Map<String, dynamic> backup) async {
    try {
      _isLoading.add(true);

      final List<dynamic> notesData = backup['notes'] ?? [];
      final notes = notesData.map((noteData) => Note.fromJson(noteData)).toList();

      // Sort by updated date
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      _notes.add(notes);
      await _saveNotes();
    } catch (e) {
      _error.add('Failed to restore backup: ${e.toString()}');
      rethrow;
    } finally {
      _isLoading.add(false);
    }
  }

  // Clear all notes
  Future<void> clearAllNotes() async {
    try {
      _isSaving.add(true);

      // Delete all attachment files
      for (final note in _notes.value) {
        for (final attachment in note.attachments) {
          await _deleteAttachmentFile(attachment);
        }
      }

      _notes.add([]);
      _currentNote.add(null);
      await _saveNotes();
    } catch (e) {
      _error.add('Failed to clear notes: ${e.toString()}');
      rethrow;
    } finally {
      _isSaving.add(false);
    }
  }

  // Get total storage used
  Future<int> getTotalStorageUsed() async {
    try {
      final documentsDir = await _documentsDirectory;
      int totalSize = 0;

      if (await documentsDir.exists()) {
        final files = documentsDir.listSync();
        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            totalSize += stat.size;
          }
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  // Clean up orphaned files (files not referenced by any note)
  Future<void> cleanupOrphanedFiles() async {
    try {
      final documentsDir = await _documentsDirectory;
      if (!await documentsDir.exists()) return;

      // Get all attachment IDs from notes
      final referencedFileIds = <String>{};
      for (final note in _notes.value) {
        for (final attachment in note.attachments) {
          referencedFileIds.add(attachment.id);
        }
      }

      // Check files in directory
      final files = documentsDir.listSync();
      for (final file in files) {
        if (file is File) {
          final fileName = path.basenameWithoutExtension(file.path);
          if (!referencedFileIds.contains(fileName)) {
            // This file is orphaned, delete it
            await file.delete();
          }
        }
      }
    } catch (e) {
      _error.add('Failed to cleanup orphaned files: ${e.toString()}');
    }
  }

  // Clear error
  void clearError() {
    _error.add('');
  }

  // Dispose streams
  void dispose() {
    _notes.close();
    _currentNote.close();
    _isLoading.close();
    _isSaving.close();
    _isProcessingFile.close();
    _uploadProgress.close();
    _error.close();
    _searchQuery.close();
  }
}