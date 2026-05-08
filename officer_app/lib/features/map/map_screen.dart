import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../tickets/data/ticket_data.dart';

// ── Hotspot model & provider ──────────────────────────────────────────────
class ViolationHotspot {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final int count;
  final String severity;
  const ViolationHotspot({required this.id, required this.name, required this.lat, required this.lng, required this.count, required this.severity});
  factory ViolationHotspot.fromJson(Map<String, dynamic> j) => ViolationHotspot(
    id: j['id']?.toString() ?? '',
    name: j['name'] ?? j['intersection_name'] ?? 'Hotspot',
    lat: (j['lat'] ?? j['latitude'] ?? 9.0).toDouble(),
    lng: (j['lng'] ?? j['longitude'] ?? 38.7).toDouble(),
    count: j['count'] ?? j['violation_count'] ?? 0,
    severity: j['severity'] ?? 'MINOR',
  );
}

final hotspotsProvider = FutureProvider.autoDispose<List<ViolationHotspot>>((ref) async {
  try {
    final res = await ref.watch(apiClientProvider).get('/admin/analytics/violations/', query: {'group_by': 'location', 'period': 'week'});
    final data = res.data;
    List list = [];
    if (data is Map && data['results'] is List) list = data['results'] as List;
    else if (data is List) list = data;
    return list.whereType<Map<String, dynamic>>().map(ViolationHotspot.fromJson).toList();
  } catch (_) {
    // Return Addis Ababa sample hotspots as fallback for demo
    return [
      const ViolationHotspot(id: '1', name: 'Mexico Square', lat: 9.0227, lng: 38.7468, count: 47, severity: 'CRITICAL'),
      const ViolationHotspot(id: '2', name: 'Bole Road', lat: 8.9961, lng: 38.7871, count: 31, severity: 'MAJOR'),
      const ViolationHotspot(id: '3', name: 'Piassa', lat: 9.0335, lng: 38.7536, count: 28, severity: 'MAJOR'),
      const ViolationHotspot(id: '4', name: 'Megenagna', lat: 9.0196, lng: 38.8029, count: 22, severity: 'MINOR'),
      const ViolationHotspot(id: '5', name: 'Sarbet', lat: 8.9897, lng: 38.7611, count: 18, severity: 'MINOR'),
      const ViolationHotspot(id: '6', name: 'Gotera', lat: 9.0048, lng: 38.7434, count: 15, severity: 'MINOR'),
    ];
  }
});

