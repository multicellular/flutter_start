import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import 'package:location/location.dart';

class MapBox extends StatefulWidget {
  @override
  MapBoxState createState() => MapBoxState();
}

class MapBoxState extends State<MapBox> {
  LocationData _currentLocation;

  @override
  void initState() {
    _getUserLocation();
  }

  _getUserLocation() async {
    // LocationData currentLocation;
    String error;
    Location location = Location();
    try {
      _currentLocation = await location.getLocation();
    } catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        error = 'please grant permission';
        print(error);
      }
      if (e.code == 'PERMISSION_DENIED_NEVER_ASK') {
        error = 'permission denied- please enable it from app settings';
        print(error);
      }
      _currentLocation = null;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            'MapBox',
            style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color.fromARGB(148, 198, 246, 248),
        ),
        body: _currentLocation != null
            ? FlutterMap(
                options: MapOptions(
                  center: new LatLng(
                      _currentLocation.latitude, _currentLocation.longitude),
                  zoom: 13.0,
                  // swPanBoundary: LatLng(56.6877, 11.5089),
                  // nePanBoundary: LatLng(56.7378, 11.6644),
                ),
                layers: [
                  TileLayerOptions(
                    additionalOptions: {
                      'accessToken': '<PUT_ACCESS_TOKEN_HERE>',
                      'id': 'mapbox.streets', //其他附加内容
                    },
                    urlTemplate:
                        "https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}@2x.png?access_token=pk.eyJ1IjoiMTM4MTM4MDgzMjYiLCJhIjoiY2sxa2h3endqMDA2MDNlbG9qbDk5b3FpMiJ9.Jpg-UaKtKLEiB7cW9VSAmw",
                  ),
                  new MarkerLayerOptions(
                    markers: [
                      new Marker(
                        //! 地图标记
                        width: 80.0,
                        height: 80.0,
                        point: new LatLng(_currentLocation.latitude,
                            _currentLocation.longitude), //经纬度注意顺序
                        builder: (ctx) => new Container(
                          child: Icon(
                            Icons.person_pin_circle,
                            color: Colors.redAccent,
                          ), // 在标记的位置加上标记
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Container());
  }
}
