// lib/models/document_context.dart
class DocumentContext {
  String extractedText = '';
  String documentSummary = '';
  bool hasDocument = false;
  String lastFilePath = '';
  String documentType = '';

  void clear() {
    extractedText = '';
    documentSummary = '';
    hasDocument = false;
    lastFilePath = '';
    documentType = '';
  }
}

// Create a global instance to maintain document context
final DocumentContext documentContext = DocumentContext();