class Attachment {
  final String id;
  final String filename;
  final String url;
  final DateTime uploadedAt;
  final String? uploadedBy;
  final int? size;

  const Attachment({required this.id, required this.filename, required this.url, required this.uploadedAt, this.uploadedBy, this.size});

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] ?? '',
      filename: json['filename'] ?? '',
      url: json['url'] ?? '',
      uploadedAt: DateTime.parse(json['uploadedAt'] ?? DateTime.now().toIso8601String()),
      uploadedBy: json['uploadedBy'],
      size: json['size'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'url': url,
      'uploadedAt': uploadedAt.toIso8601String(),
      if (uploadedBy != null) 'uploadedBy': uploadedBy,
      if (size != null) 'size': size,
    };
  }
}
