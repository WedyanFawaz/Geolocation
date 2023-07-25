import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_glocation/current_loc.dart';
import 'package:flutter_application_glocation/locations.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class DistanceMeasure extends StatefulWidget {
  @override
  State<DistanceMeasure> createState() => DistanceMeasureState();
}

class DistanceMeasureState extends State<DistanceMeasure> {
  Completer<GoogleMapController> _controller = Completer();
  TextEditingController _originController = TextEditingController();
  TextEditingController _destinationController = TextEditingController();

  Set<Marker> _markers = Set<Marker>();
  Set<Polygon> _polygons = Set<Polygon>();
  Set<Polyline> _polylines = Set<Polyline>();
  List<LatLng> polygonLatLngs = <LatLng>[];
  late GoogleMapController mapController;
  int _polygonIdCounter = 1;
  int _polylineIdCounter = 1;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }
  Future<CameraPosition> _getCurrentLocation() async {
  Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);
  LatLng currentLocation = LatLng(position.latitude, position.longitude);
  _setMarker(currentLocation);

  return CameraPosition(
    target: currentLocation,
    zoom: 14,
  );
}
  @override
  void initState() {
    super.initState();
    
  }

  void _setMarker(LatLng point) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('marker'),
          position: point,
        ),
      );
    });
  }

  void _setPolygon() {
    final String polygonIdVal = 'polygon_$_polygonIdCounter';
    _polygonIdCounter++;

    _polygons.add(
      Polygon(
        polygonId: PolygonId(polygonIdVal),
        points: polygonLatLngs,
        strokeWidth: 2,
        fillColor: Colors.transparent,
      ),
    );
  }

  void _setPolyline(List<PointLatLng> points) {
    final String polylineIdVal = 'polyline_$_polylineIdCounter';
    _polylineIdCounter++;

    _polylines.add(
      Polyline(
        polylineId: PolylineId(polylineIdVal),
        width: 2,
        color: Colors.blue,
        points: points
            .map(
              (point) => LatLng(point.latitude, point.longitude),
            )
            .toList(),
      ),
    );
  }
    Future<Position> _determinePisition() async {
    bool sereviceEnabled;
    LocationPermission userPermission;

    sereviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!sereviceEnabled) {
      return Future.error("Location services are disabled !");
    }
    userPermission = await Geolocator.checkPermission();
    if (userPermission == LocationPermission.denied) {
      userPermission = await Geolocator.requestPermission();
      if (userPermission == LocationPermission.denied) {
        return Future.error("Location services are disabled !");
      }
    }
    if (userPermission == LocationPermission.deniedForever) {
      return Future.error("Location services are permantly denied !");
    }
    Position position = await Geolocator.getCurrentPosition();
    return position;
  }



  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      leading:  IconButton(  onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CurrentLoc()));
                    }, icon: Icon(Icons.arrow_back)),
                    title: Text('Distance Measure'),

      ),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _originController,
        cursorColor: Theme.of(context).colorScheme.inversePrimary,            
                      decoration: InputDecoration(hintText: 'Start Point'),
                      onChanged: (value) {
                        print(value);
                      },
                    ),
                    TextFormField(
                      controller: _destinationController,
                      decoration: InputDecoration(hintText: 'End Point'),
                      onChanged: (value) {
                        print(value);
                      },
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  var directions = await LocationService().getDirections(
                    _originController.text,
                    _destinationController.text,
                  );
                  _goToPlace(
                    directions['start_location']['lat'],
                    directions['start_location']['lng'],
                    directions['bounds_ne'],
                    directions['bounds_sw'],
                  );

                  _setPolyline(directions['polyline_decoded']);
                },
                icon: Icon(Icons.search),
              ),
            ],
          ),
          Expanded(
  child: FutureBuilder<CameraPosition>(
    future: _getCurrentLocation(),
    builder: (BuildContext context, AsyncSnapshot<CameraPosition> snapshot) {
      if (snapshot.hasData) {
        return GoogleMap(
          mapType: MapType.normal,
          markers: _markers,
          polygons: _polygons,
          polylines: _polylines,
          initialCameraPosition: snapshot.data!,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
          onTap: (point) {
            setState(() {
              polygonLatLngs.add(point);
              _setPolygon();
            });
          },
        );
      } else {
        return Center(
          child: CircularProgressIndicator(),
        );
      }
    },
  ),
),
        ],
      ),
    );
  }

  Future<void> _goToPlace(
    double lat,
    double lng,
    Map<String, dynamic> boundsNe,
    Map<String, dynamic> boundsSw,
  ) async {
  
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 12),
      ),
    );

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(boundsSw['lat'], boundsSw['lng']),
            northeast: LatLng(boundsNe['lat'], boundsNe['lng']),
          ),
          25),
    );
    _setMarker(LatLng(lat, lng));
  }

  
}

