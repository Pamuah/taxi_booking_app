import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import 'package:google_place/google_place.dart';
import 'package:taxi_booking_app/MapScreen.dart';
import 'package:taxi_booking_app/main.dart';
import 'MapUtils.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

List cars = [
  {'id': 0, 'name': 'Select a Ride', 'price': 0.0},
  {'id': 1, 'name': 'Uber', 'price': 3.0},
  {'id': 2, 'name': 'Uber comfort', 'price': 10.0},
  {'id': 3, 'name': 'Uber luxury', 'price': 20.0},
];

void main(List<String> args) {
  runApp(const Mapscreen());
}

class Mapscreen extends StatefulWidget {
  final DetailsResult? startPosition;
  final DetailsResult? endPosition;

  const Mapscreen({super.key, this.startPosition, this.endPosition});

  @override
  State<Mapscreen> createState() => _MapscreenState();
}

class _MapscreenState extends State<Mapscreen> {
  //late GoogleMapController mapController;
  late CameraPosition _initialPosition;
  final Completer<GoogleMapController> _controller = Completer();

  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();

  int selectedCarId = 1;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  _addPolyLine() {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id,
        color: Colors.black,
        points: polylineCoordinates,
        width: 6);
    polylines[id] = polyline;
    setState(() {});
  }

  _getPolyline() async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        'AIzaSyBOkMeA9twGGfnr4A-oIRToqLiIhmMSzg0',
        PointLatLng(widget.startPosition!.geometry!.location!.lat!,
            widget.startPosition!.geometry!.location!.lng!),
        PointLatLng(widget.endPosition!.geometry!.location!.lat!,
            widget.endPosition!.geometry!.location!.lng!),
        travelMode: TravelMode.driving);
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }
    _addPolyLine();
  }

  // Constants for different car types
  static const double basePrice = 4.5;
  static const double comfortPrice = 5.5;
  static const double luxuryPrice = 10.0;

  // Function to calculate the actual price based on car type and distance
  double calculatePrice(double distance) {
    double price;
    switch (selectedCarId) {
      case 1:
        price = basePrice * distance;
        break;
      case 2:
        price = comfortPrice * distance;
        break;
      case 3:
        price = luxuryPrice * distance;
        break;
      default:
        price = 0.0; // Default price for "Select a Ride" option
    }
    return price;
  }

  double earthRadius = 6371.0; // Earth's radius in kilometers

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    double lat1Rad = _degreesToRadians(lat1);
    double lon1Rad = _degreesToRadians(lon1);
    double lat2Rad = _degreesToRadians(lat2);
    double lon2Rad = _degreesToRadians(lon2);

    double dLat = lat2Rad - lat1Rad;
    double dLon = lon2Rad - lon1Rad;
    double a = pow(sin(dLat / 2), 2) +
        cos(lat1Rad) * cos(lat2Rad) * pow(sin(dLon / 2), 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  @override
  Widget build(BuildContext context) {
    double distance = calculateDistance(
      widget.startPosition!.geometry!.location!.lat!,
      widget.startPosition!.geometry!.location!.lng!,
      widget.endPosition!.geometry!.location!.lat!,
      widget.endPosition!.geometry!.location!.lng!,
    );

    double actualPrice = calculatePrice(distance);
    print('Distance between the two points: ${distance.toStringAsFixed(2)} km');
    print('Actual price: GHC${actualPrice.toStringAsFixed(2)}');

    Set<Marker> _markers = {
      Marker(
          markerId: MarkerId('start'),
          position: LatLng(widget.startPosition!.geometry!.location!.lat!,
              widget.startPosition!.geometry!.location!.lng!)),
      Marker(
          markerId: MarkerId('end'),
          position: LatLng(widget.endPosition!.geometry!.location!.lat!,
              widget.endPosition!.geometry!.location!.lng!))
    };

    return MaterialApp(
      home: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            height: 20,
            width: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 30,
                )),
          ),
        ),
        body: Stack(children: [
          LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            return SizedBox(
              //    height: constraints.maxHeight / 2,
              child: GoogleMap(
                polylines: Set<Polyline>.of(polylines.values),
                initialCameraPosition: _initialPosition = CameraPosition(
                  target: LatLng(widget.startPosition!.geometry!.location!.lat!,
                      widget.startPosition!.geometry!.location!.lng!),
                  zoom: 15,
                ),
                markers: Set.from(_markers),
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                  Future.delayed(Duration(milliseconds: 2000), () {
                    controller.animateCamera(CameraUpdate.newLatLngBounds(
                        MapUtils.boundsFromLatLngList(
                            _markers.map((loc) => loc.position).toList()),
                        50));

                    _getPolyline();
                  });
                },
              ),
            );
          }),
          DraggableScrollableSheet(
              //   snapSizes: [0.5, 1],
              snap: false,
              initialChildSize: 0.3,
              minChildSize: 0.3,
              maxChildSize: 0.5,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Container(
                  color: Colors.white,
                  child: ListView.builder(
                    physics: ClampingScrollPhysics(),
                    controller: scrollController,
                    itemCount: cars.length,
                    itemBuilder: (BuildContext context, int index) {
                      final car = cars[index];

                      if (index == 0) {
                        return Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              SizedBox(
                                width: 50,
                                child: Divider(
                                  thickness: 5,
                                ),
                              ),
                              Text(
                                "Choose a Trip ",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    wordSpacing: 2.0),
                              )
                            ],
                          ),
                        );
                      }

                      double totalPrice = car['price'] + actualPrice;

                      return Card(
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          contentPadding: EdgeInsets.all(10.0),
                          onTap: () {
                            setState(() {
                              selectedCarId = car['id'];
                            });
                          },
                          leading: Icon(Icons.car_rental),
                          title: Text(
                            car['name'],
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          trailing: Text(
                            'Total Price: GHC${totalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          selected: selectedCarId == car['id'],
                          selectedTileColor: Color.fromARGB(255, 222, 241, 222),
                        ),
                      );
                    },
                  ),
                );
              }),
        ]),
      ),
    );
  }
}
