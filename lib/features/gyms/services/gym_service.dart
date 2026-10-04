import '../models/gym.dart';

abstract class GymService {
  List<Gym> allGyms();

  List<Gym> search(String query);
}
