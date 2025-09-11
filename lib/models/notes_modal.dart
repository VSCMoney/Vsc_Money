class Note {
  final String id;
  final String title;
  final String content;
  final String? assetId; // NEW: Asset association
  final String? assetName; // NEW: Asset name for display
  final String? assetSymbol; // NEW: Asset symbol (e.g., "AAPL", "BTC")
  final List<NoteAttachment> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.assetId,
    this.assetName,
    this.assetSymbol,
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? assetId,
    String? assetName,
    String? assetSymbol,
    List<NoteAttachment>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      assetId: assetId ?? this.assetId,
      assetName: assetName ?? this.assetName,
      assetSymbol: assetSymbol ?? this.assetSymbol,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper to check if note is associated with an asset
  bool get hasAsset => assetId != null && assetId!.isNotEmpty;

  // Helper to get display text for asset
  String get assetDisplayName {
    if (!hasAsset) return '';
    if (assetSymbol != null && assetName != null) {
      return '$assetSymbol ($assetName)';
    }
    return assetSymbol ?? assetName ?? '';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'assetId': assetId,
      'assetName': assetName,
      'assetSymbol': assetSymbol,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      assetId: json['assetId'],
      assetName: json['assetName'],
      assetSymbol: json['assetSymbol'],
      attachments: (json['attachments'] as List?)
          ?.map((a) => NoteAttachment.fromJson(a))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

enum AttachmentType { image, document, audio, video, other }

class NoteAttachment {
  final String id;
  final String name;
  final String path;
  final AttachmentType type;
  final int size;
  final DateTime createdAt;
  final String? mimeType;
  final String? thumbnailPath;

  NoteAttachment({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    required this.createdAt,
    this.mimeType,
    this.thumbnailPath,
  });

  NoteAttachment copyWith({
    String? id,
    String? name,
    String? path,
    AttachmentType? type,
    int? size,
    DateTime? createdAt,
    String? mimeType,
    String? thumbnailPath,
  }) {
    return NoteAttachment(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      size: size ?? this.size,
      createdAt: createdAt ?? this.createdAt,
      mimeType: mimeType ?? this.mimeType,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'type': type.name,
      'size': size,
      'createdAt': createdAt.toIso8601String(),
      'mimeType': mimeType,
      'thumbnailPath': thumbnailPath,
    };
  }

  factory NoteAttachment.fromJson(Map<String, dynamic> json) {
    return NoteAttachment(
      id: json['id'],
      name: json['name'],
      path: json['path'],
      type: AttachmentType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => AttachmentType.other,
      ),
      size: json['size'],
      createdAt: DateTime.parse(json['createdAt']),
      mimeType: json['mimeType'],
      thumbnailPath: json['thumbnailPath'],
    );
  }
}
