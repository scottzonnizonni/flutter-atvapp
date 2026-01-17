import 'package:flutter/foundation.dart';
import '../models/scan_history_model.dart';
import '../models/content_model.dart';
import '../services/database_service.dart';

class HistoryProvider with ChangeNotifier {
  List<ScanHistoryModel> _history = [];
  Map<String, ContentModel> _contentCache = {};
  bool _isLoading = false;
  String? _error;

  List<ScanHistoryModel> get history => _history;
  Map<String, ContentModel> get contentCache => _contentCache;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load scan history
  Future<void> loadHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _history = await DatabaseService.instance.getAllScanHistory();

      // Load associated content
      for (var scan in _history) {
        if (!_contentCache.containsKey(scan.contentId)) {
          final content = await DatabaseService.instance.getContentById(
            scan.contentId,
          );
          if (content != null) {
            _contentCache[scan.contentId] = content;
          }
        }
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add scan to history
  Future<void> addScan(String contentId, String qrCodeId) async {
    try {
      await DatabaseService.instance.addScanHistory(contentId, qrCodeId);
      await loadHistory();
    } catch (e) {
      debugPrint('Error adding scan: $e');
    }
  }

  // Clear history
  Future<void> clearHistory() async {
    try {
      await DatabaseService.instance.clearScanHistory();
      _history = [];
      _contentCache = {};
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }
}
