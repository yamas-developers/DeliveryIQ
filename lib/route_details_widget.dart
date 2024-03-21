// import 'dart:math';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_places_flutter/providers/delivery_location_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'helpers.dart';
import 'models.dart';

class RouteDetailsWidget extends StatefulWidget {
  RouteDetailsWidget({
    Key? key,
    required this.provider,
  }) : super(key: key);
  final DeliveryLocationProvider provider;

  @override
  State<RouteDetailsWidget> createState() => _RouteDetailsWidgetState();
}

class _RouteDetailsWidgetState extends State<RouteDetailsWidget> {
  int interval = 0;
  double commulativeScore = 0;

  @override
  void initState() {
    refreshData();
    super.initState();
  }

  refreshData() {
    DeliveryLocationProvider locProvider =
        context.read<DeliveryLocationProvider>();
    double sum = 0;
    for (int i = 1; i < locProvider.list.length; i++) {
      DeliveryLocation loc = locProvider.list[i];
      int dividened = 0;
      if(loc.customerSatisfaction != null)dividened += 30;
      if(loc.onTimeDelivery != null)dividened += 50;
      if(loc.lostItems != null)dividened += 20;
      double commulativeScore =
          (((loc.customerSatisfaction ?? 0) * 30) +
                  ((loc.onTimeDelivery ?? 0) * 50) +
                  ((loc.lostItems ?? 0) * 20)) /
              dividened;
      loc.commulativeScore = commulativeScore;
      sum+=locProvider.list[i].commulativeScore??0;
    }
    setState(() {
      commulativeScore = sum / (locProvider.list.length - 1);
    });
  }
  TextEditingController total = TextEditingController();
  TextEditingController received = TextEditingController();
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    TextStyle headingStyle =
        TextStyle(fontWeight: FontWeight.w600, fontSize: 15);
    TextStyle contentStyle = TextStyle(fontSize: 14);
    if (widget.provider.routeDetails["start"] != null &&
        widget.provider.routeDetails["end"] != null) {
      DateTime start = widget.provider.routeDetails["start"];
      DateTime end = widget.provider.routeDetails["end"];
      interval = end.difference(start).inMinutes; ////calculate total interval
    }
    return Container(
      height: 700,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: ListView(
        children: [
          SizedBox(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Route Details",
                style: headingStyle.copyWith(fontSize: 20),
              ),
            ],
          ),
          SizedBox(height: 10.0),
          Row(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 10,
              ),
              Text(
                "Route Start Time: ",
                style: headingStyle,
              ),
              Text(
                widget.provider.routeDetails["start"] != null
                    ? "${DateFormat("MMM dd, yy hh:mm").format(widget.provider.routeDetails["start"])}"
                    : "N/A",
                style: contentStyle,
              ),
            ],
          ),
          SizedBox(height: 10.0),
          Row(
            children: [
              SizedBox(
                width: 10,
              ),
              Text(
                "Route End Time: ",
                style: headingStyle,
              ),
              Text(
                widget.provider.routeDetails["end"] != null
                    ? "${DateFormat("MMM dd, yy hh:mm").format(widget.provider.routeDetails["end"])}"
                    : "N/A",
                style: contentStyle,
              ),
            ],
          ),
          SizedBox(height: 10.0),
          Row(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 10,
              ),
              // Spacer(),
              Text(
                "Delivery Duration: ",
                style: headingStyle,
              ),
              Text(
                "${interval} mins",
                style: contentStyle,
              ),
              SizedBox(
                width: 10,
              ),
            ],
          ),
          SizedBox(height: 10.0),
          Row(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 10,
              ),
              // Spacer(),
              Text(
                "Expected Duration: ",
                style: headingStyle,
              ),
              Text(
                "${widget.provider.routeDetails["expectedDuration"]} mins" ??
                    "0",
                style: contentStyle,
              ),
              SizedBox(
                width: 10,
              ),
            ],
          ),
          SizedBox(height: 10.0),
          Row(
            children: [
              SizedBox(
                width: 10,
              ),
              Text(
                "Distance: ",
                style: headingStyle,
              ),
              Text(
                "${widget.provider.routeDetails["distance"]} kms" ?? "0",
                style: contentStyle,
              ),
            ],
          ),
          SizedBox(height: 10.0),
          Row(
            children: [
              SizedBox(
                width: 10,
              ),
              Text(
                "Delivery Average Grade: ",
                style: headingStyle,
              ),
              Text(
                "${commulativeScore.toStringAsFixed(2)}/5",
                style: contentStyle,
              ),
            ],
          ),
          SizedBox(height: 10.0),
          ...List.generate(
            widget.provider.list.length,
            (index) {
              DeliveryLocation location = widget.provider.list[index];
              DeliveryLocation? prevLocation;
              if (index > 0) prevLocation = widget.provider.list[index - 1];

              ///one delivery item
              return Card(
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            index == 0 ? "Source" : "Delivery No: ",
                            style: headingStyle.copyWith(color: Colors.teal),
                          ),
                          if (index != 0)
                            Text(
                              "${index}",
                              style: contentStyle.copyWith(color: Colors.teal),
                            ),
                          Spacer(),
                          if (index > 0)
                            Row(
                              children: [
                                Text(
                                  "Distance: ",
                                  style:
                                      headingStyle.copyWith(color: Colors.teal),
                                ),
                                Text(
                                  "${(double.parse(location.distance ?? "0") - double.parse(prevLocation?.distance ?? "0")).toStringAsPrecision(2)} kms",
                                  style:
                                      contentStyle.copyWith(color: Colors.teal),
                                ),
                              ],
                            )
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
                          SizedBox(
                            width: 8,
                          ),
                          Expanded(
                              child: Text(
                            "${location.name}",
                            style: contentStyle,
                          )),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      if (index != 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Time Taken: ",
                                  style: headingStyle,
                                ),
                                Text(
                                  "${location.deliveryDuration} mins",
                                  style: contentStyle,
                                ),
                              ],
                            ),
                            Spacer(),
                            Row(
                              children: [
                                Text(
                                  "Expected Duration: ",
                                  style: headingStyle,
                                ),
                                Text(
                                  "${location.routeDuration! - prevLocation!.routeDuration!} mins",
                                  style: contentStyle,
                                ),
                              ],
                            )
                          ],
                        ),
                      SizedBox(
                        height: 10,
                      ),
                      if (index != 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "On Time Delivery: ",
                                  style: headingStyle.copyWith(fontSize: 14),
                                ),
                                Text(
                                  location.onTimeDelivery != null
                                      ? "${location.onTimeDelivery!}/5"
                                      : "N/A",
                                  style: contentStyle.copyWith(fontSize: 14),
                                ),
                              ],
                            ),
                            Spacer(),
                            Row(
                              children: [
                                Text(
                                  "Customer Satisfaction: ",
                                  style: headingStyle.copyWith(fontSize: 14),
                                ),
                                Text(
                                  location.customerSatisfaction != null
                                      ? "${location.customerSatisfaction!}/5"
                                      : "N/A",
                                  style: contentStyle.copyWith(fontSize: 14),
                                ),
                              ],
                            )
                          ],
                        ),
                      if (index != 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Not Losing Items: ",
                                  style: headingStyle.copyWith(fontSize: 14),
                                ),
                                Text(
                                  location.lostItems != null
                                      ? "${location.lostItems!.toStringAsFixed(1)}/5"
                                      : "N/A",
                                  style: contentStyle.copyWith(fontSize: 14),
                                ),
                              ],
                            ),
                            Spacer(),
                            Row(
                              children: [
                                Text(
                                  "Commulative Score: ",
                                  style: headingStyle.copyWith(
                                      fontSize: 14,
                                      color: Theme.of(context).primaryColor),
                                ),
                                Text(
                                  location.commulativeScore != null
                                      ? "${location.commulativeScore!.toStringAsFixed(1)}/5"
                                      : "N/A",
                                  style: contentStyle.copyWith(
                                      fontSize: 14,
                                      color: Theme.of(context).primaryColor),
                                ),
                              ],
                            )
                          ],
                        ),
                      SizedBox(height: 10,),
                      if (index != 0 && (location.customerSatisfaction==null || location.lostItems == null))ElevatedButton(onPressed: (){
                        int rating = location.customerSatisfaction??0;

                        total.text = location.totalItems != null ? location.totalItems.toString() : "";
                        received.text = location.receivedItems != null ? location.receivedItems.toString() : "";
                        showCustomDialog(context, content: StatefulBuilder(
                          builder: (context, setState) => SizedBox(
                            height: 300,
                            width: width*80,
                            child: Column(
                              children: [
                                SizedBox(height: 20,),
                                Text("Give Rating", style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold
                                ),),
                                SizedBox(height: 14,),
                                Text("What do you think about the delivery man?", style: TextStyle(
                                  fontSize: 14,
                                    fontWeight: FontWeight.bold

                                ),),
                                SizedBox(height: 6,),
                                StarRating(
                                  rating:rating,
                                  color: Theme.of(context).primaryColor,
                                  onRatingChanged: (rat) {
                                    setState(() {
                                    rating = rat;
                                    });
                                  },
                                ),
                                SizedBox(height: 20,),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [

                                      Column(children: [
                                      Text("Received Items",style: TextStyle(
                                        fontSize: 14,
                                          fontWeight: FontWeight.bold

                                      ),),
                                      SizedBox(height: 10,),
                                      Container(
                                          width: width * .35,
                                          child: TextField(
                                            keyboardType: TextInputType.number,

                                            controller: received,
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
                                            ,contentPadding: EdgeInsets.zero
                                            ),
                                          )),
                                    ],),
                                      Column(children: [
                                        Text("Total Items",style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold
                                        ),),
                                        SizedBox(height: 10,),
                                        Container(
                                            width: width * .35,
                                            child: TextField(
                                              keyboardType: TextInputType.number,
                                              controller: total,
                                              decoration: InputDecoration(
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
                                                  ,contentPadding: EdgeInsets.zero
                                              ),
                                            )),
                                      ],),
                                  ],),
                                ),
                                SizedBox(height: 20,),
                                Spacer(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                  TextButton(onPressed: (){
                                    Navigator.pop(context);
                                  }, child: Text("Cancel")),
                                  TextButton(onPressed: (){
                                      int? tot = int.tryParse(total.text);
                                      int? rec = int.tryParse(received.text);
                                    if(tot != null && rec != null){
                                      if(tot<rec){
                                        showToast("Total items can not be lesser than received");
                                        return;
                                      }
                                    }else{
                                      showToast("Only numbers are allowed");
                                      return;
                                    }
                                    location.lostItems = (rec/tot) * 5;
                                    log("lostItems: ${location.lostItems} for $rec $tot, ${rec/tot}, ${(rec/tot)*5}");
                                    location.customerSatisfaction = rating;
                                      location.totalItems = tot;
                                      location.receivedItems = rec;
                                      refreshData();
                                    Navigator.pop(context);
                                  }, child: Text("Save Rating")),
                                ],),
                                SizedBox(height: 10,),
                              ],
                            ),
                          ),
                        ));
                      }, child: Text("Get Customer Feedback", style: TextStyle(
                        // color: Colors.blueAccent,
                        fontWeight: FontWeight.bold
                      ),))
                    ],
                  ),
                ),
              );
            },
          ).toList(),
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); ////closes the bottom sheet
                },
                child: Text(
                  "Close",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
            ],
          ),
          SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }
}

typedef void RatingChangeCallback(int rating);

class StarRating extends StatelessWidget {
  final int starCount;
  final int rating;
  final RatingChangeCallback onRatingChanged;
  final Color color;

  StarRating(
      {this.starCount = 5,
        this.rating = 0,
        required this.onRatingChanged,
        required this.color});

  Widget buildStar(BuildContext context, int index) {
    Icon icon;
    double size = 50;
    Color unfilledColor = Colors.blueGrey.withOpacity(0.6);
    if (index >= rating) {
      icon = new Icon(
        Icons.star_border,
        color: unfilledColor,
        size: size,
      );
    } else if (index > rating - 1 && index < rating) {
      icon = new Icon(
        Icons.star_half,
        color: color,
        size: size,
      );
    } else {
      icon = new Icon(
        Icons.star,
        color: color,
        size: size,
      );
    }
    return new InkResponse(
      onTap: onRatingChanged == null ? null : () => onRatingChanged(index + 1),
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children:
        new List.generate(starCount, (index) => buildStar(context, index)));
  }
}
