import '../../gyms/models/gym.dart';
import '../models/location_snapshot.dart';

abstract class LocationService {
  LocationSnapshot current();

  LocationSnapshot outsideGym();

  LocationSnapshot enterZone(Gym gym);

  LocationSnapshot leaveZone();
}
