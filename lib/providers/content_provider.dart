import 'package:flutter/foundation.dart';
import '../models/content_model.dart';
import '../services/database_service.dart';

class ContentProvider with ChangeNotifier {
  List<ContentModel> _contents = [];
  bool _isLoading = false;

  List<ContentModel> get contents => _contents;
  bool get isLoading => _isLoading;

  // Load all content
  Future<void> loadContents() async {
    _isLoading = true;
    notifyListeners();

    try {
      _contents = await DatabaseService.instance.getAllContent();
    } catch (e) {
      debugPrint('Error loading contents: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get content by ID
  Future<ContentModel?> getContentById(String id) async {
    try {
      return await DatabaseService.instance.getContentById(id);
    } catch (e) {
      debugPrint('Error getting content: $e');
      return null;
    }
  }

  // Get content by QR code ID
  Future<ContentModel?> getContentByQrCodeId(String qrCodeId) async {
    try {
      return await DatabaseService.instance.getContentByQrCodeId(qrCodeId);
    } catch (e) {
      debugPrint('Error getting content by QR: $e');
      return null;
    }
  }

  // Create new content
  Future<bool> createContent(ContentModel content) async {
    try {
      await DatabaseService.instance.createContent(content);
      await loadContents();
      return true;
    } catch (e) {
      debugPrint('Error creating content: $e');
      return false;
    }
  }

  // Update content
  Future<bool> updateContent(ContentModel content) async {
    try {
      await DatabaseService.instance.updateContent(content);
      await loadContents();
      return true;
    } catch (e) {
      debugPrint('Error updating content: $e');
      return false;
    }
  }

  // Delete content
  Future<bool> deleteContent(String id) async {
    try {
      await DatabaseService.instance.deleteContent(id);
      await loadContents();
      return true;
    } catch (e) {
      debugPrint('Error deleting content: $e');
      return false;
    }
  }
}
