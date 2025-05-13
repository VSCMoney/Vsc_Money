// // lib/utils/file_helpers.dart
// import 'dart:io';
// import 'dart:typed_data';
//
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/foundation.dart';
// import 'package:path/path.dart' as path;
// import 'package:path_provider/path_provider.dart';
// import 'package:universal_html/html.dart' as html;
//
// import '../../services/document_service.dart';
// import '../models/document_context.dart';
//
// class FileHelpers {
//   static final DocumentService _documentService = DocumentService();
//
//   static Future<String> pickAndProcessFile() async {
//     if (kIsWeb) {
//       return await _pickWebFile();
//     } else {
//       return await _pickNativeFile();
//     }
//   }
//
//   static Future<String> _pickNativeFile() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['pdf', 'docx', 'jpg', 'png'],
//     );
//
//     if (result != null && result.files.isNotEmpty) {
//       String? filePath = result.files.single.path;
//       if (filePath != null) {
//         return await _documentService.processDocument(filePath);
//       }
//     }
//
//     return "No file selected.";
//   }
//
//   static Future<String> _pickWebFile() async {
//     final uploadInput = html.FileUploadInputElement();
//     uploadInput.accept = '.pdf,.docx,.jpg,.jpeg,.png';
//     uploadInput.click();
//
//     try {
//       final event = await uploadInput.onChange.first;
//
//       if (uploadInput.files != null && uploadInput.files!.isNotEmpty) {
//         final file = uploadInput.files![0];
//         return await _documentService.processWebDocument(file);
//       }
//     } catch (e) {
//       return "Error selecting file: $e";
//     }
//
//     return "No file selected.";
//   }
//
//   static Future<File> saveTemporaryFile(Uint8List bytes, String fileName) async {
//     final directory = await getTemporaryDirectory();
//     final filePath = path.join(directory.path, fileName);
//     final file = File(filePath);
//     await file.writeAsBytes(bytes);
//     return file;
//   }
//
//   static String getFileExtension(String fileName) {
//     try {
//       return fileName.split('.').last.toLowerCase();
//     } catch (e) {
//       return '';
//     }
//   }
//
//   static bool isFileSupported(String fileName) {
//     final extension = getFileExtension(fileName);
//     return ['pdf', 'docx', 'jpg', 'jpeg', 'png'].contains(extension);
//   }
//
//   static Future<void> clearTemporaryFiles() async {
//     try {
//       final directory = await getTemporaryDirectory();
//       final files = directory.listSync();
//       for (var file in files) {
//         if (file is File) {
//           await file.delete();
//         }
//       }
//     } catch (e) {
//       print("Error clearing temporary files: $e");
//     }
//   }
// }