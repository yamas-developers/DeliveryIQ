class Delivery {
  String? id;
  String? address;
  String? street;
  String? streetNumber;
  String? city;
  String? zip;

  Delivery(
      {this.id,
        this.address,
        this.street,
        this.streetNumber,
        this.city,
        this.zip});

  Delivery.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    address = json['address'];
    street = json['street'];
    streetNumber = json['streetNumber'];
    city = json['city'];
    zip = json['zip'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['address'] = this.address;
    data['street'] = this.street;
    data['streetNumber'] = this.streetNumber;
    data['city'] = this.city;
    data['zip'] = this.zip;
    return data;
  }
}

class DeliveryLocation {
  String? id, name, distance;
  double? lat, lng;
  int? routeDuration, deliveryDuration, onTimeDelivery, customerSatisfaction, totalItems, receivedItems;
  double? commulativeScore, lostItems;
/////model of delivery used on tracking page and in provider
  DeliveryLocation(
      {this.id,
      this.name,
      this.lat,
      this.lng,
      this.routeDuration,
      this.distance,
      this.deliveryDuration,
      this.onTimeDelivery,
        this.customerSatisfaction,
        this.lostItems,
        this.commulativeScore
      });
}

class Cluster {
  DeliveryLocation centroid;
  bool isCompleted = false;
  late List<DeliveryLocation> points;

  Cluster(this.centroid) {
    points = <DeliveryLocation>[];
  }
}
