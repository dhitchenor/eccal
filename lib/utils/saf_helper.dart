import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';

// Helper class for Storage Access Framework (SAF) operations on Android.
// Uses native Kotlin code via method channels to properly handle SAF permissions.
class SafHelper {
  static const MethodChannel _channel = MethodChannel('com.dhitchenor.eccal/saf');
  
  // Pick a directory using SAF and get persistent URI permission
  // Returns the tree URI string if successful, null if cancelled
  static Future<String?> pickDirectory() async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('SAF is only available on Android');
    }
    
    try {
      final String? uri = await _channel.invokeMethod('pickDirectory');
      return uri;
    } on PlatformException catch (e) {
      if (e.code == 'CANCELLED') {
        return null; // User cancelled
      }
      rethrow;
    }
  }
  
  // Persist URI permission for a saved tree URI
  // Call this when restoring from SharedPreferences to ensure we still have access
  static Future<bool> persistUriPermission(String uri) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('SAF is only available on Android');
    }
    
    try {
      final bool result = await _channel.invokeMethod('persistUriPermission', {
        'uri': uri,
      });
      return result;
    } on PlatformException catch (_) {
      return false;
    }
  }
  
  // Write content to a file in the SAF directory
  // Returns the file URI if successful
  static Future<String> writeFile({
    required String treeUri,
    required String fileName,
    required String content,
    String? subfolder, // Optional subfolder within the SAF directory
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('SAF is only available on Android');
    }
    
    final String fileUri = await _channel.invokeMethod('writeFile', {
      'treeUri': treeUri,
      'fileName': fileName,
      'content': content,
      'subfolder': subfolder, // Pass subfolder to Kotlin
    });
    return fileUri;
  }
  
  // Write binary content (bytes) to a file in the SAF directory (with optional subfolder)
  // Returns the file URI if successful
  // Use this for ZIP files, PDFs, images, etc.
  static Future<String> writeFileBytes({
    required String treeUri,
    required String fileName,
    required List<int> bytes,
    String? subfolder, // Optional subfolder within the SAF directory
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('SAF is only available on Android');
    }
    
    final String fileUri = await _channel.invokeMethod('writeFileBytes', {
      'treeUri': treeUri,
      'fileName': fileName,
      'bytes': Uint8List.fromList(bytes), // Convert to Uint8List for platform channel
      'subfolder': subfolder,
    });
    return fileUri;
  }
  
  // Read content from a file in the SAF directory
  static Future<String> readFile({
    required String treeUri,
    required String fileName,
    String? subfolder,
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('SAF is only available on Android');
    }
    
    final String content = await _channel.invokeMethod('readFile', {
      'treeUri': treeUri,
      'fileName': fileName,
      'subfolder': subfolder,
    });
    return content;
  }
  
  /// List all .ics files in the SAF directory
  static Future<List<String>> listFiles(String treeUri, {String? subfolder}) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('SAF is only available on Android');
    }
    
    final List<dynamic> files = await _channel.invokeMethod('listFiles', {
      'treeUri': treeUri,
      'subfolder': subfolder,
    });
    return files.cast<String>();
  }
  
  // Delete a file from the SAF directory
  static Future<bool> deleteFile({
    required String treeUri,
    required String fileName,
    String? subfolder, // Optional subfolder within the SAF directory
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('SAF is only available on Android');
    }
    
    final bool deleted = await _channel.invokeMethod('deleteFile', {
      'treeUri': treeUri,
      'fileName': fileName,
      'subfolder': subfolder,
    });
    return deleted;
  }
  
  // Check if we still have access to a saved URI
  static Future<bool> checkAccess(String uri) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('SAF is only available on Android');
    }
    
    final bool hasAccess = await _channel.invokeMethod('checkAccess', {
      'uri': uri,
    });
    return hasAccess;
  }
  
  /// Get display name for a tree URI (folder name)
  static Future<String?> getDisplayName(String treeUri) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('SAF is only available on Android');
    }
    
    try {
      final String? name = await _channel.invokeMethod('getDisplayName', {
        'treeUri': treeUri,
      });
      return name;
    } on PlatformException catch (_) {
      return null;
    }
  }
}