import '../entities/home_entities.dart';

abstract class HomeRepository {
  Future<HomeOverview> load();
}