// ── Map Screen ─────────────────────────────────────────────────────────────
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  // Default: Addis Ababa center
  static const _defaultCenter = LatLng(9.0222, 38.7468);
  String _selectedLayer = 'hotspots'; // hotspots | tickets | zones
  ViolationHotspot? _selectedHotspot;

  @override
  Widget build(BuildContext context) {
    final hotspotsAsync = ref.watch(hotspotsProvider);
    final ticketsAsync  = ref.watch(ticketsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Enforcement Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_outlined),
            onPressed: () => _mapController.move(_defaultCenter, 13),
          ),
          IconButton(
            icon: const Icon(Icons.layers_outlined),
            onPressed: () => _showLayerSheet(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map ───────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 13,
              minZoom: 10,
              maxZoom: 18,
            ),
            children: [
              // OSM tile layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.itms.officer_app',
                maxZoom: 19,
              ),

              // Hotspot circles
              if (_selectedLayer == 'hotspots')
                hotspotsAsync.when(
                  loading: () => const CircleLayer<Object>(circles: []),
                  error: (_, __) => const CircleLayer<Object>(circles: []),
                  data: (hotspots) => CircleLayer(
                    circles: hotspots.map((h) => CircleMarker(
                      point: LatLng(h.lat, h.lng),
                      radius: _radiusForCount(h.count),
                      color: _colorForSeverity(h.severity).withValues(alpha: 0.35),
                      borderColor: _colorForSeverity(h.severity),
                      borderStrokeWidth: 1.5,
                      useRadiusInMeter: false,
                    )).toList(),
                  ),
                ),

              // Hotspot markers
              if (_selectedLayer == 'hotspots')
                hotspotsAsync.when(
                  loading: () => const MarkerLayer(markers: []),
                  error: (_, __) => const MarkerLayer(markers: []),
                  data: (hotspots) => MarkerLayer(
                    markers: hotspots.map((h) => Marker(
                      point: LatLng(h.lat, h.lng),
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedHotspot = h),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _colorForSeverity(h.severity),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.white, width: 2),
                            boxShadow: AppShadows.card,
                          ),
                          child: Center(
                            child: Text('${h.count}',
                                style: AppTypography.caption.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                ),

              // Officer ticket pins
              if (_selectedLayer == 'tickets')
                ticketsAsync.when(
                  loading: () => const MarkerLayer(markers: []),
                  error: (_, __) => const MarkerLayer(markers: []),
                  data: (page) => MarkerLayer(
                    markers: page.results
                        .where((t) => t.locationLat != null && t.locationLng != null)
                        .map((t) => Marker(
                          point: LatLng(t.locationLat!, t.locationLng!),
                          width: 32,
                          height: 32,
                          child: GestureDetector(
                            onTap: () => context.push('/tickets/${t.id}'),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                                border: Border.all(color: AppColors.white, width: 1.5),
                              ),
                              child: const Icon(Icons.receipt_long_outlined, size: 16, color: AppColors.white),
                            ),
                          ),
                        )).toList(),
                  ),
                ),
            ],
          ),

          // ── Layer legend ──────────────────────────────────────────────
          Positioned(
            top: AppSpacing.md,
            left: AppSpacing.md,
            child: _LayerChip(
              label: _selectedLayer == 'hotspots' ? '🔴 Hotspots' : _selectedLayer == 'tickets' ? '📍 My Tickets' : '🟡 Zones',
              onTap: () => _showLayerSheet(context),
            ),
          ),

          // ── Stats overlay ─────────────────────────────────────────────
          Positioned(
            top: AppSpacing.md,
            right: AppSpacing.md,
            child: hotspotsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (h) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.radiusMd,
                  boxShadow: AppShadows.card,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${h.length} hotspots', style: AppTypography.labelSmall),
                    Text('${h.fold(0, (s, x) => s + x.count)} violations', style: AppTypography.caption),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom info card ──────────────────────────────────────────
          if (_selectedHotspot != null)
            Positioned(
              bottom: AppSpacing.md + 80,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: _HotspotInfoCard(
                hotspot: _selectedHotspot!,
                onClose: () => setState(() => _selectedHotspot = null),
                onTicket: () {
                  setState(() => _selectedHotspot = null);
                  context.push('/new-ticket');
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/new-ticket'),
        icon: const Icon(Icons.add),
        label: const Text('New Ticket Here'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
    );
  }

  double _radiusForCount(int count) => (count / 5.0).clamp(6.0, 24.0);

  Color _colorForSeverity(String s) => switch (s) {
    'CRITICAL' => AppColors.danger,
    'MAJOR'    => AppColors.warning,
    _          => AppColors.info,
  };

  void _showLayerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Map Layers', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.md),
            ...[
              ('hotspots', Icons.local_fire_department_outlined, 'Violation Hotspots', 'Clustered violation heat zones'),
              ('tickets',  Icons.receipt_long_outlined,          'My Tickets',          'Tickets you have issued'),
              ('zones',    Icons.location_city_outlined,         'Enforcement Zones',   'Assigned patrol areas'),
            ].map((l) => ListTile(
              leading: Icon(l.$2, color: _selectedLayer == l.$1 ? AppColors.primary : AppColors.textSecondary),
              title: Text(l.$3, style: AppTypography.labelLarge.copyWith(
                  color: _selectedLayer == l.$1 ? AppColors.primary : AppColors.textPrimary)),
              subtitle: Text(l.$4, style: AppTypography.bodySmall),
              trailing: _selectedLayer == l.$1 ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
              onTap: () {
                setState(() => _selectedLayer = l.$1);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: AppSpacing.md),
            // Legend
            Text('Legend', style: AppTypography.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            Row(children: [
              _LegendDot(color: AppColors.danger,  label: 'Critical'),
              const SizedBox(width: AppSpacing.md),
              _LegendDot(color: AppColors.warning, label: 'Major'),
              const SizedBox(width: AppSpacing.md),
              _LegendDot(color: AppColors.info,    label: 'Minor'),
            ]),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _LayerChip extends StatelessWidget {
  const _LayerChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.border), boxShadow: AppShadows.card,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: AppTypography.labelSmall),
        const SizedBox(width: 4),
        const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
      ]),
    ),
  );
}

class _HotspotInfoCard extends StatelessWidget {
  const _HotspotInfoCard({required this.hotspot, required this.onClose, required this.onTicket});
  final ViolationHotspot hotspot;
  final VoidCallback onClose;
  final VoidCallback onTicket;
  @override
  Widget build(BuildContext context) {
    final col = switch (hotspot.severity) {
      'CRITICAL' => AppColors.danger, 'MAJOR' => AppColors.warning, _ => AppColors.info,
    };
    return AppCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(hotspot.name, style: AppTypography.labelLarge)),
            IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onClose, visualDensity: VisualDensity.compact),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            StatusBadge(label: '${hotspot.count} violations', type: BadgeType.danger, compact: true),
            const SizedBox(width: 8),
            StatusBadge(label: hotspot.severity, type: switch (hotspot.severity) {
              'CRITICAL' => BadgeType.danger, 'MAJOR' => BadgeType.warning, _ => BadgeType.info,
            }, compact: true),
          ]),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Issue Ticket at This Location',
            icon: Icons.add_circle_outline,
            compact: true,
            onPressed: onTicket,
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: AppTypography.caption),
  ]);
}
