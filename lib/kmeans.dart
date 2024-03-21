import 'dart:math';

import 'helpers.dart';
import 'models.dart';

List<Cluster> kmeans(List<DeliveryLocation> points, int k) {
  // Initialize the centroids randomly
  Random random = Random();

  // int count = 0;
  //
  double maxX = points[0].lat!;
  double minX = points[0].lat!;
  double maxY = points[0].lng!;
  double minY = points[0].lng!;

  for (DeliveryLocation p in points) {
    if (p.lat! > maxX) maxX = p.lat!;
    if (p.lat! < minX) minX = p.lat!;
    if (p.lng! > maxY) maxY = p.lng!;
    if (p.lng! < minY) minY = p.lng!;
  }

  // log("minX: $minX, maxX: $maxX, minY: $minY, maxY: $maxY");

  List<Cluster> clusters = List.generate(k, (int index) {
    double x = random.nextDouble() * (maxX - minX) + minX;
    double y = random.nextDouble() * (maxY - minY) + minY;
    return Cluster(DeliveryLocation(lat: x, lng: y));
  });

  bool converged = false;
  while (!converged) {
    for (Cluster cluster in clusters) {
      cluster.points.clear();
    }
    // Assign each point to the closest cluster
    for (DeliveryLocation point in points) {
      double minDistance = double.infinity;
      Cluster? closestCluster;
      for (Cluster cluster in clusters) {
        double distance = euclideanDistance(point, cluster.centroid);
        if (distance < minDistance) {
          minDistance = distance;
          closestCluster = cluster;
        }
      }
      closestCluster!.points.add(point);
      // log("closestCluster for ${point.x} and ${point.y} is ${closestCluster.points.length}");
    }

    // Calculate the new centroids
    converged = true;
    for (Cluster cluster in clusters) {
      DeliveryLocation oldCentroid = cluster.centroid;
      DeliveryLocation? point = calculateCentroid(cluster.points);
      if (point == null) {
        converged = false;
      } else {
        cluster.centroid = point;
        var dist = euclideanDistance(oldCentroid, cluster.centroid);
        if (dist > 0.01 /*&& count<50*/) {
          converged = false;
          // count++;
        }
      }
    }
  }

  return clusters;
}

// Define a function that calculates the centroid of a cluster of points
DeliveryLocation? calculateCentroid(List<DeliveryLocation> points) {
  if (points.isEmpty) {
    return null;
  }
  double xSum = 0;
  double ySum = 0;
  for (DeliveryLocation point in points) {
    xSum += point.lat!;
    ySum += point.lng!;
  }
  int n = points.length;
  return DeliveryLocation(lat: xSum / n, lng: ySum / n);
}