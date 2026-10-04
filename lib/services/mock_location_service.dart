import '../core/utils/geo.dart';
import '../features/gyms/models/gym.dart';
import '../features/session/models/location_snapshot.dart';
import '../features/session/services/location_service.dart';

class MockLocationService implements LocationService {
  MockLocationService({LocationSnapshot? initial})
      : _snapshot = initial ??
            const LocationSnapshot(
              point: outsidePoint,
              presence: DemoPresence.outside,
            );

  static const outsidePoint = GeoPoint(31.4582, 76.2594);

  LocationSnapshot _snapshot;

  @override
  LocationSnapshot current() => _snapshot;

  @override
  LocationSnapshot outsideGym() {
    _snapshot = const LocationSnapshot(
      point: outsidePoint,
      presence: DemoPresence.outside,
    );
    return _snapshot;
  }

  @override
  LocationSnapshot enterZone(Gym gym) {
    _snapshot = LocationSnapshot(
      point: gym.location,
      presence: DemoPresence.inside,
    );
    return _snapshot;
  }

  @override
  LocationSnapshot leaveZone() => outsideGym();
}
