import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles_pmtiles/vector_map_tiles_pmtiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

/// Hosted vector basemap (Zambia PMTiles on Cloudflare R2) with an
/// OpenStreetMap raster fallback. Same hosted map stack used across the
/// ChurchOnApp / Carpso fleet. No API keys required.
class HostedMap extends StatefulWidget {
  final LatLng center;
  final double zoom;
  final List<Marker> markers;
  final List<Polyline> polylines;
  final MapOptions? options;

  const HostedMap({
    super.key,
    this.center = const LatLng(-15.3875, 28.3228),
    this.zoom = 12,
    this.markers = const [],
    this.polylines = const [],
    this.options,
  });

  @override
  State<HostedMap> createState() => _HostedMapState();
}

class _HostedMapState extends State<HostedMap> {
  PmTilesVectorTileProvider? _provider;
  vtr.Theme? _theme;
  bool _vectorReady = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final provider = await PmTilesVectorTileProvider.fromSource(
        'https://maps.churchonapp.com/zambia.pmtiles',
      );
      if (!mounted) return;
      setState(() {
        _provider = provider;
        _theme = ProtomapsThemes.lightV4();
        _vectorReady = true;
      });
    } catch (_) {
      // R2 archive unavailable — OSM raster layer stays active as fallback.
    }
  }

  @override
  void dispose() {
    _provider?.archive.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: widget.options ??
          MapOptions(
            initialCenter: widget.center,
            initialZoom: widget.zoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
      children: [
        if (_vectorReady && _provider != null && _theme != null)
          VectorTileLayer(
            tileProviders: TileProviders({'protomaps': _provider!}),
            theme: _theme!,
          )
        else
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.grandelephants.shop',
          ),
        if (widget.polylines.isNotEmpty) PolylineLayer(polylines: widget.polylines),
        if (widget.markers.isNotEmpty) MarkerLayer(markers: widget.markers),
      ],
    );
  }
}

/// Builds a delivery-style marker pin.
Marker buildDeliveryMarker(LatLng point, IconData icon, Color color) {
  return Marker(
    point: point,
    width: 44,
    height: 44,
    child: Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    ),
  );
}