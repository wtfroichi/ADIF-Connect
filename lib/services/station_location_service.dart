import 'package:geolocator/geolocator.dart';

import '../core/constants/adif_stations.dart';

enum StationLocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  stationNotFound,
}

class StationLocationException implements Exception {
  final StationLocationFailure failure;

  const StationLocationException(this.failure);
}

class StationLocationService {
  Future<StationInfo> findNearestStation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const StationLocationException(
        StationLocationFailure.serviceDisabled,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const StationLocationException(
        StationLocationFailure.permissionDeniedForever,
      );
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      throw const StationLocationException(
        StationLocationFailure.permissionDenied,
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 20),
      ),
    );
    final station = AdifStations.nearestTo(
      position.latitude,
      position.longitude,
    );
    if (station == null) {
      throw const StationLocationException(
        StationLocationFailure.stationNotFound,
      );
    }
    return station;
  }
}
