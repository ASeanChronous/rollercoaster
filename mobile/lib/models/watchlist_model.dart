import 'package:flutter/material.dart';

class WatchlistLocation {
  final String id;
  final String label;
  final String zip;
  final String cityState;
  final String iconName;
  final String? primaryIspSlug;

  WatchlistLocation({
    required this.id,
    required this.label,
    required this.zip,
    required this.cityState,
    required this.iconName,
    this.primaryIspSlug,
  });

  IconData get icon {
    switch (iconName) {
      case 'work':
        return Icons.business_rounded;
      case 'parents':
        return Icons.family_restroom_rounded;
      case 'store':
        return Icons.storefront_rounded;
      case 'home':
      default:
        return Icons.home_rounded;
    }
  }

  factory WatchlistLocation.fromJson(Map<String, dynamic> json) {
    return WatchlistLocation(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? 'Saved Location',
      zip: json['zip'] as String? ?? '75001',
      cityState: json['cityState'] as String? ?? '',
      iconName: json['iconName'] as String? ?? 'home',
      primaryIspSlug: json['primaryIspSlug'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'zip': zip,
      'cityState': cityState,
      'iconName': iconName,
      'primaryIspSlug': primaryIspSlug,
    };
  }
}
