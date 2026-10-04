import '../core/utils/geo.dart';
import '../features/gyms/models/gym.dart';
import '../features/gyms/services/gym_service.dart';

class MockGymService implements GymService {
  static const gyms = <Gym>[
    Gym(
      id: 'iron-house',
      name: 'Iron House Gym',
      address: 'Una, Himachal Pradesh',
      location: GeoPoint(31.4689, 76.2708),
      placeholderLabel: 'IH',
    ),
    Gym(
      id: 'fitzone-una',
      name: 'FitZone Una',
      address: 'Mehatpur Road, Una',
      location: GeoPoint(31.4712, 76.2741),
      placeholderLabel: 'FZ',
    ),
    Gym(
      id: 'muscle-factory',
      name: 'Muscle Factory',
      address: 'Nangal Road, Una',
      location: GeoPoint(31.4651, 76.2664),
      placeholderLabel: 'MF',
    ),
    Gym(
      id: 'anytime-fitness',
      name: 'Anytime Fitness',
      address: 'Rakkar Colony, Una',
      location: GeoPoint(31.4744, 76.2689),
      placeholderLabel: 'AF',
    ),
    Gym(
      id: 'fitness-hub',
      name: 'The Fitness Hub',
      address: 'Hamirpur Road, Una',
      location: GeoPoint(31.4628, 76.2755),
      placeholderLabel: 'FH',
    ),
  ];

  @override
  List<Gym> allGyms() => List.unmodifiable(gyms);

  @override
  List<Gym> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return allGyms();
    return gyms
        .where(
          (gym) =>
              gym.name.toLowerCase().contains(q) ||
              gym.address.toLowerCase().contains(q),
        )
        .toList();
  }
}
