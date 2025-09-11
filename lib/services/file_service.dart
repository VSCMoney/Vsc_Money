import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:rxdart/rxdart.dart';
import '../models/notes_modal.dart';


class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = Uuid();

  // Streams for file operations
  final BehaviorSubject<bool> _isProcessing = BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<double> _uploadProgress = BehaviorSubject<double>.seeded(0.0);
  final BehaviorSubject<String> _error = BehaviorSubject<String>.seeded('');

  // Getters for streams
  Stream<bool> get isProcessing$ => _isProcessing.stream;
  Stream<double> get uploadProgress$ => _uploadProgress.stream;
  Stream<String> get error$ => _error.stream;

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
  Future<NoteAttachment?> pickImageFromCamera() async {
    try {
      _isProcessing.add(true);
      _error.add('');

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image == null) return null;

      final attachment = await _processFile(File(image.path));
      return attachment;
    } catch (e) {
      _error.add('Failed to capture image: ${e.toString()}');
      return null;
    } finally {
      _isProcessing.add(false);
    }
  }

  // Pick image from gallery
  Future<NoteAttachment?> pickImageFromGallery() async {
    try {
      _isProcessing.add(true);
      _error.add('');

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return null;

      final attachment = await _processFile(File(image.path));
      return attachment;
    } catch (e) {
      _error.add('Failed to pick image: ${e.toString()}');
      return null;
    } finally {
      _isProcessing.add(false);
    }
  }

  // Pick multiple images from gallery
  Future<List<NoteAttachment>> pickMultipleImages() async {
    try {
      _isProcessing.add(true);
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
        }
      }

      return attachments;
    } catch (e) {
      _error.add('Failed to pick images: ${e.toString()}');
      return [];
    } finally {
      _isProcessing.add(false);
      _uploadProgress.add(0.0);
    }
  }

  // Pick document files
  Future<List<NoteAttachment>> pickDocuments() async {
    try {
      _isProcessing.add(true);
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
          }
        }
      }

      return attachments;
    } catch (e) {
      _error.add('Failed to pick documents: ${e.toString()}');
      return [];
    } finally {
      _isProcessing.add(false);
      _uploadProgress.add(0.0);
    }
  }

  // Pick any file type
  Future<List<NoteAttachment>> pickAnyFiles() async {
    try {
      _isProcessing.add(true);
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
          }
        }
      }

      return attachments;
    } catch (e) {
      _error.add('Failed to pick files: ${e.toString()}');
      return [];
    } finally {
      _isProcessing.add(false);
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
    };

    return mimeTypes[ext];
  }

  // Delete attachment file
  Future<bool> deleteAttachment(NoteAttachment attachment) async {
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

  // Clear error
  void clearError() {
    _error.add('');
  }

  // Dispose streams
  void dispose() {
    _isProcessing.close();
    _uploadProgress.close();
    _error.close();
  }
}