// Scan history model
class ScanHistoryModel {
  final String id;
  final String contentId;
  final String qrCodeId;
  final DateTime scannedAt;

  ScanHistoryModel({
    required this.id,
    required this.contentId,
    required this.qrCodeId,
    required this.scannedAt,
  });

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content_id': contentId,
      'qr_code_id': qrCodeId,
      'scanned_at': scannedAt.toIso8601String(),
    };
  }

  // Create from Map
  factory ScanHistoryModel.fromMap(Map<String, dynamic> map) {
    return ScanHistoryModel(
      id: map['id'] as String,
      contentId: map['content_id'] as String,
      qrCodeId: map['qr_code_id'] as String,
      scannedAt: DateTime.parse(map['scanned_at'] as String),
    );
  }
}
