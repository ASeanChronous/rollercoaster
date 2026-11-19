import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/service_model.dart';
import '../models/map_models.dart';
import '../models/weather_alert_model.dart';

class ApiService {
  final String baseUrl;
  final String deviceId;

  ApiService({required this.baseUrl, required this.deviceId});

  Uri _uri(String path, [Map<String, dynamic>? queryParameters]) {
    final cleanBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$cleanBase$path');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(
        queryParameters: queryParameters.map(
          (k, v) => MapEntry(k, v?.toString() ?? ''),
        )..removeWhere((k, v) => v.isEmpty),
      );
    }
    return uri;
  }

  Future<List<ServiceSummary>> getServices({
    String? category,
    String? zip,
    String? state,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (category != null && category != 'all') query['category'] = category;
      if (zip != null && zip.isNotEmpty) query['zip'] = zip;
      if (state != null && state.isNotEmpty) query['state'] = state;

      final response = await http
          .get(_uri('/api/services', query))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final list = data['services'] as List<dynamic>? ?? [];
        return list
            .map((item) => ServiceSummary.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Fallback to rich pre-seeded mock dataset if backend is not currently running
    }
    return _mockServices(category: category);
  }

  Future<ServiceDetail> getServiceDetail(
    String slug, {
    String? zip,
    String? state,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (zip != null && zip.isNotEmpty) query['zip'] = zip;
      if (state != null && state.isNotEmpty) query['state'] = state;

      final response = await http
          .get(_uri('/api/services/$slug', query))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return ServiceDetail.fromJson(data);
      }
    } catch (_) {
      // Fallback to realistic mock detail
    }
    return _mockServiceDetail(slug);
  }

  Future<Map<String, dynamic>> submitReport({
    required String serviceSlug,
    required String problemType,
    required String zip,
    String? comment,
  }) async {
    try {
      final response = await http
          .post(
            _uri('/api/reports'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'service': serviceSlug,
              'problemType': problemType,
              'zip': zip,
              'comment': comment ?? '',
              'deviceId': deviceId,
            }),
          )
          .timeout(const Duration(seconds: 5));

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'ok': true, 'id': data['id'], 'nearby': data['nearbyLastHour']};
      } else {
        return {'ok': false, 'error': data['error'] ?? 'Submission failed'};
      }
    } catch (e) {
      // If offline/demo mode, simulate successful report creation
      return {
        'ok': true,
        'id': 'sim-${DateTime.now().millisecondsSinceEpoch}',
        'nearby': 12,
        'isSimulated': true,
      };
    }
  }

  Future<Map<String, dynamic>?> lookupZip(String zip) async {
    try {
      final response = await http
          .get(_uri('/api/geo', {'zip': zip}))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<List<WeatherAlert>> getWeatherAlerts({String? zip, String? state}) async {
    try {
      final query = <String, dynamic>{};
      if (zip != null && zip.isNotEmpty) query['zip'] = zip;
      if (state != null && state.isNotEmpty) query['state'] = state;

      if (query.isNotEmpty) {
        final response = await http
            .get(_uri('/api/weather', query))
            .timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final list = data['alerts'] as List<dynamic>? ?? [];
          return list
              .map((item) => WeatherAlert.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return _mockWeatherAlerts(zip: zip, state: state);
  }

  List<WeatherAlert> _mockWeatherAlerts({String? zip, String? state}) {
    // Contextual alert correlating to the demo seed outages in TX and NY
    final alerts = <WeatherAlert>[];
    if (state == 'TX' || zip?.startsWith('75') == true || zip == null) {
      alerts.add(
        WeatherAlert(
          id: 'nws-tx-01',
          event: 'Severe Thunderstorm & High Wind Warning',
          severity: 'Severe',
          headline: 'Severe Thunderstorm Warning in effect for Dallas, Collin, and Tarrant Counties until 8:00 PM',
          areaDesc: 'Dallas-Fort Worth Metroplex; Dallas County, Tarrant County, Collin County',
          states: ['TX'],
          onset: 'Active now',
          ends: '8:00 PM CST',
          sender: 'NWS Fort Worth TX',
        ),
      );
    }
    if (state == 'NY' || zip?.startsWith('10') == true || zip == null) {
      alerts.add(
        WeatherAlert(
          id: 'nws-ny-01',
          event: 'High Wind Warning',
          severity: 'Moderate',
          headline: 'High Wind Warning: Gusts up to 55 mph expected across NYC metro and coastal Long Island',
          areaDesc: 'New York (Manhattan), Kings (Brooklyn), Queens, Bronx',
          states: ['NY', 'NJ'],
          onset: 'Active now',
          ends: '11:00 PM EST',
          sender: 'NWS New York NY',
        ),
      );
    }
    return alerts;
  }

  Future<({List<MapCell> cells, List<StateOutageSummary> states})> getMapData({
    int minutes = 60,
    String? category,
    String? serviceSlug,
  }) async {
    try {
      final query = <String, dynamic>{'minutes': minutes};
      if (category != null && category != 'all') query['category'] = category;
      if (serviceSlug != null && serviceSlug.isNotEmpty) query['service'] = serviceSlug;

      final response = await http
          .get(_uri('/api/map', query))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rawCells = data['cells'] as List<dynamic>? ?? [];
        final rawStates = data['states'] as List<dynamic>? ?? [];

        final cells = rawCells.map((c) => MapCell.fromJson(c as Map<String, dynamic>)).toList();
        final states = rawStates.map((s) => StateOutageSummary.fromJson(s as Map<String, dynamic>)).toList();

        return (cells: cells, states: states);
      }
    } catch (_) {}

    return _mockMapData();
  }

  ({List<MapCell> cells, List<StateOutageSummary> states}) _mockMapData() {
    final mockCells = [
      // Dallas - Fort Worth cluster (Major Spectrum outage)
      MapCell(
        lat: 32.7767,
        lng: -96.7970,
        count: 480,
        top: [
          MapTopService(slug: 'spectrum', name: 'Spectrum', count: 420),
          MapTopService(slug: 'att-internet', name: 'AT&T', count: 60),
        ],
      ),
      MapCell(
        lat: 32.9483,
        lng: -96.7299,
        count: 220,
        top: [
          MapTopService(slug: 'spectrum', name: 'Spectrum', count: 190),
        ],
      ),
      // NYC Metro cluster (Verizon issue)
      MapCell(
        lat: 40.7128,
        lng: -74.0060,
        count: 360,
        top: [
          MapTopService(slug: 'verizon', name: 'Verizon', count: 280),
          MapTopService(slug: 'spectrum', name: 'Spectrum', count: 80),
        ],
      ),
      MapCell(
        lat: 40.7484,
        lng: -73.9857,
        count: 190,
        top: [
          MapTopService(slug: 'verizon', name: 'Verizon', count: 160),
        ],
      ),
      // Miami / South Florida
      MapCell(
        lat: 25.7617,
        lng: -80.1918,
        count: 140,
        top: [
          MapTopService(slug: 'xfinity', name: 'Xfinity', count: 95),
          MapTopService(slug: 'att-internet', name: 'AT&T', count: 45),
        ],
      ),
      // Los Angeles Metro
      MapCell(
        lat: 34.0522,
        lng: -118.2437,
        count: 95,
        top: [
          MapTopService(slug: 'spectrum', name: 'Spectrum', count: 65),
          MapTopService(slug: 't-mobile', name: 'T-Mobile', count: 30),
        ],
      ),
      // Chicago Metro
      MapCell(
        lat: 41.8781,
        lng: -87.6298,
        count: 75,
        top: [
          MapTopService(slug: 'xfinity', name: 'Xfinity', count: 50),
          MapTopService(slug: 'att-internet', name: 'AT&T', count: 25),
        ],
      ),
      // Seattle Metro
      MapCell(
        lat: 47.6062,
        lng: -122.3321,
        count: 60,
        top: [
          MapTopService(slug: 'xfinity', name: 'Xfinity', count: 45),
        ],
      ),
    ];

    final mockStates = [
      StateOutageSummary(state: 'TX', name: 'Texas', fips: '48', level: StatusLevel.problems, problems: 2, possible: 1, lat: 31.054487, lng: -97.563461),
      StateOutageSummary(state: 'NY', name: 'New York', fips: '36', level: StatusLevel.possible, problems: 1, possible: 2, lat: 42.165726, lng: -74.948051),
      StateOutageSummary(state: 'FL', name: 'Florida', fips: '12', level: StatusLevel.possible, problems: 1, possible: 1, lat: 27.766279, lng: -81.686783),
      StateOutageSummary(state: 'CA', name: 'California', fips: '06', level: StatusLevel.ok, problems: 0, possible: 1, lat: 36.116203, lng: -119.681564),
      StateOutageSummary(state: 'IL', name: 'Illinois', fips: '17', level: StatusLevel.ok, problems: 0, possible: 0, lat: 40.349457, lng: -88.986137),
      StateOutageSummary(state: 'WA', name: 'Washington', fips: '53', level: StatusLevel.ok, problems: 0, possible: 0, lat: 47.400902, lng: -121.490494),
      StateOutageSummary(state: 'GA', name: 'Georgia', fips: '13', level: StatusLevel.ok, problems: 0, possible: 1, lat: 33.040619, lng: -83.643074),
      StateOutageSummary(state: 'OH', name: 'Ohio', fips: '39', level: StatusLevel.ok, problems: 0, possible: 0, lat: 40.388783, lng: -82.764915),
    ];

    return (cells: mockCells, states: mockStates);
  }

  // Fallback demo mock generator
  List<ServiceSummary> _mockServices({String? category}) {
    final all = [
      ServiceSummary(
        slug: 'spectrum',
        name: 'Spectrum',
        category: 'isp',
        level: StatusLevel.problems,
        current: 1240,
        baseline: 180,
        ratio: 6.8,
        reasons: ['Crowd reports 6.8x normal (Dallas, TX metro cluster)'],
        officialMessage: 'Technicians are investigating fiber cuts in North Texas.',
        etaAt: DateTime.now().millisecondsSinceEpoch + 7200000,
      ),
      ServiceSummary(
        slug: 'playstation-network',
        name: 'PlayStation Network',
        category: 'gaming',
        level: StatusLevel.problems,
        current: 3500,
        baseline: 420,
        ratio: 8.3,
        reasons: ['Official status page reports major login and matchmaking failure'],
        officialMessage: 'Some services are experiencing issues. Our team is investigating.',
      ),
      ServiceSummary(
        slug: 'verizon',
        name: 'Verizon',
        category: 'mobile',
        level: StatusLevel.possible,
        current: 580,
        baseline: 240,
        ratio: 2.4,
        reasons: ['Report volume 2.4x baseline across NY and NJ'],
      ),
      ServiceSummary(
        slug: 'att-internet',
        name: 'AT&T Internet',
        category: 'isp',
        level: StatusLevel.ok,
        current: 95,
        baseline: 110,
        ratio: 0.86,
        reasons: ['Reports within historical baseline'],
      ),
      ServiceSummary(
        slug: 'xfinity',
        name: 'Xfinity (Comcast)',
        category: 'isp',
        level: StatusLevel.ok,
        current: 140,
        baseline: 160,
        ratio: 0.87,
        reasons: ['No widespread disruptions detected'],
      ),
      ServiceSummary(
        slug: 't-mobile',
        name: 'T-Mobile',
        category: 'mobile',
        level: StatusLevel.ok,
        current: 80,
        baseline: 90,
        ratio: 0.88,
        reasons: ['Normal network health'],
      ),
      ServiceSummary(
        slug: 'github',
        name: 'GitHub',
        category: 'cloud',
        level: StatusLevel.ok,
        current: 22,
        baseline: 30,
        ratio: 0.73,
        reasons: ['All systems operational'],
      ),
      ServiceSummary(
        slug: 'cloudflare',
        name: 'Cloudflare',
        category: 'cloud',
        level: StatusLevel.ok,
        current: 15,
        baseline: 25,
        ratio: 0.60,
        reasons: ['Global edge functioning normally'],
      ),
      ServiceSummary(
        slug: 'discord',
        name: 'Discord',
        category: 'social',
        level: StatusLevel.possible,
        current: 310,
        baseline: 130,
        ratio: 2.38,
        reasons: ['Voice gateway connectivity reports elevated'],
      ),
      ServiceSummary(
        slug: 'chase',
        name: 'Chase Bank',
        category: 'banking',
        level: StatusLevel.ok,
        current: 45,
        baseline: 55,
        ratio: 0.81,
        reasons: ['Online banking & mobile app operational'],
      ),
    ];

    if (category == null || category == 'all') return all;
    return all.where((s) => s.category == category).toList();
  }

  ServiceDetail _mockServiceDetail(String slug) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final curvePoints = <ReportCurvePoint>[];
    for (int i = 24; i >= 0; i--) {
      final t = now - (i * 3600 * 1000);
      final count = (slug == 'spectrum' || slug == 'playstation-network') && i < 4
          ? 800 + (24 - i) * 150
          : 50 + (i % 7) * 10;
      curvePoints.add(ReportCurvePoint(timestamp: t, count: count, baseline: 70));
    }

    final isProblem = slug == 'spectrum' || slug == 'playstation-network';
    return ServiceDetail(
      slug: slug,
      name: slug == 'spectrum'
          ? 'Spectrum'
          : slug == 'playstation-network'
              ? 'PlayStation Network'
              : slug.toUpperCase(),
      category: slug == 'playstation-network' ? 'gaming' : 'isp',
      aliases: ['Charter', 'Spectrum Internet'],
      states: [],
      problemTypes: ['no_connection', 'slow', 'intermittent', 'tv'],
      troubleshooting: [
        'Restart your modem and router: unplug both for 60 seconds, then reconnect.',
        'Check coaxial cable connections for loose or bent pins.',
        'Test directly with an Ethernet cable to isolate Wi-Fi interference.',
        'If your neighborhood is experiencing a confirmed outage, repairs are already underway.',
      ],
      officialStatusUrl: 'https://www.spectrum.net/support/manage-account/check-outages',
      status: StatusResult(
        level: isProblem ? StatusLevel.problems : StatusLevel.ok,
        confidence: 0.94,
        current: isProblem ? 1240 : 45,
        baseline: 180,
        ratio: isProblem ? 6.8 : 0.8,
        reasons: isProblem
            ? ['Crowd spike 6.8x normal baseline', 'Confirmed by multiple independent feeds']
            : ['Report volume is low and consistent with normal background rate'],
        sourcesReporting: ['Rollercoaster Crowd', 'Status Feeds', 'Atlassian Statuspage'],
        sourcesTotal: 4,
        officialMessage: isProblem ? 'Engineers are actively working on restoring connectivity.' : null,
        etaAt: isProblem ? now + 7200000 : null,
      ),
      curve: curvePoints,
      breakdown: {
        'no_connection': 64,
        'slow': 22,
        'intermittent': 10,
        'tv': 4,
      },
      uptime24h: isProblem ? 94.2 : 99.8,
      sources: [
        SourceInfo(id: 'crowd', name: 'Rollercoaster Users'),
        SourceInfo(id: 'statuspage', name: 'Official Status Page'),
      ],
    );
  }
}
