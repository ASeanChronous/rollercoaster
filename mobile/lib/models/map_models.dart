import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'service_model.dart';

class MapTopService {
  final String slug;
  final String name;
  final int count;

  MapTopService({
    required this.slug,
    required this.name,
    required this.count,
  });

  factory MapTopService.fromJson(Map<String, dynamic> json) {
    return MapTopService(
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class MapCell {
  final double lat;
  final double lng;
  final int count;
  final List<MapTopService> top;

  MapCell({
    required this.lat,
    required this.lng,
    required this.count,
    required this.top,
  });

  LatLng get point => LatLng(lat, lng);

  factory MapCell.fromJson(Map<String, dynamic> json) {
    final rawTop = json['top'] as List<dynamic>? ?? [];
    return MapCell(
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      top: rawTop.map((t) => MapTopService.fromJson(t as Map<String, dynamic>)).toList(),
    );
  }

  Color get color {
    if (count >= 100) {
      return const Color(0xFFEF4444); // Severe Red
    } else if (count >= 25) {
      return const Color(0xFFF97316); // High Orange
    } else {
      return const Color(0xFFF59E0B); // Moderate Amber
    }
  }

  double calculateRadius(double currentZoom) {
    // Dynamic LOD: scale with zoom level and report volume
    final base = (count >= 100 ? 18.0 : count >= 25 ? 14.0 : 10.0);
    final zoomFactor = (currentZoom / 4.0).clamp(0.8, 2.5);
    return base * zoomFactor;
  }
}

class StateOutageSummary {
  final String state;
  final String name;
  final String fips;
  final StatusLevel level;
  final int problems;
  final int possible;
  final double lat;
  final double lng;

  StateOutageSummary({
    required this.state,
    required this.name,
    required this.fips,
    required this.level,
    required this.problems,
    required this.possible,
    required this.lat,
    required this.lng,
  });

  LatLng get point => LatLng(lat, lng);

  factory StateOutageSummary.fromJson(Map<String, dynamic> json) {
    final stateCode = json['state'] as String? ?? '';
    final coords = _stateCoordinates[stateCode] ?? const [39.8283, -98.5795];

    return StateOutageSummary(
      state: stateCode,
      name: json['name'] as String? ?? stateCode,
      fips: json['fips'] as String? ?? '',
      level: StatusLevelExtension.fromString(json['level'] as String?),
      problems: (json['problems'] as num?)?.toInt() ?? 0,
      possible: (json['possible'] as num?)?.toInt() ?? 0,
      lat: coords[0],
      lng: coords[1],
    );
  }

  static const Map<String, List<double>> _stateCoordinates = {
    'AL': [32.806671, -86.791130],
    'AK': [61.370716, -152.404419],
    'AZ': [33.729759, -111.431221],
    'AR': [34.969704, -92.373123],
    'CA': [36.116203, -119.681564],
    'CO': [39.059811, -105.311104],
    'CT': [41.597782, -72.755371],
    'DE': [39.318523, -75.507141],
    'FL': [27.766279, -81.686783],
    'GA': [33.040619, -83.643074],
    'HI': [21.094318, -157.498337],
    'ID': [44.240459, -114.478828],
    'IL': [40.349457, -88.986137],
    'IN': [39.849426, -86.258278],
    'IA': [42.011539, -93.210526],
    'KS': [38.526600, -96.726486],
    'KY': [37.668140, -84.670067],
    'LA': [31.169546, -91.867805],
    'ME': [44.693947, -69.381927],
    'MD': [39.063946, -76.802101],
    'MA': [42.230171, -71.530106],
    'MI': [43.326618, -84.536095],
    'MN': [45.694454, -93.900192],
    'MS': [32.741646, -89.678696],
    'MO': [38.456085, -92.288368],
    'MT': [46.921925, -110.454353],
    'NE': [41.125370, -98.268082],
    'NV': [38.313515, -117.055374],
    'NH': [43.452492, -71.563896],
    'NJ': [40.298904, -74.521011],
    'NM': [34.840515, -106.248482],
    'NY': [42.165726, -74.948051],
    'NC': [35.630066, -79.806419],
    'ND': [47.528912, -99.784012],
    'OH': [40.388783, -82.764915],
    'OK': [35.565342, -96.928917],
    'OR': [44.572021, -122.070938],
    'PA': [40.590752, -77.209755],
    'RI': [41.680893, -71.511780],
    'SC': [33.856892, -80.945007],
    'SD': [44.299782, -99.438828],
    'TN': [35.747845, -86.692345],
    'TX': [31.054487, -97.563461],
    'UT': [40.150032, -111.862434],
    'VT': [44.045876, -72.710686],
    'VA': [37.769337, -78.169968],
    'WA': [47.400902, -121.490494],
    'WV': [38.491226, -80.954453],
    'WI': [44.268543, -89.616508],
    'WY': [42.755966, -107.302490],
  };
}
