import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_places_flutter/address_search.dart';
import 'package:google_places_flutter/locations.dart';
import 'package:google_places_flutter/place_service.dart';
import 'package:google_places_flutter/locations.dart';
import 'package:google_places_flutter/providers/delivery_location_provider.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'home_page.dart';
import 'models.dart';
import 'tracking.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => DeliveryLocationProvider())
      ],
      child: MaterialApp(
        title: 'Routing App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.teal,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: MyHomePage(title: 'Destination Addresses Search'),
      ),
    );
  }
}


