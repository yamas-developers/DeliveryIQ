import 'package:flutter/material.dart';

import '../models.dart';

class DeliveryLocationProvider with ChangeNotifier{
  bool _isRouteStarted = false;
  bool _isRouteCompleted = false;
  bool _isPhysicalRestricted = false;
  bool _isBikeMode = true;
  int _currentDeliveryIndex = 0;
  List<DeliveryLocation> _list = [];
  List<Cluster> _clusterList = [];
  DateTime? _currentDeliveryStartTime;
  Map _routeDetails = {};

  bool get isRouteStarted{
 return _isRouteStarted;
}
bool get isPhysicalRestricted{
 return _isPhysicalRestricted;
}
bool get isBikeMode{
 return _isBikeMode;
}
  Map get routeDetails{
    return _routeDetails;
  }
bool get isRouteCompleted{
 return _isRouteCompleted;
}
  int get currentDeliveryIndex{
    return _currentDeliveryIndex;
  }
  List<DeliveryLocation> get list{
    return _list;
  }
  List<Cluster> get clusterList{
    return _clusterList;
  }
  DateTime? get currentDeliveryStartTime{
    return _currentDeliveryStartTime;
  }
  set list(locList){
    _list = locList;
    notifyListeners();
  }
  set clusterList(list){
    _clusterList = list;
    notifyListeners();
  }
  set isRouteStarted(val){
    _isRouteStarted = val;
    notifyListeners();
  }
  set isBikeMode(val){
    _isBikeMode = val;
    notifyListeners();
  }
  set isPhysicalRestricted(val){
    _isPhysicalRestricted = val;
    notifyListeners();
  }
  set routeDetails(val){
    _routeDetails = val;
    notifyListeners();
  }
  set isRouteCompleted(val){
    _isRouteCompleted = val;
    if(val)setDistance();
    notifyListeners();
  }
  set currentDeliveryIndex(val){
    _currentDeliveryIndex = val;
    notifyListeners();
  }
  set currentDeliveryStartTime(val){
    _currentDeliveryStartTime = val;
    notifyListeners();
  }

  setDistance(){
    _routeDetails["distance"] = _list.last.distance;
    _routeDetails["expectedDuration"] = _list.last.routeDuration;
  }

  void reset(){
    _isRouteStarted = false;
    _isRouteCompleted = false;
    _currentDeliveryIndex = 0;
    _list = [];
    _currentDeliveryStartTime = null;
    _routeDetails = {};
    notifyListeners();
}

}