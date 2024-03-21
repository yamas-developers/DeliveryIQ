import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_places_flutter/helpers.dart';
import 'package:google_places_flutter/place_service.dart';
import 'package:google_places_flutter/providers/delivery_location_provider.dart';
import 'package:google_places_flutter/route_details_widget.dart';
import 'package:google_places_flutter/tracking.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:google_places_flutter/locations.dart';

import 'address_search.dart';
import 'kmeans.dart';
import 'models.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String sourceLocation =
      'EjNCYWxhdCwgWWF2dXogU2VsaW0gQ2FkZGVzaSwgRmF0aWgvxLBzdGFuYnVsLCBUdXJrZXkiLiosChQKEglBjVbbHrrKFBGAfBWyUNskLxIUChIJaS0ixQK6yhQRPkjTz-BwuiQ'; //original
  List<String> places = [];
  List<Delivery> deliveries = [];

  // ignore: non_constant_identifier_names

  final _controller = TextEditingController();
  String _streetNumber = '';
  String _street = '';
  String _city = '';
  String _zipCode = '';
  String _id = '';
  bool deliveryMode = true;
  bool loading = false;
  Delivery source = Delivery();

  @override
  void initState() {
    getData();
    clear();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Cluster> pointsList = [];

  getData() {
    ////assigns default address as source
    source = Delivery(
        id: sourceLocation,
        address: "Balat, Yavuz Selim Caddesi, Fatih/İstanbul, Turkey",
        city: "N/A",
        street: "Yavuz Selim Caddesi",
        streetNumber: null,
        zip: null);

    getDeliveries();
  }

  clear() {
    places = [];
    // places.add(sourceLocation);
  }

  @override
  Widget build(BuildContext context) {
    TextStyle headingStyle =
        TextStyle(fontWeight: FontWeight.w600, fontSize: 15);
    TextStyle contentStyle = TextStyle(fontSize: 14);
    return Consumer<DeliveryLocationProvider>(
        //////listens to the realtime value changes of DeliveryLocationProvider
        builder: (context, locProvider, child) => Scaffold(
              appBar: AppBar(
                title: Text(
                  widget.title,
                  style: TextStyle(fontSize: 17),
                ),
                flexibleSpace: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (loading)
                      LinearProgressIndicator(
                        color: Colors.teal,
                      ),
                  ],
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                        onPressed: () {
                          locProvider.isBikeMode = !locProvider.isBikeMode;
                          showToast(
                              "Direction Mode is Set for ${locProvider.isBikeMode ? "Bike" : "Car"}");
                        },
                        icon: Icon(locProvider.isBikeMode
                            ? Icons.pedal_bike_sharp
                            : Icons.drive_eta_rounded)),
                  )
                ],
              ),
              body: Opacity(
                opacity: loading ? 0.3 : 1,
                child: SingleChildScrollView(
                  child: Padding(
                          padding: const EdgeInsets.only(
                              left: 14, right: 10, bottom: 90),
                          child: !locProvider.isRouteStarted
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    TextField(
                                      controller: _controller,
                                      readOnly: true,
                                      onTap: () async {
                                        // generate a new token here
                                        final sessionToken = Uuid().v4();
                                        final Suggestion? result =
                                            await showSearch(
                                          context: context,
                                          delegate: AddressSearch(sessionToken),
                                        );
                                        // This will change the text displayed in the TextField

                                        if (result != null) {
                                          final placeDetails =
                                              await PlaceApiProvider(
                                                      sessionToken)
                                                  .getPlaceDetailFromId(
                                                      result.placeId);


                                          setState(() {
                                            _controller.text =
                                                result.description;
                                            _streetNumber =
                                                placeDetails.streetNumber ??
                                                    "N/A";
                                            _street =
                                                placeDetails.street ?? "N/A";
                                            _city = placeDetails.city ?? "N/A";
                                            _zipCode =
                                                placeDetails.zipCode ?? "N/A";
                                            _id = result.placeId;
                                          });
                                        }
                                      },
                                      decoration: InputDecoration(
                                        icon: Container(
                                          width: 10,
                                          height: 10,
                                          child: Icon(
                                            Icons.home,
                                            color: Colors.black,
                                          ),
                                        ),
                                        hintText: "Enter your address here",
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.only(
                                            left: 8.0, top: 16.0),
                                      ),
                                    ),
                                    SizedBox(height: 20.0),
                                    if (_controller.text.isNotEmpty) ...[
                                      Text('Street Number: $_streetNumber'),
                                      Text('Street: $_street'),
                                      Text('City: $_city'),
                                      Text('ZIP Code: $_zipCode'),
                                      Center(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            if (loading) return;
                                            if (!deliveryMode) {
                                              // sets source address
                                              Delivery src = Delivery(
                                                  id: _id,
                                                  address: _controller.text,
                                                  city: _city,
                                                  street: _street,
                                                  streetNumber: _streetNumber,
                                                  zip: _zipCode);
                                              setState(() {
                                                source = src;
                                                sourceLocation = _id;
                                              });
                                              setDeliveries();
                                            } else {
                                              // if (deliveries.length >= 10) {
                                              //   showToast(
                                              //       "More than 9 deliveries are not allowed");
                                              //   return;
                                              // }
                                              bool placeExist = false;
                                              deliveries.forEach((element) {
                                                /////checks if adding item already exists in the list
                                                if (element.id == _id)
                                                  placeExist = true;
                                                if (element.id ==
                                                    sourceLocation) {
                                                  placeExist = true;
                                                  showToast(
                                                      "Source Location can not be included in deliveries");
                                                }
                                              });
                                              if (placeExist) {
                                                // if place exists
                                                showToast(
                                                    "This place already included in list");
                                                return;
                                              }
                                              Delivery delivery = Delivery(
                                                  id: _id,
                                                  address: _controller.text,
                                                  city: _city,
                                                  street: _street,
                                                  streetNumber: _streetNumber,
                                                  zip: _zipCode);
                                              setState(() {
                                                deliveries.add(delivery);
                                              });
                                              setDeliveries();
                                            }
                                            setState(() {
                                              _streetNumber = '';
                                              _street = '';
                                              _city = '';
                                              _zipCode = '';
                                              _id = '';
                                              _controller.text = '';
                                            });
                                          },
                                          child: Text(deliveryMode
                                              ? "Add Address"
                                              : "Set Source"),
                                        ),
                                      ),
                                      SizedBox(height: 20.0),
                                    ],
                                    Row(
                                      children: [
                                        Text(
                                          deliveryMode
                                              ? "Deliveries"
                                              : "Source",
                                          style: headingStyle.copyWith(
                                              fontSize: 18),
                                        ),
                                        Spacer(),
                                        TextButton(
                                          onPressed: () {
                                            //toggle between source and delivery addresses
                                            setState(() {
                                              deliveryMode = !deliveryMode;
                                            });
                                          },
                                          child: Text(
                                            deliveryMode
                                                ? "View Source Address"
                                                : "View Deliveries",
                                            style: headingStyle.copyWith(
                                                fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20.0),
                                    if (!deliveryMode)
                                      HomeAddressItem(
                                          onRemove: null,
                                          delivery: source,
                                          sequence: -1)
                                    else
                                      ...List.generate(
                                        deliveries.length,
                                        (index) {
                                          Delivery delivery = deliveries[index];
                                          dynamic onRemove = () {
                                            if (loading) return;
                                            setState(() {
                                              deliveries.removeAt(index);
                                            });
                                            setDeliveries();
                                          };
                                          return HomeAddressItem(
                                            onRemove: onRemove,
                                            delivery: delivery,
                                            sequence: index + 1,
                                          );
                                        },
                                      ).toList(),
                                    if (deliveries.isEmpty && deliveryMode)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 18.0),
                                        child: Center(
                                            child: Text(
                                          "Please Add Delivery Addresses",
                                          style: contentStyle.copyWith(
                                              color: Colors.grey, fontSize: 16),
                                        )),
                                      ),
                                  ],
                                )
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: 50,
                                      ),
                                      Text(
                                        "One delivery route is already in progress",
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      if (locProvider.isRouteCompleted)
                                        TextButton(
                                            onPressed: () {
                                              if (loading) return;
                                              showModalBottomSheet(
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              30)),
                                                  context: context,
                                                  clipBehavior: Clip.hardEdge,
                                                  builder: (context) =>
                                                      RouteDetailsWidget(
                                                        provider: locProvider,
                                                      ));
                                            },
                                            child: Text(
                                              "See Route Details",
                                              style:
                                                  TextStyle(color: Colors.teal),
                                            ))
                                      else
                                        TextButton(
                                            onPressed: () {
                                              if (loading) return;
                                              ////cancel route here
                                              locProvider.reset();
                                            },
                                            child: Text(
                                              "Cancel Route",
                                              style:
                                                  TextStyle(color: Colors.red),
                                            )),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      if (locProvider.isRouteCompleted)
                                        Text("OR"),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      if (locProvider.isRouteCompleted)
                                        TextButton(
                                            onPressed: () {
                                              if (loading) return;
                                              ////cancel route here
                                              locProvider.reset();
                                            },
                                            child: Text(
                                              "Reset Route",
                                              style:
                                                  TextStyle(color: Colors.red),
                                            )),
                                    ],
                                  ),
                                ),
                        )

                ),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
              floatingActionButton: Container(
                height: 50,
                margin: const EdgeInsets.all(10),
                child: ElevatedButton(
                  onPressed: () {
                    if (loading) return;
                    if (locProvider.isRouteStarted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => OrderTrackingPage()),
                      );
                    } else {
                      showAlertDialog(context, "Should Rider be Restricted",
                          "Do you want to restrict rider to only mark delivery as completed while physically present at that location?",
                          okButtonText: "Restrict",
                          onPress: () {
                            Navigator.pop(context);
                            locProvider.isPhysicalRestricted = true;
                            submit(locProvider);
                          },
                          cancelButtonText: "No",
                          onCancelPress: () {
                            Navigator.pop(context);
                            locProvider.isPhysicalRestricted = false;
                            submit(locProvider);
                          });
                    }
                  },
                  child: Center(
                    child: Text(
                        "${locProvider.isRouteStarted ? "Go to Route Details" : 'Find Route'}"),
                  ),
                ),
              ),
            ));
  }

  setDeliveries() async {
    log("MK: in set Deliveries");

    List<Map<String, dynamic>> data = [];
    data.add(source.toJson());
    deliveries.forEach((element) {
      data.add(element.toJson());
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deliveries', json.encode(data));
  }

  getDeliveries() async {
    log("MK: in get Deliveries");
    final prefs = await SharedPreferences.getInstance();
    dynamic jsonData = await prefs.getString('deliveries');
    List<dynamic> data = json.decode(jsonData??'');
    Delivery src = Delivery.fromJson(data[0]);
    List<Delivery> list = [];
    for (int i = 1; i < data.length; i++) {
      list.add(Delivery.fromJson(data[i]));
    }
    setState(() {
      source = src;
      deliveries = list;
      sourceLocation = src.id ?? sourceLocation;
    });
  }

  submit(DeliveryLocationProvider locProvider) async {
    // if (deliveries.length > 9) {
    //   showToast("No more than 9 deliveries are allowed");
    //   return;
    // }

    bool flag = false;
    deliveries.forEach((element) {
      if (element.id == sourceLocation) {
        //checks if adding address had not been set as source
        flag = true;
      }
    });

    if (flag) {
      showToast("Source Address can not be included in the Deliveries");
      return;
    }
    if (deliveries.isEmpty) {
      showToast("Please Add Deliveries");
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      places = [];
      places.add(sourceLocation);
      deliveries.forEach((element) {
        places.add(element.id!);
      });
      final list = await location.getLocation(places);



      //////for testing/////
      // DeliveryLocation soureLoc = DeliveryLocation(
      //   id: "sourceId",
      //   name: "100 BLOCK GALLOWAY STREET NE",
      //   lat: 41.980264315,
      //   lng: -87.913624596,
      // );
      //
      // DeliveryLocation deliveryLoc = DeliveryLocation(
      //   id: "deliveryId",
      //   name: "200 BLOCK WEBSTER STREET NW",
      //   lat: 41.899602111,
      //   lng: -87.633308037,
      // );
      //
      // // for test
      // List<DeliveryLocation> locList = [];
      // locList.add(soureLoc);
      // locList.add(deliveryLoc);
      // int k = 1;//for test
      //////////////end test//////////


      ///for real functionality///////////////
      DeliveryLocation soureLoc = DeliveryLocation(
        id: list[0]!["id"],
        name: list[0]!["address"],
        lat: double.parse(list[0]!["lat"] ?? "0"),
        lng: double.parse(list[0]!["lng"] ?? "0"),
      );
      List<DeliveryLocation> locList = [];
      for (int i = 1; i < list.length; i++) {
        Map? element = list[i];
        DeliveryLocation deliveryLocation = DeliveryLocation(
          id: element!["id"],
          name: element["address"],
          lat: double.parse(element["lat"] ?? "0"),
          lng: double.parse(element["lng"] ?? "0"),
        );
        locList.add(deliveryLocation);
      }
      int k = (locList.length ~/ 9) + 1;

      ////////////end real//////////////////

      List<Cluster> clusterList = await kmeans(locList, k);

      bool shouldProceed = false;
      int count = 0;
      while (!shouldProceed) {
        shouldProceed = true;
        List<Cluster> tempList = [...clusterList];

        tempList.forEach((cluster) async {
          if (cluster.points.length > 9) {
            List<Cluster> _list = await kmeans(cluster.points, 2);
            clusterList.remove(cluster);
            clusterList.addAll(_list);
            shouldProceed = false;
          }
        });
      }

      locProvider.clusterList = clusterList;

      log("MK: number of clusters: ${clusterList.length} with k = ${k}");

      double minDistance = double.infinity;
      Cluster? closestCluster;
      for (Cluster cluster in clusterList) {
        double distance = euclideanDistance(soureLoc, cluster.centroid);
        if (distance < minDistance) {
          minDistance = distance;
          closestCluster = cluster;
        }
      }
      List<Map> input = [];
      input.add({
        "address": soureLoc.name,
        "lat": soureLoc.lat,
        "lng": soureLoc.lng,
      });
      closestCluster!.points.forEach((element) {
        Map map = {};
        map["address"] = element.name;
        map["lat"] = element.lat;
        map["lng"] = element.lng;
        input.add(map);
      });

      var result = await location.getShortPath(input);
      List<DeliveryLocation> locList2 = [];
      soureLoc.routeDuration = result["route"][0]["arrival"];
      soureLoc.distance = result["route"][0]["distance"].toString();
      locList2.add(soureLoc);


      for (int i = 1; i < result['route'].length; i++) {
        Map res = result["route"][i];

        DeliveryLocation loc;
        closestCluster.points.forEach((element) {

          if (element.name == res["name"]) {
            loc = element;
            loc.routeDuration = res["arrival"];
            loc.distance = res["distance"].toString();

            locList2.add(loc);
          }
        });
      }

      for (int i = 0; i < locProvider.clusterList.length; i++) {
        Cluster element = locProvider.clusterList[i];
        if (element.centroid.lat == closestCluster.centroid.lat &&
            element.centroid.lng == closestCluster.centroid.lng)
          locProvider.clusterList[i].isCompleted = true;
      }
      locProvider.list = locList2;
      setState(() {
        loading = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OrderTrackingPage()),
      );
    } catch (e) {
      showToast("Error occured while fetching data");
      log("error: $e");
    } finally {
      setState(() {
        loading = false;
      });
    }

  }
}

class HomeAddressItem extends StatelessWidget {
  HomeAddressItem({
    Key? key,
    required this.onRemove,
    required this.delivery,
    required this.sequence,
  }) : super(key: key);

  final int sequence;
  final onRemove;
  final Delivery delivery;
  TextStyle headingStyle = TextStyle(fontWeight: FontWeight.w600, fontSize: 15);
  TextStyle contentStyle = TextStyle(fontSize: 14);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 14),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  sequence == -1 ? "Source" : "Delivery No: ",
                  //sequence will be -1 when this widget is used for source address
                  style: headingStyle,
                ),
                if (sequence != -1)
                  Text(
                    "${sequence}",
                    style: contentStyle,
                  ),
                Spacer(),
                if (onRemove != null)
                  TextButton(
                      onPressed: onRemove,
                      child: Text(
                        "Remove Address",
                        style: headingStyle.copyWith(color: Colors.redAccent),
                      )),
              ],
            ),
            SizedBox(
              height: 14,
            ),
            Row(
              children: [
                Text(
                  "Address: ",
                  style: headingStyle,
                ),
                Expanded(
                    child: Text(
                  "${delivery.address}",
                  style: contentStyle,
                )),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Expanded(
                    child: Row(
                  children: [
                    Text(
                      "Street: ",
                      style: headingStyle,
                    ),
                    Expanded(
                      child: Text(
                        "${delivery.street}",
                        style: contentStyle,
                      ),
                    ),
                  ],
                )),
                Expanded(
                    child: Row(
                  children: [
                    Text(
                      "St. Name: ",
                      style: headingStyle,
                    ),
                    Expanded(
                      child: Text(
                        "${delivery.streetNumber}",
                        style: contentStyle,
                      ),
                    ),
                  ],
                ))
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Text(
                  "City: ",
                  style: headingStyle,
                ),
                Text(
                  "${delivery.city}",
                  style: contentStyle,
                ),
                Spacer(),
                Text(
                  "Zip Code: ",
                  style: headingStyle,
                ),
                Text(
                  "${delivery.zip}",
                  style: contentStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

