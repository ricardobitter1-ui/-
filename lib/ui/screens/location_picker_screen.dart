import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../constants/geofence_constants.dart';
import '../../data/services/location_service.dart';
import '../theme/app_theme.dart';

/// Resultado do fluxo de escolha no mapa (OSM + pin).
class LocationPickerResult {
  const LocationPickerResult({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.locationLabel,
  });

  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String? locationLabel;
}

/// Mapa OSM com pin arrastável, raio em metros e rótulo opcional.
class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialRadiusMeters,
    this.initialLabel,
  });

  final double? initialLatitude;
  final double? initialLongitude;
  final double? initialRadiusMeters;
  final String? initialLabel;

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  late LatLng _markerPoint;
  late double _radiusMeters;
  bool _locating = false;
  final _mapController = MapController();
  final _markerKey = GlobalKey<DragMarkerWidgetState>();
  final _labelController = TextEditingController();

  static const LatLng _fallbackCenter = LatLng(-23.5505, -46.6333);

  @override
  void initState() {
    super.initState();
    final lat = widget.initialLatitude;
    final lng = widget.initialLongitude;
    if (lat != null && lng != null) {
      _markerPoint = LatLng(lat, lng);
    } else {
      _markerPoint = _fallbackCenter;
    }
    _radiusMeters = widget.initialRadiusMeters ??
        kDefaultGeofenceRadiusMeters;
    if (_radiusMeters < kMinGeofenceRadiusMeters) {
      _radiusMeters = kMinGeofenceRadiusMeters;
    }
    if (widget.initialLabel != null && widget.initialLabel!.isNotEmpty) {
      _labelController.text = widget.initialLabel!;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _centerOnGps() async {
    setState(() => _locating = true);
    try {
      final pos = await ref.read(locationServiceProvider).getCurrentLocation();
      if (!mounted) return;
      if (pos == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível obter a localização. Verifique permissões e GPS.',
            ),
          ),
        );
        return;
      }
      final ll = LatLng(pos.latitude, pos.longitude);
      setState(() => _markerPoint = ll);
      _mapController.move(ll, 16);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _confirm() {
    Navigator.of(context).pop(
      LocationPickerResult(
        latitude: _markerPoint.latitude,
        longitude: _markerPoint.longitude,
        radiusMeters: _radiusMeters,
        locationLabel: _labelController.text.trim().isEmpty
            ? null
            : _labelController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Onde lembrar'),
        actions: [
          TextButton(
            onPressed: _confirm,
            child: const Text('CONCLUIR'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _markerPoint,
                    initialZoom: 16,
                    onTap: (tapPosition, point) {
                      setState(() => _markerPoint = point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.exmtodo.todo_app',
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _markerPoint,
                          radius: _radiusMeters,
                          useRadiusInMeter: true,
                          color:
                              AppTheme.brandPrimary.withValues(alpha: 0.22),
                          borderStrokeWidth: 2,
                          borderColor:
                              AppTheme.brandPrimary.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                    DragMarkers(
                      markers: [
                        DragMarker(
                          key: _markerKey,
                          point: _markerPoint,
                          size: const Size(48, 48),
                          offset: const Offset(0, -24),
                          alignment: Alignment.bottomCenter,
                          builder: (context, _, isDragging) {
                            return Icon(
                              Icons.location_on,
                              size: isDragging ? 52 : 44,
                              color: AppTheme.brandPrimary,
                            );
                          },
                          onDragEnd: (_, point) {
                            setState(() => _markerPoint = point);
                          },
                        ),
                      ],
                    ),
                    SimpleAttributionWidget(
                      source: const Text(
                        'OpenStreetMap',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _locating ? null : _centerOnGps,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: _locating
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.my_location_rounded,
                                color: AppTheme.brandPrimary,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Toque no mapa ou arraste o pin. Raio pequeno pode falhar por imprecisão do GPS.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Raio: '),
                Expanded(
                  child: Slider(
                    value: _radiusMeters.clamp(50, 500),
                    min: 50,
                    max: 500,
                    divisions: 18,
                    label: '${_radiusMeters.round()} m',
                    onChanged: (v) => setState(() => _radiusMeters = v),
                  ),
                ),
                SizedBox(
                  width: 52,
                  child: Text(
                    '${_radiusMeters.round()} m',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('50 m'),
                  selected: _radiusMeters.round() == 50,
                  onSelected: (_) =>
                      setState(() => _radiusMeters = kMinGeofenceRadiusMeters),
                ),
                ChoiceChip(
                  label: const Text('100 m'),
                  selected: (_radiusMeters - 100).abs() < 8,
                  onSelected: (_) =>
                      setState(() => _radiusMeters = kDefaultGeofenceRadiusMeters),
                ),
                ChoiceChip(
                  label: const Text('200 m'),
                  selected: (_radiusMeters - 200).abs() < 8,
                  onSelected: (_) => setState(() => _radiusMeters = 200),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Nome do lugar (opcional)',
                hintText: 'Ex.: Mercado, trabalho',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
        ],
      ),
    );
  }
}
