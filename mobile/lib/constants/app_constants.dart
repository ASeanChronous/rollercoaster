import 'package:flutter/material.dart';

class AppConstants {
  static const String defaultApiUrl = 'http://localhost:3000';

  static const Map<String, String> categoryLabels = {
    'all': 'All',
    'isp': 'Internet / ISP',
    'mobile': 'Mobile',
    'tv': 'TV / Cable',
    'streaming': 'Streaming',
    'gaming': 'Gaming',
    'banking': 'Banking',
    'cloud': 'Cloud & Dev',
    'social': 'Social',
    'power': 'Power',
  };

  static const Map<String, IconData> categoryIcons = {
    'all': Icons.grid_view_rounded,
    'isp': Icons.wifi_rounded,
    'mobile': Icons.phone_iphone_rounded,
    'tv': Icons.tv_rounded,
    'streaming': Icons.movie_outlined,
    'gaming': Icons.sports_esports_rounded,
    'banking': Icons.account_balance_rounded,
    'cloud': Icons.cloud_queue_rounded,
    'social': Icons.chat_bubble_outline_rounded,
    'power': Icons.bolt_rounded,
  };

  static const Map<String, String> problemLabels = {
    'no_connection': 'No connection / Total blackout',
    'slow': 'Slow speeds',
    'intermittent': 'Keeps dropping',
    'tv': 'TV / video issues',
    'phone': 'Phone / calls',
    'login': 'Login / account',
    'app': 'App or website error',
    'payments': 'Payments failed',
    'power': 'Power outage',
  };

  static const List<String> usStates = [
    'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
    'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
    'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
    'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
    'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY', 'DC'
  ];
}
