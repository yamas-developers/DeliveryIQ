import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/helpers.dart';
import 'package:google_places_flutter/models.dart';
import 'package:google_places_flutter/providers/delivery_location_provider.dart';
import 'package:google_places_flutter/route_details_widget.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

import 'locations.dart' as locat;

class OrderTrackingPage extends StatefulWidget {

  const OrderTrackingPage({Key? key}) : super(key: key);

  @override
  State<OrderTrackingPage> createState() => OrderTrackingPageState();
}

class OrderTrackingPageState extends State<OrderTrackingPage> {
  final Completer<GoogleMapController> _controller = Completer();

  // static const LatLng sourceLocation = LatLng(40.9890076, 28.7890331);
  // static const LatLng destination = LatLng(40.9991090, 28.8465719);

  List<LatLng> polylineCoordinates = [];
  late BitmapDescriptor bitmapIcon;
  late BitmapDescriptor bitmapIcon2;
  late BitmapDescriptor riderIcon;

  late StreamSubscription subs;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  Map<PolylineId, Polyline> polylines = {};
  Set<Circle> circles =
      Set.from([]); /////shows circle arround the marker on maps
  DeliveryLocationProvider? provider;
  LatLng? target;
  bool isInit = false;
  bool exceedFromMid = false;
  Set<Circle> tempCircles =
  Set.from([]);

  @override
  void initState() {
    provider = context.read<
        DeliveryLocationProvider>(); //////declares a provider to fetch its data
    getData();

    super.initState();
  }

