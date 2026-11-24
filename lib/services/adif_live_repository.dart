import '../models/station_board_model.dart';
import '../core/constants/adif_stations.dart';

export '../core/constants/adif_stations.dart' show StationInfo;

abstract class AdifLiveRepository {
  Future<List<StationBoardItem>> getDepartures(String stationCode);
  Future<List<StationBoardItem>> getArrivals(String stationCode);
  List<StationInfo> getAvailableStations();
}

class StationCatalog {
  static const List<StationInfo> stations = AdifStations.all;
}
