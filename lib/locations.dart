import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_places_flutter/constants.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

class Location {
  String? address;
  double? lat;
  double? long;

  Location({this.address, this.lat, this.long});

  Location.fromJson(Map<String, dynamic> json)
      : address = json['formatted_address'],
        lat = json['geometry.location.lat'],
        long = json['geometry.location.lng'];

  Future<List<Map?>> getLocation(List<String> places) async {
    var requests = places.map((place) async {
      final String request =
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$place&key=$apiKey';

      final response = await get(Uri.parse(request));
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'OK') {
          return {
            "id": place,
            'address': result['result']['formatted_address'],
            'lat': result['result']['geometry']['location']['lat'].toString(),
            'lng': result['result']['geometry']['location']['lng'].toString()
          };
        }
        //return null;
        throw Exception(result['error_message']);
      } else {
        throw Exception('Failed to fetch suggestion');
      }
      return null;
      //log(res.body);
    });
    return await Future.wait(requests);
  }

  getShortPath(List<Map?> places) async {
    String username = 'mouin';
    String password = 'P@ssw0rd';
    String basicAuth =
        'Basic ' + base64.encode(utf8.encode('$username:$password'));
    log('auth' + basicAuth);
    var map = new Map<String, dynamic>();
    map['locations'] = json.encode(places);

    Response r = await post(Uri.parse('https://api.routexl.com/tour'),
        headers: <String, String>{'authorization': basicAuth}, body: map);
    var result = json.decode(r.body);
    var routes = (result['route'] as Map<String, dynamic>);
    var routeKeys = routes.keys;
    List<Map<String, dynamic>> routesList = [];

    for (var key in routeKeys) {
      var route = routes[key];
      var place = {};
      places.forEach((element) {
        route["name"] = route["name"].toString().replaceAll("&amp;", "&");
        if(element!['address'] == route['name']){
          place = element;
        }
      });
      if(place.isEmpty){
        log("MK: place is empty: ${route['name']}");
      }
      // places.firstWhere(
      //     (element) => element!['address'] == route['name'],
      //     // orElse: () => null
      // );
      if (place != null && place.isNotEmpty) {
        route['lat'] = place['lat'];
        route['lng'] = place['lng'];
      }
      routesList.add(route);
    }
    result['route'] = routesList;
    return result;
  }
}

final location = Location();
