import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ramzan_companion/features/location/data/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final currentLocationProvider = FutureProvider<Position?>((ref) async {
  final service = ref.read(locationServiceProvider);
  return await service.getCurrentPosition();
});

final currentCityProvider = FutureProvider<String?>((ref) async {
  final position = await ref.watch(currentLocationProvider.future);
  if (position == null) return null;

  final service = ref.read(locationServiceProvider);
  return await service.getCityFromPosition(
    position.latitude,
    position.longitude,
  );
});
