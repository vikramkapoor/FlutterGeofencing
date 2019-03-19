// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geofencing/geofencing.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String geofenceState = 'N/A';
  double latitude = 23.5864;
  double longitude = 58.4224;
  double radius = 150.0;
  ReceivePort port = ReceivePort();
  final List<GeofenceEvent> triggers = <GeofenceEvent>[
    GeofenceEvent.enter,
    GeofenceEvent.dwell,
    GeofenceEvent.exit
  ];
  final AndroidGeofencingSettings androidSettings = AndroidGeofencingSettings(
      initialTrigger: <GeofenceEvent>[
        GeofenceEvent.enter,
        GeofenceEvent.exit,
        GeofenceEvent.dwell
      ],
      loiteringDelay: 1000 * 60,
      notificationResponsiveness: 1000 * 10);

  @override
  void initState() {
    super.initState();
    IsolateNameServer.registerPortWithName(
        port.sendPort, 'geofencing_send_port');
    port.listen((dynamic data) {
      print('Event: $data');
      setState(() {
        geofenceState = data;
      });
    });
    initPlatformState();
  }

  static void callback(List<String> ids, Location l, GeofenceEvent e) async {
    print('Fences: $ids Location $l Event: $e');
    final SendPort send =
        IsolateNameServer.lookupPortByName('geofencing_send_port');
    send?.send(e.toString());
  }

  static void locationcallback(
      List<String> ids, Location l, GeofenceEvent e) async {
    print('Location CallBack: $ids Location $l Event: $e');
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    print('Initializing...');
    await GeofencingManager.initialize();
    print('Initialization done');
  }

  String numberValidator(String value) {
    if (value == null) {
      return null;
    }
    final num a = num.tryParse(value);
    if (a == null) {
      return '"$value" is not a valid number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Flutter Geofencing Example'),
          ),
          body: Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text('Current state: $geofenceState'),
                    Center(
                      child: RaisedButton(
                        child: const Text('Register'),
                        onPressed: () {
                          if (latitude == null) {
                            setState(() => latitude = 0.0);
                          }
                          if (longitude == null) {
                            setState(() => longitude = 0.0);
                          }
                          if (radius == null) {
                            setState(() => radius = 0.0);
                          }
                          GeofencingManager.registerGeofence(
                              GeofenceRegion(
                                  'mtv', latitude, longitude, radius, triggers,
                                  androidSettings: androidSettings),
                              callback);
                        },
                      ),
                    ),
                    Center(
                      child: RaisedButton(
                          child: const Text('Unregister'),
                          onPressed: () =>
                              GeofencingManager.removeGeofenceById('mtv')),
                    ),
                    Center(
                      child: RaisedButton(
                          child: const Text('Current Location'),
                          onPressed: () async {
                            Location location =
                                await GeofencingManager.getCurrentLocation();
                            print('Current Location : $location');
                          }),
                    ),
                    Center(
                      child: RaisedButton(
                        child: const Text('Register Location'),
                        onPressed: () {
                          if (latitude == null) {
                            setState(() => latitude = 0.0);
                          }
                          if (longitude == null) {
                            setState(() => longitude = 0.0);
                          }
                          if (radius == null) {
                            setState(() => radius = 0.0);
                          }
                          GeofencingManager.registerLocation(
                              GeofenceRegion(
                                  'mtv', latitude, longitude, radius, triggers,
                                  androidSettings: androidSettings),
                              locationcallback);
                        },
                      ),
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Latitude',
                      ),
                      keyboardType: TextInputType.number,
                      controller:
                          TextEditingController(text: latitude.toString()),
                      onChanged: (String s) {
                        latitude = double.tryParse(s);
                      },
                    ),
                    TextField(
                        decoration:
                            const InputDecoration(hintText: 'Longitude'),
                        keyboardType: TextInputType.number,
                        controller:
                            TextEditingController(text: longitude.toString()),
                        onChanged: (String s) {
                          longitude = double.tryParse(s);
                        }),
                    TextField(
                        decoration: const InputDecoration(hintText: 'Radius'),
                        keyboardType: TextInputType.number,
                        controller:
                            TextEditingController(text: radius.toString()),
                        onChanged: (String s) {
                          radius = double.tryParse(s);
                        }),
                  ]))),
    );
  }
}
