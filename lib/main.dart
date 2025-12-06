import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  StreamSubscription<Position>? _positionSubscription;
  bool get _geocodingSupported =>
      kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  // Source - https://stackoverflow.com/a/56534916
  // Posted by Miguel Ruivo, modified by community. See post 'Timeline' for change history
  // Retrieved 2025-12-06, License - CC BY-SA 4.0

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  loadMarker() async {
    final Uint8List markerIcon = await getBytesFromAsset(
      'assets/images/store.png',
      50,
    );
    _markers.add(
      Marker(
        icon: BitmapDescriptor.bytes(markerIcon),
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
    // _markers.add(
    //   Marker(
    //     markerId: const MarkerId('2'),
    //     position: const LatLng(29.1927299, 32.4520471),
    //     infoWindow: const InfoWindow(
    //       title: 'Marker 2',
    //       snippet: 'This is marker 1',
    //     ),
    //     draggable: true,
    //     onTap: () {
    //       print('Marker 2 Tapped');
    //     },
    //     onDrag: (newPosition) {
    //       // print('Marker 2 Dragged to $newPosition');
    //     },
    //     onDragEnd: (value) => print('Marker 2 Drag Ended at $value'),
    //   ),
    // );
    setState(() {});
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  getCurrentLocation() async {
    try {
      Position position = await _determinePosition();
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 1,
          ),
        ),
      );
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  listenToUserLocation() {
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position? position) {
          log(
            position == null
                ? 'Unknown'
                : '${position.latitude.toString()}, ${position.longitude.toString()}',
          );
        });
  }

  calculateDistanceBetweenTwoPoints(LatLng point1, LatLng point2) {
    double distanceInMeters = Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
    log('Distance: $distanceInMeters meters');
  }

  getLocationFromAddress(String address) async {
    if (!_geocodingSupported) {
      log('Geocoding not supported on this platform.');
      return;
    }
    try {
      List<Location> locations = await locationFromAddress(address);
      for (var location in locations) {
        log('Location: ${location.latitude}, ${location.longitude}');
      }
    } catch (e) {
      log('Error: $e');
    }
  }

  getAddressFromLocation(double latitude, double longitude) async {
    if (!_geocodingSupported) {
      log('Geocoding not supported on this platform.');
      return;
    }
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      for (var placemark in placemarks) {
        log(
          'Address: ${placemark.street}, ${placemark.locality}, ${placemark.country}',
        );
      }
    } catch (e) {
      log('Error: $e');
    }
  }

  @override
  void initState() {
    loadMarker();
    if (_geocodingSupported) {
      getLocationFromAddress("Gronausestraat 710, Enschede");
      getAddressFromLocation(52.2165157, 6.9437819);
    } else {
      log('Skipping geocoding calls: unsupported platform.');
    }
    calculateDistanceBetweenTwoPoints(
      const LatLng(27.1927299, 33.4520471),
      const LatLng(29.1927299, 32.4520471),
    );
    getCurrentLocation();
    listenToUserLocation();
    super.initState();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
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
        onPressed: () {
          _animateToPosition(_kLake.target);
        },
        label: const Text('To the lake!'),
        icon: const Icon(Icons.directions_boat),
      ),
    );
  }

  Future<void> _animateToPosition(LatLng position) async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 14.0),
      ),
    );
  }
}
