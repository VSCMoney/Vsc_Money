// // lib/services/document_service.dart
// import 'dart:convert';
// import 'dart:io';
// import 'dart:math';
// import 'dart:typed_data';
//
// import 'package:docx_template/docx_template.dart';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';
// import 'package:syncfusion_flutter_pdf/pdf.dart';
// import 'package:universal_html/html.dart' as html;
//
// import '../constants/constants.dart';
// import '../screens/models/document_context.dart';
//
//
//
// class DocumentService {
//   Future<String> _extractTextFromFile(String filePath) async {
//     try {
//       // Check if filePath is valid
//       if (filePath == null || filePath.isEmpty) {
//         print("ERROR: File path is null or empty");
//         return '⚠️ Invalid file path';
//       }
//
//       print("Processing file: $filePath"); // Print the full path for debugging
//
//       // More robust extension extraction
//       String extension;
//       try {
//         extension = filePath.split('.').last.toLowerCase();
//         if (extension.contains('/') || extension.contains('\\')) {
//           // This means the path doesn't have a proper extension
//           print("ERROR: No valid extension found in path: $filePath");
//           return '⚠️ Could not determine file format';
//         }
//       } catch (e) {
//         print("ERROR extracting extension: $e");
//         return '⚠️ Error detecting file format';
//       }
//
//       print("Detected file extension: $extension"); // Debug log
//
//       // Set the document type in the context
//       documentContext.documentType = extension;
//
//       // Check for supported formats with explicit logging
//       if (extension == 'pdf') {
//         print("Processing as PDF file");
//         return await _extractTextFromPDF(filePath);
//       } else if (extension == 'docx') {
//         print("Processing as DOCX file");
//         return await _extractTextFromDocx(filePath);
//         // } else if (extension == 'jpg' ||
//         //     extension == 'jpeg' ||
//         //     extension == 'png') {
//         //   print("Processing as image file");
//         //   return await _extractTextFromImage(filePath);
//       } else {
//         print("ERROR: Unsupported file format: $extension");
//         return '⚠️ Unsupported file format: .$extension';
//       }
//     } catch (e) {
//       print("ERROR in _extractTextFromFile: $e");
//       return '⚠️ Error processing file: $e';
//     }
//   }
//
//   Future<String> _extractTextFromPDF(String filePath) async {
//     try {
//       print("Starting PDF extraction from: $filePath");
//       final File pdfFile = File(filePath);
//
//       // Check if file exists
//       if (!await pdfFile.exists()) {
//         print("ERROR: PDF file does not exist at path: $filePath");
//         return "⚠️ PDF file not found";
//       }
//
//       // Get file size for debugging
//       int fileSize = await pdfFile.length();
//       print("PDF file size: $fileSize bytes");
//
//       if (fileSize == 0) {
//         print("ERROR: PDF file is empty");
//         return "⚠️ PDF file is empty";
//       }
//
//       try {
//         final bytes = await pdfFile.readAsBytes();
//         print("Successfully read ${bytes.length} bytes from PDF");
//
//         final PdfDocument document = PdfDocument(inputBytes: bytes);
//         print("PDF document loaded with ${document.pages.count} pages");
//
//         PdfTextExtractor extractor = PdfTextExtractor(document);
//
//         StringBuffer textBuffer = StringBuffer();
//         for (int i = 0; i < document.pages.count; i++) {
//           print("Extracting text from PDF page ${i + 1}");
//           String pageText =
//           extractor.extractText(startPageIndex: i, endPageIndex: i);
//           print("Page ${i + 1} text length: ${pageText.length} characters");
//           textBuffer.write(pageText);
//           textBuffer.write('\n\n');
//         }
//
//         document.dispose();
//         String result = textBuffer.toString().trim();
//         print("Total extracted text length: ${result.length} characters");
//
//         return result.isNotEmpty
//             ? result
//             : "⚠️ No readable text found in the PDF.";
//       } catch (e) {
//         print("ERROR during PDF processing: $e");
//         return "⚠️ Error processing PDF content: $e";
//       }
//     } catch (e) {
//       print("ERROR in _extractTextFromPDF: $e");
//       return "⚠️ Error extracting text from PDF: $e";
//     }
//   }
//
//   Future<String> _extractTextFromDocx(String filePath) async {
//     try {
//       final docxFile = File(filePath);
//       final docx = await docxFile.readAsBytes();
//       final template = await DocxTemplate.fromBytes(docx);
//
//       return template.toString().isNotEmpty
//           ? template.toString()
//           : "⚠️ No readable text found in the DOCX.";
//     } catch (e) {
//       return "⚠️ Error extracting text from DOCX: $e";
//     }
//   }
//
//   // For web platforms
//   Future<String> processWebDocument(html.File file) async {
//     try {
//       print("Processing web document: ${file.name}");
//
//       // Get the file extension
//       final String extension = file.name.split('.').last.toLowerCase();
//       documentContext.documentType = extension;
//
//       // Read file content
//       final reader = html.FileReader();
//       reader.readAsArrayBuffer(file);
//
//       // Wait for the file to be read
//       await reader.onLoad.first;
//       final Uint8List bytes = reader.result as Uint8List;
//
//       String extractedText = "";
//
//       if (extension == 'pdf') {
//         // Process PDF bytes
//         extractedText = await _extractTextFromPdfBytes(bytes);
//       } else if (extension == 'docx') {
//         // Process DOCX bytes
//         extractedText = await _extractTextFromDocxBytes(bytes);
//       } else if (['jpg', 'jpeg', 'png'].contains(extension)) {
//         // Process image bytes
//         extractedText = await _extractTextFromImageBytes(bytes);
//       } else {
//         return '⚠️ Unsupported file format: .$extension';
//       }
//
//       // Save the extracted text
//       documentContext.extractedText = extractedText;
//       documentContext.hasDocument = true;
//       documentContext.lastFilePath = file.name;
//
//       // Get summary
//       final summary = await _getDocumentSummary(extractedText);
//       documentContext.documentSummary = summary;
//
//       return "✅ Document processed successfully. I've analyzed the content and I'm ready to answer your questions about it.";
//     } catch (e) {
//       print("ERROR in processWebDocument: $e");
//       return "⚠️ Error processing document: $e";
//     }
//   }
//
//   // Web-specific extraction methods
//   Future<String> _extractTextFromPdfBytes(Uint8List bytes) async {
//     try {
//       final PdfDocument document = PdfDocument(inputBytes: bytes);
//       PdfTextExtractor extractor = PdfTextExtractor(document);
//
//       StringBuffer textBuffer = StringBuffer();
//       for (int i = 0; i < document.pages.count; i++) {
//         textBuffer
//             .write(extractor.extractText(startPageIndex: i, endPageIndex: i));
//         textBuffer.write('\n\n');
//       }
//
//       document.dispose();
//       String result = textBuffer.toString().trim();
//       return result.isNotEmpty ? result : "⚠️ No readable text found in the PDF.";
//     } catch (e) {
//       return "⚠️ Error extracting text from PDF: $e";
//     }
//   }
//
//   Future<String> _extractTextFromDocxBytes(Uint8List bytes) async {
//     try {
//       final template = await DocxTemplate.fromBytes(bytes);
//       return template.toString().isNotEmpty
//           ? template.toString()
//           : "⚠️ No readable text found in the DOCX.";
//     } catch (e) {
//       return "⚠️ Error extracting text from DOCX: $e";
//     }
//   }
//
//   Future<String> _extractTextFromImageBytes(Uint8List bytes) async {
//     try {
//       // For web, ML Kit integration works differently
//       // You may need a web-compatible OCR solution
//       return "⚠️ Image OCR is not supported in web version yet.";
//     } catch (e) {
//       return "⚠️ Error extracting text from image: $e";
//     }
//   }
//
//   // Process uploaded document and get initial summary
//   Future<String> processDocument(String filePath) async {
//     try {
//       print("Starting document processing for path: $filePath");
//
//       // Validate file path
//       if (filePath == null || filePath.isEmpty) {
//         print("ERROR: File path is null or empty");
//         return "⚠️ Invalid file path";
//       }
//
//       // Check if file exists
//       final file = File(filePath);
//       if (!await file.exists()) {
//         print("ERROR: File does not exist at path: $filePath");
//         return "⚠️ File not found: $filePath";
//       }
//
//       // Clear previous document context
//       documentContext.clear();
//
//       // Extract text from the document with detailed logging
//       print("Calling _extractTextFromFile");
//       final extractedText = await _extractTextFromFile(filePath);
//       print(
//           "Result from _extractTextFromFile: ${extractedText.substring(0, min(50, extractedText.length))}...");
//
//       if (extractedText.startsWith('⚠️')) {
//         print("ERROR returned from text extraction: $extractedText");
//         return extractedText;
//       }
//
//       // Save the extracted text
//       documentContext.extractedText = extractedText;
//       documentContext.hasDocument = true;
//       documentContext.lastFilePath = filePath;
//
//       print(
//           "Document processed successfully, extracted text length: ${extractedText.length}");
//
//       // Get an initial summary of the document using Gemini
//       print("Getting document summary from Gemini");
//       final summary = await _getDocumentSummary(extractedText);
//       documentContext.documentSummary = summary;
//
//       return "✅ Document processed successfully. I've analyzed the content and I'm ready to answer your questions about it.";
//     } catch (e) {
//       print("ERROR in processDocument: $e");
//       return "⚠️ Error processing document: $e";
//     }
//   }
//
//   // Get a summary of the document
//   Future<String> _getDocumentSummary(String documentText) async {
//     if (ApiConstants.geminiApiKey.isEmpty) return "Error: Missing API key.";
//
//     final apiUrl =
//         "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0:generateContent?key=${ApiConstants.geminiApiKey}";
//
//     final requestBody = {
//       "contents": [
//         {
//           "role": "user",
//           "parts": [
//             {"text": "Summarize this document: $documentText"}
//           ]
//         }
//       ],
//       "generationConfig": {"temperature": 0.3, "maxOutputTokens": 500}
//     };
//
//     try {
//       final response = await http.post(
//         Uri.parse(apiUrl),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(requestBody),
//       );
//
//       if (response.statusCode == 200) {
//         final jsonResponse = jsonDecode(response.body);
//         return jsonResponse["candidates"][0]["content"]["parts"][0]["text"] ??
//             "No summary available.";
//       } else {
//         return "Error: ${response.statusCode}";
//       }
//     } catch (e) {
//       return "⚠️ API Error: $e";
//     }
//   }
//
//   Future<String> checkDependencies() async {
//     try {
//       StringBuffer status = StringBuffer();
//
//       // Check PDF dependency
//       try {
//         final testDoc = PdfDocument();
//         testDoc.dispose();
//         status.write("✅ PDF library working\n");
//       } catch (e) {
//         status.write("❌ PDF library error: $e\n");
//       }
//
//       // Check file access
//       try {
//         final directory = await getApplicationDocumentsDirectory();
//         status.write("✅ File system access working: ${directory.path}\n");
//       } catch (e) {
//         status.write("❌ File system access error: $e\n");
//       }
//
//       return status.toString();
//     } catch (e) {
//       return "Error checking dependencies: $e";
//     }
//   }
//
//   int min(int a, int b) => a < b ? a : b;
// }