  getData() async {
    /////different markers icons for delivery man and delivery addresses
    bitmapIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(200, 200)),
        'assets/icons/source_marker.png');
    bitmapIcon2 = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(200, 200)),
        'assets/icons/source_marker_3x.png');
    riderIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(200, 200)),
        'assets/icons/rider_marker.png');
    ////get rider's current location
    getCurrentLocation();
    ////draw poly lines on map
    getPolyPoints();
    setMarkers();
  }

  setMarkers(){
    if(provider == null){
      log("Provider is null, returning...");
      return;
    }
    List<Color> colorList = [Colors.red, Colors.green, Colors.teal, Colors.blue, Colors.orange, Colors.pink];
    List<Cluster> list = provider!.clusterList;
    final circleList = [];
    for (Cluster cluster in list){
      Color color = colorList[math.Random().nextInt(colorList.length-1)];

      cluster.points.forEach((element) {
        circleList.add(Circle(
            circleId: CircleId(element.id!),
            center: LatLng(element.lat!, element.lng!),
            radius: 100,
            fillColor: color.withOpacity(0.1),
            strokeWidth: 2,
            strokeColor: color));
        var markerId = MarkerId(element.id!);
        markers[markerId] = Marker(
            markerId: markerId,
            position: LatLng(
              element.lat!,
              element.lng!,
            ),
            icon: bitmapIcon);
      });

    }
      tempCircles = Set.from(circleList);

  }

  @override
  void dispose() {
    // subs.cancel();
    super.dispose();
  }

  void getCurrentLocation() async {
    log("in get current location");
    Location location = Location();
    var currentLocation = await location.getLocation();
    updateCurrentLocationMarker(currentLocation);

    // GoogleMapController googleMapController = await _controller.future;
    // subs = location.onLocationChanged.listen(
    //   (newLoc) {
    //     googleMapController.animateCamera(
    //       CameraUpdate.newCameraPosition(
    //         CameraPosition(
    //           zoom: 14,
    //           target: LatLng(
    //             newLoc.latitude!,
    //             newLoc.longitude!,
    //           ),
    //         ),
    //       ),
    //     );
    //     updateCurrentLocationMarker(newLoc);
    //   },
    // );
  }

  Future<bool> checkIfFeasible(deliveryLat, deliveryLng) async {
    Location currentLoc = Location();
    LocationData currentLocation = await currentLoc.getLocation();
    double dist = calculateDistance(deliveryLat, deliveryLng,
        currentLocation.latitude, currentLocation.longitude);
    if (dist < 0.5)
      return true;
    else
      return false;
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = math.cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  PolylinePoints polylinePoints = PolylinePoints();

  getPolyPoints() async {
    if (provider == null) {
      showToast("Unexpected error: code-512");
      return;
    }
    List list = provider!.list;
    int length = list.length;

    for (int i = 0; i < length; i++) {
      DeliveryLocation place = list[i];

      var location = LatLng(
        place.lat!,
        place.lng!,
      );
      int _destination = i < length - 1 ? i + 1 : length - 1;

      bool isCurrent = _destination ==
          provider!
              .currentDeliveryIndex; //////true if the specified delivery is the current one

      var markerId = MarkerId(place.id!);
      markers[markerId] = Marker(
          markerId: markerId,
          position: location,
          icon: i == provider!.currentDeliveryIndex ? bitmapIcon2 : bitmapIcon);


      if (
      (!isInit) || (isCurrent)) {////////for the current running delivery

        setState(() {
          showInfo = false;
        });

        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          'AIzaSyAbVR58OxpThOOaKsL93jwXAUvVNQB_Re4',
          PointLatLng(location.latitude, location.longitude),
          PointLatLng(list[_destination].lat, list[_destination].lng),
          // travelMode: provider!.isBikeMode ? TravelMode.bicycling : TravelMode.driving,

        );
        polylineCoordinates = [];
        // log("MK: results of polyLines: ${result}");
        if (result.points.isNotEmpty) {
          result.points.forEach((PointLatLng point) {
            polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          });
        }
        // polylineCoordinates.add(location);

        PolylineId id = PolylineId(place.id ?? "id");
        Polyline polyline = Polyline(
            polylineId: id,
            points: polylineCoordinates,
            width: 4,
            color: isCurrent ? Colors.green : Colors.blue);
        polylines[id] = polyline;
      }
    }
    if (provider!.list.length > 5 &&
        provider!.currentDeliveryIndex > 5 &&
        !exceedFromMid) {
      /////if the polylines are drawn for more than half deliveries than we need not to draw them again
      exceedFromMid = true;
    }

    setState(() {
      target = LatLng(provider!.list[provider!.currentDeliveryIndex].lat!,
          provider!.list[provider!.currentDeliveryIndex].lng!);
      showInfo = true;
    });

    GoogleMapController googleMapController = await _controller.future;
    // if(provider!.currentDeliveryIndex >= 1)
    googleMapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          zoom: 15,
          target: target!,
          tilt: 29.440717697143555,
          // bearing: 92.8334901395799,
        ),
      ),
    );
    isInit = true;
  }

  updateCurrentLocationMarker(LocationData newLoc) async {
    var key = MarkerId('rider');
    markers[key] = Marker(
        markerId: key,
        position: LatLng(newLoc.latitude!, newLoc.longitude!),
        icon: riderIcon);

    //places circle arround rider's current location
    circles = Set.from([
      Circle(
          circleId: CircleId("currentLoc"),
          center: LatLng(newLoc.latitude!, newLoc.longitude!),
          radius: 600,
          fillColor: Colors.teal.withOpacity(0.1),
          strokeWidth: 1,
          strokeColor: Colors.green.withOpacity(0.5))
    ]);
    setState(() {});
    GoogleMapController googleMapController = await _controller.future;
    googleMapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          zoom: 16,
          target: LatLng(
            newLoc.latitude!,
            newLoc.longitude!,
          ),
        ),
      ),
    );
  }





  bool showInfo = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Track delivery",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Consumer<DeliveryLocationProvider>(
        builder: (BuildContext context, locProvider, _) => Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target:
                    LatLng(locProvider.list[0].lat!, locProvider.list[0].lat!),
                zoom: 14,
              ),
              markers: Set<Marker>.of(markers.values),
              onMapCreated: (mapController) {
                _controller.complete(mapController);
              },
              onTap: (LatLng) {
                log("MK: latlng: ${LatLng}");
              },
              onCameraMove: (v) {
                setState(() {
                  showInfo = false; ////hides delivery info
                });
              },
              onCameraIdle: () {
                setState(() {
                  showInfo = true;
                  ////shows delivery info
                });
              },
              polylines: Set<Polyline>.of(polylines.values),
              circles: tempCircles,
            ),
            if (!showInfo)
              Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(
                    color: Colors.teal,
                  )),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
                child: AnimatedOpacity(
                  opacity: showInfo ? 1 : 0,
                  duration: Duration(milliseconds: 500),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                    ),
                    // height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Color(0xee009688),
                        borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          !locProvider.isRouteStarted
                              ? "Pickup Items"
                              : locProvider.isRouteCompleted
                                  ? "End of Current Route"
                                  : "Current Delivery: ",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w600),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        if (!locProvider.isRouteCompleted)
                          ...[
                            Row(
                              children: [
                                Text(
                                  "Name: ",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Expanded(
                                  child: Text(
                                    "${locProvider.list[locProvider.currentDeliveryIndex].name}",
                                    maxLines: 2,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            // Spacer(),

                            SizedBox(
                              height: 10,
                            ),
                            if (locProvider.currentDeliveryStartTime != null)
                              Row(
                                children: [
                                  Text(
                                    "Started at: ",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: Text(
                                      locProvider.currentDeliveryStartTime !=
                                              null
                                          ? "${DateFormat("MMM dd, yy hh:mm").format(locProvider.currentDeliveryStartTime!)}"
                                          : "N/A",
                                      maxLines: 2,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            SizedBox(
                              height: 10,
                            ),
                            if (locProvider.currentDeliveryStartTime != null)
                              Row(
                                children: [
                                  Text(
                                    "Expected Delivery at: ",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: Text(
                                      "${DateFormat("MMM dd, yy hh:mm").format(locProvider.currentDeliveryStartTime!.add(Duration(minutes: locProvider.list[locProvider.currentDeliveryIndex].routeDuration! - locProvider.list[locProvider.currentDeliveryIndex > 0 ? locProvider.currentDeliveryIndex - 1 : 0].routeDuration!)))} "
                                      "| (${locProvider.list[locProvider.currentDeliveryIndex].routeDuration! - locProvider.list[locProvider.currentDeliveryIndex > 0 ? locProvider.currentDeliveryIndex - 1 : 0].routeDuration!} mins)",
                                      maxLines: 2,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            SizedBox(
                              height: 10,
                            ),
                            if(locProvider.currentDeliveryIndex > 0)
                            Row(
                              children: [
                                Text(
                                  "Distance: ",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Expanded(
                                  child: Text(
                                    "${(double.parse(locProvider.list[locProvider.currentDeliveryIndex].distance??"0")
                                        - double.parse(locProvider.list[locProvider.currentDeliveryIndex-1].distance??"0")).toStringAsFixed(2)} kms",
                                    maxLines: 2,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 10,
                            ),
                          ].toList(),
                        ElevatedButton(
                          onPressed: () async {
                            // locProvider.isRouteCompleted = false;return;
                            if (locProvider.isRouteCompleted) {
                              showModalBottomSheet(
                                  /////shows route details
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                  context: context,
                                  clipBehavior: Clip.hardEdge,
                                  builder: (context) => RouteDetailsWidget(
                                        provider: locProvider,
                                      ));
                              return;
                            }

                            if(locProvider.isPhysicalRestricted){
                              bool physicalStatus = await checkIfFeasible(
                                  locProvider
                                      .list[locProvider.currentDeliveryIndex].lat,
                                  locProvider
                                      .list[locProvider.currentDeliveryIndex]
                                      .lng);
                              if (!physicalStatus) {
                                showToast("Sorry! You are not physically present at the location.");
                                return;
                              }
                            }

                            if (locProvider.currentDeliveryIndex ==
                                locProvider.list.length - 1) {
                              ///////last delivery reaches
                              bool isRouteRemaining = false;
                              locProvider.clusterList.forEach((element) {
                                if(!element.isCompleted)isRouteRemaining = true;
                              });

                              if(isRouteRemaining){
                                DeliveryLocation soureLoc = locProvider.list[locProvider.currentDeliveryIndex];
                                double minDistance = double.infinity;
                                Cluster? closestCluster;
                                Iterable<Cluster> clusterList = locProvider.clusterList.where((element) => !element.isCompleted);

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

                                var result = await locat.location.getShortPath(input);
                                List<DeliveryLocation> locList2 = [];
                                for (int i = 1; i < result['route'].length; i++) {
                                  Map res = result["route"][i];

                                  DeliveryLocation loc = closestCluster.points.firstWhere((element) => element.name == res["name"]);
                                  if(loc != null){
                                    loc.routeDuration = res["arrival"];
                                    loc.distance = res["distance"].toString();
                                  }
                                  locList2.add(loc);
                                }
                                locProvider.clusterList.firstWhere((element) => element == closestCluster).isCompleted = true;

                                locProvider.list.addAll(locList2);

                                if (locProvider.currentDeliveryIndex >= 1)
                                    assignsDuration(locProvider);





                                locProvider.currentDeliveryIndex++;
                                locProvider.currentDeliveryStartTime =
                                    DateTime.now();
                                isInit = false;
                                getPolyPoints();


                              }else{
                                if (!locProvider.isRouteCompleted)
                                  showToast("Delivery Route Completed");
                                locProvider.isRouteCompleted = true;
                                locProvider.routeDetails["end"] = DateTime.now();
                                if (locProvider.currentDeliveryIndex >=
                                    1) //////checks if it is not the source
                                  assignsDuration(locProvider);
                                return;
                              }
                            } else {
                              if (!locProvider.isRouteStarted) {
                                locProvider.isRouteStarted = true;
                                locProvider.routeDetails["start"] =
                                    DateTime.now(); ////sets route start time
                              }

                              if (locProvider.currentDeliveryIndex >= 1)
                                assignsDuration(locProvider);
                              locProvider.currentDeliveryIndex++;
                              locProvider.currentDeliveryStartTime =
                                  DateTime.now();
                              // if(locProvider.currentDeliveryIndex >= 1)
                              getPolyPoints();
                            }
                          },
                          child: Text(
                            !locProvider.isRouteStarted
                                ? "Pickup and start to Deliver"
                                : locProvider.isRouteCompleted
                                    ? "Show Route Details"
                                    : "Mark as Delivered",
                            style: TextStyle(color: Colors.teal),
                          ),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
  assignsDuration(locProvider){
    int deliveryDuration = DateTime.now()
        .difference(locProvider
        .currentDeliveryStartTime!)
        .inMinutes;

    locProvider
        .list[locProvider.currentDeliveryIndex]
        .deliveryDuration = deliveryDuration;

    int expectedDuration = locProvider
        .list[locProvider.currentDeliveryIndex].routeDuration ?? 0;

    if(deliveryDuration <= expectedDuration){
      locProvider
          .list[locProvider.currentDeliveryIndex].onTimeDelivery = 5;
    }else if(deliveryDuration <= expectedDuration + 20){
      locProvider
          .list[locProvider.currentDeliveryIndex].onTimeDelivery = 3;
    }else{
      locProvider
          .list[locProvider.currentDeliveryIndex].onTimeDelivery = 1;
    }
  }
}
