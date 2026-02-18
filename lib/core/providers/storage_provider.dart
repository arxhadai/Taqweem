import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramzan_companion/core/data/storage_service.dart';

// This provider will be overridden in main.dart
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError();
});
