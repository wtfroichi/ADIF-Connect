import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/constants/adif_stations.dart';
import '../models/station_board_model.dart';

abstract final class StationWidgetCache {
  static const MethodChannel _channel =
      MethodChannel('es.adifconnect.app/widget-cache');

  static Future<void> updateDefaultStation(StationInfo station) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      await _channel.invokeMethod<void>('updateDefaultStation', {
        'stationCode': station.adifCode,
        'stationName': station.name,
      });
    } on MissingPluginException {
      debugPrint('O widget de estación non está dispoñible nesta aplicación.');
    } on PlatformException catch (error) {
      debugPrint(
          'Non se puido actualizar a estación do widget: ${error.message}');
    }
  }

  static Future<void> cacheDepartures(
    StationInfo station,
    List<StationBoardItem> items,
  ) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      await _channel.invokeMethod<void>('cacheDepartures', {
        'stationCode': station.adifCode,
        'stationName': station.name,
        'departuresJson': jsonEncode(items.map((item) {
          return {
            ...item.toJson(),
            'destination': AdifStations.resolveName(item.destination),
          };
        }).toList()),
      });
    } on MissingPluginException {
      debugPrint('O widget de estación non está dispoñible nesta aplicación.');
    } on PlatformException catch (error) {
      debugPrint(
          'Non se puideron gardar as saídas para o widget: ${error.message}');
    }
  }
}
