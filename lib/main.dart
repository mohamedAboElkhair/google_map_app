import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  static const CameraPosition _intialCameraPosition = CameraPosition(
    target: LatLng(27.1927299, 33.4520471),
    zoom: 3,
  );

  static const CameraPosition _kLake = CameraPosition(
    bearing: 192.8334901395799,
    target: LatLng(37.43296265331129, -122.08832357078792),
    tilt: 59.440717697143555,
    zoom: 19.151926040649414,
  );

  final Set<Marker> _markers = {};

  @override
  void initState() {
    _markers.add(
      Marker(
        markerId: const MarkerId('1'),
        position: const LatLng(27.1927299, 33.4520471),
        infoWindow: const InfoWindow(
          title: 'Marker 1',
          snippet: 'This is marker 1',
        ),
        draggable: true,
        onDragEnd: (value) => print('Marker 1 Drag Ended at $value'),
      ),
    );
    _markers.add(
      Marker(
        markerId: const MarkerId('2'),
        position: const LatLng(29.1927299, 32.4520471),
        infoWindow: const InfoWindow(
          title: 'Marker 2',
          snippet: 'This is marker 1',
        ),
        draggable: true,
        onTap: () {
          print('Marker 2 Tapped');
        },
        onDrag: (newPosition) {
          // print('Marker 2 Dragged to $newPosition');
        },
        onDragEnd: (value) => print('Marker 2 Drag Ended at $value'),
      ),
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _intialCameraPosition,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: _markers,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToTheLake,
        label: const Text('To the lake!'),
        icon: const Icon(Icons.directions_boat),
      ),
    );
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }
}
